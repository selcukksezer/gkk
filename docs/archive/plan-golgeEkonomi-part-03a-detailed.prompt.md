# Gölge Ekonomi — Plan Detaylandırma (Part 03A)

> Kaynak: plan-golgeEkonomi-part-03.prompt.md (Faza 6)
> Oyun: Gölge Krallık: Kadim Mühür'ün Çöküşü
> Amaç: Görev + Zindan + Hastane döngüsünü enerji sistemi ile entegre, server-authoritative, audit edilebilir şekilde tanımlamak.

---

## FAZA 6 — Görev & Zindan Sistemi (Hafta 29–36)

### 6.1 Tasarım İlkeleri
- **Enerji temelli tempo:** oyuncu enerji harcayarak aktivite yapar; hız kısıtı enerji ile kontrol edilir
- **Risk/ödül şeffaf:** başarı olasılığı anlaşılır olmalı
- **Server RNG:** başarı/loot/kritik başarısızlık kararları sadece server'da
- **Hastane = alternatif loop:** oyuncu oyundan kopmasın diye hastane ekranı "pazar okuma", "lonca/chat", "plan yapma" gibi aktiviteleri destekler

---

## 6.2 Görev Tipleri ve Parametreler

| Görev Tipi | Enerji | Kazanç Bandı | Risk Seviyesi | Süre |
|---|---:|---:|---:|---:|
| Kolay Görev | 5-10 | 100–500 altın | ⭐ | 1-3 dk |
| Orta Görev | 10-15 | 500–2K | ⭐⭐ | 3-7 dk |
| Zor Görev | 15-20 | 2K–10K | ⭐⭐⭐ | 7-15 dk |
| Zindan (Solo) | 20-30 | 10K–100K | ⭐⭐⭐⭐ | 10-30 dk |
| Zindan (Grup) | 25-40 | 50K–500K | ⭐⭐⭐⭐⭐ | 20-60 dk |

### 6.2.1 Bölge özellikleri
- Her region için `danger_level` (0–100) tutulur
- Tehlike seviyesi arttıkça:
  - Başarı şansı azalır
  - Ödüller artar
  - Hastanelik riski artar
  - Nadir loot şansı artar

> `danger_level` dinamik olabilir (event/sezon), ama ilk sürümde statik başlayabilir.

---

## 6.3 Başarı Olasılığı: Hesaplama Modeli

### 6.3.1 Feature'lar
- Ekipman katkısı: weapon/armor
- Beceri katkısı (skill tree)
- Seviye katkısı
- Zorluk katsayısı
- Bölge tehlike cezası

### 6.3.2 Önerilen hesap
1) **Base chance**: görev tipine göre
   - Kolay: 0.85
   - Orta: 0.70
   - Zor: 0.55
   - Zindan Solo: 0.45
   - Zindan Grup: 0.60 (grup bonusu)

2) **Power score** (0–1 normalize)
   - `gear_score`, `skill_score`, `level_score` normalize edilir

3) **Final chance**
$$
P(success) = clamp\left( base + a \cdot gear + b \cdot skill + c \cdot level - d \cdot difficulty - e \cdot danger, P_{min}, P_{max} \right)
$$

Öneri:
- `P_min = 0.10` (asla 0 olmasın)
- `P_max = 0.95` (asla garanti olmasın; tutorial hariç)
- a=0.20, b=0.15, c=0.10, d=0.15, e=0.10

> Tutorial akışında (ilk görev) `P_max` override edilip "garantili başarı" uygulanabilir.

---

## 6.4 Kritik Başarısızlık (Hastanelik) Kararı
Başarısızlık olduğunda, özellikle zindan için hastanelik riski vardır.

### 6.4.1 Önerilen yaklaşım
- Başarısızlık olduğunda:
  - `P(hospital | fail)` görev tipine göre artar
  - Kolay/Orta: %0 (hastane yok)
  - Zor: %5
  - Zindan Solo: %15
  - Zindan Grup: %10 (grup güvenlik)

$$
P(hospital) = clamp\left( h_0 + h_1 \cdot danger + h_2 \cdot questRisk - h_3 \cdot armorDefense, 0, 1 \right)
$$

### 6.4.2 Hastane süresi
- Süre bandı görev tipine göre:
  - Zor görev: 1-2 saat
  - Zindan Solo: 2-6 saat
  - Zindan Grup: 3-8 saat (daha tehlikeli)

---

## 6.5 Hastaneden Çıkış Yolları (Suistimal Dayanımı)

### 6.5.1 Süre bekle (ücretsiz)
- `release_at` timestamp server'da

### 6.5.2 Gem harca
- Maliyet: `remaining_minutes × 3`
- Anti-abuse:
  - Günlük limit: 3 kez
  - Aynı hastanelikte sadece 1 kez

### 6.5.3 Hekim çağır
- Maliyet: 1,000–10,000 altın (kalan süreye göre)
- Başarı: %30–70 (hekim kalitesi/seviye)
- Başarı: kalan süre %50-80 azalır
- Başarısızlık: kalan süre +%50
- Cooldown: 1 deneme / hastanelik
- Server-side RNG + audit

### 6.5.4 Lonca yardımı
- Lonca üyeleri "heal" kullanabilir
- Her heal: süre -%20
- Günlük limit: 3 heal / lonca (toplam)
- Maliyetsiz

---

## 6.6 API Sözleşmeleri (Faza 6)

### Quest/Zindan
- `POST /v1/quest/start`
  - Body: `{ quest_id, loadout? }`
  - Response: `{ quest_instance_id, energy_cost, estimated_duration }`

- `POST /v1/quest/resolve`
  - Body: `{ quest_instance_id }`
  - Response: `{ success, rewards, loot, hospital? }`

### Hastane
- `GET /v1/hospital/status`
  - Response: `{ in_hospital, reason, admitted_at, release_at, remaining_minutes }`

- `POST /v1/hospital/early-release`
  - Body: `{ method: "gem" | "healer" | "guild_heal" }`
  - Response: `{ success, cost?, new_release_at }`

- `POST /v1/hospital/healer-attempt`
  - Body: `{ healer_id }`
  - Response: `{ success, roll, success_chance, time_reduced, cost }`

---

## 6.7 Veri Modeli (Postgres / Supabase)

### 6.7.1 Çekirdek tablolar
- `quests` (static metadata)
  - `id`, `name`, `type`, `energy_cost`, `base_success`, `min_level`, `danger_level`

- `quest_instances`
  - `id`, `player_id`, `quest_id`, `started_at`, `resolved_at`, `success`, `rewards`, `loot`, `hospitalized`

- `hospital_records`
  - `id`, `player_id`, `reason`, `admitted_at`, `release_at`, `early_release_method`, `healer_attempts`

- `loot_drops`
  - `quest_instance_id`, `item_id`, `quantity`, `rarity`

### 6.7.2 Ledger
- `ledger_entries`
  - Transaction kayıtları (enerji harcama, altın kazanma, item drop)

### 6.7.3 Security events
- `security_events`
  - Anomali tespiti (quest spam, hospital abuse)

---

## 6.8 Anti-Abuse ve Exploit Önlemleri
- **Quest spam:**
  - Rate limit: 10 quest start / dakika
  - Aynı anda max 3 aktif quest (paralel)
- **Hospital abuse:**
  - Gem early release: günlük 3 kez
  - Healer abuse: 1 deneme / hastanelik
- **Quest farming:**
  - Aynı quest tekrar: diminishing returns (3. tekrardan sonra -%30 ödül)

---

## 6.9 Telemetry
- quest_start → quest_resolve funnel
- quest_success_rate by type
- hospital_admission_rate by quest_type
- hospital_exit_method distribution (wait/gem/healer/guild)
- healer_success_rate distribution (anomali tespiti)

---

## 6.10 Definition of Done (Faza 6)
- [ ] Quest döngüsü uçtan uca çalışıyor (start/resolve/loot)
- [ ] Enerji tüketimi doğru
- [ ] Hastane sistemi uçtan uca çalışıyor (wait/gem/healer/guild)
- [ ] RNG + ledger + security_events kayıtları var
- [ ] Anti-abuse limitleri aktif
- [ ] Loot tabloları çalışıyor
- [ ] Başarı/hastanelik formülleri dengeli
- [ ] Telemetri dashboard operasyonel

---

**Son Güncelleme:** 2 Ocak 2026  
**Versiyon:** 2.0 (Ortaçağ + Enerji + Hastane Sistemi)
