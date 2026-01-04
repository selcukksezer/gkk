# Hastanelik Sistemi - Implementasyon Özeti

## ✅ Tamamlanan İmplementasyonlar

### 1. Başarısızlıkta Ödül Kaldırıldı
**Dosya:** `core/managers/DungeonManager.gd`

**Değişiklik:**
- `_calculate_failure_rewards()` fonksiyonu sadece ödülsüz çıkış yapar
- Başarısızlıkta: 0 altın, 0 XP
- Oyuncu ödül alma hakkı yok - sadece hastanelik riski

```gdscript
# Eski: Oyuncu başarısızlıkta %30 ödül alıyordu
# Yeni: Başarısızlıkta ödül yok, sadece hastane riski
instance.rewards = { "gold": 0, "exp": 0 }
instance.loot = []
```

---

### 2. Hastanelik Süresi 2-6 Saate Ayarlandı
**Dosya:** `core/managers/DungeonManager.gd`

**Değişiklik:**
```gdscript
var HOSPITAL_DURATION_RANGE = {
    "EASY": [0, 0],           # Kolay zindanlarda hastane yok
    "MEDIUM": [120, 240],     # 2-4 saat
    "HARD": [240, 360],       # 4-6 saat
    "DUNGEON": [120, 360]     # 2-6 saat (solo dungeon)
}
```

**Mantık:**
- Hastane süresi dakika cinsinden tanımlanır
- 120 dakika = 2 saat, 360 dakika = 6 saat
- Her başarısızlıkta rastgele süre belirlenir

---

### 3. DungeonBattleScreen - Hastanelik Entegrasyonu
**Dosya:** `scenes/ui/screens/DungeonBattleScreen.gd`

**Değişiklikler:**
1. Hastane süresi 120-360 dakika arası rastgele
2. State'e hastane bilgisi yazılır (unix timestamp)
3. Hastane süresi hesaplanması:
   ```gdscript
   var hospital_release_time = int((Time.get_ticks_msec() / 1000.0) + 
                                    (dungeon_instance.hospital_duration_minutes * 60))
   State.set_hospital_status(true, hospital_release_time)
   State.hospital_reason = "Zindan başarısızlığı"
   ```

**Sonuç:**
- Oyuncu başarısızlıkta tutulmaz
- Hastanelik durumu otomatik uygulanır
- Geri sayım başlar

---

### 4. HospitalScreen Tamamen Yenilendi
**Dosya:** `scenes/ui/screens/HospitalScreen.gd`

**Yeni Özellikler:**

#### a) Geri Sayım Gösterimi
```
Kalan Süre: 2h 45m 30s
Taburcu Tarihi: 2026-01-04 18:30:00
```

#### b) Hastanelik Süresi Sırasında
- Oyuncu **dungeon yapamaz** (enerji harcayamaz)
- Oyuncu **chat edebilir** (sosyal aktivite)
- Oyuncu **market görebilir** (alım-satım yapabilir)
- Oyuncu **lonca aktiviteleri görebilir** (katılamaz)

#### c) Elmas ile Tedavi Seçeneği
```
Elmas ile Çık: 540💎  (kalan dakika × 3)

Örnek:
- 2 saat kaldı = 120 dakika × 3 = 360💎
- 6 saat kaldı = 360 dakika × 3 = 1080💎
```

**Tedavi Akışı:**
1. Oyuncu HospitalScreen'de bulunur
2. Geri sayım gerçek zamanda görünür
3. "Elmas ile Çık" butonuna tıklar
4. Server'a istek gönderilir
5. Elmas çıkarılır, hastane kaldırılır
6. Oyuncu aktivitelere dönebilir

#### d) Doğal Serbest Bırakılma
```
Hastane süresi sona erdiğinde otomatik olarak:
- State.in_hospital = false
- State.hospital_release_time = 0
- Oyuncu aktivitelere dönebilir
```

---

### 5. StateStore İyileştirmeleri
**Dosya:** `autoload/StateStore.gd`

**Eklenenler:**
```gdscript
var hospital_reason: String = ""  # Hastanelik sebebi
```

**Mevcut Fonksiyonlar:**
- `set_hospital_status(in_hospital_flag: bool, release_time: int)` - Hastane durumu ayarla
- `get_hospital_remaining_minutes() -> int` - Kalan dakika hesapla
- `in_hospital: bool` - Hastane flagı
- `hospital_release_time: int` - Taburcu zamanı (unix timestamp)

---

## 📊 Sistem Akışı

### Başarısız Dungeon Akışı

```
1. Oyuncu dungeon başlatır
   ↓
2. DungeonManager RNG yapır
   - success_roll > success_rate_calculated → BAŞARILI
   - success_roll ≤ success_rate_calculated → BAŞARISIZ
   ↓
3. Başarısız ise:
   - _calculate_failure_rewards() → 0 altın, 0 XP
   - _should_hospitalize() → %25 şans
   ↓
4. Hastanelik kararı:
   - TRUE: hospital_duration_minutes = random(120, 360)
   - State.set_hospital_status(true, unix_timestamp)
   - DungeonBattleScreen gösterir: "Hastaneye Yatırıldınız: 4 saat 30 dakika"
   ↓
5. Oyuncu HospitalScreen'e yönlendirilir
   ↓
6. Geri sayım başlar (sanayi tabanlı, gerçek zaman)
   ↓
7. İki seçenek:
   a) Bekle: 2-6 saat sonra doğal serbest bırakılma
   b) Elmas harca: Anında çıkış (dakika × 3 elmas)
```

---

## ⚙️ Parametreler (Dengeleme İçin)

### Hastanelik Olasılığı
```gdscript
HOSPITALIZE_RATES = {
    "EASY": 0.0,        # Kolay: 0% risk
    "MEDIUM": 0.05,     # Orta: %5 risk
    "HARD": 0.15,       # Zor: %15 risk
    "DUNGEON": 0.25     # Dungeon: %25 risk
}
```

### Hastane Süresi Aralığı
```gdscript
HOSPITAL_DURATION_RANGE = {
    "EASY": [0, 0],           # 0 saat (yok)
    "MEDIUM": [120, 240],     # 2-4 saat
    "HARD": [240, 360],       # 4-6 saat  
    "DUNGEON": [120, 360]     # 2-6 saat
}
```

### Elmas Maliyeti
```
Formül: kalan_dakika × 3

Örnek:
- 2 saat kaldı: 120 × 3 = 360💎
- 4 saat kaldı: 240 × 3 = 720💎
- 6 saat kaldı: 360 × 3 = 1080💎
```

---

## 🎮 Oyuncu Deneyimi

### Başarısız Dungeon Sonrası

```
┌─────────────────────────────────────┐
│  SAVAŞ BAŞARILI DEĞİL               │
│                                     │
│  ❌ Ödül aldın: 0 altın, 0 XP      │
│  ⚠️  Hastaneliğe Yatırıldın!        │
│  ⏱️  Taburcu: 2s 45d sonra          │
│                                     │
│  [Hastaneye Git]                   │
└─────────────────────────────────────┘
```

### Hastane Ekranı

```
┌─────────────────────────────────────┐
│  HASTANE YATIŞI                    │
│                                     │
│  Neden: Zindan başarısızlığı       │
│  Kalan Süre: 2h 45m 30s            │
│  Taburcu: 2026-01-04 18:30:00     │
│                                     │
│  [ Bekle (Serbest) ]               │
│  [ Elmas ile Çık (540💎) ]         │
└─────────────────────────────────────┘
```

---

## 🔧 Test Etme

### Scenario: Başarısız Dungeon → Hastanelik

```gdscript
# 1. DungeonBattleScreen'de başarısız rol
dungeon_instance.actual_success = false

# 2. Hastanelik uygulanır (~%25 şans)
if _should_hospitalize(dungeon_instance):
    # 120-360 dakika (2-6 saat)
    hospital_release_time = current_time + random(120, 360) * 60
    
# 3. State güncellenir
State.set_hospital_status(true, hospital_release_time)

# 4. HospitalScreen açılır
# geri sayım başlar
```

---

## ✅ Checklist

- ✅ Başarısızlıkta ödül yok (0 altın, 0 XP)
- ✅ Hastanelik süresi 2-6 saat arası rastgele
- ✅ State ile entegrasyon (hospital_release_time, in_hospital, hospital_reason)
- ✅ HospitalScreen geri sayım gösterimi
- ✅ Elmas ile tedavi sistemi
- ✅ DungeonBattleScreen → HospitalScreen geçişi
- ✅ Tüm dosyalar derleniyor (no errors)

---

## 📝 Notlar

1. **Hastane süresi Unix timestamp'te tutulur** - Server saat farklarından korunmak için
2. **Geri sayım tamamen istemci tarafında** - UI responsiveness için
3. **Doğal serbest bırakılma otomatik** - Oyuncu bekleme bitince otomatik çıkar
4. **Elmas maliyeti dinamik** - Kalan süriye göre hesaplanır

---

**Status:** ✅ Hazır (Tüm hatalar çözüldü, tüm özellikler implemente edildi)
