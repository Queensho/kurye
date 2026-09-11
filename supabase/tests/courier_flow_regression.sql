-- Runs entirely inside a transaction and rolls back all fixtures.
-- Covers single-winner claim semantics, one-active-job guard, stale courier
-- presence, realtime publication and idempotent delivery earnings.
begin;

do $$
declare
  v_customer uuid := gen_random_uuid();
  v_courier1 uuid := gen_random_uuid();
  v_courier2 uuid := gen_random_uuid();
  v_shipment1 uuid := gen_random_uuid();
  v_shipment2 uuid := gen_random_uuid();
  v_count integer;
begin
  insert into auth.users(id,aud,role,created_at,updated_at,is_sso_user,is_anonymous)
  values
    (v_customer,'authenticated','authenticated',now(),now(),false,false),
    (v_courier1,'authenticated','authenticated',now(),now(),false,false),
    (v_courier2,'authenticated','authenticated',now(),now(),false,false);

  insert into public.profiles(id,full_name,account_status)
  values
    (v_customer,'Test Customer','active'),
    (v_courier1,'Test Courier 1','active'),
    (v_courier2,'Test Courier 2','active');

  insert into public.couriers(user_id,is_approved,is_online,vehicle_type,last_seen_at)
  values
    (v_courier1,true,true,'motorcycle',now()),
    (v_courier2,true,true,'motorcycle',now());

  insert into public.shipments(id,user_id,status,vehicle_type,package_type,pickup_address,dropoff_address,estimated_price,courier_earning)
  values
    (v_shipment1,v_customer,'searching','motorcycle','package','A','B',100,80),
    (v_shipment2,v_customer,'searching','motorcycle','package','C','D',120,90);

  perform set_config('request.jwt.claim.sub', v_courier1::text, true);
  perform public.claim_shipment(v_shipment1);

  if not exists(select 1 from public.shipments where id=v_shipment1 and courier_id=v_courier1 and status='accepted') then
    raise exception 'first courier did not win shipment';
  end if;

  perform set_config('request.jwt.claim.sub', v_courier2::text, true);
  begin
    perform public.claim_shipment(v_shipment1);
    raise exception 'second courier unexpectedly claimed same shipment';
  exception when others then
    if position('shipment_already_claimed_or_unavailable' in sqlerrm)=0 then
      raise;
    end if;
  end;

  perform set_config('request.jwt.claim.sub', v_courier1::text, true);
  begin
    perform public.claim_shipment(v_shipment2);
    raise exception 'courier unexpectedly claimed a second active job';
  exception when others then
    if position('courier_already_has_active_job' in sqlerrm)=0 then
      raise;
    end if;
  end;

  perform public.update_shipment_status(v_shipment1,'at_pickup');
  perform public.update_shipment_status(v_shipment1,'picked_up');
  perform public.update_shipment_status(v_shipment1,'at_dropoff');
  perform public.update_shipment_status(v_shipment1,'delivered');

  update public.shipments set status='delivered' where id=v_shipment1;
  select count(*) into v_count
  from public.courier_earnings
  where shipment_id=v_shipment1 and entry_type='delivery';
  if v_count <> 1 then
    raise exception 'delivery earning is not idempotent: % rows', v_count;
  end if;

  update public.couriers
  set is_online=true,last_seen_at=now()-interval '10 minutes'
  where user_id=v_courier2;
  perform set_config('request.jwt.claim.sub', v_courier2::text, true);
  begin
    perform public.claim_shipment(v_shipment2);
    raise exception 'stale courier unexpectedly claimed shipment';
  exception when others then
    if position('courier_offline' in sqlerrm)=0 then
      raise;
    end if;
  end;

  perform public.set_courier_online(true,'motorcycle',null,null);
  perform public.claim_shipment(v_shipment2);
  if not exists(select 1 from public.shipments where id=v_shipment2 and courier_id=v_courier2 and status='accepted') then
    raise exception 'fresh courier could not claim shipment';
  end if;

  if not exists(
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='shipments'
  ) then
    raise exception 'shipments is not in supabase_realtime publication';
  end if;
end $$;

rollback;
