# Gölge Krallık: Kadim Mühür'ün Çöküşü

Ortaçağ temalı mobil MMORPG oyunu.

## 🎮 Oyun Hakkında

Karanlık bir ortaçağ krallığında geçen bu oyunda, oyuncular görevler yaparak, kaynak toplayarak ve diğer oyuncularla savaşarak güçlenirler. Enerji sistemi ve iksir bağımlılığı mekanizması ile benzersiz bir risk-ödül dengesi sunar.

## 🛠️ Teknoloji

- **Engine:** Godot 4.3+
- **Platform:** iOS, Android
- **Backend:** Supabase
- **Dil:** GDScript

## 📁 Proje Yapısı

Detaylı proje yapısı için: [PROJE-YAPISI.md](PROJE-YAPISI.md)

```
golge-krallik/
├── autoload/          # Singleton sistemler
├── core/              # Çekirdek sistemler
├── scenes/            # Tüm sahneler
├── scripts/           # Script dosyaları
├── resources/         # Resource dosyaları
└── assets/            # Görsel/ses dosyaları
```

## 🚀 Kurulum

1. Godot 4.3+ indirin: https://godotengine.org/
2. Projeyi klonlayın
3. Godot'ta `project.godot` dosyasını açın
4. Backend ayarlarını yapılandırın (Project Settings → Game Settings)

## 🔧 Geliştirme

### Ön Gereksinimler
- Godot 4.3+
- Git
- Supabase hesabı (backend için)

### İlk Çalıştırma
1. `project.godot` içinde backend URL'ini ayarlayın
2. F5 ile oyunu çalıştırın

### Build
- Android: Project → Export → Android
- iOS: Project → Export → iOS (Mac gerekli)

## 📖 Dokümantasyon

- [Oyun Tasarım Dökümanı](OYUN-OZET-v2.0.md)
- [Ekonomi Planları](plan-golgeEkonomi-part-01.prompt.md)
- [Enerji Sistemi](plan-golgeEkonomi-ENERGY-POTION-detailed.prompt.md)
- [PvP Sistemi](plan-golgeEkonomi-PVP-detailed.prompt.md)
- [Proje Yapısı](PROJE-YAPISI.md)

## 🎯 Geliştirme Durumu

- [x] Proje yapısı
- [ ] Network layer
- [ ] Enerji sistemi
- [ ] İksir sistemi
- [ ] Görev sistemi
- [ ] PvP sistemi
- [ ] Market sistemi
- [ ] Lonca sistemi

## 🤝 Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/amazing`)
3. Commit yapın (`git commit -m 'Add amazing feature'`)
4. Push yapın (`git push origin feature/amazing`)
5. Pull Request açın

## 📝 Lisans

Telif Hakkı © 2026 - Tüm hakları saklıdır.

## 👥 Ekip

- Lead Developer: [İsim]
- Game Designer: [İsim]
- Artist: [İsim]

## 📞 İletişim

- Discord: [Link]
- Email: [Email]
- Website: [URL]

---

**Versiyon:** 0.1.0  
**Son Güncelleme:** 2 Ocak 2026
