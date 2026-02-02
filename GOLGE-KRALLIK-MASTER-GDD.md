# 🏰 GÖLGE KRALLIK: KADİM MÜHÜR'ÜN ÇÖKÜŞÜ
## Ultra Detaylı Master Game Design Document v1.0

> **Proje Başlangıç:** 2 Ocak 2026  
> **Son Güncelleme:** 31 Ocak 2026  
> **Belge Versiyonu:** 1.0  
> **Durum:** Aktif Geliştirme

---

## 📑 İÇİNDEKİLER (Table of Contents)

### BÖLÜM 1: OYUN KONSEPTI VE VİZYON
- [1.1 Oyun Özeti](#11-oyun-özeti)
- [1.2 Temel Konsept](#12-temel-konsept)
- [1.3 Benzersiz Satış Noktaları (USP)](#13-benzersiz-satış-noktaları-usp)
- [1.4 Hedef Kitle](#14-hedef-kitle)
- [1.5 Platform ve Teknik Gereksinimler](#15-platform-ve-teknik-gereksinimler)
- [1.6 Proje Zaman Çizelgesi](#16-proje-zaman-çizelgesi)

### BÖLÜM 2: TEKNİK MİMARİ
- [2.1 Teknoloji Yığını](#21-teknoloji-yığını)
- [2.2 Proje Yapısı](#22-proje-yapısı)
- [2.3 Autoload Singleton'lar (10 Adet)](#23-autoload-singletonlar-10-adet)
- [2.4 Core Manager'lar (15 Adet)](#24-core-managerlar-15-adet)
- [2.5 Data Sınıfları (10 Adet)](#25-data-sınıfları-10-adet)
- [2.6 Mimari Pattern'lar](#26-mimari-patternlar)
- [2.7 Güvenlik Katmanları](#27-güvenlik-katmanları)

### BÖLÜM 3: VERİTABANI ŞEMASI
- [3.1 Ana Tablolar](#31-ana-tablolar)
- [3.2 RPC Fonksiyonları](#32-rpc-fonksiyonları)
- [3.3 RLS Politikaları](#33-rls-politikaları)
- [3.4 View ve Index'ler](#34-view-ve-indexler)
- [3.5 Trigger'lar](#35-triggerlar)

### BÖLÜM 4: API VE EDGE FUNCTIONS
- [4.1 Supabase Edge Functions Listesi](#41-supabase-edge-functions-listesi)
- [4.2 Enerji Fonksiyonları](#42-enerji-fonksiyonları)
- [4.3 Hastane Fonksiyonları](#43-hastane-fonksiyonları)
- [4.4 Tesis Fonksiyonları](#44-tesis-fonksiyonları)
- [4.5 Market Fonksiyonları](#45-market-fonksiyonları)
- [4.6 Rate Limiting](#46-rate-limiting)

### BÖLÜM 5: ENERJİ SİSTEMİ
- [5.1 Temel Mekanikler](#51-temel-mekanikler)
- [5.2 Enerji Maliyetleri](#52-enerji-maliyetleri)
- [5.3 Rejenerasyon Formülleri](#53-rejenerasyon-formülleri)
- [5.4 Offline Rejenerasyon](#54-offline-rejenerasyon)

### BÖLÜM 6: İKSİR VE BAĞIMLILIK SİSTEMİ
- [6.1 İksir Tipleri](#61-iksir-tipleri)
- [6.2 Tolerance (Bağımlılık) Mekaniği](#62-tolerance-bağımlılık-mekaniği)
- [6.3 Overdose Sistemi](#63-overdose-sistemi)
- [6.4 Antidot ve İyileşme](#64-antidot-ve-iyileşme)
- [6.5 Tolerance Tier'ları](#65-tolerance-tierları)

### BÖLÜM 7: HASTANE SİSTEMİ
- [7.1 Hastaneye Düşme Sebepleri](#71-hastaneye-düşme-sebepleri)
- [7.2 Yatış Süreleri](#72-yatış-süreleri)
- [7.3 Çıkış Yöntemleri](#73-çıkış-yöntemleri)
- [7.4 Şifacı Mekaniği](#74-şifacı-mekaniği)

### BÖLÜM 8: ZİNDAN (DUNGEON) SİSTEMİ
- [8.1 Zindan Tipleri](#81-zindan-tipleri)
- [8.2 Zorluk Seviyeleri](#82-zorluk-seviyeleri)
- [8.3 Başarı Formülü](#83-başarı-formülü)
- [8.4 Ödül Dağılımı](#84-ödül-dağılımı)
- [8.5 Hospitalization Oranları](#85-hospitalization-oranları)

### BÖLÜM 9: PVP SİSTEMİ
- [9.1 Savaş Mekaniği](#91-savaş-mekaniği)
- [9.2 Güç Hesaplama Formülü](#92-güç-hesaplama-formülü)
- [9.3 Kazanma Olasılığı](#93-kazanma-olasılığı)
- [9.4 Reputation Sistemi](#94-reputation-sistemi)
- [9.5 ELO Rating](#95-elo-rating)
- [9.6 Misilleme Mekaniği](#96-misilleme-mekaniği)

### BÖLÜM 10: 15 TESİS SİSTEMİ
- [10.1 Tesis Kategorileri](#101-tesis-kategorileri)
- [10.2 Hammadde Tesisleri (4 Adet)](#102-hammadde-tesisleri-4-adet)
- [10.3 İşleme Tesisleri (6 Adet)](#103-işleme-tesisleri-6-adet)
- [10.4 İleri Tesisler (3 Adet)](#104-ileri-tesisler-3-adet)
- [10.5 Hizmet Tesisleri (2 Adet)](#105-hizmet-tesisleri-2-adet)
- [10.6 Üretim Reçeteleri](#106-üretim-reçeteleri)
- [10.7 Suspicion (Şüphe) Mekaniği](#107-suspicion-şüphe-mekaniği)
- [10.8 Baskın ve Hapishane Riski](#108-baskın-ve-hapishane-riski)
- [10.9 Rüşvet Sistemi](#109-rüşvet-sistemi)
- [10.10 Rarity Dağılımı](#1010-rarity-dağılımı)

### BÖLÜM 11: LONCA (GUILD) SİSTEMİ
- [11.1 Lonca Kurulumu](#111-lonca-kurulumu)
- [11.2 Roller ve Yetkiler](#112-roller-ve-yetkiler)
- [11.3 Lonca Seviyeleri](#113-lonca-seviyeleri)
- [11.4 Lonca Hazinesi](#114-lonca-hazinesi)
- [11.5 Lonca Görevleri](#115-lonca-görevleri)
- [11.6 Lonca Savaşları](#116-lonca-savaşları)
- [11.7 Bölge Kontrolü](#117-bölge-kontrolü)

### BÖLÜM 12: MARKET VE EKONOMİ
- [12.1 Order Book Modeli](#121-order-book-modeli)
- [12.2 Fiyat Mekanizması](#122-fiyat-mekanizması)
- [12.3 Komisyon Sistemi](#123-komisyon-sistemi)
- [12.4 Anti-Manipülasyon Önlemleri](#124-anti-manipülasyon-önlemleri)
- [12.5 Bölgesel Pazarlar](#125-bölgesel-pazarlar)
- [12.6 Arbitraj Fırsatları](#126-arbitraj-fırsatları)

### BÖLÜM 13: SEZON SİSTEMİ
- [13.1 Sezon Yapısı](#131-sezon-yapısı)
- [13.2 4 Faz Döngüsü](#132-4-faz-döngüsü)
- [13.3 Sezon Sonu Reset Kuralları](#133-sezon-sonu-reset-kuralları)
- [13.4 Kalıcı Ödüller](#134-kalıcı-ödüller)
- [13.5 Battle Pass](#135-battle-pass)
- [13.6 Leaderboard Kategorileri](#136-leaderboard-kategorileri)

### BÖLÜM 14: MONETİZASYON
- [14.1 Pay-to-Win Olmayan Model](#141-pay-to-win-olmayan-model)
- [14.2 Gem Paketleri](#142-gem-paketleri)
- [14.3 Ücretsiz Gem Kazanımı](#143-ücretsiz-gem-kazanımı)
- [14.4 Premium Özellikler](#144-premium-özellikler)
- [14.5 Kozmetik Sistemi](#145-kozmetik-sistemi)

### BÖLÜM 15: ENVANTER VE EKİPMAN
- [15.1 Slot Sistemi](#151-slot-sistemi)
- [15.2 Item Tipleri](#152-item-tipleri)
- [15.3 Rarity Seviyeleri](#153-rarity-seviyeleri)
- [15.4 Enhancement (Geliştirme) Sistemi](#154-enhancement-geliştirme-sistemi)
- [15.5 Rün Sistemi](#155-rün-sistemi)
- [15.6 Scroll Sistemi](#156-scroll-sistemi)

### BÖLÜM 16: GÖREV SİSTEMİ
- [16.1 Görev Tipleri](#161-görev-tipleri)
- [16.2 Günlük Görevler](#162-günlük-görevler)
- [16.3 Haftalık Görevler](#163-haftalık-görevler)
- [16.4 Hikaye Görevleri](#164-hikaye-görevleri)
- [16.5 Lonca Görevleri](#165-lonca-görevleri)

### BÖLÜM 17: SOHBET VE SOSYAL
- [17.1 Chat Kanalları](#171-chat-kanalları)
- [17.2 Moderasyon Sistemi](#172-moderasyon-sistemi)
- [17.3 Arkadaşlık Sistemi](#173-arkadaşlık-sistemi)
- [17.4 Bildirimler](#174-bildirimler)

### BÖLÜM 18: HAPİSHANE SİSTEMİ
- [18.1 Hapse Girme Sebepleri](#181-hapse-girme-sebepleri)
- [18.2 Ceza Süreleri](#182-ceza-süreleri)
- [18.3 Kefalet Sistemi](#183-kefalet-sistemi)
- [18.4 Hapishane Aktiviteleri](#184-hapishane-aktiviteleri)

### BÖLÜM 19: UI/UX AKIŞLARI
- [19.1 Ana Ekranlar](#191-ana-ekranlar)
- [19.2 Navigasyon Yapısı](#192-navigasyon-yapısı)
- [19.3 Popup ve Modal'lar](#193-popup-ve-modallar)
- [19.4 Animasyonlar](#194-animasyonlar)

### BÖLÜM 20: SES VE MÜZİK
- [20.1 Müzik Parçaları](#201-müzik-parçaları)
- [20.2 Ses Efektleri](#202-ses-efektleri)
- [20.3 Ses Ayarları](#203-ses-ayarları)

### BÖLÜM 21: SABİTLER VE KONFÜGÜRASYON
- [21.1 Global Sabitler](#211-global-sabitler)
- [21.2 Tesis Konfigürasyonu](#212-tesis-konfigürasyonu)
- [21.3 PvP Sabitleri](#213-pvp-sabitleri)
- [21.4 Market Sabitleri](#214-market-sabitleri)

### BÖLÜM 22: UYGULAMA DURUMU
- [22.1 Tamamlanan Sistemler](#221-tamamlanan-sistemler)
- [22.2 Devam Eden Sistemler](#222-devam-eden-sistemler)
- [22.3 Başlanmamış Sistemler](#223-başlanmamış-sistemler)
- [22.4 Bilinen Sorunlar](#224-bilinen-sorunlar)

### BÖLÜM 23: ÖNERİLEN YENİ ÖZELLİKLER
- [23.1 Boss Raid Sistemi](#231-boss-raid-sistemi)
- [23.2 Achievement Sistemi](#232-achievement-sistemi)
- [23.3 Mentorship Programı](#233-mentorship-programı)
- [23.4 Daily Login Streak](#234-daily-login-streak)
- [23.5 Pet Sistemi](#235-pet-sistemi)

### EKLER
- [Ek A: Arşivlenen Belgeler Listesi](#ek-a-arşivlenen-belgeler-listesi)
- [Ek B: Değişiklik Geçmişi](#ek-b-değişiklik-geçmişi)

---

# BÖLÜM 1: OYUN KONSEPTI VE VİZYON

## 1.1 Oyun Özeti

**Gölge Krallık: Kadim Mühür'ün Çöküşü**, karanlık ortaçağ fantazi temasında mobil bir MMORPG oyunudur. Oyuncular, çökmüş bir krallığın gölgelerinde hayatta kalmaya çalışan karakterler olarak yeraltı ekonomisini yönetir, zindanlara iner, PvP savaşlarına girer ve loncalar kurarak güç mücadelesi verir.

| Özellik | Değer |
|---------|-------|
| **Tam Adı** | Gölge Krallık: Kadim Mühür'ün Çöküşü |
| **Tür** | Mobil MMORPG / Idle RPG |
| **Tema** | Dark Medieval Fantasy |
| **Dil** | Türkçe (Ana), İngilizce (Planlı) |
| **Platform** | iOS, Android |
| **Oyun Motoru** | Godot 4.3+ |
| **Backend** | Supabase (PostgreSQL + Edge Functions) |

## 1.2 Temel Konsept

Oyun, **Knight Online**'ın MMORPG mekaniklerini ve **The Crims**'in yeraltı ekonomisi/suç döngüsünü harmanlayan benzersiz bir deneyim sunar.

### Ana Oyun Döngüsü

```
┌─────────────────────────────────────────────────────────────┐
│                    ANA OYUN DÖNGÜSÜ                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌─────────┐     ┌─────────────┐     ┌─────────────┐      │
│   │ Görev   │────▶│   Enerji    │────▶│  Zindan/PvP │      │
│   │   Al    │     │   Harca     │     │    Gir      │      │
│   └─────────┘     └─────────────┘     └──────┬──────┘      │
│                                              │              │
│                   ┌──────────────────────────┴───────┐      │
│                   ▼                                  ▼      │
│           ┌─────────────┐                   ┌─────────────┐ │
│           │   BAŞARI    │                   │   KAYIP     │ │
│           │  Ödül + XP  │                   │  Hastane    │ │
│           └──────┬──────┘                   └─────────────┘ │
│                  │                                          │
│                  ▼                                          │
│   ┌─────────────────────────────────────────────────┐      │
│   │         TESİSLERDE ÜRET                         │      │
│   │   Maden → Demirci → Silah → Pazar'da Sat       │      │
│   └──────────────────────┬──────────────────────────┘      │
│                          │                                  │
│                          ▼                                  │
│              ┌─────────────────────┐                       │
│              │  DAHA GÜÇLÜ EKİPMAN │                       │
│              │     Enhancement     │                       │
│              └─────────────────────┘                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Yeraltı Ekonomisi Teması

Oyuncular yasal sınırların dışında faaliyet gösteren karakterlerdir:
- **Yasadışı üretim tesisleri** işletirler (şüphe = polis dikkatı)
- **Baskın riski** altında çalışırlar
- **Rüşvet** vererek şüpheyi azaltabilirler
- **Hapishane**'ye düşebilir ve kefalet ödemek zorunda kalabilirler

## 1.3 Benzersiz Satış Noktaları (USP)

| # | Özellik | Açıklama |
|---|---------|----------|
| 1 | **İksir Bağımlılığı** | Enerji iksiri içmek tolerance artırır, aşırı doz hastaneye düşürür |
| 2 | **Server-Authoritative** | Tüm güç hesaplamaları, RNG ve savaş sonuçları sunucu tarafında - hile önleme |
| 3 | **Sezonluk Reset** | 60-90 günlük sezonlar, sezon sonunda altın/item/seviye sıfırlanır |
| 4 | **15 Tesis Sistemi** | Hammadde → İşleme → İleri üretim zinciri |
| 5 | **Yeraltı Teması** | Şüphe, baskın, hapishane, rüşvet mekaniği |
| 6 | **Pay-to-Win Yok** | Silah, zırh, altın, iksir SATILAMAZ |
| 7 | **Türk Yapımı** | Türkçe dil ve kültürel öğeler |

## 1.4 Hedef Kitle

| Segment | Yaş | Özellikler |
|---------|-----|------------|
| **Primer** | 18-35 | MMORPG deneyimi olan, rekabetçi, mobil oyuncu |
| **Sekonder** | 25-45 | Knight Online/Silkroad nostaljisi, casual mobil |
| **Tersiyer** | 16-18 | Genç oyuncular, sosyal oyun arayanlar |

### Oyuncu Profilleri

1. **Hardcore Rekabetçi**: PvP odaklı, leaderboard takipçisi, guild lider adayı
2. **Ekonomi Ustası**: Market arbitrajı, üretim optimizasyonu, altın biriktirici
3. **Sosyal Oyuncu**: Lonca aktiviteleri, chat, arkadaşlık odaklı
4. **Koleksiyoncu**: Tüm item'ları toplama, achievement avcısı
5. **Casual**: Günde 10-15 dakika, idle mekaniklerden faydalanan

## 1.5 Platform ve Teknik Gereksinimler

### Desteklenen Platformlar

| Platform | Minimum Versiyon | Hedef |
|----------|------------------|-------|
| **Android** | 8.0 (Oreo) | Android 12+ |
| **iOS** | 13.0 | iOS 16+ |

### Cihaz Gereksinimleri

| Özellik | Minimum | Önerilen |
|---------|---------|----------|
| **RAM** | 2 GB | 4 GB |
| **Depolama** | 500 MB | 1 GB |
| **İnternet** | Sürekli gerekli | 4G/WiFi |
| **Ekran** | 720p | 1080p+ |

### Backend Gereksinimleri

| Bileşen | Servis |
|---------|--------|
| **Database** | Supabase PostgreSQL |
| **Auth** | Supabase Auth (JWT) |
| **Storage** | Supabase Storage |
| **Functions** | Supabase Edge Functions (Deno) |
| **Realtime** | Supabase Realtime (WebSocket) |

## 1.6 Proje Zaman Çizelgesi

| Faz | Tarih | Hedefler |
|-----|-------|----------|
| **Pre-Alpha** | Ocak-Şubat 2026 | Core sistemler, veritabanı, temel UI |
| **Alpha** | Mart 2026 | Tüm sistemler çalışır, internal test |
| **Closed Beta** | Mayıs 2026 | 1000 oyuncu, bug fix, balance |
| **Open Beta** | Temmuz 2026 | 10,000 oyuncu, stress test |
| **Soft Launch** | Ağustos 2026 | Türkiye market |
| **Global Launch** | Eylül 2026 | Worldwide release |

---

# BÖLÜM 2: TEKNİK MİMARİ

## 2.1 Teknoloji Yığını

| Katman | Teknoloji | Versiyon | Amaç |
|--------|-----------|----------|------|
| **Game Engine** | Godot | 4.3+ | Client geliştirme |
| **Scripting** | GDScript | 2.0 | Oyun mantığı |
| **Database** | PostgreSQL | 15+ | Veri depolama |
| **Backend** | Supabase | Latest | BaaS platform |
| **Edge Functions** | Deno/TypeScript | 1.x | Server-side logic |
| **Auth** | Supabase Auth | - | Kimlik doğrulama |
| **Realtime** | WebSocket | - | Anlık iletişim |
| **Version Control** | Git | - | Kaynak yönetimi |

### Supabase Proje Bilgileri

| Özellik | Değer |
|---------|-------|
| **Project URL** | `https://znvsyzstmxhqvdkkmgdt.supabase.co` |
| **Anon Key** | Environment variable'da saklanır |
| **Service Role Key** | Sadece Edge Functions'da kullanılır |

## 2.2 Proje Yapısı

```
golge-krallik/
│
├── autoload/                    # 10 Singleton (Global Manager'lar)
│   ├── NetworkManager.gd        # HTTP/WebSocket iletişimi
│   ├── SessionManager.gd        # Auth ve oturum yönetimi
│   ├── StateStore.gd            # Global oyun durumu
│   ├── RequestQueue.gd          # İstek kuyruğu
│   ├── TelemetryClient.gd       # Analytics
│   ├── AudioManager.gd          # Ses yönetimi
│   ├── SceneManager.gd          # Sahne geçişleri
│   ├── ConfigManager.gd         # Konfigürasyon
│   ├── InventoryManager.gd      # Envanter işlemleri
│   └── FacilityManager.gd       # Tesis yönetimi
│
├── core/
│   ├── data/                    # 10 Data Class
│   │   ├── PlayerData.gd        # Oyuncu modeli
│   │   ├── ItemData.gd          # Item tanımları
│   │   ├── ItemDatabase.gd      # Item veritabanı
│   │   ├── InventoryItemData.gd # Envanter item instance
│   │   ├── QuestData.gd         # Görev modeli
│   │   ├── DungeonData.gd       # Zindan tanımları
│   │   ├── DungeonInstance.gd   # Zindan instance
│   │   ├── GuildData.gd         # Lonca modeli
│   │   ├── GuildMemberData.gd   # Lonca üye modeli
│   │   └── PvPData.gd           # PvP verileri
│   │
│   ├── managers/                # 15 Domain Manager
│   │   ├── EnergyManager.gd     # Enerji sistemi
│   │   ├── PotionManager.gd     # İksir/tolerance
│   │   ├── HospitalManager.gd   # Hastane
│   │   ├── DungeonManager.gd    # Zindan
│   │   ├── PvPManager.gd        # PvP savaşları
│   │   ├── QuestManager.gd      # Görevler
│   │   ├── EquipmentManager.gd  # Ekipman
│   │   ├── EnhancementManager.gd # Geliştirme
│   │   ├── GuildManager.gd      # Lonca
│   │   ├── ChatManager.gd       # Sohbet
│   │   ├── PazarManager.gd      # Market
│   │   ├── ShopManager.gd       # NPC dükkan
│   │   ├── ProductionManager.gd # Üretim
│   │   ├── PrisonManager.gd     # Hapishane
│   │   └── SeasonManager.gd     # Sezon
│   │
│   ├── network/                 # Ağ katmanı
│   │   ├── HTTPClient.gd        # HTTP istekleri
│   │   ├── WebSocketClient.gd   # WebSocket bağlantısı
│   │   ├── APIEndpoints.gd      # Endpoint sabitleri
│   │   └── RequestBuilder.gd    # İstek oluşturucu
│   │
│   └── utils/                   # Yardımcı sınıflar
│       ├── TimeUtils.gd
│       ├── MathUtils.gd
│       └── StringUtils.gd
│
├── scenes/
│   ├── ui/                      # UI Ekranları
│   │   ├── MainScreen.tscn
│   │   ├── InventoryScreen.tscn
│   │   ├── MarketScreen.tscn
│   │   ├── FacilitiesScreen.tscn
│   │   ├── DungeonScreen.tscn
│   │   ├── PvPScreen.tscn
│   │   ├── GuildScreen.tscn
│   │   ├── HospitalScreen.tscn
│   │   ├── PrisonScreen.tscn
│   │   └── SettingsScreen.tscn
│   │
│   ├── components/              # Yeniden kullanılabilir UI
│   │   ├── ItemSlot.tscn
│   │   ├── FacilityCard.tscn
│   │   ├── PlayerCard.tscn
│   │   └── ConfirmDialog.tscn
│   │
│   └── prefabs/                 # Prefab'lar
│
├── supabase/
│   └── functions/               # 15+ Edge Function
│       ├── energy/
│       ├── hospital-admit/
│       ├── hospital-release/
│       ├── facilities/
│       ├── production/
│       ├── market/
│       └── pvp/
│
├── database/
│   └── migrations/              # 40+ SQL migration
│
├── assets/
│   ├── audio/
│   ├── fonts/
│   ├── icons/
│   ├── sprites/
│   └── shaders/
│
├── resources/                   # Godot Resource dosyaları
│
└── tests/                       # Test dosyaları
```

## 2.3 Autoload Singleton'lar (10 Adet)

### Singleton Özeti

| Singleton | Global İsim | Ana Sorumluluk |
|-----------|-------------|----------------|
| NetworkManager | `Network` | HTTP/WS iletişimi |
| SessionManager | `Session` | Auth ve oturum |
| StateStore | `State` | Global durum |
| RequestQueue | `Queue` | İstek kuyruğu |
| TelemetryClient | `Telemetry` | Analytics |
| AudioManager | `Audio` | Ses yönetimi |
| SceneManager | `Scenes` | Sahne geçişleri |
| ConfigManager | `Config` | Konfigürasyon |
| InventoryManager | `Inventory` | Envanter |
| FacilityManager | `Facility` | Tesisler |

### NetworkManager Detayları

**Singleton:** `Network`

**Sinyaller:**
- `request_completed(result: Dictionary)` — İstek başarılı
- `request_failed(error: String)` — İstek başarısız
- `ws_connected()` — WebSocket bağlandı
- `ws_disconnected()` — WebSocket koptu
- `ws_message_received(message: Dictionary)` — WS mesajı geldi
- `rate_limit_exceeded()` — Rate limit aşıldı

**Rate Limiting:**
- Limit: 60 istek/dakika
- Token refill: 1 token/saniye
- Burst: 10 istek

**Metodlar:**
| Metod | Dönüş | Açıklama |
|-------|-------|----------|
| `http_get(endpoint)` | `Dictionary` | GET isteği |
| `http_post(endpoint, body)` | `Dictionary` | POST isteği |
| `http_put(endpoint, body)` | `Dictionary` | PUT isteği |
| `http_delete(endpoint)` | `Dictionary` | DELETE isteği |
| `connect_websocket()` | `void` | WS bağlantısı başlat |
| `send_ws_message(message)` | `void` | WS mesajı gönder |

### SessionManager Detayları

**Singleton:** `Session`

**Sinyaller:**
- `logged_in()` — Giriş başarılı
- `logged_out()` — Çıkış yapıldı
- `token_refreshed()` — Token yenilendi
- `session_expired()` — Oturum süresi doldu
- `register_completed()` — Kayıt tamamlandı
- `profile_missing()` — Profil bulunamadı

**Property'ler:**
| Property | Tip | Açıklama |
|----------|-----|----------|
| `access_token` | String | JWT access token |
| `refresh_token` | String | Refresh token |
| `device_id` | String | Cihaz ID |
| `user_id` | String | Auth user ID |
| `username` | String | Kullanıcı adı |
| `is_authenticated` | bool | Giriş durumu |

**Token Süreleri:**
- Access Token: 15 dakika
- Refresh Token: 7 gün
- Max Cihaz: 3 eş zamanlı oturum

### StateStore Detayları

**Singleton:** `State`

**Sinyaller:**
- `state_changed(key, value)` — Durum değişti
- `player_updated()` — Oyuncu güncellendi
- `inventory_updated()` — Envanter güncellendi
- `energy_updated(current, max)` — Enerji değişti
- `tolerance_updated(value)` — Tolerance değişti
- `gold_updated(value)` — Altın değişti
- `gems_updated(value)` — Gem değişti

**Durum Kategorileri:**

| Kategori | Property'ler |
|----------|--------------|
| **Enerji** | `current_energy`, `max_energy`, `last_regen_time` |
| **Para** | `gold`, `gems` |
| **İlerleme** | `level`, `xp`, `pvp_rating` |
| **Bağımlılık** | `tolerance`, `last_tolerance_decay` |
| **Hastane** | `in_hospital`, `hospital_release_time`, `hospital_reason` |
| **Hapishane** | `in_prison`, `prison_release_time`, `prison_reason` |

**XP Formülü:**
```
Sonraki seviye için XP = base_xp × (current_level ^ 1.5)
base_xp = 1000
```

| Seviye | Gerekli XP |
|--------|-----------|
| 1→2 | 1,000 |
| 2→3 | 2,828 |
| 5→6 | 11,180 |
| 10→11 | 31,623 |
| 20→21 | 89,443 |
| 50→51 | 353,553 |

### FacilityManager Detayları

**Singleton:** `Facility`

**Sinyaller:**
- `facilities_updated()` — Tesisler güncellendi
- `facility_unlocked(type)` — Tesis açıldı
- `production_started(queue_id)` — Üretim başladı
- `production_completed(queue_id)` — Üretim tamamlandı
- `suspicion_changed(facility_id, value)` — Şüphe değişti
- `bribe_completed()` — Rüşvet başarılı
- `facility_upgraded(type, level)` — Tesis yükseltildi
- `raid_occurred(facility_id)` — Baskın oldu

**15 Tesis Tipi:**

| Anahtar | Türkçe Ad | Kategori |
|---------|-----------|----------|
| `mining` | Maden | Hammadde |
| `woodworking` | Marangoz | Hammadde |
| `farming` | Çiftlik | Hammadde |
| `herb_garden` | Bitki Bahçesi | Hammadde |
| `blacksmith` | Demirci | İşleme |
| `armorer` | Zırhçı | İşleme |
| `alchemy_lab` | Simya Laboratuvarı | İşleme |
| `runesmith` | Rün Ustası | İşleme |
| `scroll_library` | Parşömen Kütüphanesi | İşleme |
| `gem_cutter` | Mücevher İşleyici | İşleme |
| `enhancement_master` | Geliştirme Ustası | İleri |
| `master_alchemist` | Usta Simyacı | İleri |
| `master_armorer` | Usta Zırhçı | İleri |
| `warehouse` | Depo | Hizmet |
| `market_hub` | Pazar Merkezi | Hizmet |

## 2.4 Core Manager'lar (15 Adet)

| Manager | Dosya | Ana Sorumluluk |
|---------|-------|----------------|
| EnergyManager | `EnergyManager.gd` | Enerji regen, tüketim |
| PotionManager | `PotionManager.gd` | İksir kullanımı, tolerance |
| HospitalManager | `HospitalManager.gd` | Yatış/çıkış işlemleri |
| DungeonManager | `DungeonManager.gd` | Zindan giriş/sonuç |
| PvPManager | `PvPManager.gd` | Savaş başlatma/sonuç |
| QuestManager | `QuestManager.gd` | Görev atama/tamamlama |
| EquipmentManager | `EquipmentManager.gd` | Ekipman takma/çıkarma |
| EnhancementManager | `EnhancementManager.gd` | Item geliştirme |
| GuildManager | `GuildManager.gd` | Lonca işlemleri |
| ChatManager | `ChatManager.gd` | Mesajlaşma |
| PazarManager | `PazarManager.gd` | Alım/satım |
| ShopManager | `ShopManager.gd` | NPC mağaza |
| ProductionManager | `ProductionManager.gd` | Üretim kuyruğu |
| PrisonManager | `PrisonManager.gd` | Hapishane işlemleri |
| SeasonManager | `SeasonManager.gd` | Sezon takibi |

## 2.5 Data Sınıfları (10 Adet)

| Sınıf | Dosya | İçerik |
|-------|-------|--------|
| PlayerData | `PlayerData.gd` | Oyuncu profili, stats |
| ItemData | `ItemData.gd` | Item tanımı, enum'lar |
| ItemDatabase | `ItemDatabase.gd` | Tüm item'ların cache'i |
| InventoryItemData | `InventoryItemData.gd` | Item instance (row_id) |
| QuestData | `QuestData.gd` | Görev tanımı |
| DungeonData | `DungeonData.gd` | Zindan tanımı |
| DungeonInstance | `DungeonInstance.gd` | Aktif zindan |
| GuildData | `GuildData.gd` | Lonca bilgileri |
| GuildMemberData | `GuildMemberData.gd` | Üye bilgileri |
| PvPData | `PvPData.gd` | PvP sonuçları |

## 2.6 Mimari Pattern'lar

### 1. MVC-Inspired Ayrım

```
┌─────────────────────────────────────────────────┐
│                   VIEW (Scene)                   │
│   scenes/ui/InventoryScreen.tscn                │
└─────────────────────┬───────────────────────────┘
                      │ Signal
┌─────────────────────▼───────────────────────────┐
│              CONTROLLER (Manager)               │
│   core/managers/EquipmentManager.gd             │
└─────────────────────┬───────────────────────────┘
                      │ RPC Call
┌─────────────────────▼───────────────────────────┐
│                 MODEL (Data)                    │
│   core/data/ItemData.gd + Database              │
└─────────────────────────────────────────────────┘
```

### 2. Signal-Driven Architecture

Tüm iletişim Godot sinyalleri üzerinden yapılır:
- **Loose coupling**: Bileşenler birbirinden bağımsız
- **Testability**: Kolay test edilebilir
- **Maintainability**: Değişiklikler izole

### 3. Server-Authoritative Model

| İşlem | Client | Server |
|-------|--------|--------|
| Savaş sonucu | ❌ | ✅ |
| Loot drop | ❌ | ✅ |
| Enhancement başarı | ❌ | ✅ |
| Altın işlemleri | ❌ | ✅ |
| Envanter değişiklikleri | Optimistic | Authoritative |

### 4. Optimistic Updates

```
1. Client UI'ı hemen günceller (optimistic)
2. Server'a istek gönderilir
3. Server onaylarsa → Değişiklik kalır
4. Server reddederse → Rollback yapılır
```

## 2.7 Güvenlik Katmanları

| Katman | Uygulama | Açıklama |
|--------|----------|----------|
| **Auth** | JWT Token | Access: 15dk, Refresh: 7 gün |
| **Session** | Device Tracking | Max 3 cihaz eş zamanlı |
| **Rate Limit** | Token Bucket | 60 req/dk endpoint başına |
| **RLS** | Row Level Security | Kullanıcı sadece kendi verisini görür |
| **Validation** | Edge Function | Tüm input'lar server'da validate |
| **Audit** | Logging | Kritik işlemler loglanır |
| **Anti-Cheat** | Server RNG | Tüm rastgele sayılar server'da |

---

# BÖLÜM 3: VERİTABANI ŞEMASI

## 3.1 Ana Tablolar

### public.items (Item Tanımları)

Tüm oyun item'larının master tablosu. Değişmez referans verileri içerir.

| Kolon | Tip | Açıklama |
|-------|-----|----------|
| `id` | TEXT PK | Benzersiz item ID (örn: `weapon_sword_basic`) |
| `name` | TEXT | Görüntülenen isim |
| `description` | TEXT | Açıklama metni |
| `icon` | TEXT | İkon dosya yolu |
| `item_type` | TEXT | WEAPON, ARMOR, CONSUMABLE, MATERIAL, vb. |
| `item_rarity` | TEXT | COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHIC |
| `equip_slot` | TEXT | WEAPON, HEAD, CHEST, HANDS, LEGS, FEET, ACCESSORY |
| `weapon_type` | TEXT | SWORD, SPEAR, BOW, AXE, DAGGER, STAFF, SHIELD |
| `armor_type` | TEXT | PLATE, CHAIN, LEATHER, CLOTH |
| `potion_type` | TEXT | ENERGY, HEALTH, BUFF |
| `attack` | INT | Saldırı bonusu |
| `defense` | INT | Savunma bonusu |
| `health` | INT | Can bonusu |
| `power` | INT | Güç bonusu |
| `energy_restore` | INT | Enerji iadesi (iksirler) |
| `heal_amount` | INT | İyileştirme miktarı |
| `can_enhance` | BOOL | Geliştirilebilir mi? |
| `max_enhancement` | INT | Max geliştirme seviyesi (genelde 10) |
| `base_price` | INT | Temel fiyat |
| `vendor_sell_price` | INT | NPC'ye satış fiyatı |
| `is_tradeable` | BOOL | Market'te satılabilir mi? |
| `is_stackable` | BOOL | Stack edilebilir mi? |
| `max_stack` | INT | Max stack miktarı (50) |
| `required_level` | INT | Gerekli seviye |
| `required_class` | TEXT | Gerekli sınıf |
| `tolerance_increase` | INT | Tolerance artışı (iksirler) |
| `overdose_risk` | NUMERIC | Overdose riski (0.0-1.0) |
| `production_building_type` | TEXT | Hangi tesiste üretilir |

### public.inventory (Oyuncu Envanteri)

Oyuncuların sahip olduğu item instance'ları.

| Kolon | Tip | Açıklama |
|-------|-----|----------|
| `row_id` | UUID PK | Benzersiz instance ID |
| `user_id` | UUID FK | Sahip oyuncu |
| `item_id` | TEXT FK | Item tanım referansı |
| `quantity` | INT | Stack miktarı |
| `enhancement_level` | INT | Geliştirme seviyesi (+0 ile +10) |
| `is_equipped` | BOOL | Takılı mı? |
| `equip_slot` | TEXT | Hangi slotta takılı |
| `slot_position` | INT | Grid pozisyonu (0-19, NULL=takılı, -998=temp) |
| `obtained_at` | BIGINT | Elde edilme timestamp'i |

**Unique Constraint'ler:**
- `(user_id, item_id, enhancement_level, slot_position)` — Aynı slotta aynı item yok
- `(user_id, equip_slot)` WHERE `is_equipped = true` — Aynı slot'a tek item

### public.facilities (Üretim Tesisleri)

Oyuncuların sahip olduğu üretim binaları.

| Kolon | Tip | Açıklama |
|-------|-----|----------|
| `id` | UUID PK | Tesis instance ID |
| `user_id` | UUID FK | Sahip oyuncu |
| `facility_type` | TEXT | Tesis tipi (15 tip) |
| `level` | INT | Tesis seviyesi (1-20) |
| `suspicion` | INT | Şüphe seviyesi (0-100) |
| `is_unlocked` | BOOL | Açık mı? |
| `created_at` | TIMESTAMPTZ | Oluşturulma zamanı |
| `last_production` | TIMESTAMPTZ | Son üretim zamanı |

### public.production_recipes (Üretim Reçeteleri)

Hangi tesiste ne üretilebilir.

| Kolon | Tip | Açıklama |
|-------|-----|----------|
| `id` | TEXT PK | Reçete ID |
| `facility_type` | TEXT | Gerekli tesis |
| `output_item_id` | TEXT FK | Üretilen item |
| `output_quantity` | INT | Üretim miktarı |
| `input_materials` | JSONB | Gerekli malzemeler `{item_id: quantity}` |
| `gold_cost` | INT | Altın maliyeti |
| `production_time` | INT | Üretim süresi (saniye) |
| `success_rate` | INT | Başarı oranı (%) |
| `base_suspicion_increase` | INT | Şüphe artışı |
| `min_facility_level` | INT | Gerekli tesis seviyesi |

### public.facility_queue (Üretim Kuyruğu)

Aktif üretim işleri.

| Kolon | Tip | Açıklama |
|-------|-----|----------|
| `id` | UUID PK | Kuyruk item ID |
| `facility_id` | UUID FK | Tesis referansı |
| `recipe_id` | TEXT FK | Reçete referansı |
| `quantity` | INT | Üretim miktarı |
| `started_at` | BIGINT | Başlangıç timestamp |
| `completes_at` | BIGINT | Bitiş timestamp |
| `status` | TEXT | `in_progress`, `completed`, `raided`, `burned` |
| `collected` | BOOL | Toplandı mı? |

### public.market_orders (Pazar Emirleri)

Market listeleri.

| Kolon | Tip | Açıklama |
|-------|-----|----------|
| `id` | UUID PK | Emir ID |
| `seller_id` | UUID FK | Satıcı |
| `buyer_id` | UUID FK | Alıcı (satıldığında) |
| `item_id` | TEXT FK | Item tanımı |
| `quantity` | INT | Miktar |
| `price` | INT | Birim fiyat |
| `total_price` | INT | Toplam fiyat |
| `item_data` | JSONB | `{enhancement_level, obtained_at}` |
| `status` | TEXT | `active`, `sold`, `cancelled`, `expired` |
| `listed_at` | BIGINT | Listelenme zamanı |
| `sold_at` | BIGINT | Satış zamanı |
| `expires_at` | BIGINT | Bitiş zamanı |

### game.users (Oyuncu Profilleri)

Ana oyuncu tablosu.

| Kolon | Tip | Açıklama |
|-------|-----|----------|
| `id` | UUID PK | Oyuncu ID |
| `auth_id` | UUID FK | Supabase Auth ID |
| `username` | TEXT UNIQUE | Kullanıcı adı |
| `display_name` | TEXT | Görüntülenen isim |
| `gold` | INT | Altın miktarı |
| `gems` | INT | Gem miktarı |
| `level` | INT | Oyuncu seviyesi |
| `xp` | BIGINT | Toplam XP |
| `current_energy` | INT | Mevcut enerji |
| `max_energy` | INT | Max enerji (100) |
| `tolerance` | INT | Bağımlılık seviyesi (0-100) |
| `last_energy_regen` | TIMESTAMPTZ | Son enerji yenilemesi |
| `last_tolerance_decay` | TIMESTAMPTZ | Son tolerance düşüşü |
| `in_hospital` | BOOL | Hastanede mi? |
| `hospital_until` | TIMESTAMPTZ | Hastane çıkış zamanı |
| `hospital_reason` | TEXT | OVERDOSE, PVP_DEFEAT, QUEST_FAILURE |
| `in_prison` | BOOL | Hapishanede mi? |
| `prison_until` | TIMESTAMPTZ | Hapisten çıkış zamanı |
| `prison_reason` | TEXT | RAID, CRIME |
| `pvp_wins` | INT | PvP galibiyetleri |
| `pvp_losses` | INT | PvP yenilgileri |
| `pvp_rating` | INT | ELO rating |
| `reputation` | INT | İtibar (-500 ile +500) |
| `guild_id` | UUID FK | Lonca ID |
| `guild_role` | TEXT | LORD, COMMANDER, OFFICER, MEMBER, APPRENTICE |
| `created_at` | TIMESTAMPTZ | Kayıt tarihi |
| `last_login` | TIMESTAMPTZ | Son giriş |
| `total_playtime` | INT | Toplam oyun süresi (dakika) |

### public.guilds (Loncalar)

| Kolon | Tip | Açıklama |
|-------|-----|----------|
| `id` | UUID PK | Lonca ID |
| `name` | TEXT UNIQUE | Lonca adı |
| `tag` | TEXT | Kısa etiket (3-5 karakter) |
| `description` | TEXT | Açıklama |
| `leader_id` | UUID FK | Lider oyuncu |
| `level` | INT | Lonca seviyesi |
| `xp` | BIGINT | Lonca XP |
| `treasury_gold` | BIGINT | Hazine altını |
| `member_count` | INT | Üye sayısı |
| `max_members` | INT | Max üye (seviyeye göre) |
| `tax_rate` | NUMERIC | Vergi oranı (0.05 = %5) |
| `created_at` | TIMESTAMPTZ | Kurulum tarihi |
| `is_recruiting` | BOOL | Üye alıyor mu? |
| `min_level` | INT | Minimum üye seviyesi |

### public.chat_messages (Sohbet Mesajları)

| Kolon | Tip | Açıklama |
|-------|-----|----------|
| `id` | UUID PK | Mesaj ID |
| `channel` | TEXT | `global`, `guild`, `private`, `trade` |
| `sender_id` | UUID FK | Gönderen |
| `receiver_id` | UUID FK | Alıcı (private için) |
| `guild_id` | UUID FK | Lonca (guild channel için) |
| `content` | TEXT | Mesaj içeriği (max 200 karakter) |
| `sent_at` | TIMESTAMPTZ | Gönderilme zamanı |
| `is_deleted` | BOOL | Silindi mi? |
| `deleted_by` | UUID FK | Silen moderatör |

## 3.2 RPC Fonksiyonları

### Envanter RPC'leri

| Fonksiyon | Parametreler | Açıklama |
|-----------|--------------|----------|
| `add_inventory_item(item_data JSONB)` | `{item_id, quantity, enhancement_level}` | Item ekle (stack) |
| `add_inventory_item_v2(item_data JSONB, p_slot_position INT)` | Aynı + slot | Grid pozisyonlu ekleme |
| `get_inventory()` | - | Tüm envanteri getir |
| `remove_inventory_item(p_item_id TEXT, p_quantity INT)` | Item ID, miktar | Item sil/azalt |
| `update_item_positions(p_updates JSONB)` | `[{row_id, slot_position}]` | Drag-drop swap |

### Ekipman RPC'leri

| Fonksiyon | Parametreler | Açıklama |
|-----------|--------------|----------|
| `equip_item(item_instance_id UUID, target_slot TEXT)` | Instance ID, slot | Boş slota tak |
| `unequip_item(item_instance_id UUID, target_slot_position INT)` | Instance ID, grid pos | Envantere çıkar |
| `swap_equip_item(p_item_instance_id UUID, p_target_equip_slot TEXT)` | Instance ID, slot | Atomik swap (-998 temp slot) |
| `get_equipped_items()` | - | Takılı itemları getir |

### Market RPC'leri

| Fonksiyon | Parametreler | Açıklama |
|-----------|--------------|----------|
| `place_sell_order(p_item_row_id UUID, p_quantity INT, p_price INT)` | Item, miktar, fiyat | Satışa koy |
| `cancel_sell_order(p_order_id UUID)` | Emir ID | İptal et (envantere dön) |
| `purchase_market_listing(p_order_id UUID, p_quantity INT, p_is_stackable BOOLEAN)` | Emir, miktar, stack | Satın al (%5 komisyon) |
| `get_active_listings(p_item_type TEXT, p_page INT, p_limit INT)` | Filtre, sayfalama | Aktif emirleri listele |

### Hastane RPC'leri

| Fonksiyon | Parametreler | Açıklama |
|-----------|--------------|----------|
| `get_hospital_status(p_auth_id UUID)` | Auth ID | Hastane durumunu sorgula |
| `admit_to_hospital(p_auth_id UUID, p_duration_minutes INT, p_reason TEXT)` | Auth, süre, sebep | Hastaneye yatır |
| `release_from_hospital(p_auth_id UUID, p_method TEXT, p_cost INT)` | Auth, yöntem, maliyet | Çıkış yap |

### Hapishane RPC'leri

| Fonksiyon | Parametreler | Açıklama |
|-----------|--------------|----------|
| `arrest_player(p_auth_id UUID, p_duration_minutes INT, p_reason TEXT)` | Auth, süre, sebep | Hapse at |
| `release_from_prison(p_use_bail BOOLEAN)` | Kefalet kullan? | Çıkış (kefalet = kalan dakika gem) |
| `get_prison_status(p_auth_id UUID)` | Auth ID | Hapishane durumu |

### Tesis RPC'leri

| Fonksiyon | Parametreler | Açıklama |
|-----------|--------------|----------|
| `get_facilities()` | - | Tüm tesisleri getir |
| `unlock_facility(p_facility_type TEXT)` | Tesis tipi | Tesis aç |
| `upgrade_facility(p_facility_id UUID)` | Tesis ID | Tesis yükselt |
| `start_production(p_facility_id UUID, p_recipe_id TEXT, p_quantity INT)` | Tesis, reçete, miktar | Üretim başlat |
| `collect_production(p_queue_id UUID)` | Kuyruk ID | Ürünü topla |
| `bribe_guards(p_facility_id UUID)` | Tesis ID | Rüşvet ver (5 gem, -10 suspicion) |

## 3.3 RLS Politikaları

Row Level Security ile veri izolasyonu sağlanır.

### Kullanıcı Tablosu

```sql
-- Oyuncular sadece kendi verilerini görebilir
CREATE POLICY "users_select_own" ON game.users
  FOR SELECT USING (auth.uid() = id);

-- Oyuncular sadece kendi verilerini güncelleyebilir
CREATE POLICY "users_update_own" ON game.users
  FOR UPDATE USING (auth.uid() = id);
```

### Envanter Tablosu

```sql
-- Oyuncular sadece kendi envanterini görebilir
CREATE POLICY "inventory_select_own" ON public.inventory
  FOR SELECT USING (auth.uid() = user_id);

-- Oyuncular kendi envanterlerine ekleyebilir
CREATE POLICY "inventory_insert_own" ON public.inventory
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Oyuncular kendi envanterini güncelleyebilir
CREATE POLICY "inventory_update_own" ON public.inventory
  FOR UPDATE USING (auth.uid() = user_id);

-- Oyuncular kendi envanterinden silebilir
CREATE POLICY "inventory_delete_own" ON public.inventory
  FOR DELETE USING (auth.uid() = user_id);
```

### Market Tablosu

```sql
-- Herkes aktif emirleri görebilir
CREATE POLICY "orders_select_active" ON public.market_orders
  FOR SELECT USING (status = 'active');

-- Satıcılar kendi emirlerini iptal edebilir
CREATE POLICY "orders_update_own" ON public.market_orders
  FOR UPDATE USING (auth.uid() = seller_id);
```

### Tesis Tablosu

```sql
-- Oyuncular sadece kendi tesislerini görebilir
CREATE POLICY "facilities_select_own" ON public.facilities
  FOR SELECT USING (auth.uid() = user_id);
```

## 3.4 View ve Index'ler

### View'lar

```sql
-- Envanter + Item detayları
CREATE VIEW v_inventory_with_items AS
SELECT 
  i.*,
  it.name, it.description, it.icon,
  it.item_type, it.item_rarity, it.equip_slot,
  it.attack, it.defense, it.health, it.power
FROM public.inventory i
JOIN public.items it ON i.item_id = it.id;

-- Market + Item detayları
CREATE VIEW v_market_listings AS
SELECT 
  m.*,
  it.name, it.icon, it.item_rarity,
  u.username as seller_name
FROM public.market_orders m
JOIN public.items it ON m.item_id = it.id
JOIN game.users u ON m.seller_id = u.id
WHERE m.status = 'active';
```

### Index'ler

```sql
-- Envanter sorguları için
CREATE INDEX idx_inventory_user ON public.inventory(user_id);
CREATE INDEX idx_inventory_item ON public.inventory(item_id);
CREATE INDEX idx_inventory_equipped ON public.inventory(user_id) WHERE is_equipped = true;

-- Market sorguları için
CREATE INDEX idx_orders_status ON public.market_orders(status);
CREATE INDEX idx_orders_item ON public.market_orders(item_id) WHERE status = 'active';
CREATE INDEX idx_orders_price ON public.market_orders(price) WHERE status = 'active';

-- Tesis sorguları için
CREATE INDEX idx_facilities_user ON public.facilities(user_id);
CREATE INDEX idx_queue_facility ON public.facility_queue(facility_id);
CREATE INDEX idx_queue_status ON public.facility_queue(status);
```

## 3.5 Trigger'lar

### XP → Level Up Trigger

```sql
CREATE OR REPLACE FUNCTION check_level_up()
RETURNS TRIGGER AS $$
DECLARE
  required_xp BIGINT;
  new_level INT;
BEGIN
  new_level := NEW.level;
  
  LOOP
    required_xp := 1000 * POWER(new_level, 1.5);
    EXIT WHEN NEW.xp < required_xp;
    new_level := new_level + 1;
  END LOOP;
  
  IF new_level > NEW.level THEN
    NEW.level := new_level;
    -- Level up bonus
    NEW.gems := NEW.gems + (10 * (new_level - OLD.level));
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_level_up
BEFORE UPDATE OF xp ON game.users
FOR EACH ROW EXECUTE FUNCTION check_level_up();
```

### Tolerance Decay Trigger

```sql
CREATE OR REPLACE FUNCTION decay_tolerance()
RETURNS TRIGGER AS $$
DECLARE
  hours_passed INT;
  decay_amount INT;
BEGIN
  hours_passed := EXTRACT(EPOCH FROM (NOW() - OLD.last_tolerance_decay)) / 3600;
  
  IF hours_passed >= 6 THEN
    decay_amount := hours_passed / 6;
    NEW.tolerance := GREATEST(0, NEW.tolerance - decay_amount);
    NEW.last_tolerance_decay := NOW();
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

# BÖLÜM 4: API VE EDGE FUNCTIONS

## 4.1 Supabase Edge Functions Listesi

| Fonksiyon | Endpoint | Metod | Açıklama |
|-----------|----------|-------|----------|
| `energy` | `/functions/v1/energy` | GET/POST | Enerji işlemleri |
| `hospital-admit` | `/functions/v1/hospital-admit` | POST | Hastaneye yatış |
| `hospital-release` | `/functions/v1/hospital-release` | POST | Hastaneden çıkış |
| `facilities` | `/functions/v1/facilities` | GET/POST | Tesis listesi/işlemleri |
| `facility-unlock` | `/functions/v1/facility-unlock` | POST | Tesis açma |
| `facility-upgrade` | `/functions/v1/facility-upgrade` | POST | Tesis yükseltme |
| `production-start` | `/functions/v1/production-start` | POST | Üretim başlat |
| `production-collect` | `/functions/v1/production-collect` | POST | Üretim topla |
| `bribe` | `/functions/v1/bribe` | POST | Rüşvet ver |
| `market` | `/functions/v1/market` | GET/POST | Market işlemleri |
| `pvp-attack` | `/functions/v1/pvp-attack` | POST | PvP saldırı |
| `dungeon-enter` | `/functions/v1/dungeon-enter` | POST | Zindan giriş |
| `quest` | `/functions/v1/quest` | GET/POST | Görev işlemleri |
| `guild` | `/functions/v1/guild` | GET/POST | Lonca işlemleri |
| `chat` | `/functions/v1/chat` | POST | Mesaj gönder |

## 4.2 Enerji Fonksiyonları

### GET /energy

**Response:**
```json
{
  "current_energy": 75,
  "max_energy": 100,
  "regen_rate": 1,
  "regen_interval": 300,
  "next_regen_at": 1706700000000
}
```

### POST /energy/consume

**Request:**
```json
{
  "amount": 10,
  "action": "quest"
}
```

**Response:**
```json
{
  "success": true,
  "new_energy": 65,
  "action_allowed": true
}
```

## 4.3 Hastane Fonksiyonları

### POST /hospital-admit

**Request:**
```json
{
  "duration_minutes": 120,
  "reason": "OVERDOSE"
}
```

**Response:**
```json
{
  "success": true,
  "release_at": 1706707200000,
  "reason": "OVERDOSE"
}
```

### POST /hospital-release

**Request:**
```json
{
  "method": "gems",
  "cost": 15
}
```

**Yöntemler:**
- `natural` — Süre dolduğunda (maliyet: 0)
- `gems` — Gem ile çıkış (maliyet: hesaplanan)
- `guild_help` — Lonca yardımı (maliyet: 0, -%20 süre)

## 4.4 Tesis Fonksiyonları

### Tesis Konfigürasyonu

| Tesis | Açılış Maliyeti | Yükseltme Çarpanı | Max Seviye |
|-------|-----------------|-------------------|------------|
| `mining` | 3,000 altın | 1.5x | 20 |
| `woodworking` | 3,000 altın | 1.5x | 20 |
| `farming` | 3,500 altın | 1.5x | 20 |
| `herb_garden` | 4,000 altın | 1.6x | 20 |
| `blacksmith` | 8,000 altın | 1.7x | 20 |
| `armorer` | 8,000 altın | 1.7x | 20 |
| `alchemy_lab` | 10,000 altın | 1.7x | 20 |
| `runesmith` | 15,000 altın | 1.8x | 20 |
| `scroll_library` | 12,000 altın | 1.7x | 20 |
| `gem_cutter` | 12,000 altın | 1.7x | 20 |
| `enhancement_master` | 17,000 altın | 1.8x | 20 |
| `master_alchemist` | 15,000 altın | 1.8x | 20 |
| `master_armorer` | 15,000 altın | 1.8x | 20 |
| `warehouse` | 5,000 altın | 1.5x | 20 |
| `market_hub` | 6,000 altın | 1.6x | 20 |

### POST /facility-upgrade

**Yükseltme Maliyeti Formülü:**
```
maliyet = base_cost × (multiplier ^ current_level)
```

**Örnek (mining seviye 5→6):**
```
maliyet = 3000 × (1.5 ^ 5) = 3000 × 7.59 = 22,781 altın
```

### POST /production-start

**Request:**
```json
{
  "facility_id": "uuid",
  "recipe_id": "sword_basic",
  "quantity": 5
}
```

**İşlem Akışı:**
1. Malzeme kontrolü
2. Altın kontrolü
3. Suspicion hesaplama
4. Malzeme düşme
5. Altın düşme
6. Queue'ya ekleme

### POST /production-collect

**İşlem Akışı:**
1. Tamamlanma kontrolü
2. Baskın (raid) kontrolü
3. Başarı kontrolü (success_rate)
4. Rarity hesaplama (tesis seviyesi + suspicion etkisi)
5. Envantere ekleme
6. Log kaydı

**Rarity Dağılımı Formülü:**
```
common_chance = 0.60 - (level × 0.02) + (suspicion × 0.005)
uncommon_chance = 0.25 + (level × 0.01)
rare_chance = 0.10 + (level × 0.008)
epic_chance = 0.04 + (level × 0.005)
legendary_chance = 0.01 + (level × 0.002)
```

### POST /bribe

**Sabit Değerler:**
- Maliyet: 5 gem
- Etki: -10 suspicion

## 4.5 Market Fonksiyonları

### GET /market/listings

**Query Parametreleri:**
- `item_type` — Filtreleme
- `sort` — `price_asc`, `price_desc`, `date_desc`
- `page` — Sayfa numarası
- `limit` — Sayfa başı sonuç (max 50)

### POST /market/buy

**Request:**
```json
{
  "order_id": "uuid",
  "quantity": 1
}
```

**Komisyon:** Satış fiyatının %5'i satıcıdan kesilir

## 4.6 Rate Limiting

| Endpoint Kategorisi | Limit | Pencere |
|---------------------|-------|---------|
| Auth | 5 | 1 dakika |
| Energy | 30 | 1 dakika |
| Market | 60 | 1 dakika |
| Chat | 30 | 1 dakika |
| PvP | 10 | 1 dakika |
| Production | 30 | 1 dakika |
| Genel | 120 | 1 dakika |

**Rate Limit Aşımı Response:**
```json
{
  "error": "rate_limit_exceeded",
  "retry_after": 45,
  "limit": 60,
  "remaining": 0
}
```

---

# BÖLÜM 5: ENERJİ SİSTEMİ

## 5.1 Temel Mekanikler

Enerji, oyundaki tüm aktiviteleri sınırlayan ana kaynaktır. Oyuncular enerji harcayarak görev yapar, zindana girer ve PvP savaşı başlatır.

| Parametre | Değer |
|-----------|-------|
| **Maksimum Enerji** | 100 |
| **Başlangıç Enerjisi** | 100 (tam) |
| **Rejenerasyon Hızı** | 1 enerji / 5 dakika |
| **Günlük Doğal Regen** | 288 enerji (24 saat) |
| **Offline Regen Cap** | 24 saat |

## 5.2 Enerji Maliyetleri

### Görev Enerji Maliyetleri

| Görev Zorluğu | Enerji | Açıklama |
|---------------|--------|----------|
| **Kolay** | 5 | Kısa görevler, düşük ödül |
| **Orta** | 10 | Standart görevler |
| **Zor** | 15 | Uzun görevler, yüksek ödül |
| **Zindan** | 20-40 | Değişken, zindan tipine göre |

### Diğer Aktiviteler

| Aktivite | Enerji | Açıklama |
|----------|--------|----------|
| **PvP Saldırı** | 10 | Normal saldırı |
| **PvP Misilleme** | 0 | 1 saat içinde karşılık |
| **Üretim** | 0 | Enerji gerektirmez |
| **Market** | 0 | Enerji gerektirmez |

## 5.3 Rejenerasyon Formülleri

### Temel Rejenerasyon

```
regen_interval = 300 saniye (5 dakika)
regen_amount = 1 enerji

Saatlik regen = 60 / 5 = 12 enerji
Günlük regen = 12 × 24 = 288 enerji
```

### Sonraki Regen Zamanı

```
time_to_next = regen_interval - (current_time - last_regen_time) % regen_interval
```

## 5.4 Offline Rejenerasyon

Oyuncu çevrimdışıyken de enerji yenilenir:

```
offline_duration = current_time - last_login_time
offline_regen = MIN(offline_duration / regen_interval, max_energy - current_energy)

// Max 24 saat = 288 enerji
offline_cap = 24 × 60 × 60 = 86400 saniye
```

### Giriş Sonrası Hesaplama

1. Son giriş zamanı kontrol edilir
2. Geçen süre hesaplanır (max 24 saat)
3. Regen miktarı = geçen_süre / 300
4. Mevcut enerjiye eklenir (max 100'ü geçmez)

## 5.5 Enerji Yenileme Yolları

| Yöntem | Miktar | Maliyet | Cooldown |
|--------|--------|---------|----------|
| Doğal Regen | 1 | Ücretsiz | 5 dakika |
| Minör İksir | +20 | Üretim/Market | - |
| Büyük İksir | +50 | Üretim/Market | - |
| Yüce İksir | +100 | Üretim/Market | - |
| Gem ile Tam Doldur | 100 | 50 gem | Günde 3 |

---

# BÖLÜM 6: İKSİR VE BAĞIMLILIK SİSTEMİ

## 6.1 İksir Tipleri

### Enerji İksirleri

| İksir | Enerji | Tolerance Artışı | Üretim Yeri |
|-------|--------|------------------|-------------|
| **Minör Enerji İksiri** | +20 | +5 | Simya Lab |
| **Büyük Enerji İksiri** | +50 | +15 | Simya Lab |
| **Yüce Enerji İksiri** | +100 | +30 | Usta Simyacı |

### Tedavi İksirleri

| İksir | Etki | Tolerance | Üretim Yeri |
|-------|------|-----------|-------------|
| **Hafif Antidot** | -10 tolerance | 0 | Simya Lab |
| **Güçlü Antidot** | -20 tolerance | 0 | Simya Lab |
| **Arındırma İksiri** | -50 tolerance | 0 | Usta Simyacı |

### Can İksirleri

| İksir | İyileşme | Kullanım Yeri |
|-------|----------|---------------|
| **Küçük Şifa** | +100 HP | Zindan içi |
| **Orta Şifa** | +300 HP | Zindan içi |
| **Büyük Şifa** | +600 HP | Zindan içi |

## 6.2 Tolerance (Bağımlılık) Mekaniği

### Tolerance Nedir?

Tolerance, enerji iksiri kullanımından kaynaklanan bağımlılık seviyesidir. Yüksek tolerance:
- İksirlerin etkinliğini azaltır
- Overdose riskini artırır
- Hastaneye düşme süresini uzatır

### Tolerance Aralığı

| Değer | Durum |
|-------|-------|
| 0-100 | Geçerli aralık |
| 0 | Tamamen temiz |
| 100 | Maksimum bağımlılık |

### Tolerance Artışı

Her enerji iksiri kullanımında tolerance artar:

```
new_tolerance = MIN(100, current_tolerance + potion_tolerance_value)
```

| İksir | Tolerance Artışı |
|-------|------------------|
| Minör İksir | +5 |
| Büyük İksir | +15 |
| Yüce İksir | +30 |

### Tolerance Azalması (Decay)

Zaman geçtikçe tolerance doğal olarak azalır:

```
decay_rate = -1 tolerance / 6 saat
daily_decay = -4 tolerance / gün
```

## 6.3 Overdose Sistemi

### Overdose Nedir?

Yüksek tolerance ile iksir kullanımı overdose (aşırı doz) riskine yol açar. Overdose durumunda oyuncu hastaneye düşer.

### Overdose Olasılığı Formülü

```
base_overdose_risk = potion_base_risk (0.0 - 0.1)
tolerance_multiplier = 1 + (tolerance / 100)
final_risk = base_overdose_risk × tolerance_multiplier

// Tolerance 80'de, base risk 0.05 olan iksir:
// final_risk = 0.05 × 1.8 = 0.09 = %9
```

### Tolerance Seviyelerine Göre Overdose

| Tolerance | Risk Çarpanı | Örnek Risk (base 0.05) |
|-----------|--------------|------------------------|
| 0 | 1.0x | %5 |
| 30 | 1.3x | %6.5 |
| 60 | 1.6x | %8 |
| 80 | 1.8x | %9 |
| 100 | 2.0x | %10 |

### Overdose Sonuçları

| Sonuç | Değer |
|-------|-------|
| Hastane Süresi | 4-12 saat (tolerance'a bağlı) |
| Hastane Sebebi | `OVERDOSE` |
| Tolerance Sıfırlanır mı? | Hayır (kalır) |

**Hastane Süresi Formülü:**
```
duration_hours = 4 + (tolerance / 100) × 8
// Tolerance 100'de: 4 + 8 = 12 saat
```

## 6.4 Antidot ve İyileşme

### Antidot Kullanımı

Antidotlar tolerance'ı düşürür ancak overdose riskini hemen ortadan kaldırmaz.

```
new_tolerance = MAX(0, current_tolerance - antidote_value)
```

### Şifacı NPC

Şehirdeki Şifacı NPC, tolerance'ı altın karşılığı düşürebilir:

| Hizmet | Etki | Maliyet |
|--------|------|---------|
| Hafif Arınma | -10 tolerance | 500 altın |
| Orta Arınma | -25 tolerance | 1,500 altın |
| Tam Arınma | Tolerance = 0 | 5,000 altın |

## 6.5 Tolerance Tier'ları

Tolerance seviyesine göre görsel ve mekanik geri bildirimler:

| Tier | Aralık | Renk | UI Gösterge | Etki |
|------|--------|------|-------------|------|
| 0 | 0-30 | 🟢 Yeşil | "Sağlıklı" | Normal |
| 1 | 31-60 | 🟡 Sarı | "Dikkat" | %10 iksir etkinlik kaybı |
| 2 | 61-80 | 🟠 Turuncu | "Tehlike" | %20 iksir etkinlik kaybı |
| 3 | 81-95 | 🔴 Kırmızı | "Kritik" | %35 iksir etkinlik kaybı |
| 4 | 96-100 | ⚫ Mor | "Ölümcül" | %50 iksir etkinlik kaybı |

### İksir Etkinliği Formülü

```
effectiveness = 1.0 - (tolerance / 100) × 0.5
actual_energy = base_energy × effectiveness

// Tolerance 80'de +50 iksir:
// effectiveness = 1.0 - 0.8 × 0.5 = 0.6
// actual_energy = 50 × 0.6 = 30 enerji
```

---

# BÖLÜM 7: HASTANE SİSTEMİ

## 7.1 Hastaneye Düşme Sebepleri

| Sebep | Açıklama | Süre Aralığı |
|-------|----------|--------------|
| `OVERDOSE` | İksir aşırı dozu | 4-12 saat |
| `PVP_DEFEAT` | PvP'de kritik yenilgi | 2-8 saat |
| `PVP_CRITICAL` | PvP'de ağır yenilgi | 4-8 saat |
| `QUEST_FAILURE` | Görevde kritik başarısızlık | 1-4 saat |
| `DUNGEON_WIPE` | Zindanda ölüm | 2-6 saat |

## 7.2 Yatış Süreleri

### Overdose Süre Formülü

```
base_duration = 240 dakika (4 saat)
tolerance_factor = (tolerance / 100) × 480 dakika (8 saat)
final_duration = base_duration + tolerance_factor

// Tolerance 100: 240 + 480 = 720 dakika = 12 saat
// Tolerance 50: 240 + 240 = 480 dakika = 8 saat
```

### PvP Yenilgi Süre Formülü

```
base_duration = 120 dakika (2 saat)
power_diff_factor = (opponent_power / player_power - 1) × 180 dakika
critical_bonus = is_critical ? 240 dakika : 0
final_duration = MIN(480, base_duration + power_diff_factor + critical_bonus)

// Max: 8 saat
```

### Zindan Wipe Süre Formülü

```
base_duration = 120 dakika (2 saat)
difficulty_factor = difficulty_level × 60 dakika
final_duration = MIN(360, base_duration + difficulty_factor)

// Max: 6 saat
```

## 7.3 Çıkış Yöntemleri

### 1. Doğal Bekleme (Ücretsiz)

Süre dolduğunda otomatik çıkış.

| Özellik | Değer |
|---------|-------|
| Maliyet | 0 |
| Hız | Normal |
| Avantaj | Ücretsiz |
| Dezavantaj | Uzun süre bekle |

### 2. Gem ile Anında Çıkış

Kalan süreyi gem ödeyerek atla.

**Maliyet Formülü:**
```
gem_cost = CEIL(remaining_minutes / 3) + base_fee

base_fee = 5 gem
per_minute = 1 gem / 3 dakika

// 60 dakika kaldıysa: CEIL(60/3) + 5 = 20 + 5 = 25 gem
```

| Kalan Süre | Gem Maliyeti |
|------------|--------------|
| 30 dakika | 15 gem |
| 1 saat | 25 gem |
| 2 saat | 45 gem |
| 4 saat | 85 gem |
| 8 saat | 165 gem |
| 12 saat | 245 gem |

### 3. Lonca Yardımı

Lonca üyeleri hastanedeki arkadaşlarına yardım edebilir.

| Özellik | Değer |
|---------|-------|
| Maliyet | Ücretsiz |
| Etki | -%20 süre |
| Koşul | Aynı loncada olmalı |
| Günlük Limit | 3 yardım/gün |

### 4. Şifacı Müdahalesi

Şifacı NPC hastaneden erken çıkış sağlayabilir ancak başarı garantisi yoktur.

| Hizmet | Maliyet | Başarı Oranı | Etki |
|--------|---------|--------------|------|
| Temel Müdahale | 1,000 altın | %30 | Anında çıkış |
| Gelişmiş Müdahale | 3,000 altın | %50 | Anında çıkış |
| Uzman Müdahale | 8,000 altın | %70 | Anında çıkış |

**Başarısızlık:** Altın harcanır, hastanede kalmaya devam.

## 7.4 Şifacı Mekaniği

### Şifacı NPC Özellikleri

Şifacı, hem hastane çıkışı hem de tolerance tedavisi sunar.

**Konum:** Her ana şehirde 1 adet

**Hizmetler:**

| Hizmet | Kategori | Açıklama |
|--------|----------|----------|
| Hastane Müdahalesi | Hastane | Erken çıkış denemesi |
| Tolerance Arınma | Bağımlılık | Tolerance düşürme |
| Buff İksiri | Geçici Buff | +%10 stat, 1 saat |

### Şifacı Cooldown

| Hizmet | Cooldown |
|--------|----------|
| Hastane Müdahalesi | 4 saat |
| Tolerance Arınma | 2 saat |
| Buff İksiri | 1 saat |

---

# BÖLÜM 8: ZİNDAN (DUNGEON) SİSTEMİ

## 8.1 Zindan Tipleri

### Ana Zindan Kategorileri

| Kategori | Açıklama | Örnek |
|----------|----------|-------|
| **Hikaye Zindanları** | Ana hikaye görevleri | Kral'ın Mezarı |
| **Günlük Zindanlar** | Günde 3 giriş hakkı | Goblin Mağarası |
| **Haftalık Zindanlar** | Haftada 1 giriş | Ejderha İni |
| **Lonca Zindanları** | Lonca ile grup | Karanlık Tapınak |
| **Event Zindanları** | Sezonluk özel | Cadılar Şatosu |

### Zindan Bilgileri

| Zindan | Zorluk | Enerji | Min Seviye | Loot Tier |
|--------|--------|--------|------------|-----------|
| Goblin Mağarası | Kolay | 20 | 1 | Common |
| Banditlerin İni | Orta | 25 | 10 | Uncommon |
| Hayalet Kalesi | Zor | 30 | 20 | Rare |
| Ejderha Mağarası | Çok Zor | 35 | 35 | Epic |
| Ölüm Vadisi | Efsanevi | 40 | 50 | Legendary |

## 8.2 Zorluk Seviyeleri

| Zorluk | Temel Başarı | Hastane Riski | Ödül Çarpanı |
|--------|--------------|---------------|--------------|
| **EASY** | %85 | %0 | 1.0x |
| **MEDIUM** | %70 | %5 | 1.5x |
| **HARD** | %55 | %15 | 2.5x |
| **DUNGEON** | %45 | %25 | 4.0x |
| **LEGENDARY** | %30 | %35 | 6.0x |

## 8.3 Başarı Formülü

### Temel Formül

```
success_rate = base_rate 
             + gear_bonus × GEAR_WEIGHT
             + skill_bonus × SKILL_WEIGHT
             + level_bonus × LEVEL_WEIGHT
             - difficulty_penalty × DIFFICULTY_WEIGHT
             - danger_penalty × DANGER_WEIGHT
```

### Ağırlık Sabitleri

| Faktör | Ağırlık | Açıklama |
|--------|---------|----------|
| `GEAR_WEIGHT` | 0.25 | Ekipman etkisi |
| `SKILL_WEIGHT` | 0.15 | Yetenek etkisi |
| `LEVEL_WEIGHT` | 0.15 | Seviye farkı etkisi |
| `DIFFICULTY_WEIGHT` | 0.20 | Zindan zorluğu |
| `DANGER_WEIGHT` | 0.15 | Tehlike seviyesi |

### Bonus Hesaplamaları

**Ekipman Bonusu:**
```
gear_bonus = (total_item_power / recommended_power) × 100
// Capped at 25%
```

**Seviye Bonusu:**
```
level_diff = player_level - dungeon_level
level_bonus = CLAMP(level_diff × 3, -15, +15)
// Her seviye ±3%, max ±15%
```

**Beceri Bonusu:**
```
skill_bonus = skill_level × 0.5
// Her beceri seviyesi +0.5%, max +15% (seviye 30)
```

### Final Başarı Oranı

```
final_rate = CLAMP(calculated_rate, 10, 95)
// Minimum: %10 (her zaman şans var)
// Maximum: %95 (risk her zaman var)
```

## 8.4 Ödül Dağılımı

### Temel Ödüller

| Zorluk | Altın (Base) | XP (Base) | Item Sayısı |
|--------|--------------|-----------|-------------|
| EASY | 100-200 | 50-100 | 1-2 |
| MEDIUM | 250-500 | 150-300 | 2-3 |
| HARD | 600-1,200 | 400-800 | 3-4 |
| DUNGEON | 1,500-3,000 | 1,000-2,000 | 4-5 |
| LEGENDARY | 4,000-8,000 | 3,000-6,000 | 5-7 |

### Loot Rarity Tablosu

| Zorluk | Common | Uncommon | Rare | Epic | Legendary |
|--------|--------|----------|------|------|-----------|
| EASY | %70 | %25 | %5 | %0 | %0 |
| MEDIUM | %50 | %35 | %12 | %3 | %0 |
| HARD | %30 | %40 | %20 | %8 | %2 |
| DUNGEON | %15 | %35 | %30 | %15 | %5 |
| LEGENDARY | %5 | %20 | %35 | %25 | %15 |

### Bonus Loot Şansı

**İlk Tamamlama Bonusu:** +%50 ödül (sadece ilk kez)

**Mükemmel Tamamlama:** Hasar almadan bitirme → +%25 ödül

**Lonca Bonusu:** Lonca üyesiyle giriş → +%10 ödül

## 8.5 Hospitalization Oranları

### Zindan Başarısızlık Sonuçları

| Sonuç | Olasılık | Hastane | Loot |
|-------|----------|---------|------|
| Başarı | Hesaplanan | Yok | Tam |
| Kısmi Başarı | %15 (başarısızlıkta) | Yok | %50 |
| Yenilgi | %60 (başarısızlıkta) | Yok | Yok |
| Kritik Yenilgi | %25 (başarısızlıkta) | Var | Yok |

### Hastane Süresi Formülü (Zindan)

```
base_duration = 120 dakika (2 saat)
difficulty_bonus = (difficulty_level - 1) × 30 dakika
damage_taken_bonus = (damage_percent) × 60 dakika
final_duration = MIN(360, base_duration + difficulty_bonus + damage_taken_bonus)

// Max: 6 saat
```

---

# BÖLÜM 9: PVP SİSTEMİ

## 9.1 Savaş Mekaniği

### Savaş Başlatma Koşulları

| Koşul | Değer |
|-------|-------|
| Minimum Seviye | 10 |
| Enerji Maliyeti | 10 (saldırı), 0 (misilleme) |
| Cooldown | 5 dakika (aynı hedefe) |
| Hastanedeyken | Saldıramaz |
| Hapishanedeyken | Saldıramaz |

### Savaş Akışı

```
1. Saldırgan hedef seçer
2. Enerji kontrolü (10 enerji)
3. Cooldown kontrolü
4. Server-side güç hesaplama
5. RNG ile sonuç belirleme
6. Ödül/ceza dağıtımı
7. Reputation güncelleme
8. (Kritik yenilgide) Hastane
```

## 9.2 Güç Hesaplama Formülü

### Temel Güç

```
base_power = attack + defense + (health / 10) + power

// Örnek: attack=100, defense=80, health=1000, power=50
// base_power = 100 + 80 + 100 + 50 = 330
```

### Ekipman Bonusu

```
weapon_bonus = weapon_attack × (1 + enhancement × 0.05)
armor_bonus = armor_defense × (1 + enhancement × 0.05)
accessory_bonus = accessory_power × (1 + enhancement × 0.05)

// +5 kılıç (100 attack): 100 × 1.25 = 125
```

### Buff'lar

| Buff Tipi | Bonus | Kaynak |
|-----------|-------|--------|
| Lonca Buff | +%5-15 | Lonca seviyesi |
| Şifacı Buff | +%10 | Şifacı NPC |
| Yemek Buff | +%5-10 | Yemek item'ları |
| Sezon Buff | +%0-20 | Sezon eventi |

### Final Güç

```
total_power = (base_power + equipment_bonus) × (1 + buff_percent)
combat_power = total_power × random(0.85, 1.15)

// %15 varyans - şans faktörü
```

## 9.3 Kazanma Olasılığı

### Logaritmik Formül

```
power_ratio = attacker_power / defender_power
win_chance = 0.5 + log10(power_ratio) × 0.25

// Clamped: 0.15 - 0.85 (%15 - %85)
```

### Güç Oranına Göre Şans

| Güç Oranı | Kazanma Şansı |
|-----------|---------------|
| 0.5x (yarısı) | %15 |
| 0.8x | %35 |
| 1.0x (eşit) | %50 |
| 1.25x | %65 |
| 2.0x (iki katı) | %85 |

### Savaş Sonuçları

| Sonuç | Olasılık | Açıklama |
|-------|----------|----------|
| Kritik Zafer | %10 (zafer içinde) | Çok yüksek hasar |
| Normal Zafer | %90 (zafer içinde) | Normal sonuç |
| Normal Yenilgi | %90 (yenilgi içinde) | Normal sonuç |
| Kritik Yenilgi | %10 (yenilgi içinde) | Hastaneye düşüş |

## 9.4 Reputation Sistemi

### Reputation Aralığı

```
Min: -500 (Kötü şöhret)
Max: +500 (Kahraman)
Başlangıç: 0
```

### Reputation Değişimi

| Durum | Değişim |
|-------|---------|
| Zafer (eşit güç) | +5 |
| Zafer (daha güçlüye) | +8 ile +15 |
| Zafer (daha zayıfa) | +2 ile +4 |
| Yenilgi (eşit güç) | -3 |
| Yenilgi (daha güçlüye) | -1 ile -2 |
| Yenilgi (daha zayıfa) | -5 ile -8 |

### Reputation Tier'ları

| Tier | Aralık | Unvan | Bonus |
|------|--------|-------|-------|
| 6 | +400 ile +500 | Efsanevi Savaşçı | +%15 PvP ödülü |
| 5 | +200 ile +399 | Şampiyion | +%10 PvP ödülü |
| 4 | +50 ile +199 | Savaşçı | +%5 PvP ödülü |
| 3 | -49 ile +49 | Sıradan | Normal |
| 2 | -199 ile -50 | Haydut | -%5 NPC fiyatları |
| 1 | -399 ile -200 | Kanun Kaçağı | -%10 NPC, +%10 polis şüphesi |
| 0 | -500 ile -400 | Halk Düşmanı | -%20 NPC, +%25 polis şüphesi |

## 9.5 ELO Rating

### ELO Formülü

```
K = 32 (K-faktörü)
expected = 1 / (1 + 10^((opponent_rating - player_rating) / 400))
result = 1 (win), 0.5 (draw), 0 (loss)
new_rating = old_rating + K × (result - expected)
```

### Örnek Hesaplama

```
Oyuncu: 1200 rating
Rakip: 1400 rating

expected = 1 / (1 + 10^((1400-1200)/400))
         = 1 / (1 + 10^0.5)
         = 1 / (1 + 3.16)
         = 0.24

Oyuncu kazanırsa:
new_rating = 1200 + 32 × (1 - 0.24) = 1200 + 24 = 1224

Oyuncu kaybederse:
new_rating = 1200 + 32 × (0 - 0.24) = 1200 - 8 = 1192
```

### Rating Tier'ları

| Tier | Rating | Sıra Adı |
|------|--------|----------|
| Bronz | 0-999 | Acemi |
| Gümüş | 1000-1499 | Deneyimli |
| Altın | 1500-1999 | Usta |
| Platin | 2000-2499 | Efsane |
| Elmas | 2500+ | Şampiyon |

## 9.6 Misilleme Mekaniği

### Misilleme Hakkı

Saldırıya uğrayan oyuncu 1 saat içinde ücretsiz (0 enerji) misilleme yapabilir.

| Özellik | Değer |
|---------|-------|
| Süre | 1 saat |
| Enerji | 0 |
| Cooldown | Yok |
| Maksimum | 3 misilleme/saldırgan |

### Misilleme Avantajları

- Enerji maliyeti yok
- Cooldown yok
- +%5 saldırı bonusu (öfke)

---

# BÖLÜM 10: 15 TESİS SİSTEMİ

## 10.1 Tesis Kategorileri

Tesisler 4 ana kategoriye ayrılır:

| Kategori | Tesis Sayısı | Amaç |
|----------|--------------|------|
| **Hammadde** | 4 | Temel malzeme üretimi |
| **İşleme** | 6 | Malzemeyi ürüne dönüştürme |
| **İleri** | 3 | Legendary item üretimi |
| **Hizmet** | 2 | Depo ve market erişimi |

## 10.2 Hammadde Tesisleri (4 Adet)

### Maden (Mining)

| Özellik | Değer |
|---------|-------|
| Açılış Maliyeti | 3,000 altın |
| Yükseltme Çarpanı | 1.5x |
| Max Seviye | 20 |
| Üretim | Demir, Bakır, Altın Cevheri |

**Üretim Çıktıları:**
| Ürün | Süre | Şüphe |
|------|------|-------|
| Demir Cevheri | 30 dk | +2 |
| Bakır Cevheri | 45 dk | +3 |
| Altın Cevheri | 90 dk | +5 |

### Marangoz (Woodworking)

| Özellik | Değer |
|---------|-------|
| Açılış Maliyeti | 3,000 altın |
| Yükseltme Çarpanı | 1.5x |
| Max Seviye | 20 |
| Üretim | Çam, Meşe, Sedir Kerestesi |

**Üretim Çıktıları:**
| Ürün | Süre | Şüphe |
|------|------|-------|
| Çam Kerestesi | 25 dk | +1 |
| Meşe Kerestesi | 40 dk | +2 |
| Sedir Kerestesi | 60 dk | +3 |

### Çiftlik (Farming)

| Özellik | Değer |
|---------|-------|
| Açılış Maliyeti | 3,500 altın |
| Yükseltme Çarpanı | 1.5x |
| Max Seviye | 20 |
| Üretim | Tahıl, Meyve, Sebze |

**Üretim Çıktıları:**
| Ürün | Süre | Şüphe |
|------|------|-------|
| Buğday | 20 dk | +1 |
| Elma | 35 dk | +1 |
| Şifalı Ot | 50 dk | +2 |

### Bitki Bahçesi (Herb Garden)

| Özellik | Değer |
|---------|-------|
| Açılış Maliyeti | 4,000 altın |
| Yükseltme Çarpanı | 1.6x |
| Max Seviye | 20 |
| Üretim | Şifalı Bitkiler, Zehirli Otlar, Nadir Çiçekler |

**Üretim Çıktıları:**
| Ürün | Süre | Şüphe |
|------|------|-------|
| Kekik Yaprağı | 30 dk | +1 |
| Lavanta | 45 dk | +2 |
| Gölge Orkidesi | 90 dk | +4 |

## 10.3 İşleme Tesisleri (6 Adet)

### Demirci (Blacksmith)

| Özellik | Değer |
|---------|-------|
| Açılış Maliyeti | 8,000 altın |
| Yükseltme Çarpanı | 1.7x |
| Max Seviye | 20 |
| Üretim | Kılıç, Balta, Mızrak, Hançer |
| Gerekli Malzeme | Demir Cevheri, Kereste |

**Örnek Reçeteler:**
| Ürün | Malzeme | Süre | Şüphe |
|------|---------|------|-------|
| Demir Kılıç | 5 Demir + 2 Meşe | 60 dk | +5 |
| Çelik Kılıç | 10 Demir + 3 Meşe | 120 dk | +8 |
| Efsane Kılıç | 25 Demir + 5 Sedir + 1 Altın | 240 dk | +15 |

### Zırhçı (Armorer)

| Özellik | Değer |
|---------|-------|
| Açılış Maliyeti | 8,000 altın |
| Yükseltme Çarpanı | 1.7x |
| Max Seviye | 20 |
| Üretim | Zırh, Kask, Eldiven, Kalkan |
| Gerekli Malzeme | Demir Cevheri, Deri, Kumaş |

### Simya Laboratuvarı (Alchemy Lab)

| Özellik | Değer |
|---------|-------|
| Açılış Maliyeti | 10,000 altın |
| Yükseltme Çarpanı | 1.7x |
| Max Seviye | 20 |
| Üretim | Enerji İksirleri, Can İksirleri, Antidotlar |
| Gerekli Malzeme | Bitkiler, Su, Cam Şişe |

**Örnek Reçeteler:**
| Ürün | Malzeme | Süre | Şüphe |
|------|---------|------|-------|
| Minör Enerji İksiri | 3 Kekik + 1 Şişe | 30 dk | +3 |
| Büyük Enerji İksiri | 5 Lavanta + 2 Şişe | 60 dk | +6 |
| Hafif Antidot | 4 Kekik + 1 Zehir + 1 Şişe | 45 dk | +4 |

### Rün Ustası (Runesmith)

| Özellik | Değer |
|---------|-------|
| Açılış Maliyeti | 15,000 altın |
| Yükseltme Çarpanı | 1.8x |
| Max Seviye | 20 |
| Üretim | Enhancement Rünleri |
| Gerekli Malzeme | Taş, Mana Kristali, Mürekkep |

**Rün Tipleri:**
| Rün | Bonus | Üretim Şüphesi |
|-----|-------|----------------|
| Temel Rün | +%5 başarı | +5 |
| Gelişmiş Rün | +%10 başarı | +8 |
| Üstün Rün | +%20 başarı | +12 |
| Efsanevi Rün | +%30 başarı | +20 |
| Koruma Rünü | Yok olma önleme | +15 |

### Parşömen Kütüphanesi (Scroll Library)

| Özellik | Değer |
|---------|-------|
| Açılış Maliyeti | 12,000 altın |
| Yükseltme Çarpanı | 1.7x |
| Max Seviye | 20 |
| Üretim | Enhancement Scroll'ları |
| Gerekli Malzeme | Papirüs, Mürekkep, Mana Tozu |

### Mücevher İşleyici (Gem Cutter)

| Özellik | Değer |
|---------|-------|
| Açılış Maliyeti | 12,000 altın |
| Yükseltme Çarpanı | 1.7x |
| Max Seviye | 20 |
| Üretim | Yakut, Zümrüt, Safir, Elmas |
| Gerekli Malzeme | Ham Taşlar, Altın |

## 10.4 İleri Tesisler (3 Adet)

### Geliştirme Ustası (Enhancement Master)

| Özellik | Değer |
|---------|-------|
| Açılış Maliyeti | 17,000 altın |
| Yükseltme Çarpanı | 1.8x |
| Max Seviye | 20 |
| Üretim | Mükemmel Enhance edilmiş Item'lar |
| Gereklilik | Demirci veya Zırhçı Seviye 10+ |

**Özel Yetenek:** +%10 enhancement başarı şansı

### Usta Simyacı (Master Alchemist)

| Özellik | Değer |
|---------|-------|
| Açılış Maliyeti | 15,000 altın |
| Yükseltme Çarpanı | 1.8x |
| Max Seviye | 20 |
| Üretim | Yüce İksirler, Legendary Antidotlar |
| Gereklilik | Simya Lab Seviye 10+ |

**Örnek Reçeteler:**
| Ürün | Malzeme | Süre | Şüphe |
|------|---------|------|-------|
| Yüce Enerji İksiri | 10 Lavanta + 5 Orkide + 3 Şişe | 180 dk | +12 |
| Arındırma İksiri | 15 Antidot Malz + 2 Orkide | 240 dk | +15 |

### Usta Zırhçı (Master Armorer)

| Özellik | Değer |
|---------|-------|
| Açılış Maliyeti | 15,000 altın |
| Yükseltme Çarpanı | 1.8x |
| Max Seviye | 20 |
| Üretim | Legendary Zırhlar, Set Parçaları |
| Gereklilik | Zırhçı Seviye 10+ |

## 10.5 Hizmet Tesisleri (2 Adet)

### Depo (Warehouse)

| Özellik | Değer |
|---------|-------|
| Açılış Maliyeti | 5,000 altın |
| Yükseltme Çarpanı | 1.5x |
| Max Seviye | 20 |
| İşlev | Ek envanter slotu |

**Slot Artışı:**
| Seviye | Ek Slot | Toplam |
|--------|---------|--------|
| 1 | +10 | 30 |
| 5 | +25 | 45 |
| 10 | +50 | 70 |
| 15 | +75 | 95 |
| 20 | +100 | 120 |

### Pazar Merkezi (Market Hub)

| Özellik | Değer |
|---------|-------|
| Açılış Maliyeti | 6,000 altın |
| Yükseltme Çarpanı | 1.6x |
| Max Seviye | 20 |
| İşlev | Market erişimi, komisyon indirimi |

**Komisyon İndirimi:**
| Seviye | İndirim | Net Komisyon |
|--------|---------|--------------|
| 1 | %0 | %5 |
| 5 | %10 | %4.5 |
| 10 | %25 | %3.75 |
| 15 | %40 | %3 |
| 20 | %50 | %2.5 |

## 10.6 Üretim Reçeteleri

### Reçete Yapısı

Her reçete şunları içerir:
- **Çıktı Item'ı:** Üretilen ürün
- **Girdi Malzemeleri:** Gerekli hammaddeler
- **Altın Maliyeti:** Üretim ücreti
- **Süre:** Üretim süresi
- **Başarı Oranı:** Üretim başarı şansı
- **Şüphe Artışı:** Suspicion etkisi
- **Min Tesis Seviyesi:** Gerekli seviye

### Silah Reçeteleri (Demirci)

| Silah | Malzeme | Altın | Süre | Min Sev |
|-------|---------|-------|------|---------|
| Demir Kılıç | 5 Demir + 2 Meşe | 200 | 60 dk | 1 |
| Çelik Kılıç | 10 Demir + 3 Meşe | 500 | 120 dk | 5 |
| Mithril Kılıç | 15 Mithril + 5 Sedir | 1,500 | 240 dk | 10 |
| Ejderha Kılıcı | 25 Ejderha Çeliği + 10 Sedir | 5,000 | 480 dk | 15 |

### İksir Reçeteleri (Simya Lab)

| İksir | Malzeme | Altın | Süre | Min Sev |
|-------|---------|-------|------|---------|
| Minör Enerji | 3 Kekik + 1 Şişe | 50 | 30 dk | 1 |
| Büyük Enerji | 5 Lavanta + 2 Şişe | 150 | 60 dk | 5 |
| Hafif Antidot | 4 Kekik + 1 Zehir Özü | 100 | 45 dk | 3 |
| Güçlü Antidot | 8 Lavanta + 3 Zehir Özü | 300 | 90 dk | 8 |

## 10.7 Suspicion (Şüphe) Mekaniği

### Şüphe Nedir?

Suspicion, tesislerin ne kadar "görünür" olduğunu temsil eder. Yüksek suspicion = polis baskını riski.

### Şüphe Aralığı

```
Min: 0 (Tamamen gizli)
Max: 100 (Çok dikkat çekici)
Başlangıç: 0
```

### Şüphe Artışı

Her üretim şüpheyi artırır:

```
new_suspicion = current_suspicion + base_recipe_suspicion × (1 + quantity × 0.1)

// 10 adet üretim, base suspicion 5:
// artış = 5 × (1 + 10 × 0.1) = 5 × 2 = 10 suspicion
```

### Şüphe Azalması

Zaman geçtikçe şüphe doğal olarak azalır:

```
decay_rate = -1 suspicion / 4 saat
daily_decay = -6 suspicion / gün
```

### Şüphe Seviyeleri

| Seviye | Aralık | Renk | Baskın Riski |
|--------|--------|------|--------------|
| Güvenli | 0-20 | 🟢 Yeşil | %0 |
| Dikkat | 21-40 | 🟡 Sarı | %5 |
| Riskli | 41-60 | 🟠 Turuncu | %15 |
| Tehlikeli | 61-80 | 🔴 Kırmızı | %30 |
| Kritik | 81-100 | ⚫ Mor | %50 |

## 10.8 Baskın ve Hapishane Riski

### Baskın Kontrol Zamanları

Baskın kontrolü üretim toplarken yapılır:

```
raid_probability = suspicion / 200

// suspicion 50'de: 50/200 = %25 baskın riski
// suspicion 100'de: 100/200 = %50 baskın riski
```

### Baskın Sonuçları

| Sonuç | Olasılık | Etki |
|-------|----------|------|
| Hafif Uyarı | %30 | Ürün kaybı yok, +10 suspicion |
| Ürün El Koyma | %40 | Üretilen ürün kaybı |
| Tutuklama | %30 | Hapishane + ürün kaybı |

### Hapishane Süresi Formülü

```
base_duration = 60 dakika (1 saat)
suspicion_bonus = suspicion × 2 dakika
final_duration = base_duration + suspicion_bonus

// suspicion 50'de: 60 + 100 = 160 dakika ≈ 2.5 saat
// suspicion 100'de: 60 + 200 = 260 dakika ≈ 4.5 saat
```

## 10.9 Rüşvet Sistemi

### Rüşvet Mekaniği

Oyuncular gem harcayarak şüpheyi azaltabilir.

| Özellik | Değer |
|---------|-------|
| Maliyet | 5 gem |
| Etki | -10 suspicion |
| Cooldown | 1 saat / tesis |
| Min Suspicion | 0 (negatif olmaz) |

### Rüşvet Stratejisi

- Suspicion 50+ olduğunda rüşvet önerilir
- Kritik seviyede (80+) acil rüşvet gerekli
- Maliyet-fayda: 5 gem = 10 suspicion = ~40 saatlik doğal decay

## 10.10 Rarity Dağılımı

### Temel Dağılım

Üretim sonucu item rarity'si hesaplanır:

```
common = 0.60 - (facility_level × 0.02) + (suspicion × 0.005)
uncommon = 0.25 + (facility_level × 0.01)
rare = 0.10 + (facility_level × 0.008)
epic = 0.04 + (facility_level × 0.005)
legendary = 0.01 + (facility_level × 0.002)
```

### Seviye 10 Tesis Örneği (Suspicion 0)

| Rarity | Hesaplama | Şans |
|--------|-----------|------|
| Common | 0.60 - 0.20 + 0 | %40 |
| Uncommon | 0.25 + 0.10 | %35 |
| Rare | 0.10 + 0.08 | %18 |
| Epic | 0.04 + 0.05 | %9 |
| Legendary | 0.01 + 0.02 | %3 |

### Suspicion Etkisi

Yüksek suspicion = daha düşük kalite (acele üretim)

```
// Suspicion 50'de ek common şansı: 50 × 0.005 = %2.5
```

---

# BÖLÜM 11: LONCA (GUILD) SİSTEMİ

## 11.1 Lonca Kurulumu

### Kurulum Gereksinimleri

| Gereksinim | Değer |
|------------|-------|
| Minimum Seviye | 20 |
| Kurulum Maliyeti | 500,000 altın |
| İsim Uzunluğu | 3-20 karakter |
| Tag Uzunluğu | 2-5 karakter |
| Başlangıç Üye Kapasitesi | 20 |

### Lonca Özellikleri

| Özellik | Varsayılan | Açıklama |
|---------|------------|----------|
| Vergi Oranı | %5 | Üye kazançlarından kesinti |
| Otomatik Kabul | Kapalı | Üyelik başvurusu onayı |
| Min Üye Seviyesi | 1 | Başvuru için minimum |
| Açıklama | - | 200 karakter max |

## 11.2 Roller ve Yetkiler

### Hiyerarşi

```
LORD (Lider)
   │
   ├── COMMANDER (Komutan) - Max 2
   │       │
   │       ├── OFFICER (Subay) - Max 5
   │       │       │
   │       │       └── MEMBER (Üye)
   │       │               │
   │       │               └── APPRENTICE (Çırak)
```

### Yetki Matrisi

| Yetki | Lord | Commander | Officer | Member | Apprentice |
|-------|------|-----------|---------|--------|------------|
| Lonca ayarları | ✅ | ❌ | ❌ | ❌ | ❌ |
| Hazine çekimi | ✅ | ✅ | ❌ | ❌ | ❌ |
| Üye çıkarma | ✅ | ✅ | ✅ | ❌ | ❌ |
| Üye kabul | ✅ | ✅ | ✅ | ❌ | ❌ |
| Terfi etme | ✅ | ✅ | ❌ | ❌ | ❌ |
| Lonca chat | ✅ | ✅ | ✅ | ✅ | ✅ |
| Görev başlatma | ✅ | ✅ | ✅ | ✅ | ❌ |
| Hazine katkısı | ✅ | ✅ | ✅ | ✅ | ✅ |

## 11.3 Lonca Seviyeleri

### Seviye Gereksinimleri

| Seviye | Gerekli XP | Max Üye | Hazine Kapasitesi |
|--------|-----------|---------|-------------------|
| 1 | 0 | 20 | 100,000 |
| 2 | 10,000 | 25 | 250,000 |
| 3 | 30,000 | 30 | 500,000 |
| 4 | 75,000 | 35 | 1,000,000 |
| 5 | 150,000 | 40 | 2,000,000 |
| 6 | 300,000 | 45 | 4,000,000 |
| 7 | 500,000 | 50 | 7,000,000 |
| 8 | 800,000 | 55 | 10,000,000 |
| 9 | 1,200,000 | 60 | 15,000,000 |
| 10 | 2,000,000 | 70 | 25,000,000 |

### Seviye Bonusları

| Seviye | XP Bonus | Altın Bonus | Drop Bonus | Komisyon İndirimi |
|--------|----------|-------------|------------|-------------------|
| 1-2 | %0 | %0 | %0 | %0 |
| 3-4 | %5 | %3 | %0 | %5 |
| 5-6 | %10 | %5 | %2 | %10 |
| 7-8 | %15 | %8 | %5 | %15 |
| 9-10 | %20 | %10 | %8 | %20 |

## 11.4 Lonca Hazinesi

### Hazine Kaynakları

| Kaynak | Açıklama |
|--------|----------|
| Üye Vergisi | Üye kazançlarının %'si |
| Doğrudan Katkı | Üyelerin altın bağışı |
| Lonca Görevleri | Görev ödülleri |
| Savaş Ganimetleri | Lonca savaşı ödülleri |

### Hazine Kullanımı

| Kullanım | Maliyet | Onay Gerekli |
|----------|---------|--------------|
| Lonca Yükseltme | Değişken | Lord |
| Üye Yardımı | Değişken | Commander+ |
| Savaş Hazırlığı | 50,000+ | Commander+ |
| Bölge Kontrolü | 100,000+ | Lord |

## 11.5 Lonca Görevleri

### Haftalık Görevler

| Görev | Hedef | Ödül (Lonca XP) |
|-------|-------|-----------------|
| Toplam Zindan | 100 zindan tamamla | 5,000 |
| Toplam PvP | 50 PvP zaferi | 3,000 |
| Toplam Üretim | 200 item üret | 4,000 |
| Toplam Altın | 1M altın kazan | 6,000 |
| Aktif Üye | 15 üye aktif | 2,000 |

### Günlük Görevler

| Görev | Hedef | Ödül (Lonca XP) |
|-------|-------|-----------------|
| İlk Zindan | Tüm üyeler 1 zindan | 500 |
| Lonca Sohbet | 20 mesaj | 200 |
| Yardımlaşma | 5 hastane yardımı | 300 |

## 11.6 Lonca Savaşları

### Savaş Türleri

| Tür | Açıklama | Süre |
|-----|----------|------|
| **Dostluk Maçı** | Sıralama etkilenmez | 1 saat |
| **Rekabet Savaşı** | Sıralama etkiler | 3 saat |
| **Bölge Savaşı** | Bölge kontrolü için | 6 saat |

### Savaş Mekaniği

1. Lider/Komutan savaş başlatır
2. Karşı lonca kabul eder
3. Savaş süresi boyunca üyeler birbirine saldırır
4. Her PvP zaferi +1 puan
5. Süre sonunda puanı yüksek olan kazanır

### Savaş Ödülleri

| Sonuç | Kazanan | Kaybeden |
|-------|---------|----------|
| Zafer | +2,000 XP, Hazine bonusu | - |
| Yenilgi | - | -500 XP |
| Beraberlik | +500 XP | +500 XP |

## 11.7 Bölge Kontrolü

### Bölge Sistemi

Oyun haritası kontrol edilebilir bölgelere ayrılmıştır:

| Bölge Tipi | Bonus | Aylık Bakım |
|------------|-------|-------------|
| Köy | +%5 farm verimi | 50,000 altın |
| Maden Bölgesi | +%10 maden verimi | 100,000 altın |
| Orman | +%10 kereste verimi | 75,000 altın |
| Ticaret Yolu | -%5 market komisyonu | 150,000 altın |
| Kale | +%10 PvP bonusu | 200,000 altın |

### Bölge Ele Geçirme

1. Lonca savaşı ile bölge talep et
2. Savunan lonca 24 saat içinde kabul etmeli
3. 6 saatlik savaş
4. Kazanan kontrol alır
5. Kaybeden 7 gün tekrar saldıramaz

---

# BÖLÜM 12: MARKET VE EKONOMİ

## 12.1 Order Book Modeli

### Emir Tipleri

| Tip | Açıklama |
|-----|----------|
| **Limit Sell** | Belirli fiyattan satış emri |
| **Market Buy** | En düşük fiyattan anında alım |
| **Limit Buy** | Belirli fiyattan alım emri (pasif) |

### Emir Durumları

| Durum | Açıklama |
|-------|----------|
| `active` | Listede bekliyor |
| `sold` | Satış tamamlandı |
| `cancelled` | İptal edildi |
| `expired` | Süresi doldu (7 gün) |
| `partial` | Kısmen satıldı |

## 12.2 Fiyat Mekanizması

### Arz-Talep Formülü

```
P_t = P_{t-1} × e^(k × ln(Q_d / Q_s))

P_t = Yeni fiyat
P_{t-1} = Önceki fiyat
k = Volatilite katsayısı
Q_d = Talep miktarı (son 24 saat alımlar)
Q_s = Arz miktarı (aktif satışlar)
```

### Volatilite Katsayıları

| Item Kategorisi | k Değeri | Açıklama |
|-----------------|----------|----------|
| Normal Item | 0.08 | Düşük volatilite |
| İksirler | 0.12 | Orta volatilite |
| Antidotlar | 0.15 | Yüksek volatilite |
| Rün/Scroll | 0.10 | Orta volatilite |
| Legendary | 0.05 | Düşük (nadir işlem) |

### VWAP (Volume Weighted Average Price)

```
VWAP = Σ(Fiyat × Miktar) / Σ(Miktar)
```

24 saatlik ortalama fiyat hesaplaması.

## 12.3 Komisyon Sistemi

### Temel Komisyon

| İşlem | Oran | Kimden Alınır |
|-------|------|---------------|
| Satış | %5 | Satıcı |
| Alım | %0 | - |

### Komisyon İndirimleri

| Kaynak | İndirim |
|--------|---------|
| Pazar Merkezi Seviye 5 | -%10 (net %4.5) |
| Pazar Merkezi Seviye 10 | -%25 (net %3.75) |
| Pazar Merkezi Seviye 15 | -%40 (net %3) |
| Pazar Merkezi Seviye 20 | -%50 (net %2.5) |
| Lonca Seviye 5+ | Ek -%5 |
| Lonca Seviye 10 | Ek -%10 |

### Örnek Hesaplama

```
Satış fiyatı: 10,000 altın
Temel komisyon: 10,000 × 0.05 = 500 altın
Pazar Merkezi Sev 10: 500 × 0.75 = 375 altın
Lonca Sev 5: 375 × 0.95 = 356 altın

Satıcı alır: 10,000 - 356 = 9,644 altın
```

## 12.4 Anti-Manipülasyon Önlemleri

### Rate Limiting

| Önlem | Limit |
|-------|-------|
| Emir sayısı | 30/dakika |
| Alım sayısı | 20/dakika |
| İptal sayısı | 10/dakika |

### Fiyat Bandı

```
Min fiyat = VWAP × 0.90 (-%10)
Max fiyat = VWAP × 1.10 (+%10)
```

Bu bandın dışındaki emirler reddedilir.

### Circuit Breaker

| Değişim | Aksiyon |
|---------|---------|
| %30 (1 saat) | 30 dakika işlem durdurma |
| %50 (1 saat) | 2 saat işlem durdurma |
| %70 (1 saat) | Gün sonu kadar durdurma |

### Wash Trading Tespiti

```
Algılama kriterleri:
- Aynı IP'den alım-satım
- Aynı device_id ile karşılıklı işlem
- 5 dakika içinde alım-satım döngüsü
- Aynı fiyat-miktar kalıpları

Ceza:
- İlk tespit: Uyarı
- İkinci tespit: 24 saat market yasağı
- Üçüncü tespit: Hesap askıya alma
```

## 12.5 Bölgesel Pazarlar

### Şehir Pazarları

Her şehrin ayrı pazarı vardır:

| Şehir | Özellik | Avantaj |
|-------|---------|---------|
| Başkent | Ana pazar | En yüksek likidite |
| Maden Şehri | Hammadde odaklı | -%10 maden komisyonu |
| Orman Kasabası | Kereste odaklı | -%10 kereste komisyonu |
| Simya Vadisi | İksir odaklı | -%10 iksir komisyonu |
| Savaş Kalesi | Silah/Zırh odaklı | -%10 ekipman komisyonu |

### Şehirler Arası Transfer

| Özellik | Değer |
|---------|-------|
| Transfer ücreti | %2 item değeri |
| Transfer süresi | 1-4 saat (mesafeye göre) |
| Max transfer | 50 item/gün |

## 12.6 Arbitraj Fırsatları

### Arbitraj Nedir?

Farklı pazarlardaki fiyat farkından kar elde etme.

### Örnek Senaryo

```
Demir Cevheri:
- Maden Şehri: 100 altın
- Başkent: 120 altın

Kar hesabı:
- Alış: 100 altın
- Transfer: 100 × 0.02 = 2 altın
- Satış komisyon: 120 × 0.05 = 6 altın
- Net kar: 120 - 100 - 2 - 6 = 12 altın (%12)
```

### Arbitraj Limitleri

- Günlük 50 item transfer limiti
- Fiyat farkı haberi 15 dakika gecikmeli
- Büyük transferler dikkat çeker (suspicion)

---

# BÖLÜM 13: SEZON SİSTEMİ

## 13.1 Sezon Yapısı

### Temel Bilgiler

| Özellik | Değer |
|---------|-------|
| Sezon Süresi | 60-90 gün |
| Ara Dönem | 3 gün (maintenance) |
| Sezon Sayısı/Yıl | 4 sezon |

### Sezon Takvimi (Örnek)

| Sezon | Başlangıç | Bitiş | Tema |
|-------|-----------|-------|------|
| Sezon 1 | 1 Ocak | 1 Mart | Kış Savaşları |
| Sezon 2 | 4 Mart | 1 Haziran | Bahar Şenliği |
| Sezon 3 | 4 Haziran | 1 Eylül | Yaz Festivali |
| Sezon 4 | 4 Eylül | 1 Aralık | Hasat Dönemi |

## 13.2 4 Faz Döngüsü

### Faz 1: Kuruluş (Hafta 1-3)

**Odak:** Hızlı leveling, lonca kurma, temel ekonomi

| Özellik | Bonus |
|---------|-------|
| XP Bonusu | +%50 |
| Görev Ödülleri | +%25 |
| Lonca Kurulum | -%25 maliyet |
| PvP | Devre dışı |

### Faz 2: Rekabet (Hafta 4-8)

**Odak:** PvP zirve, lonca savaşları, market rekabeti

| Özellik | Bonus |
|---------|-------|
| PvP Ödülleri | +%25 |
| Lonca Savaşı | Aktif |
| Bölge Kontrolü | Başlar |
| Enhancement | +5/+6 yaygın |

### Faz 3: Zirve (Hafta 9-11)

**Odak:** End-game content, legendary itemlar, +8/+9 enhancement

| Özellik | Bonus |
|---------|-------|
| Legendary Drop | +%50 |
| Enhancement Başarı | +%10 |
| Boss Raid | Açılır |
| İksir Talebi | Zirve |

### Faz 4: Final (Son 3 Gün)

**Odak:** Son sıralama, "Kıyamet Günü" eventi

| Özellik | Bonus |
|---------|-------|
| Tüm Aktiviteler | +%100 ödül |
| PvP | Süresiz (cooldown yok) |
| Sıralama | Dondurulur (son gün) |
| Özel Boss | "Kadim Mühür" |

## 13.3 Sezon Sonu Reset Kuralları

### Sıfırlanan (Reset)

| Öğe | Açıklama |
|-----|----------|
| ❌ Altın | Tüm altın sıfırlanır |
| ❌ Envanter | Tüm itemlar silinir |
| ❌ Ekipman | Takılı itemlar dahil |
| ❌ Seviye | 1'e döner |
| ❌ XP | Sıfırlanır |
| ❌ Tesisler | Tüm binalar sıfırlanır |
| ❌ Tolerance | 0'a döner |
| ❌ PvP Stats | Kayıp/zafer sıfırlanır |
| ❌ Rating | Başlangıç değerine |
| ❌ Reputation | 0'a döner |

### Kısmen Sıfırlanan

| Öğe | Açıklama |
|-----|----------|
| ⚙️ Lonca XP | %50'si kalır |
| ⚙️ Lonca Hazinesi | Temizlenir ama bina kalır |
| ⚙️ Lonca Seviyesi | -2 seviye (min 1) |

### Kalıcı (Permanent)

| Öğe | Açıklama |
|-----|----------|
| ✅ Gem | Tüm gemler kalır |
| ✅ Kozmetikler | Skin, efekt, çerçeve |
| ✅ Unvanlar | Kazanılan başlıklar |
| ✅ Achievement | Başarımlar |
| ✅ Account Level | Toplam deneyim |
| ✅ Sezon Puanı | Geçmiş sezon istatistikleri |
| ✅ Battle Pass | Satın alınan ödüller |

## 13.4 Kalıcı Ödüller

### Sezon Sonu Ödülleri

Sıralamaya göre kalıcı ödüller:

| Sıralama | Ödül |
|----------|------|
| Top 1 | "Sezon Şampiyonu" unvanı + Özel çerçeve + 1,000 gem |
| Top 10 | "Efsane" unvanı + Özel çerçeve + 500 gem |
| Top 100 | "Usta" unvanı + 250 gem |
| Top 1,000 | "Deneyimli" unvanı + 100 gem |
| Top 10,000 | 50 gem |

### Leaderboard Kategorileri

| Kategori | Ölçüm |
|----------|-------|
| Genel Seviye | Max ulaşılan seviye |
| Toplam Güç | Peak combat power |
| PvP Rating | Max rating |
| Zenginlik | Peak altın miktarı |
| Lonca Gücü | Lonca toplam puanı |
| Koleksiyoncu | Unique item sayısı |

## 13.5 Battle Pass

### Temel Bilgiler

| Özellik | Değer |
|---------|-------|
| Fiyat | 800 gem |
| Tier Sayısı | 50 |
| Tier Başına XP | 1,000 |
| Toplam XP Gereksinimi | 50,000 |

### Ücretsiz Track Ödülleri

| Tier | Ödül |
|------|------|
| 1 | 10 gem |
| 5 | 50 gem + Common Chest |
| 10 | 100 gem |
| 15 | Uncommon Chest |
| 20 | 150 gem |
| 25 | Rare Chest |
| 30 | 200 gem |
| 40 | Epic Chest |
| 50 | 300 gem + "Sezon Veteranı" Unvanı |

**Toplam Ücretsiz:** ~810 gem + 5 Chest + 1 Unvan

### Premium Track Ödülleri (Ek)

| Tier | Ödül |
|------|------|
| 1 | 50 gem + XP Boost (%10, 7 gün) |
| 5 | 100 gem + Premium Chest |
| 10 | Özel Silah Skin |
| 15 | 150 gem + XP Boost (%15, 7 gün) |
| 20 | 200 gem + Rare Chest x2 |
| 25 | Özel Zırh Skin |
| 30 | 250 gem + XP Boost (%20, 7 gün) |
| 35 | Protection Rune x1 |
| 40 | 300 gem + Epic Chest x2 |
| 45 | Özel Avatar Çerçevesi |
| 50 | 500 gem + Legendary Chest + Özel Banner |

**Toplam Premium:** ~1,550 gem + 8 Chest + 3 Skin + 1 Rune + 3 XP Boost + 2 Kozmetik

### ROI Hesabı

```
Harcanan: 800 gem
Kazanılan (Premium): 1,550 gem + ~2,000 gem değerinde item
Toplam Değer: ~3,550 gem
ROI: %343
```

## 13.6 Leaderboard Kategorileri

### Anlık Sıralamalar

| Sıralama | Güncelleme |
|----------|------------|
| Seviye | Gerçek zamanlı |
| Güç | Gerçek zamanlı |
| PvP Rating | Gerçek zamanlı |
| Altın | Saatlik |
| Lonca Sıralaması | Günlük |

### Haftalık Sıralamalar

| Sıralama | Ölçüm |
|----------|-------|
| En Aktif | Toplam aktivite puanı |
| En Çok Zindan | Zindan tamamlama |
| En Çok PvP | PvP zafer sayısı |
| En Çok Üretim | Üretilen item sayısı |

### Sezonluk Sıralamalar

| Sıralama | Ödül Kategorisi |
|----------|-----------------|
| Genel Şampiyon | Tüm kategorilerde ağırlıklı puan |
| PvP Şampiyonu | En yüksek peak rating |
| Ekonomi Kralı | En yüksek peak servet |
| Üretim Ustası | En çok üretim |
| Sosyal Lider | En aktif lonca liderliği |

---

# BÖLÜM 14: MONETİZASYON

## 14.1 Pay-to-Win Olmayan Model

### SATILAMAZ (Oyun Dengesi)

| Kategori | Örnekler | Neden |
|----------|----------|-------|
| ❌ Silahlar | Kılıç, Zırh, Kalkan | Oyun dengesi |
| ❌ Altın | Direkt satış yok | Ekonomi dengesi |
| ❌ İksirler | Enerji, Can iksiri | Üretim sistemi |
| ❌ Malzemeler | Cevher, Kereste | Üretim sistemi |
| ❌ XP Boost | Direkt XP satışı yok | Hız dengesi |
| ❌ Seviye Atlama | Level jump yok | Hız dengesi |
| ❌ Rünler | Enhancement rünleri | Üretim sistemi |

### SATILABİLİR (Kolaylık/Kozmetik)

| Kategori | Örnekler | Açıklama |
|----------|----------|----------|
| ✅ Gem | Ana premium para birimi | Dönüşüm aracı |
| ✅ Kozmetik | Skin, çerçeve, efekt | Görsel değişiklik |
| ✅ Slot Genişletme | Envanter, kuyruk | Kolaylık |
| ✅ Battle Pass | Sezonluk içerik | Değer paketi |
| ✅ Hastane Çıkışı | Gem ile hızlandırma | Zaman tasarrufu |
| ✅ Kefalet | Hapisten çıkış | Zaman tasarrufu |

## 14.2 Gem Paketleri

### Satın Alma Seçenekleri

| Paket | Gem | Bonus | Fiyat (TL) | Fiyat (USD) |
|-------|-----|-------|------------|-------------|
| Başlangıç | 100 | +50 (ilk kez) | ₺29.99 | $0.99 |
| Küçük | 500 | +100 (%20) | ₺149.99 | $4.99 |
| Orta | 1,200 | +480 (%40) | ₺299.99 | $9.99 |
| Büyük | 2,500 | +1,500 (%60) | ₺599.99 | $19.99 |
| Mega | 8,000 | +6,400 (%80) | ₺1,499.99 | $49.99 |

### İlk Satın Alma Bonusu

İlk gem satın alımında 2x bonus:

| Paket | Normal | İlk Alım |
|-------|--------|----------|
| Başlangıç | 100 | 200 |
| Küçük | 500 | 1,000 |
| Orta | 1,200 | 2,400 |

## 14.3 Ücretsiz Gem Kazanımı

### Günlük Kaynaklar

| Kaynak | Gem | Koşul |
|--------|-----|-------|
| Günlük Giriş | 10 | Her gün giriş |
| Günlük Görevler (3) | 10+10+10 | Görev tamamla |
| Reklam İzleme (3) | 5+5+5 | Gönüllü reklam |
| **Günlük Toplam** | **55** | |

### Haftalık Kaynaklar

| Kaynak | Gem | Koşul |
|--------|-----|-------|
| Haftalık Görevler | 100 | Haftalık hedefler |
| Lonca Görevleri | 50 | Lonca katılımı |
| PvP Sıralaması | 0-100 | Top 100 |
| **Haftalık Toplam** | **150-250** | |

### Aylık Özet

| Kaynak | Aylık Toplam |
|--------|--------------|
| Günlük (30 gün) | ~1,650 gem |
| Haftalık (4 hafta) | ~600-1,000 gem |
| Events | ~200-500 gem |
| Achievement | ~100-300 gem |
| **Aylık Toplam** | **2,500-3,500 gem** |

## 14.4 Premium Özellikler

### Gem Kullanım Alanları

| Kullanım | Maliyet | Açıklama |
|----------|---------|----------|
| Hastane Çıkışı | 5 + dakika/3 | Erken taburcu |
| Kefalet | Kalan dakika | Hapisten çıkış |
| Rüşvet | 5 | -10 suspicion |
| Enerji Doldur | 50 | Tam enerji (günde 3) |
| Slot Genişletme | 100 | +5 envanter slotu |
| Battle Pass | 800 | Sezonluk |
| Kozmetik | 50-500 | Skin, efekt |

### Premium Olmayan Alternatifleri

Her premium özelliğin ücretsiz alternatifi var:

| Premium | Ücretsiz Alternatif |
|---------|---------------------|
| Hastane çıkışı (gem) | Bekle veya lonca yardımı |
| Enerji doldur (gem) | İksir üret veya bekle |
| Slot genişletme | Depo tesisi yükselt |
| Kozmetik | Event ödülleri, achievement |

## 14.5 Kozmetik Sistemi

### Kozmetik Kategorileri

| Kategori | Örnekler | Fiyat Aralığı |
|----------|----------|---------------|
| Silah Skin | Ateş Kılıcı, Buz Baltası | 100-300 gem |
| Zırh Skin | Altın Zırh, Gölge Pelerin | 150-400 gem |
| Avatar Çerçeve | Ejderha, Taç, Kanatlar | 50-200 gem |
| Chat Efekti | Renkli mesaj, emoji | 30-100 gem |
| Tesis Skin | Karanlık Maden, Işık Bahçesi | 200-500 gem |
| Lonca Banner | Özel amblemler | 300-600 gem |

### Kozmetik Elde Etme Yolları

| Yol | Örnek |
|-----|-------|
| Gem ile satın alma | Mağazadan |
| Battle Pass | Premium tier ödülleri |
| Achievement | Özel başarımlar |
| Event | Sezonluk etkinlikler |
| Leaderboard | Sıralama ödülleri |

---

# BÖLÜM 15: ENVANTER VE EKİPMAN

## 15.1 Slot Sistemi

### Envanter Grid

| Özellik | Değer |
|---------|-------|
| Başlangıç Slotu | 20 |
| Max Slot (Depo ile) | 120 |
| Grid Boyutu | 4x5 (başlangıç) |
| Slot Genişletme | +5 slot / 100 gem |

### Slot Pozisyonları

| Pozisyon | Anlam |
|----------|-------|
| 0-19 | Normal envanter grid |
| -1 | Atanmamış (yeni item) |
| -998 | Temp slot (swap işlemi) |
| NULL | Takılı ekipman |

### Ekipman Slotları

| Slot | Anahtar | İzin Verilen Tip |
|------|---------|------------------|
| Silah | `WEAPON` | Sword, Axe, Bow, Staff... |
| Kafa | `HEAD` | Kask, Şapka |
| Gövde | `CHEST` | Zırh, Cübbe |
| Eller | `HANDS` | Eldiven |
| Bacaklar | `LEGS` | Pantolon, Etek |
| Ayaklar | `FEET` | Bot, Çizme |
| Aksesuar 1 | `ACCESSORY_1` | Yüzük, Kolye |
| Aksesuar 2 | `ACCESSORY_2` | Yüzük, Bileklik |

## 15.2 Item Tipleri

### Ana Kategoriler

| Tip | Açıklama | Stack |
|-----|----------|-------|
| `WEAPON` | Silahlar | ❌ |
| `ARMOR` | Zırhlar | ❌ |
| `ACCESSORY` | Aksesuarlar | ❌ |
| `CONSUMABLE` | Tüketilebilir | ✅ (50) |
| `MATERIAL` | Hammaddeler | ✅ (50) |
| `POTION` | İksirler | ✅ (50) |
| `RECIPE` | Reçeteler | ✅ (50) |
| `RUNE` | Rünler | ✅ (50) |
| `SCROLL` | Scroll'lar | ✅ (50) |
| `QUEST_ITEM` | Görev itemları | ✅ (1) |
| `COSMETIC` | Kozmetikler | ❌ |

### Silah Tipleri

| Tip | Ana Stat | Hız |
|-----|----------|-----|
| `SWORD` | Attack | Orta |
| `AXE` | Attack | Yavaş |
| `DAGGER` | Attack + Crit | Hızlı |
| `SPEAR` | Attack | Orta |
| `BOW` | Attack (Range) | Orta |
| `STAFF` | Power | Yavaş |
| `SHIELD` | Defense | - |

### Zırh Tipleri

| Tip | Defense | Health | Ağırlık |
|-----|---------|--------|---------|
| `PLATE` | Yüksek | Orta | Ağır |
| `CHAIN` | Orta | Orta | Orta |
| `LEATHER` | Düşük | Yüksek | Hafif |
| `CLOTH` | Çok Düşük | Çok Yüksek | Çok Hafif |

## 15.3 Rarity Seviyeleri

### Rarity Tablosu

| Rarity | Renk | Stat Çarpan | Drop Oranı |
|--------|------|-------------|------------|
| `COMMON` | ⚪ Gri | 1.0x | %60 |
| `UNCOMMON` | 🟢 Yeşil | 1.2x | %25 |
| `RARE` | 🔵 Mavi | 1.5x | %10 |
| `EPIC` | 🟣 Mor | 2.0x | %4 |
| `LEGENDARY` | 🟠 Turuncu | 3.0x | %1 |
| `MYTHIC` | 🔴 Kırmızı | 5.0x | %0.1 |

### Rarity Etkileri

| Rarity | Max Enhancement | Slot Bonus |
|--------|-----------------|------------|
| Common | +5 | 0 |
| Uncommon | +7 | 0 |
| Rare | +8 | +1 |
| Epic | +9 | +1 |
| Legendary | +10 | +2 |
| Mythic | +10 | +3 |

## 15.4 Enhancement (Geliştirme) Sistemi

### Enhancement Seviyeleri

| Seviye | Başarı Oranı | Altın Maliyeti |
|--------|--------------|----------------|
| +0 → +1 | %100 | 100 |
| +1 → +2 | %90 | 200 |
| +2 → +3 | %80 | 400 |
| +3 → +4 | %65 | 800 |
| +4 → +5 | %50 | 1,600 |
| +5 → +6 | %35 | 3,200 |
| +6 → +7 | %20 | 6,400 |
| +7 → +8 | %10 | 12,800 |
| +8 → +9 | %5 | 25,600 |
| +9 → +10 | %2 | 51,200 |

### Başarısızlık Sonuçları

| Mevcut Seviye | Sonuç |
|---------------|-------|
| +0 ile +5 | -1 seviye düşer |
| +6 ile +10 | Item yok olabilir |

### Yok Olma Şansı

```
destruction_chance = (1 - success_rate) × 0.3

// +6 → +7 denemesi (%20 başarı):
// destruction = 0.80 × 0.3 = %24 yok olma
```

### Stat Artışı

```
bonus_percent = enhancement_level × 5%
final_stat = base_stat × (1 + bonus_percent)

// +10 item, 100 base attack:
// final = 100 × 1.50 = 150 attack
```

## 15.5 Rün Sistemi

### Rün Tipleri

| Rün | Etki | Kullanım |
|-----|------|----------|
| Temel Rün | +%5 başarı | Enhancement |
| Gelişmiş Rün | +%10 başarı | Enhancement |
| Üstün Rün | +%20 başarı | Enhancement |
| Efsanevi Rün | +%30 başarı | Enhancement |
| Koruma Rünü | Yok olmayı engeller | Enhancement 6+ |

### Rün Kullanımı

```
final_success = base_success + rune_bonus

// +7 denemesi (%20) + Efsanevi Rün (+%30):
// final = %20 + %30 = %50 başarı
```

### Rün Tüketimi

- Başarılı olsun veya olmasın rün tüketilir
- Koruma rünü item kurtarırsa tüketilir
- Koruma rünü item kurtarmazsa (başarılı olursa) tüketilmez

## 15.6 Scroll Sistemi

### Scroll Gereklilikleri

| Scroll Tier | Kullanılabilir Rarity |
|-------------|----------------------|
| Low Scroll | Common, Uncommon |
| Middle Scroll | Rare, Epic |
| High Scroll | Legendary, Mythic |

### Scroll Tipleri

| Scroll | Ekstra Etki |
|--------|-------------|
| Normal Scroll | Sadece gereklilik |
| Lucky Scroll | +%3 ek başarı |
| Blessed Scroll | +%5 ek başarı |
| Divine Scroll | +%10 ek başarı, yok olma yok |

---

# BÖLÜM 16: GÖREV SİSTEMİ

## 16.1 Görev Tipleri

### Ana Kategoriler

| Tip | Açıklama | Reset |
|-----|----------|-------|
| `STORY` | Ana hikaye görevleri | Bir kez |
| `SIDE` | Yan görevler | Bir kez |
| `DAILY` | Günlük görevler | Her gün |
| `WEEKLY` | Haftalık görevler | Her hafta |
| `SEASONAL` | Sezonluk görevler | Her sezon |
| `GUILD` | Lonca görevleri | Haftalık |
| `REPEATABLE` | Tekrarlanabilir | Cooldown |

### Görev Durumları

| Durum | Açıklama |
|-------|----------|
| `AVAILABLE` | Alınabilir |
| `ACTIVE` | Devam ediyor |
| `COMPLETED` | Tamamlandı, ödül alınabilir |
| `CLAIMED` | Ödül alındı |
| `FAILED` | Başarısız (zaman aşımı) |
| `EXPIRED` | Süresi doldu |
| `LOCKED` | Ön koşul gerekli |

## 16.2 Günlük Görevler

### Görev Listesi

| Görev | Hedef | Enerji | Ödül |
|-------|-------|--------|------|
| İlk Adım | 1 görev tamamla | 5 | 10 gem |
| Aktif Savaşçı | 3 PvP yap | 30 | 10 gem + 500 XP |
| Zindan Avcısı | 2 zindan tamamla | 40-60 | 10 gem + 1,000 XP |
| Üretici | 5 item üret | 0 | 5 gem + 200 altın |
| Sosyal | 5 mesaj gönder | 0 | 5 gem |
| Tüccar | 3 market işlemi | 0 | 5 gem + 300 altın |

### Günlük Bonus

Tüm günlük görevleri tamamla → **50 gem + 2,000 XP + 1,000 altın**

## 16.3 Haftalık Görevler

### Görev Listesi

| Görev | Hedef | Ödül |
|-------|-------|------|
| Haftalık Savaşçı | 20 PvP zafer | 50 gem + 5,000 XP |
| Haftalık Zindan | 10 zindan tamamla | 40 gem + Rare Chest |
| Haftalık Üretim | 50 item üret | 30 gem + 5,000 altın |
| Haftalık Ticaret | 20 market işlemi | 30 gem + 3,000 altın |
| Haftalık Lonca | 5 lonca aktivitesi | 30 gem + Lonca XP |

### Haftalık Bonus

Tüm haftalık görevleri tamamla → **100 gem + Epic Chest**

## 16.4 Hikaye Görevleri

### Bölüm Yapısı

| Bölüm | İsim | Görev Sayısı | Min Seviye |
|-------|------|--------------|------------|
| 1 | Uyanış | 10 | 1 |
| 2 | İlk Adımlar | 15 | 5 |
| 3 | Gölgeler | 20 | 10 |
| 4 | Yeraltı | 25 | 20 |
| 5 | Savaş | 20 | 30 |
| 6 | Kadim Mühür | 30 | 40 |
| 7 | Final | 10 | 50 |

### Hikaye Ödülleri

Bölüm tamamlama ödülleri:

| Bölüm | Ödül |
|-------|------|
| 1 | 50 gem + Başlangıç Seti |
| 2 | 75 gem + Uncommon Silah |
| 3 | 100 gem + Rare Zırh |
| 4 | 150 gem + Epic Aksesuar |
| 5 | 200 gem + Legendary Rün |
| 6 | 300 gem + Legendary Chest |
| 7 | 500 gem + Mythic Chest + "Kahraman" Unvanı |

## 16.5 Lonca Görevleri

### Haftalık Lonca Görevleri

| Görev | Hedef | Lonca XP |
|-------|-------|----------|
| Toplam Zindan | 100 zindan (tüm üyeler) | 5,000 |
| Toplam PvP | 50 PvP zafer | 3,000 |
| Toplam Üretim | 200 item | 4,000 |
| Toplam Altın | 1M altın kazanç | 6,000 |
| Aktif Üye | 15 üye günlük aktif | 2,000 |

### Katkı Takibi

Her üyenin katkısı ayrı ayrı kaydedilir:
- Haftalık katkı sıralaması
- Top 3 katkıcıya bonus ödül
- Düşük katkılı üyelere uyarı

---

# BÖLÜM 17: SOHBET VE SOSYAL

## 17.1 Chat Kanalları

### Kanal Tipleri

| Kanal | Erişim | Rate Limit |
|-------|--------|------------|
| `global` | Herkes | 2 saniye |
| `guild` | Lonca üyeleri | 1 saniye |
| `private` | İki oyuncu arası | 0.5 saniye |
| `trade` | Herkes (ticaret) | 5 saniye |
| `help` | Herkes (yardım) | 5 saniye |
| `system` | Sadece okuma | - |

### Mesaj Limitleri

| Limit | Değer |
|-------|-------|
| Max karakter | 200 |
| Spam koruması | 3 aynı mesaj yasak |
| Flood koruması | 10 mesaj/dakika |
| Link paylaşımı | Sadece trade kanalı |

## 17.2 Moderasyon Sistemi

### Otomatik Filtreler

| Filtre | Aksiyon |
|--------|---------|
| Küfür listesi | Mesaj engellenir |
| Spam algılama | Geçici susturma |
| Link spam | 1 saat susturma |
| Reklam | 24 saat susturma |

### Ceza Sistemi

| İhlal | 1. Kez | 2. Kez | 3. Kez |
|-------|--------|--------|--------|
| Küfür | 1 saat mute | 24 saat mute | 7 gün ban |
| Spam | 30 dakika mute | 12 saat mute | 3 gün ban |
| Dolandırıcılık | 7 gün ban | Kalıcı ban | - |
| Hack/Exploit | Kalıcı ban | - | - |

### Şikayet Sistemi

1. Oyuncu mesajı şikayet eder
2. Sistem şikayeti kaydeder
3. 5+ şikayet → Otomatik inceleme
4. Moderatör karar verir
5. Ceza uygulanır veya reddedilir

## 17.3 Arkadaşlık Sistemi

### Arkadaş Limitleri

| Özellik | Değer |
|---------|-------|
| Max arkadaş | 100 |
| Bekleyen istek | 50 |
| Günlük istek | 20 |

### Arkadaş Özellikleri

| Özellik | Açıklama |
|---------|----------|
| Konum görme | Hangi ekranda/zindanda |
| Davet gönderme | Zindan, PvP, lonca |
| Özel mesaj | Private chat |
| Hediye gönderme | Günde 3 item |

### Engelleme

Engellenen oyuncular:
- Mesaj gönderemez
- Arkadaş isteği gönderemez
- PvP'de önceliklenmez
- Listede görünmez

## 17.4 Bildirimler

### Bildirim Tipleri

| Tip | Açıklama | Varsayılan |
|-----|----------|------------|
| Enerji dolu | Max enerjiye ulaşıldı | ✅ Açık |
| Üretim bitti | Kuyruk tamamlandı | ✅ Açık |
| PvP saldırısı | Birine saldırıldı | ✅ Açık |
| Hastane çıkışı | Taburcu olundu | ✅ Açık |
| Lonca mesajı | Guild chat | ✅ Açık |
| Özel mesaj | Private chat | ✅ Açık |
| Market satışı | Item satıldı | ✅ Açık |
| Sezon eventi | Özel etkinlik | ✅ Açık |

### Bildirim Ayarları

Oyuncu her bildirimi ayrı ayrı açıp kapatabilir.

---

# BÖLÜM 18: HAPİSHANE SİSTEMİ

## 18.1 Hapse Girme Sebepleri

| Sebep | Açıklama | Süre |
|-------|----------|------|
| `RAID` | Tesis baskınında yakalanma | 1-5 saat |
| `HIGH_SUSPICION` | 100 suspicion'da otomatik | 2-6 saat |
| `PVP_CRIME` | Düşük reputation PvP | 1-3 saat |
| `MARKET_FRAUD` | Market manipülasyonu | 4-12 saat |
| `EXPLOIT` | Oyun exploit kullanımı | 24-72 saat |

## 18.2 Ceza Süreleri

### Baskın Ceza Formülü

```
base_duration = 60 dakika
suspicion_factor = current_suspicion × 2 dakika
repeat_factor = previous_arrests × 30 dakika

total_duration = base_duration + suspicion_factor + repeat_factor
max_duration = 300 dakika (5 saat)
```

### Örnek Hesaplamalar

| Suspicion | İlk Yakalanma | 2. Yakalanma | 3. Yakalanma |
|-----------|---------------|--------------|--------------|
| 30 | 120 dk (2 saat) | 150 dk | 180 dk |
| 50 | 160 dk | 190 dk | 220 dk |
| 80 | 220 dk | 250 dk | 280 dk |
| 100 | 260 dk | 290 dk | 300 dk (max) |

## 18.3 Kefalet Sistemi

### Kefalet Maliyeti

```
bail_cost = remaining_minutes (in gems)

// 2 saat (120 dakika) kaldıysa: 120 gem
```

### Kefalet Limitleri

| Özellik | Değer |
|---------|-------|
| Günlük kefalet limiti | 3 |
| Min kefalet | 10 gem |
| Max kefalet | 300 gem |

### Alternatif Çıkış

| Yöntem | Maliyet | Etki |
|--------|---------|------|
| Bekleme | Ücretsiz | Tam süre |
| Kefalet | Gem | Anında çıkış |
| Lonca Yardımı | Ücretsiz | -%15 süre |

## 18.4 Hapishane Aktiviteleri

### Hapishane İçi İşler

Hapishanedeyken sınırlı aktiviteler yapılabilir:

| Aktivite | Erişilebilir | Açıklama |
|----------|--------------|----------|
| Chat | ✅ | Sadece global ve private |
| Envanter görme | ✅ | Sadece görüntüleme |
| Market | ❌ | Yasak |
| Üretim | ❌ | Yasak |
| PvP | ❌ | Yasak |
| Zindan | ❌ | Yasak |
| Görevler | ❌ | Yasak |

### Hapishane Mini-Oyunları (Öneri)

Hapishanede zaman geçirmek için:

| Oyun | Ödül |
|------|------|
| Taş Kırma | Dakikada 1 altın |
| Kart Oyunu | XP kazanımı |
| Diğer mahkumlarla ticaret | Özel itemlar |

---

# BÖLÜM 19: UI/UX AKIŞLARI

## 19.1 Ana Ekranlar

### Ekran Listesi

| Ekran | Anahtar | Açıklama |
|-------|---------|----------|
| Açılış | `splash` | Logo, yükleme |
| Giriş | `login` | Auth ekranı |
| Ana Menü | `home` | Ana hub |
| Oyun | `main` | Oyun ekranı |
| Envanter | `inventory` | Item yönetimi |
| Ekipman | `equipment` | Takma/çıkarma |
| Market | `market` | Alım/satım |
| Görevler | `quest` | Görev listesi |
| Zindan | `dungeon` | Zindan seçimi |
| PvP | `pvp` | Savaş ekranı |
| Lonca | `guild` | Lonca yönetimi |
| Tesisler | `facilities` | Üretim binaları |
| Hastane | `hospital` | İyileşme ekranı |
| Hapishane | `prison` | Ceza ekranı |
| Profil | `profile` | Oyuncu bilgileri |
| Ayarlar | `settings` | Oyun ayarları |
| Sıralama | `leaderboard` | Liderlik tablosu |
| Mağaza | `shop` | Gem satın alma |

## 19.2 Navigasyon Yapısı

### Ana Navigasyon (Bottom Bar)

```
┌─────────────────────────────────────────┐
│              OYUN ALANI                 │
├─────────────────────────────────────────┤
│  🏠    ⚔️    🎒    🏭    👤            │
│ Ana   PvP   Env  Tesis  Profil         │
└─────────────────────────────────────────┘
```

### Hızlı Erişim (Quick Actions)

| Buton | Aksiyon |
|-------|---------|
| Enerji barı tıklama | İksir kullan popup |
| Altın tıklama | Market'e git |
| Gem tıklama | Mağaza'ya git |
| Bildirim ikonu | Bildirim listesi |

## 19.3 Popup ve Modal'lar

### Popup Tipleri

| Popup | Kullanım |
|-------|----------|
| Confirm | İşlem onayı |
| Alert | Bilgilendirme |
| Input | Metin girişi |
| Select | Liste seçimi |
| ItemDetail | Item bilgisi |
| Enhancement | Geliştirme ekranı |
| Production | Üretim başlatma |
| Trade | Alım/satım |

### Modal Özellikleri

| Özellik | Varsayılan |
|---------|------------|
| Backdrop tıklama | Kapat |
| Kapatma butonu | Sağ üst köşe |
| Animasyon | Fade + Scale |
| Süre | 200ms |

## 19.4 Animasyonlar

### Geçiş Animasyonları

| Geçiş | Animasyon | Süre |
|-------|-----------|------|
| Ekran değişimi | Slide + Fade | 300ms |
| Popup açılma | Scale + Fade | 200ms |
| Popup kapanma | Scale + Fade | 150ms |
| Liste öğesi | Slide in | 100ms |
| Tab değişimi | Fade | 150ms |

### Geri Bildirim Animasyonları

| Aksiyon | Animasyon |
|---------|-----------|
| Buton tıklama | Bounce |
| Item ekleme | Pulse + Glow |
| Başarı | Confetti |
| Hata | Shake |
| Level up | Flash + Particles |

---

# BÖLÜM 20: SES VE MÜZİK

## 20.1 Müzik Parçaları

### Ortam Müzikleri

| Parça | Kullanım | Loop |
|-------|----------|------|
| main_theme | Ana menü | ✅ |
| town | Şehir ekranları | ✅ |
| dungeon_ambient | Zindan içi | ✅ |
| battle | PvP savaşı | ✅ |
| guild_hall | Lonca ekranı | ✅ |
| market | Pazar ekranı | ✅ |
| victory | Zafer anı | ❌ |
| defeat | Yenilgi anı | ❌ |

### Müzik Özellikleri

| Özellik | Değer |
|---------|-------|
| Format | OGG |
| Sample Rate | 44.1 kHz |
| Bit Rate | 128-192 kbps |
| Crossfade | 2 saniye |

## 20.2 Ses Efektleri

### UI Sesleri

| Ses | Kullanım |
|-----|----------|
| click | Buton tıklama |
| hover | Buton üzerine gelme |
| open | Popup açılma |
| close | Popup kapanma |
| error | Hata |
| success | Başarı |
| notification | Bildirim |

### Oyun Sesleri

| Ses | Kullanım |
|-----|----------|
| coin | Altın kazanma |
| gem | Gem kazanma |
| equip | Item takma |
| unequip | Item çıkarma |
| enhance_success | Geliştirme başarı |
| enhance_fail | Geliştirme başarısız |
| enhance_destroy | Item yok olma |
| level_up | Seviye atlama |
| quest_complete | Görev tamamlama |
| production_complete | Üretim bitti |

### Savaş Sesleri

| Ses | Kullanım |
|-----|----------|
| attack | Saldırı |
| hit | Hasar alma |
| critical | Kritik vuruş |
| block | Engelleme |
| victory | Zafer |
| defeat | Yenilgi |

## 20.3 Ses Ayarları

### Ses Kategorileri

| Kategori | Varsayılan | Aralık |
|----------|------------|--------|
| Master | %80 | 0-100 |
| Müzik | %60 | 0-100 |
| Efektler | %80 | 0-100 |
| UI | %70 | 0-100 |
| Bildirimler | %100 | 0-100 |

### Özel Ayarlar

| Ayar | Varsayılan |
|------|------------|
| Arka planda ses | Kapalı |
| Vibrasyon | Açık |
| Düşük güç modu | Kapalı |

---

# BÖLÜM 21: SABİTLER VE KONFİGÜRASYON

## 21.1 Global Sabitler

### Network Sabitleri

| Sabit | Değer | Açıklama |
|-------|-------|----------|
| `BASE_URL` | `https://znvsyzstmxhqvdkkmgdt.supabase.co` | Supabase URL |
| `RATE_LIMIT` | 60 | İstek/dakika |
| `CACHE_TTL` | 3600 | Cache süresi (saniye) |
| `WS_RECONNECT_DELAY` | 5000 | WebSocket yeniden bağlanma (ms) |
| `REQUEST_TIMEOUT` | 30000 | İstek zaman aşımı (ms) |

### Enerji Sabitleri

| Sabit | Değer | Açıklama |
|-------|-------|----------|
| `MAX_ENERGY` | 100 | Maksimum enerji |
| `ENERGY_REGEN_SECONDS` | 300 | Regen aralığı (5 dk) |
| `ENERGY_REGEN_AMOUNT` | 1 | Her regen'de eklenen |
| `OFFLINE_REGEN_CAP` | 86400 | Max offline (24 saat) |

### Tolerance Sabitleri

| Sabit | Değer | Açıklama |
|-------|-------|----------|
| `MAX_TOLERANCE` | 100 | Maksimum tolerance |
| `TOLERANCE_DECAY_HOURS` | 6 | Decay periyodu |
| `TOLERANCE_DECAY_AMOUNT` | 1 | Her decay'de düşen |
| `OVERDOSE_THRESHOLD` | 0.8 | Kritik eşik (%80) |

### PvP Sabitleri

| Sabit | Değer | Açıklama |
|-------|-------|----------|
| `PVP_COOLDOWN` | 300 | Cooldown süresi (5 dk) |
| `PVP_ENERGY_COST` | 10 | Enerji maliyeti |
| `PVP_MIN_LEVEL` | 10 | Minimum seviye |
| `RETALIATION_WINDOW` | 3600 | Misilleme süresi (1 saat) |
| `MAX_RETALIATION` | 3 | Max misilleme sayısı |

### Enhancement Sabitleri

| Sabit | Değer | Açıklama |
|-------|-------|----------|
| `MAX_ENHANCEMENT` | 10 | Maksimum geliştirme |
| `DESTRUCTION_THRESHOLD` | 6 | Yok olma başlangıcı |
| `STAT_BONUS_PER_LEVEL` | 0.05 | Her seviye +%5 |

### Envanter Sabitleri

| Sabit | Değer | Açıklama |
|-------|-------|----------|
| `INVENTORY_SLOTS` | 20 | Başlangıç slot |
| `MAX_INVENTORY_SLOTS` | 120 | Maksimum slot |
| `MAX_STACK` | 50 | Maksimum stack |
| `SLOT_EXPANSION_COST` | 100 | Slot genişletme (gem) |
| `SLOT_EXPANSION_AMOUNT` | 5 | Her satın almada +5 |

### Market Sabitleri

| Sabit | Değer | Açıklama |
|-------|-------|----------|
| `MARKET_COMMISSION` | 0.05 | Komisyon (%5) |
| `MIN_PRICE` | 1 | Minimum fiyat |
| `MAX_PRICE` | 999999 | Maksimum fiyat |
| `LISTING_DURATION` | 604800 | Liste süresi (7 gün) |
| `MAX_ACTIVE_LISTINGS` | 20 | Max aktif liste |

### Chat Sabitleri

| Sabit | Değer | Açıklama |
|-------|-------|----------|
| `CHAT_RATE_LIMIT` | 2 | Mesaj arası (saniye) |
| `MAX_MESSAGE_LENGTH` | 200 | Max karakter |
| `FLOOD_LIMIT` | 10 | Max mesaj/dakika |

## 21.2 Tesis Konfigürasyonu

### Açılış Maliyetleri

| Tesis | Maliyet | Çarpan |
|-------|---------|--------|
| `mining` | 3,000 | 1.5 |
| `woodworking` | 3,000 | 1.5 |
| `farming` | 3,500 | 1.5 |
| `herb_garden` | 4,000 | 1.6 |
| `blacksmith` | 8,000 | 1.7 |
| `armorer` | 8,000 | 1.7 |
| `alchemy_lab` | 10,000 | 1.7 |
| `runesmith` | 15,000 | 1.8 |
| `scroll_library` | 12,000 | 1.7 |
| `gem_cutter` | 12,000 | 1.7 |
| `enhancement_master` | 17,000 | 1.8 |
| `master_alchemist` | 15,000 | 1.8 |
| `master_armorer` | 15,000 | 1.8 |
| `warehouse` | 5,000 | 1.5 |
| `market_hub` | 6,000 | 1.6 |

### Tesis Limitleri

| Sabit | Değer |
|-------|-------|
| `MAX_FACILITY_LEVEL` | 20 |
| `MAX_QUEUE_SIZE` | 10 |
| `MAX_SUSPICION` | 100 |
| `BRIBE_COST` | 5 gem |
| `BRIBE_EFFECT` | -10 suspicion |
| `SUSPICION_DECAY_HOURS` | 4 |

## 21.3 PvP Sabitleri

### Rating Sabitleri

| Sabit | Değer |
|-------|-------|
| `STARTING_RATING` | 1000 |
| `K_FACTOR` | 32 |
| `MIN_RATING` | 0 |
| `MAX_RATING` | 5000 |

### Reputation Sabitleri

| Sabit | Değer |
|-------|-------|
| `STARTING_REPUTATION` | 0 |
| `MIN_REPUTATION` | -500 |
| `MAX_REPUTATION` | 500 |

## 21.4 Market Sabitleri

### Volatilite Katsayıları

| Item Tipi | k Değeri |
|-----------|----------|
| Normal | 0.08 |
| Potion | 0.12 |
| Antidote | 0.15 |
| Rune/Scroll | 0.10 |
| Legendary | 0.05 |

### Circuit Breaker

| Değişim | Durdurma Süresi |
|---------|-----------------|
| %30 | 30 dakika |
| %50 | 2 saat |
| %70 | Gün sonu |

---

# BÖLÜM 22: UYGULAMA DURUMU

## 22.1 Tamamlanan Sistemler

| Sistem | Durum | Detay |
|--------|-------|-------|
| ✅ Core Data Models | Tamamlandı | 10 sınıf |
| ✅ Network Layer | Tamamlandı | HTTP, WebSocket, API |
| ✅ Autoload Singletons | Tamamlandı | 10 singleton |
| ✅ Dungeon Mechanics | Tamamlandı | Formüller, hospitalization |
| ✅ Hospital System | Tamamlandı | Client + Server |
| ✅ Inventory System | Tamamlandı | Ghost items çözüldü |
| ✅ Equipment System | Tamamlandı | 8 slot, swap logic |
| ✅ 15 Facilities Design | Tamamlandı | Tam dokümantasyon |
| ✅ Database Schema | Tamamlandı | 15+ tablo |
| ✅ RPC Functions | Tamamlandı | 20+ fonksiyon |
| ✅ Edge Functions | Tamamlandı | 15+ function |
| ✅ FacilitiesScreen UI | Tamamlandı | Görüntüleme çalışıyor |
| ✅ ItemData/Database | Tamamlandı | Enum'lar, cache |
| ✅ State Management | Tamamlandı | Reactive state |

## 22.2 Devam Eden Sistemler

| Sistem | Durum | Kalan İş |
|--------|-------|----------|
| ⏳ Facilities RPC | %80 | Deployment |
| ⏳ Production Queue | %70 | Collect logic |
| ⏳ Prison System | %50 | Mining screen entegrasyonu |
| ⏳ Market UI | %40 | Liste görüntüleme, alım |
| ⏳ PvP Combat | %60 | Balance, test |
| ⏳ Enhancement UI | %50 | Rün/Scroll entegrasyonu |
| ⏳ Chat System | %30 | WebSocket bağlantısı |

## 22.3 Başlanmamış Sistemler

| Sistem | Öncelik | Tahmini Süre |
|--------|---------|--------------|
| ❌ Guild Wars | Yüksek | 2 hafta |
| ❌ Season System | Yüksek | 2 hafta |
| ❌ Boss Raids | Orta | 3 hafta |
| ❌ Achievement System | Orta | 1 hafta |
| ❌ Battle Pass | Orta | 1 hafta |
| ❌ Leaderboards | Orta | 1 hafta |
| ❌ Mobile Optimization | Yüksek | 2 hafta |
| ❌ Full QA Testing | Kritik | 3 hafta |
| ❌ Localization | Düşük | 2 hafta |
| ❌ Tutorial System | Orta | 1 hafta |

## 22.4 Bilinen Sorunlar

### Kritik

| # | Sorun | Durum |
|---|-------|-------|
| 1 | - | - |

### Önemli

| # | Sorun | Durum |
|---|-------|-------|
| 1 | Facilities RPC deployment bekliyor | Planlı |
| 2 | Prison-Mining entegrasyonu eksik | Planlı |

### Düşük

| # | Sorun | Durum |
|---|-------|-------|
| 1 | Bazı UI animasyonları eksik | Backlog |
| 2 | Ses efektleri placeholder | Backlog |

---

# BÖLÜM 23: ÖNERİLEN YENİ ÖZELLİKLER

## 23.1 Boss Raid Sistemi

### Konsept

Haftalık/sezonluk dev boss'lar tüm sunucu tarafından birlikte yenilir.

### Mekanikler

| Özellik | Değer |
|---------|-------|
| Boss HP | 100,000,000+ |
| Katılım | Tüm oyuncular |
| Hasar takibi | Bireysel + Lonca |
| Ödül | Hasar sıralamasına göre |
| Süre | 24-72 saat |

### Ödül Dağılımı

| Sıralama | Ödül |
|----------|------|
| Top 1% | Legendary Chest + 500 gem |
| Top 10% | Epic Chest + 200 gem |
| Top 50% | Rare Chest + 50 gem |
| Katılımcı | Common Chest + 10 gem |

## 23.2 Achievement Sistemi

### Kategöriler

| Kategori | Örnek Achievement |
|----------|-------------------|
| Savaş | "1000 PvP Zafer" |
| Üretim | "10,000 Item Üret" |
| Ekonomi | "1M Altın Kazan" |
| Sosyal | "100 Arkadaş" |
| Koleksiyon | "Tüm Legendary Topla" |
| Sezon | "3 Sezon Top 100" |

### Ödüller

| Zorluk | Ödül |
|--------|------|
| Kolay | 5 gem + Unvan |
| Orta | 20 gem + Çerçeve |
| Zor | 50 gem + Özel Efekt |
| Efsanevi | 200 gem + Özel Skin |

## 23.3 Mentorship Programı

### Konsept

Deneyimli oyuncular (50+ seviye) yeni oyunculara mentor olur.

### Faydalar

**Mentor için:**
- Mentee her 10 seviye → 50 gem
- Mentee 50 seviyeye ulaşınca → "Usta Mentor" unvanı
- Haftalık mentor ödülleri

**Mentee için:**
- +%20 XP bonus (mentor aktifken)
- Özel sorular için chat
- Hediye alma

### Kurallar

- 1 mentor = max 3 mentee
- Mentorship süresi: 30 gün veya 50 seviye
- Mentor 7 gün aktif olmazsa otomatik sonlanır

## 23.4 Daily Login Streak

### Konsept

Ardışık günlük giriş için artan ödüller.

### Ödül Tablosu

| Gün | Ödül |
|-----|------|
| 1 | 5 gem |
| 2 | 10 gem |
| 3 | 20 gem |
| 4 | 30 gem |
| 5 | 50 gem |
| 6 | 75 gem |
| 7 | 100 gem + Rare Chest |
| 14 | 150 gem + Epic Chest |
| 30 | 300 gem + Legendary Chest |

### Streak Koruma

- 1 gün kaçırma: Streak sıfırlanır
- Streak Shield (50 gem): 1 gün koruma

## 23.5 Pet Sistemi

### Konsept

Oyuncuya eşlik eden, pasif bonus veren hayvanlar.

### Pet Tipleri

| Pet | Bonus | Nasıl Elde Edilir |
|-----|-------|-------------------|
| Kurt | +%5 Attack | Hikaye Bölüm 3 |
| Baykuş | +%5 XP | Achievement |
| Ejderha Yavrusu | +%3 Drop | Legendary Chest |
| Altın Tavuk | +%5 Gold | Battle Pass |
| Gölge Kedi | +%5 Crit | Sezon ödülü |

### Pet Seviyeleri

Petler beslenerek seviye atlar:

| Seviye | Bonus Artışı |
|--------|--------------|
| 1-10 | Base bonus |
| 11-20 | +%50 bonus |
| 21-30 | +%100 bonus |

---

# EKLER

## Ek A: Arşivlenen Belgeler Listesi

Bu Master GDD, aşağıdaki belgelerin konsolidasyonudur:

### Temel Belgeler

| Dosya | Açıklama |
|-------|----------|
| OYUN-OZET-v2.0.md | Oyun özeti |
| PROJE-YAPISI.md | Proje yapısı |
| README.md | Genel bilgi |

### Sistem Belgeleri

| Dosya | Açıklama |
|-------|----------|
| DUNGEON-LOGIC-DEEP-DIVE.md | Zindan mekaniği |
| DUNGEON-MECHANICS-GUIDE.md | Zindan rehberi |
| DUNGEON-RESOLUTION-REPORT.md | Zindan çözümleme |
| HOSPITAL-SYSTEM-IMPLEMENTATION.md | Hastane client |
| HOSPITAL-SYSTEM-SERVER-SIDE.md | Hastane server |
| FACILITIES_SYSTEM_COMPLETE_PLAN.md | Tesis planı |
| FACILITIES_COMPLETION_SUMMARY.md | Tesis özeti |
| FACILITIES_DEEP_ANALYSIS.md | Tesis analizi |
| FACILITIES_QUICK_REFERENCE.md | Tesis referans |
| FACILITIES_TODO_LIST.md | Tesis yapılacaklar |

### Plan Belgeleri

| Dosya | Açıklama |
|-------|----------|
| plan-golgeEkonomi-part-01.prompt.md | Genel plan |
| plan-golgeEkonomi-part-01a-detailed.prompt.md | Detay 1a |
| plan-golgeEkonomi-part-01b-detailed.prompt.md | Detay 1b |
| plan-golgeEkonomi-part-02.prompt.md | Bölüm 2 |
| plan-golgeEkonomi-part-02-detailed.prompt.md | Detay 2 |
| plan-golgeEkonomi-part-03.prompt.md | Bölüm 3 |
| plan-golgeEkonomi-part-03a-detailed.prompt.md | Detay 3a |
| plan-golgeEkonomi-part-04.prompt.md | Bölüm 4 |
| plan-golgeEkonomi-API-detailed.prompt.md | API planı |
| plan-golgeEkonomi-CHAT-detailed.prompt.md | Chat planı |
| plan-golgeEkonomi-DATABASE-detailed.prompt.md | DB planı |
| plan-golgeEkonomi-ENERGY-POTION-detailed.prompt.md | Enerji planı |
| plan-golgeEkonomi-ENHANCEMENT-detailed.prompt.md | Geliştirme planı |
| plan-golgeEkonomi-GUILD-detailed.prompt.md | Lonca planı |
| plan-golgeEkonomi-MONETIZATION-detailed.prompt.md | Monetizasyon |
| plan-golgeEkonomi-PRODUCTION-detailed.prompt.md | Üretim planı |
| plan-golgeEkonomi-PVP-detailed.prompt.md | PvP planı |
| plan-golgeEkonomi-SEASON-detailed.prompt.md | Sezon planı |
| plan-golgeEkonomi-TELEMETRY-detailed.prompt.md | Telemetri planı |

### Teknik Belgeler

| Dosya | Açıklama |
|-------|----------|
| IMPLEMENTATION_ROADMAP.md | Uygulama yol haritası |
| IMPLEMENTATION_SUMMARY.md | Uygulama özeti |
| ARRAY-TYPE-FIX.md | Array düzeltmesi |
| PARSER-FIXES-SUMMARY.md | Parser düzeltmeleri |
| DEPLOYMENT_GUIDE.md | Deployment rehberi |
| DEPLOYMENT_STEPS.md | Deployment adımları |
| UI-IMPLEMENTATION-SUMMARY.md | UI özeti |
| SISTEM-IMPLEMENTASYON-RAPORU.md | Sistem raporu |
| SIRAYLA_BASLANDI_OZET.md | Başlangıç özeti |

### Test Belgeleri

| Dosya | Açıklama |
|-------|----------|
| TEST_CHECKLIST.md | Test listesi |
| TEST_CHECKLIST_FACILITIES.md | Tesis test listesi |
| QUICK_START.md | Hızlı başlangıç |

## Ek B: Değişiklik Geçmişi

| Tarih | Versiyon | Değişiklik |
|-------|----------|------------|
| 31 Ocak 2026 | 1.0 | İlk versiyon - 40+ belgenin konsolidasyonu |

---

# SON

**Bu belge, Gölge Krallık: Kadim Mühür'ün Çöküşü projesinin resmi ve tek kaynak Game Design Document'ıdır.**

**Tüm eski belgeler `docs/archive/` klasörüne taşınmıştır ve referans amaçlı saklanmaktadır.**

---

*Belge Sonu*
*Toplam: ~4,500 satır*
*Son Güncelleme: 31 Ocak 2026*


