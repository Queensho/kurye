# Müşteri Gerçek Cihaz E2E Kontrol Listesi

Bu test en az iki gerçek Android cihaz ve iki ayrı hesapla yapılır: bir müşteri, bir kurye.

## Hazırlık
- Müşteri ve kurye cihazlarında güncel release/debug APK kurulu olmalı.
- Kurye hesabı onaylı olmalı.
- Her iki cihazda internet açık olmalı.
- Kurye cihazında hassas konum, arka plan konum ve bildirim izinleri verilmiş olmalı.
- Kurye cihazında pil optimizasyonu test sırasında not edilmeli.

## Senaryo 1 — Gönderi oluşturma ve havuza düşme
1. Müşteri kayıtlı adreslerden alım ve teslimat adresi seçer.
2. Kayıtlı teslimat adresindeki kişi/telefon/bina/kat/daire/kapı notunun detay ekranına otomatik geldiği doğrulanır.
3. Gönderi oluşturulur.
4. Müşteride `Kurye aranıyor` görünür.
5. Kurye cihazında iş havuzuna gönderinin realtime düştüğü doğrulanır.

Beklenen: shipment `searching`, `courier_id=null`.

## Senaryo 2 — Kurye işi alma
1. Kurye `İşi Al` butonuna basar.
2. Müşteri ekranı otomatik canlı takibe geçer.
3. Kurye adı, puanı, araç/plaka, sohbet ve arama butonları görünür.
4. Aynı işi ikinci kurye almaya çalışırsa reddedilir.

Beklenen: shipment `accepted`, yalnızca tek `courier_id`.

## Senaryo 3 — Canlı konum, rota ve ETA
1. Kurye hareket eder.
2. Müşteri haritasında kurye marker'ı hareket eder.
3. Kurye → aktif hedef arasında rota polyline görünür.
4. ETA ve kalan km güncellenir.
5. Kurye uygulaması arka plana alınır, ekran kilitlenir.
6. Konum güncellemelerinin devam ettiği doğrulanır.
7. İnternet 3+ dakika kesilir.

Beklenen: son konum korunur, müşteri `bağlantı zayıf / son konum` uyarısını görür.

## Senaryo 4 — Mesajlaşma ve arama
1. Müşteri kuryeye mesaj gönderir.
2. Kurye mesajı görür ve cevaplar.
3. Okundu durumu kontrol edilir.
4. Müşteri arama butonuna basar.

Beklenen: realtime mesajlaşma çalışır, telefon uygulaması açılır.

## Senaryo 5 — Durum zinciri
Kurye sırayla ilerler:
- accepted → at_pickup
- at_pickup → picked_up
- picked_up → at_dropoff
- at_dropoff → delivered

Beklenen: her değişiklik müşteride realtime görünür ve gönderi sonunda Geçmiş'e taşınır.

## Senaryo 6 — Uygulama yeniden açma
1. Aktif teslimat sırasında müşteri uygulaması kapatılır/açılır.
2. Kurye uygulaması kapatılır/açılır.

Beklenen: müşteri aktif gönderisini canlı takipten sürdürebilir; kurye aktif iş ekranına geri döner.

## Senaryo 7 — İptal
- `searching`: müşteri ücretsiz iptal eder.
- `accepted`: müşteri iptal eder, 20 TL iptal bedeli kayda geçer.
- `at_pickup` ve sonrası: normal iptal kapalı, destek yönlendirmesi yapılır.

Beklenen: iptal kuryede de realtime görünür ve aktif iş temizlenir.

## Senaryo 8 — Teslimat sonrası
1. Müşteri 1–5 yıldız verir ve yorum yazar.
2. Destek talebi oluşturur.
3. `Destek Taleplerim` ekranında durumunu görür.
4. `Tekrar Gönder` ile aynı teslimatı yeniden oluşturur.

Beklenen: puan tek kayıt olarak yazılır, destek talebi görünür, tekrar gönderi yeni fiyatla `searching` olarak oluşur.

## Senaryo 9 — Ödeme uyuşmazlığı (gateway bağlandıktan sonra)
- İptal bedeli itirazı
- Yanlış ücret
- Çift çekim
- Teslim edilmeyen gönderi ücreti
- Eksik iade

Beklenen: her olay ayrı destek/ödeme itirazı kaydı oluşturur ve müşteri geçmişinde görünür.

## Başarı kriteri
Tüm kritik senaryolar iki ardışık test turunda hata olmadan geçmeden production yayını yapılmamalı.
