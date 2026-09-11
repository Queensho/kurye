-- Customer -> pool -> courier -> live statuses -> delivered -> rating/support/repeat.
-- The whole test is rolled back and leaves no fixtures behind.
begin;

do $$
declare
  v_customer uuid := gen_random_uuid();
  v_courier uuid := gen_random_uuid();
  v_created jsonb;
  v_repeat jsonb;
  v_cancel jsonb;
  v_shipment uuid;
  v_cancel_shipment uuid;
  v_rating_count integer;
  v_ticket_count integer;
begin
  insert into auth.users(id,aud,role,created_at,updated_at,is_sso_user,is_anonymous)
  values
    (v_customer,'authenticated','authenticated',now(),now(),false,false),
    (v_courier,'authenticated','authenticated',now(),now(),false,false);

  insert into public.profiles(id,full_name,phone,account_status)
  values
    (v_customer,'E2E Customer','05550000001','active'),
    (v_courier,'E2E Courier','05550000002','active');

  insert into public.couriers(user_id,is_approved,is_online,vehicle_type,last_seen_at,plate_number)
  values(v_courier,true,true,'motorcycle',now(),'34 E2E 001');

  perform set_config('request.jwt.claim.sub', v_customer::text, true);
  v_created := public.create_priced_shipment(
    'motorcycle','package','Test Pickup','Test Dropoff',
    41.0001,29.0001,41.0101,29.0101,
    '2 kg','Küçük','E2E package',3.5,18,'cash',null,
    'Test Recipient','05551234567','Bina 1 Kat 2','Bina 2 Kat 3','Kapıya bırakma'
  );
  v_shipment := (v_created->>'id')::uuid;

  if not exists(select 1 from public.shipments where id=v_shipment and status='searching' and courier_id is null) then
    raise exception 'shipment did not enter courier pool';
  end if;

  perform set_config('request.jwt.claim.sub', v_courier::text, true);
  perform public.claim_shipment(v_shipment);
  if not exists(select 1 from public.shipments where id=v_shipment and courier_id=v_courier and status='accepted') then
    raise exception 'courier did not claim shipment';
  end if;

  perform public.update_shipment_status(v_shipment,'at_pickup');
  perform public.update_shipment_status(v_shipment,'picked_up');
  perform public.update_shipment_status(v_shipment,'at_dropoff');
  perform public.update_shipment_status(v_shipment,'delivered');

  if not exists(select 1 from public.shipments where id=v_shipment and status='delivered' and delivered_at is not null) then
    raise exception 'shipment did not reach delivered state';
  end if;

  perform set_config('request.jwt.claim.sub', v_customer::text, true);
  perform public.submit_shipment_rating(v_shipment,5,'E2E great delivery',null);
  select count(*) into v_rating_count from public.shipment_ratings where shipment_id=v_shipment and customer_id=v_customer;
  if v_rating_count <> 1 then raise exception 'rating was not persisted'; end if;

  perform public.create_support_ticket(v_shipment,'other','E2E support test');
  select count(*) into v_ticket_count from public.support_tickets where shipment_id=v_shipment and user_id=v_customer;
  if v_ticket_count <> 1 then raise exception 'support ticket was not persisted'; end if;

  v_repeat := public.repeat_customer_shipment(v_shipment);
  if not exists(select 1 from public.shipments where id=(v_repeat->>'id')::uuid and status='searching' and recipient_phone='05551234567') then
    raise exception 'repeat shipment did not preserve recipient details';
  end if;

  -- Cancellation policy: free while searching, 20 TL after courier acceptance.
  v_created := public.create_priced_shipment(
    'motorcycle','package','Cancel Pickup','Cancel Dropoff',
    41.0002,29.0002,41.0202,29.0202,
    '1 kg','Küçük',null,2.5,15,'cash',null,
    'Cancel Recipient','05557654321',null,null,null
  );
  v_cancel_shipment := (v_created->>'id')::uuid;

  perform set_config('request.jwt.claim.sub', v_courier::text, true);
  perform public.claim_shipment(v_cancel_shipment);
  perform set_config('request.jwt.claim.sub', v_customer::text, true);
  v_cancel := public.customer_cancel_shipment(v_cancel_shipment,'E2E cancellation');

  if (v_cancel->>'status') <> 'cancelled' or coalesce((v_cancel->>'cancellation_fee')::integer,-1) <> 20 then
    raise exception 'accepted cancellation policy failed';
  end if;
  if exists(select 1 from public.couriers where user_id=v_courier and active_shipment_id=v_cancel_shipment) then
    raise exception 'cancelled shipment still active on courier';
  end if;
end $$;

rollback;
