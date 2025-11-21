<img width="812" height="1627" alt="image" src="https://github.com/user-attachments/assets/ffc64441-a860-4169-937d-08dd6c42751f" /># 🎨 Thanette

<div align="center">

**Modern, Akıllı ve Güçlü Not Alma Deneyimi**

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2-02569B?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)](https://supabase.com)
[![License](https://img.shields.io/badge/License-Private-red)]()

</div>

---

## ✨ Özellikler

### 📝 Akıllı Not Alma
- **Zengin Metin Editörü**: Flutter Quill ile profesyonel metin düzenleme
- **Kategoriler**: Notlarınızı organize edin ve kolayca bulun
- **Otomatik Kaydetme**: Değişiklikleriniz anında kaydedilir
- **Undo/Redo**: 50 adıma kadar geri alma/ileri alma desteği

### 🎨 Gelişmiş Çizim Özellikleri
- **Apple Pencil Desteği**: Basınç hassasiyeti ve eğim algılama
- **Çoklu Araçlar**: Kalem, vurgulayıcı ve silgi
- **Gerçek Zamanlı Çizim**: Akıcı ve kesintisiz çizim deneyimi
- **Özelleştirilebilir Renkler ve Kalınlıklar**

### 📎 Dosya Yönetimi
- **Dosya Ekleme**: PDF, resim ve belgeleri notlarınıza ekleyin
- **Dosya Notlama**: PDF ve resimlerin üzerine çizim yapın
- **Galeri ve Kamera**: Hızlı dosya ekleme
- **Dosya Önizleme**: Tüm dosyalarınızı uygulama içinde görüntüleyin

### ✅ Görev Yönetimi
- **Todo List**: Notlarınıza görev listeleri ekleyin
- **İnteraktif Checklist**: Görevlerinizi kolayca takip edin

### 🤖 AI Asistanı
- **Akıllı Chatbot**: OpenAI entegrasyonu ile notlarınızı geliştirin
- **Metin Düzenleme**: AI ile notlarınızı düzenleyin ve iyileştirin
- **Yüzen Chat Balonu**: Her zaman erişilebilir AI asistanı

### 🎯 Kullanıcı Deneyimi
- **Modern UI/UX**: iOS tarzı Cupertino tasarım
- **Tema Desteği**: Açık/koyu tema seçenekleri
- **Paylaşım**: Notlarınızı e-posta ve WhatsApp ile paylaşın
- **Bulut Senkronizasyon**: Supabase ile tüm cihazlarda senkronize

---

## 🚀 Teknolojiler

### Frontend
- **Flutter 3.9.2** - Cross-platform mobil geliştirme
- **Provider** - State management
- **Flutter Quill** - Zengin metin editörü
- **Lottie** - Animasyonlar

### Backend & Servisler
- **Supabase** - Backend as a Service (Authentication, Database, Storage)
- **OpenAI API** - AI chatbot entegrasyonu

### Önemli Paketler
- `flutter_quill` - Metin editörü
- `syncfusion_flutter_pdfviewer` - PDF görüntüleme
- `photo_view` - Resim görüntüleme
- `file_picker` & `image_picker` - Dosya seçimi
- `share_plus` - Paylaşım özellikleri

---

## 📱 Platform Desteği

- ✅ iOS
- ✅ Android
- ✅ macOS
- ✅ Linux
- ✅ Windows
- ✅ Web

---

## 🛠️ Kurulum

### Gereksinimler
- Flutter SDK 3.9.2 veya üzeri
- Dart SDK
- iOS: Xcode 14+ (macOS için)
- Android: Android Studio veya VS Code

### Adımlar

1. **Repository'yi klonlayın**
```bash
git clone https://github.com/yourusername/thanette.git
cd thanette
```

2. **Bağımlılıkları yükleyin**
```bash
flutter pub get
```

3. **Environment değişkenlerini ayarlayın**
```bash
# assets/env/.env dosyası oluşturun
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
OPENAI_API_KEY=your_openai_api_key
```

4. **Uygulamayı çalıştırın**
```bash
flutter run
```

---

## 📸 Ekran Görüntüleri

<div align="center">

### Not Listesi
<img width="200" height="500" alt="image" src="https://github.com/user-attachments/assets/f9b672bd-e078-427e-a035-a2adf4d78f70" />

### Çizim Modu
<img width="918" height="1651" alt="image" src="https://github.com/user-attachments/assets/145800ba-47e0-4c10-8186-f80b30f1919f" />


### AI Asistanı
<img width="813" height="1631" alt="image" src="https://github.com/user-attachments/assets/c56e0e73-a963-40e0-96e2-166ce274cdb7" />


</div>

---

## 🎯 Kullanım Senaryoları

### Öğrenciler İçin
- 📚 Ders notları alma ve düzenleme
- ✏️ PDF'ler üzerine notlar ekleme
- 📝 Ödev takibi ve görev listeleri
- 🤖 AI ile notları iyileştirme

### Profesyoneller İçin
- 💼 Toplantı notları
- 📊 Proje dokümantasyonu
- 🎨 Tasarım notları ve eskizler
- 📎 Belge yönetimi

### Günlük Kullanım
- 📝 Günlük notlar ve hatırlatıcılar
- ✅ Kişisel görev listeleri
- 🎨 Yaratıcı çizimler
- 📱 Her cihazda erişim

---

## 🏗️ Proje Yapısı

```
lib/
├── main.dart                 # Uygulama giriş noktası
├── src/
│   ├── app.dart             # Ana uygulama widget'ı
│   ├── models/              # Veri modelleri
│   ├── providers/           # State management
│   ├── screens/             # Ekranlar
│   ├── widgets/             # Yeniden kullanılabilir widget'lar
│   └── services/            # Servisler
├── assets/
│   ├── images/              # Görseller
│   ├── lottie/              # Animasyonlar
│   └── env/                 # Environment dosyaları
└── docs/                    # Dokümantasyon
```

---

## 🔐 Güvenlik

- ✅ Supabase Authentication ile güvenli giriş
- ✅ Environment variables ile API key yönetimi
- ✅ Row Level Security (RLS) politikaları
- ✅ Güvenli dosya yükleme ve depolama

---

## 🤝 Katkıda Bulunma

Bu proje şu anda özel bir projedir. Katkıda bulunmak için lütfen önce iletişime geçin.

---

## 📄 Lisans

Bu proje özel bir lisans altındadır. Tüm hakları saklıdır.

---

## 👨‍💻 Geliştirici

**Thanette Development Team**

- Modern ve kullanıcı dostu arayüz
- Performans odaklı geliştirme
- Sürekli iyileştirme ve güncellemeler

---

## 🌟 Öne Çıkan Özellikler

### 🎨 Çizim Sistemi
- **Gerçek Zamanlı Rendering**: Optimize edilmiş çizim motoru
- **Multi-touch Desteği**: İki parmakla kaydırma desteği
- **State Management**: Çizim sırasında veri kaybını önleyen akıllı state yönetimi

### 📱 Responsive Tasarım
- Tüm ekran boyutlarına uyumlu
- Tablet ve telefon optimizasyonu
- Klavye ve çizim modu geçişleri

### ⚡ Performans
- Lazy loading
- Optimize edilmiş render döngüleri
- Efficient state updates

---

## 📞 İletişim

Sorularınız veya önerileriniz için:
- 📧 Email: bengisudemir.dev@gmail.com


---

<div align="center">

**⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın! ⭐**

Made with ❤️ using Flutter

</div>
