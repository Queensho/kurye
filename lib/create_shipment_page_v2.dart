import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'address_picker_page.dart';
import 'courier_search_page.dart';

class CreateShipmentPage extends StatefulWidget {
  const CreateShipmentPage({super.key});

  @override
  State<CreateShipmentPage> createState() => _CreateShipmentPageState();
}

class _CreateShipmentPageState extends State<CreateShipmentPage> {
  static const blue = Color(0xFF168CF5);
  static const navy = Color(0xFF10182D);
  static const muted = Color(0xFF7C879C);

  int vehicle = 0;
  int detail = 0;
  AddressSelection? pickup;
  AddressSelection? dropoff;
  bool calculatingRoute = false;
  double? routeDistanceKm;
  int? routeDurationMin;
  List<LatLng> routePoints = [];

  bool get hasAddresses => pickup != null && dropoff != null;
  bool get routeReady => hasAddresses && !calculatingRoute && routeDistanceKm != null;

  int get estimatedPrice {
    final distance = routeDistanceKm ?? 0;
    final base = vehicle == 0 ? 65.0 : 95.0;
    final perKm = vehicle == 0 ? 10.0 : 14.0;
    return (base + (distance * perKm)).round();
  }

  Future<void> _pickAddress({required bool isPickup}) async {
    final result = await Navigator.of(context).push<AddressSelection>(
      MaterialPageRoute(
        builder: (_) => AddressPickerPage(
          title: isPickup ? 'Alım Adresi' : 'Teslimat Adresi',
          initial: isPickup ? pickup : dropoff,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (isPickup) {
        pickup = result;
      } else {
        dropoff = result;
      }
    });
    if (hasAddresses) await _calculateRoute();
  }

  Future<void> _calculateRoute() async {
    final a = pickup;
    final b = dropoff;
    if (a == null || b == null) return;
    setState(() {
      calculatingRoute = true;
      routeDistanceKm = null;
      routeDurationMin = null;
      routePoints = [];
    });

    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${a.lng},${a.lat};${b.lng},${b.lat}'
        '?overview=full&geometries=geojson&steps=false',
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) throw Exception('Rota servisi yanıt vermedi');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) throw Exception('Rota bulunamadı');
      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List<dynamic>;
      final points = coordinates.map((e) {
        final pair = e as List<dynamic>;
        return LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());
      }).toList();
      if (!mounted) return;
      setState(() {
        routeDistanceKm = ((route['distance'] as num).toDouble() / 1000);
        routeDurationMin = (((route['duration'] as num).toDouble() / 60).ceil());
        routePoints = points;
      });
    } catch (_) {
      final straightKm = const Distance().as(
            LengthUnit.Kilometer,
            a.point,
            b.point,
          );
      if (!mounted) return;
      setState(() {
        routeDistanceKm = straightKm * 1.25;
        routeDurationMin = ((straightKm * 1.25) / (vehicle == 0 ? 28 : 24) * 60).ceil();
        routePoints = [a.point, b.point];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Canlı rota alınamadı, yaklaşık mesafe hesaplandı.')),
      );
    } finally {
      if (mounted) setState(() => calculatingRoute = false);
    }
  }

  void _showMapPreview() {
    if (!hasAddresses) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final a = pickup!;
        final b = dropoff!;
        final center = LatLng((a.lat + b.lat) / 2, (a.lng + b.lng) / 2);
        return FractionallySizedBox(
          heightFactor: .72,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 44, height: 5, decoration: BoxDecoration(color: const Color(0xFFDCE3EC), borderRadius: BorderRadius.circular(10))),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
                child: Row(
                  children: [
                    const Expanded(child: Text('Gönderi Rotası', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: navy))),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                  ],
                ),
              ),
              Expanded(
                child: FlutterMap(
                  options: MapOptions(initialCenter: center, initialZoom: 10.5, minZoom: 5, maxZoom: 18),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.queensho.kurye',
                    ),
                    if (routePoints.isNotEmpty)
                      PolylineLayer(polylines: [Polyline(points: routePoints, strokeWidth: 5, color: blue)]),
                    MarkerLayer(markers: [
                      Marker(
                        point: a.point,
                        width: 54,
                        height: 54,
                        child: _mapPin(blue, Icons.trip_origin_rounded),
                      ),
                      Marker(
                        point: b.point,
                        width: 54,
                        height: 54,
                        child: _mapPin(const Color(0xFF19C983), Icons.location_on_rounded),
                      ),
                    ]),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: _mapStat(Icons.route_rounded, routeDistanceKm == null ? '—' : '${routeDistanceKm!.toStringAsFixed(1)} km', 'Mesafe')),
                    const SizedBox(width: 10),
                    Expanded(child: _mapStat(Icons.schedule_rounded, routeDurationMin == null ? '—' : '$routeDurationMin dk', 'Tahmini süre')),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _mapPin(Color color, IconData icon) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 12)],
        ),
        child: Icon(icon, color: color, size: 30),
      );

  Widget _mapStat(IconData icon, String value, String label) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: const Color(0xFFF2F7FD), borderRadius: BorderRadius.circular(17)),
        child: Row(children: [
          Icon(icon, color: blue),
          const SizedBox(width: 9),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: navy)),
            Text(label, style: const TextStyle(fontSize: 10, color: muted)),
          ]),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, c) {
          final s = c.maxWidth / 390;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16*s,14*s,16*s,24*s),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _round(s, Icons.arrow_back_rounded, () => Navigator.of(context).pop()),
                SizedBox(width:14*s),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                  Text('Gönderi Oluştur',style:TextStyle(fontSize:25*s,fontWeight:FontWeight.w900,color:navy)),
                  Text('Hızlı, güvenli ve kolay',style:TextStyle(fontSize:14*s,color:muted)),
                ])),
                _round(s, Icons.help_outline_rounded, (){}),
              ]),
              SizedBox(height:16*s),
              Container(height:70*s,decoration:BoxDecoration(color:const Color(0xFFE9F4FF),borderRadius:BorderRadius.circular(18*s)),child:Stack(children:[
                Positioned(left:12*s,top:15*s,child:Container(width:40*s,height:40*s,decoration:BoxDecoration(color:blue,borderRadius:BorderRadius.circular(13*s)),child:Icon(Icons.bolt_rounded,color:Colors.white,size:27*s))),
                Positioned(left:63*s,top:14*s,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Dakikalar içinde kurye yola çıksın!',style:TextStyle(fontSize:12*s,fontWeight:FontWeight.w800,color:const Color(0xFF163C80))),SizedBox(height:4*s),Text('İhtiyacın ne olursa olsun yanındayız.',style:TextStyle(fontSize:10.5*s,color:const Color(0xFF31578D)))])),
                Positioned(right:-3*s,bottom:-5*s,width:135*s,height:88*s,child:Image.asset('assets/images/kurye_header_hd.png',fit:BoxFit.contain,alignment:Alignment.bottomRight,filterQuality:FilterQuality.high)),
              ])),
              SizedBox(height:20*s),
              Row(children:[Expanded(child:Text('Taşıma Türü',style:TextStyle(fontSize:19*s,fontWeight:FontWeight.w900,color:navy))),Text('Hangisini seçmeliyim?',style:TextStyle(fontSize:11*s,color:blue)),Icon(Icons.chevron_right_rounded,color:blue,size:18*s)]),
              SizedBox(height:10*s),
              Row(children:[
                Expanded(child:_vehicle(s,0,'Motosiklet','Hızlı ve pratik','Genellikle 10–30 dk','assets/images/motosiklet_hd.png')),
                SizedBox(width:10*s),
                Expanded(child:_vehicle(s,1,'Araç','Daha büyük gönderiler','Genellikle 20–60 dk','assets/images/arac_hd.png')),
              ]),
              SizedBox(height:16*s),
              _card(s, Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Row(children:[
                  Expanded(child:Text('Adres Bilgileri',style:TextStyle(fontSize:18*s,fontWeight:FontWeight.w900,color:navy))),
                  InkWell(
                    onTap: hasAddresses ? _showMapPreview : () => _pickAddress(isPickup: pickup == null),
                    borderRadius: BorderRadius.circular(12*s),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal:6*s,vertical:5*s),
                      child: Row(children:[Icon(Icons.map_outlined,color:blue,size:19*s),SizedBox(width:5*s),Text(hasAddresses?'Haritada Gör':'Haritadan Seç',style:TextStyle(fontSize:11.5*s,color:blue,fontWeight:FontWeight.w800))]),
                    ),
                  ),
                ]),
                SizedBox(height:14*s),
                _addressField(s,'Alım Adresi','Türkiye genelinde adres ara',pickup,Icons.trip_origin_rounded,()=>_pickAddress(isPickup:true)),
                SizedBox(height:10*s),
                _addressField(s,'Teslimat Adresi','Türkiye genelinde adres ara',dropoff,Icons.location_on_rounded,()=>_pickAddress(isPickup:false)),
                if (hasAddresses) ...[
                  SizedBox(height:10*s),
                  InkWell(
                    onTap:_showMapPreview,
                    borderRadius:BorderRadius.circular(14*s),
                    child:Container(
                      height:43*s,
                      padding:EdgeInsets.symmetric(horizontal:12*s),
                      decoration:BoxDecoration(color:const Color(0xFFEAF4FF),borderRadius:BorderRadius.circular(14*s)),
                      child:Row(children:[Icon(Icons.map_rounded,color:blue,size:21*s),SizedBox(width:9*s),Expanded(child:Text('Rotayı haritada gör',style:TextStyle(fontSize:11.5*s,color:blue,fontWeight:FontWeight.w800))),Icon(Icons.chevron_right_rounded,color:blue,size:20*s)]),
                    ),
                  ),
                ],
                SizedBox(height:10*s),
                Container(height:43*s,padding:EdgeInsets.symmetric(horizontal:12*s),decoration:BoxDecoration(color:const Color(0xFFF1F5FA),borderRadius:BorderRadius.circular(14*s)),child:Row(children:[Container(width:26*s,height:26*s,decoration:const BoxDecoration(color:Color(0xFF6EB5FF),shape:BoxShape.circle),child:Icon(Icons.add_rounded,color:Colors.white,size:19*s)),SizedBox(width:10*s),Text('Ara durak ekle (isteğe bağlı)',style:TextStyle(fontSize:11.5*s,color:const Color(0xFF64748B),fontWeight:FontWeight.w600))]))
              ])),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: hasAddresses ? Padding(
                  key: const ValueKey('price'),
                  padding: EdgeInsets.only(top:16*s),
                  child: calculatingRoute ? _calculatingCard(s) : _priceCard(s),
                ) : const SizedBox.shrink(key: ValueKey('empty')),
              ),
              SizedBox(height:16*s),
              _card(s, Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text('Gönderi Detayları',style:TextStyle(fontSize:18*s,fontWeight:FontWeight.w900,color:navy)),SizedBox(height:12*s),
                Row(children:[Expanded(child:_chip(s,0,Icons.inventory_2_outlined,'Paket')),SizedBox(width:7*s),Expanded(child:_chip(s,1,Icons.restaurant_rounded,'Yiyecek')),SizedBox(width:7*s),Expanded(child:_chip(s,2,Icons.description_outlined,'Belge')),SizedBox(width:7*s),Expanded(child:_chip(s,3,Icons.grid_view_rounded,'Diğer'))]),
                SizedBox(height:10*s),
                Row(children:[Expanded(child:_select(s,Icons.scale_outlined,'Tahmini Ağırlık')),SizedBox(width:10*s),Expanded(child:_select(s,Icons.inventory_2_outlined,'Tahmini Boyut'))]),
                SizedBox(height:10*s),
                Container(height:64*s,padding:EdgeInsets.symmetric(horizontal:12*s),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15*s),border:Border.all(color:const Color(0xFFE7ECF3))),child:Row(children:[Icon(Icons.chat_bubble_outline_rounded,color:const Color(0xFF65748A),size:20*s),SizedBox(width:10*s),Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Ek Not (isteğe bağlı)',style:TextStyle(fontSize:11*s,color:const Color(0xFF64748B),fontWeight:FontWeight.w600)),Text('Örn: Dikkatli taşınsın, kapıya bırakın, arayın...',maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:9.5*s,color:const Color(0xFFA0A9B9))) ]))]))
              ])),
              SizedBox(height:16*s),
              SizedBox(width:double.infinity,height:58*s,child:ElevatedButton.icon(
                onPressed: routeReady ? (){Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CourierSearchPage()));} : null,
                icon:Icon(Icons.send_rounded,color:Colors.white,size:22*s),
                label:Text(
                  !hasAddresses ? 'Adresleri Seç' : calculatingRoute ? 'Ücret Hesaplanıyor...' : 'Gönderi Oluştur • ₺$estimatedPrice',
                  style:TextStyle(fontSize:17*s,fontWeight:FontWeight.w800),
                ),
                style:ElevatedButton.styleFrom(backgroundColor:blue,disabledBackgroundColor:const Color(0xFFB7C7D8),foregroundColor:Colors.white,disabledForegroundColor:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20*s)),elevation:0)
              )),
            ]),
          );
        }),
      ),
    );
  }

  Widget _calculatingCard(double s)=>Container(
    width:double.infinity,
    padding:EdgeInsets.all(16*s),
    decoration:BoxDecoration(color:const Color(0xFFEAF4FF),borderRadius:BorderRadius.circular(22*s)),
    child:Row(children:[SizedBox(width:26*s,height:26*s,child:const CircularProgressIndicator(strokeWidth:3)),SizedBox(width:12*s),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Rota ve ücret hesaplanıyor',style:TextStyle(fontSize:14*s,fontWeight:FontWeight.w900,color:navy)),Text('Gerçek yol mesafesi alınıyor...',style:TextStyle(fontSize:10.5*s,color:muted))]))]),
  );

  Widget _priceCard(double s) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(15*s),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors:[Color(0xFF168CF5),Color(0xFF3AA7FF)]),
      borderRadius: BorderRadius.circular(22*s),
      boxShadow: const [BoxShadow(color:Color(0x25168CF5),blurRadius:18,offset:Offset(0,7))],
    ),
    child: Row(children:[
      Container(width:46*s,height:46*s,decoration:BoxDecoration(color:Colors.white.withValues(alpha:.18),shape:BoxShape.circle),child:Icon(Icons.payments_rounded,color:Colors.white,size:24*s)),
      SizedBox(width:12*s),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('Tahmini Ücret',style:TextStyle(fontSize:12*s,color:Colors.white.withValues(alpha:.86),fontWeight:FontWeight.w700)),
        Text('₺$estimatedPrice',style:TextStyle(fontSize:27*s,color:Colors.white,fontWeight:FontWeight.w900)),
        Text('${routeDistanceKm?.toStringAsFixed(1) ?? '—'} km • yaklaşık ${routeDurationMin ?? '—'} dk',style:TextStyle(fontSize:10.5*s,color:Colors.white.withValues(alpha:.82),fontWeight:FontWeight.w600)),
      ])),
      Container(padding:EdgeInsets.symmetric(horizontal:10*s,vertical:7*s),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(14*s)),child:Text(vehicle==0?'Motosiklet':'Araç',style:TextStyle(fontSize:10*s,color:blue,fontWeight:FontWeight.w900))),
    ]),
  );

  Widget _addressField(double s,String title,String hint,AddressSelection? value,IconData icon,VoidCallback onTap)=>InkWell(
    onTap:onTap,
    borderRadius:BorderRadius.circular(15*s),
    child:Container(
      constraints: BoxConstraints(minHeight:66*s),
      padding:EdgeInsets.symmetric(horizontal:11*s,vertical:8*s),
      decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15*s),border:Border.all(color:value!=null?const Color(0xFFB9DAFF):const Color(0xFFE7ECF3))),
      child:Row(children:[
        Container(width:32*s,height:32*s,decoration:BoxDecoration(color:value!=null?const Color(0xFFEAF4FF):const Color(0xFFF2F6FA),shape:BoxShape.circle),child:Icon(icon,color:value!=null?blue:const Color(0xFF64748B),size:20*s)),
        SizedBox(width:10*s),
        Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(title,style:TextStyle(fontSize:10.5*s,color:muted,fontWeight:FontWeight.w700)),
          SizedBox(height:2*s),
          Text(value?.displayName ?? hint,maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:11.5*s,color:value!=null?navy:const Color(0xFFA0A9B9),fontWeight:value!=null?FontWeight.w700:FontWeight.w500)),
        ])),
        Icon(value!=null?Icons.edit_location_alt_rounded:Icons.chevron_right_rounded,color:value!=null?blue:const Color(0xFF69778B),size:21*s)
      ])
    ),
  );

  Widget _round(double s,IconData i,VoidCallback f)=>InkWell(onTap:f,borderRadius:BorderRadius.circular(18*s),child:Container(width:44*s,height:44*s,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(17*s),boxShadow:const [BoxShadow(color:Color(0x12000000),blurRadius:15,offset:Offset(0,5))]),child:Icon(i,color:const Color(0xFF173C84),size:25*s)));
  Widget _vehicle(double s,int idx,String t,String sub,String time,String asset){final sel=vehicle==idx;return GestureDetector(onTap:(){setState(()=>vehicle=idx);if(hasAddresses)_calculateRoute();},child:Container(height:168*s,padding:EdgeInsets.all(10*s),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20*s),border:Border.all(color:sel?blue:const Color(0xFFE7EDF5),width:sel?1.5:1)),child:Stack(children:[Positioned(right:0,top:0,child:Container(width:24*s,height:24*s,decoration:BoxDecoration(color:sel?blue:Colors.white,shape:BoxShape.circle,border:Border.all(color:sel?blue:const Color(0xFFD2DAE6))),child:sel?Icon(Icons.check_rounded,color:Colors.white,size:17*s):null)),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:Center(child:Image.asset(asset,fit:BoxFit.contain))),Text(t,style:TextStyle(fontSize:16*s,fontWeight:FontWeight.w900,color:navy)),Text(sub,style:TextStyle(fontSize:11*s,color:muted)),SizedBox(height:6*s),Container(padding:EdgeInsets.symmetric(horizontal:9*s,vertical:5*s),decoration:BoxDecoration(color:const Color(0xFFEAF4FF),borderRadius:BorderRadius.circular(14*s)),child:Text(time,style:TextStyle(fontSize:9.5*s,color:blue,fontWeight:FontWeight.w700)))])])));}
  Widget _card(double s,Widget child)=>Container(width:double.infinity,padding:EdgeInsets.all(12*s),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22*s),boxShadow:const [BoxShadow(color:Color(0x0D000000),blurRadius:18,offset:Offset(0,5))]),child:child);
  Widget _chip(double s,int idx,IconData i,String label){final sel=detail==idx;return GestureDetector(onTap:()=>setState(()=>detail=idx),child:Container(height:48*s,decoration:BoxDecoration(color:sel?const Color(0xFFF3F9FF):Colors.white,borderRadius:BorderRadius.circular(14*s),border:Border.all(color:sel?blue:const Color(0xFFE5EAF2))),child:Center(child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(i,color:sel?blue:const Color(0xFF607089),size:18*s),SizedBox(width:5*s),Text(label,style:TextStyle(fontSize:10*s,color:sel?blue:const Color(0xFF607089),fontWeight:FontWeight.w700))]))));}
  Widget _select(double s,IconData i,String title)=>Container(height:58*s,padding:EdgeInsets.symmetric(horizontal:10*s),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15*s),border:Border.all(color:const Color(0xFFE7ECF3))),child:Row(children:[Icon(i,color:const Color(0xFF65748A),size:18*s),SizedBox(width:8*s),Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:TextStyle(fontSize:9.4*s,color:const Color(0xFF64748B))),Text('Seçiniz',style:TextStyle(fontSize:10.5*s,color:const Color(0xFF9AA4B5)))])),Icon(Icons.keyboard_arrow_down_rounded,color:const Color(0xFF56657B),size:20*s)]));
}
