# PAWERTIC - Teknik Servis ve Montaj Takip Sistemi

## 1. Öğrenci Bilgileri
*   **Ad Soyad:HASAN AKYEL
*   **Öğrenci Numarası:25010509092
*   **GitHub Proje Bağlantısı:https://github.com/Hasanhcii/pawertic

---

## 2. Projenin Amacı ve Kısa Açıklaması
**Pawertic**, araç takip sistemleri ve teknoloji çözümleri sunan firmaların saha operasyonlarını (montaj, demontaj ve servis) dijitalleştirmek amacıyla geliştirilmiş bir mobil uygulamadır.

**Projenin Amacı:** 
Sahada çalışan teknisyenlerin iş emirlerini kağıt formlar yerine mobil uygulama üzerinden yönetmelerini sağlamaktır. Uygulama, araç bilgilerini, cihaz verilerini (IMEI, SIM) ve müşteri onaylarını (dijital imza) merkezi bir bulut sisteminde (Firebase) toplar. Bu sayede veri kaybı önlenir, raporlama süreçleri hızlanır ve manuel hata payı minimize edilir.

---

## 3. Kullanılan Teknolojiler ve Kütüphaneler
Proje, hibrit uygulama geliştirme framework'ü olan **Flutter (Dart)** ile geliştirilmiştir.

*   **Backend:** Firebase Firestore (Veri saklama), Firebase Storage (İmza kayıtları).
*   **Yapay Zeka (OCR):** `google_mlkit_text_recognition` (Cihaz etiketlerinden IMEI/SIM numaralarını otomatik okuma).
*   **State Management:** Listenable & ChangeNotifier tabanlı merkezi yönetim.
*   **Dijital İmza:** `CustomPainter` ile geliştirilmiş gerçek zamanlı dijital imza paneli.
*   **Raporlama:** `excel` kütüphanesi ile tüm verilerin Excel formatına aktarımı.
*   **Görüntü İşleme:** `image_picker` (Kamera ve galeri erişimi).
*   **Yerel Depolama:** `shared_preferences` (Oturum ve tema yönetimi).

---

## 4. Proje Klasör Yapısı
lib/
├── core/           # Uygulama ayarları, dil (Locale) ve tema yönetimi
├── data/           # Araç marka/model verileri ve sabit listeler
├── models/         # Veri yapıları (İş kaydı, Kullanıcı modelleri)
├── pages/          # Uygulama ekranları (Login, Admin Paneli, Teknisyen Paneli, Formlar)
├── services/       # Firebase bağlantıları, OCR servisi ve bildirim yönetimi
├── widgets/        # Dijital imza pedi, özel butonlar ve bildirim bileşenleri
├── helpers/        # Excel oluşturma ve dosya paylaşım araçları
└── main.dart       # Uygulamanın giriş noktası ve Firebase başlatma


## 5. Kurulum Adımları
1.  Bilgisayarınızda **Flutter SDK**'nın kurulu olduğundan emin olun (`flutter doctor`).
2.  Projeyi GitHub deposundan klonlayın:(https://github.com/Hasanhcii/pawertic)`
3.  Proje klasörüne gidin: `cd pawertic`
4.  Gerekli kütüphaneleri yükleyin: `flutter pub get`
5.  Firebase bağlantısı için `google-services.json` dosyasını `android/app/` klasörü altına yerleştirin.
6.  Uygulamayı başlatın: `flutter run`


## 6. Çalıştırma / Kullanım Talimatları
1.  **Giriş:** Teknisyen veya Admin kullanıcı bilgileriyle sisteme giriş yapılır.
2.  **Yeni İş Kaydı:** Ana panelden işlem tipi (Montaj, Demontaj veya Servis) ve firma adı seçilerek iş başlatılır.
3.  **Aşama 1 (Araç Bilgileri):** Kategorisine göre araç markası, modeli ve yılı seçilir.
4.  **Aşama 2 (Kurulum & Cihaz):** 
    *   Cihaz modeli seçilir ve plaka bilgisi girilir.
    *   IMEI ve SIM numaraları kamera ikonu kullanılarak cihaz etiketinden otomatik olarak taranır.
    *   **Servis** modunda servis nedeni girilmesi zorunludur.
    *   **Demontaj** modunda cihazın kime teslim edildiği bilgisi kaydedilir.
5.  **Onay:** Müşteri imzası beyaz zemin üzerine dijital olarak alınır.
6.  **Kayıt:** "TAMAMLA" butonu ile veriler Firebase Firestore'a senkronize edilir.
7.  **Yönetici:** Admin panelinden tüm kayıtlar Excel olarak dışa aktarılabilir.

---

## 7. Ekran Görüntüleri
Giriş Ekranı 
Personel Paneli
Yönetici Paneli 
Araç Bilgileri
Kurulum Detayları
İş Detayları 
Yönetici
İş Listesi 


## 8. Kaynakça veya Yararlanılan Bağlantılar
*   [Flutter Documentation](https://docs.flutter.dev/)
*   [Firebase for Flutter Guide](https://firebase.google.com/docs/flutter/setup)
*   [Google ML Kit Text Recognition](https://developers.google.com/ml-kit/vision/text-recognition)
*   [Pub.dev Packages](https://pub.dev/)
