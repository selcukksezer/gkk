# Hospital System - Sunucu Tarafı Mimarisi (Server-Side Architecture)

## Yapılan Değişiklikler (Changes Made)

### 1. **Yeni Endpoint: `/api/v1/hospital/admit` (supabase/functions/hospital-admit/index.ts)**
- **Amaç**: Hastaneye düşme işlemini SADECE server-side yapar
- **Request Body**:
  ```json
  {
    "duration_minutes": 120,
    "reason": "Zindan başarısızlığı"
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "hospital_until": "2026-01-04T12:00:00Z",
    "release_time": 1735988400,
    "duration_minutes": 120,
    "reason": "Zindan başarısızlığı"
  }
  ```
- **Güvenlik**: Database'e doğrudan yazar, client tarafı hiçbir şey saklayamaz

### 2. **Güncelleme: `/api/v1/hospital/release` (supabase/functions/hospital-release/index.ts)**
- **İyileştirme**: Request body parsing düzeltildi (try-catch ile)
- **Güvenlik**: 
  - Süre bilgisi server'dan alınır (client hesaplaması değil)
  - Elmas kontrolü server tarafında yapılır
  - Status 400 döner eğer hastada değilse (401 yerine)

### 3. **HospitalManager.gd Güncellemeleri**

#### Yeni Fonksiyon: `admit_player(duration_minutes, reason)`
```gdscript
var result = await hospital_mgr.admit_player(120, "Zindan başarısızlığı")
```
- **Server-side** hospitalization çağrısı yapar
- State'i server response'dan update eder

#### Güncelleme: `fetch_hospital_status()`
- Her seferinde fresh veri çeker server'dan
- State cache'i sadece data değişirse update eder

#### Güncelleme: `release_with_gems()`
- **Önemli**: Önce `fetch_hospital_status()` çağırır (time manipulation önlemek)
- Elmas kontrolü server response'ından alınır
- Response body'de cost parametresi gönderilir

### 4. **DungeonBattleScreen.gd Güncellemeleri**
- Hastaneye düşme işlemi artık **asynchronous** ve **server-side**
- `hospital_mgr.admit_player()` çağrısı yapılır
- Client-side State'e hiçbir şey yazılmaz (server response'undan gelir)

### 5. **HospitalScreen.gd Güncellemeleri**
- `_load_hospital_status()` artık server'dan fresh veri çeker
- State cache'ine güvenmiyor
- Button state'i server response'una göre güncellenir

---

## Güvenlik Özellikleri (Security Features)

✅ **Time Manipulation Önleme**
- Client sistem saatini ileri alıp hastaneden çıkamaz
- Server'dan her seferinde fresh timestamp alınır

✅ **Uygulama Kapanırken Hastaneden Çıkma Sorunu Çözüldü**
- State cache'e güvenmiyoruz
- Her HospitalScreen açılışında server'dan veri çekiliyor

✅ **Çoklu Tıklama Sorunu Çözüldü**
- Button 00ms içinde disabled oluyor
- Network error durumunda button re-enable oluyor

✅ **Hospitalization Server-Side**
- Uygulamada local olarak hastanelik durumu tutulmuyor
- Server database'e yazıyor

---

## Oyun Kapalı İken Hastanelik Süresi (Hospital Duration When Game is Closed)

**Database'deki `hospital_until` timestamp'i otomatik olarak azalmaz.**

### Çözüm:
HospitalScreen açıldığında:
1. Server'dan `hospital_until` timestamp'i çekiliyor
2. Client-side `hospital_release_time` (unix timestamp) karşılaştırılır
3. **Eğer artık geçtiyse, `in_hospital=false` döner ve otomatik çıkılır**

```gdscript
# HospitalScreen._on_countdown_tick()
if remaining_seconds <= 0:
  countdown_timer.stop()
  State.set_hospital_status(false, 0)  # Otomatik çıkış
```

---

## API Endpoint Özeti

| Endpoint | Method | Purpose | Client Side? |
|----------|--------|---------|--------------|
| `/api/v1/hospital/status` | GET | Hastanelik durumunu kontrol et | ✓ (Server-side check) |
| `/api/v1/hospital/admit` | POST | Hastaneye koy | ✗ Server-side only |
| `/api/v1/hospital/release` | POST | Hastaneden çıkar | ✓ (Server validation) |

---

## Gelecek İyileştirmeler (Future Improvements)

1. **Database trigger** eklenebilir: `hospital_until` geçtiyse otomatik `hospital_reason` NULL'lanır
2. **Cron job** eklenebilir: Süresi geçen oyuncuları temizlemek için
3. **Redis cache** eklenebilir: Sık kontrol edilen statüsleri cache'lemek için
