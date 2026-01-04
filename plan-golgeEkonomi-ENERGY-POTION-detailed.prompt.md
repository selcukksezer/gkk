# Gölge Ekonomi — Enerji & İksir Bağımlılık Sistemi (Detaylı Belge)

> Oyun: Gölge Krallık: Kadim Mühür'ün Çöküşü
> Amaç: Enerji mekanizması, iksir kullanımı, bağımlılık, overdose ve tedavi sisteminin teknik detayları

---

## 1. ENERJİ SİSTEMİ DETAYI

### 1.1 Enerji Parametreleri
```
max_energy: 100 (base, upgrade ile artabilir)
regen_rate: 1 enerji / 5 dakika (288 enerji/gün)
natural_cap: max_energy (doğal olarak daha fazla dolmaz)
```

### 1.2 Enerji Tüketimi
| Aktivite | Enerji Maliyeti |
|----------|-----------------|
| Kolay görev | 5-10 |
| Orta görev | 10-15 |
| Zor görev | 15-20 |
| Zindan (solo) | 20-30 |
| Zindan (grup) | 25-40 |
| PvP saldırı | 15 |
| PvP misilleme | 0 (bedava) |
| Kaynak toplama | 5-10 |
| Bölge seyahat | 5-10 |

### 1.3 Enerji Hesaplama (Server-side)
**Doğal yenilenme algoritması:**
```python
def calculate_energy(player):
    now = datetime.now()
    last_update = player.energy_last_update
    elapsed_minutes = (now - last_update).total_seconds() / 60
    
    regen_amount = int(elapsed_minutes / 5)  # 1 per 5 min
    new_energy = min(player.current_energy + regen_amount, player.max_energy)
    
    player.current_energy = new_energy
    player.energy_last_update = now
    return new_energy
```

### 1.4 Enerji UI/UX
**Client görünümü:**
- Enerji bar (mevcut/maksimum)
- Sonraki yenilenmeye kalan süre
- Tahmini tam dolma süresi
- Düşük enerji uyarısı (<20)

**Bildirimler:**
- Enerji %50'ye ulaştı
- Enerji tam doldu
- Enerji tükendi (<5)

---

## 2. İKSİR SİSTEMİ DETAYI

### 2.1 İksir Tipleri ve Özellikleri
| İksir | Enerji Restorasyonu | Tolerans Artışı | Üretim Süresi | Nadirlık |
|-------|---------------------|-----------------|---------------|----------|
| Minör İyileştirme | +20 | +2 | 30 dk | Temel |
| Büyük İyileştirme | +50 | +5 | 1 saat | Uncommon |
| Yüce İyileştirme | +100 (max doldurur) | +10 | 2 saat | Nadir |
| Antidot | Enerji yok | -30 tolerans | 4 saat | Epic |

### 2.2 İksir Kullanımı Kuralları
**Temel kurallar:**
- İksir kullanımı anında etkilidir (gecikme yok)
- Enerji max'ı geçemez (overflow kaybolur)
- Cooldown yok (spam kullanılabilir, ama risk artar)
- Stack limit: 500 adet (envanter toplam)

**Server-side validation:**
```python
def use_potion(player, potion_instance_id):
    # 1. Ownership check
    potion = get_item(potion_instance_id)
    if potion.owner_id != player.id:
        return error("Not your potion")
    
    # 2. Calculate current tolerance
    tolerance = get_tolerance(player)
    
    # 3. Check overdose risk
    overdose_risk = calculate_overdose_risk(tolerance, potion.type)
    if random.random() < overdose_risk:
        # OVERDOSE!
        hospitalize(player, reason="overdose", duration=random.randint(120, 720))
        consume_item(potion)
        log_event("overdose", player, potion)
        return {"overdose": True, "hospitalized": True}
    
    # 4. Calculate effectiveness
    effectiveness = calculate_effectiveness(tolerance)
    energy_restored = int(potion.energy_value * effectiveness)
    
    # 5. Apply energy
    new_energy = min(player.current_energy + energy_restored, player.max_energy)
    player.current_energy = new_energy
    
    # 6. Increase tolerance
    new_tolerance = min(tolerance + potion.tolerance_increase, 100)
    set_tolerance(player, new_tolerance)
    
    # 7. Consume item
    consume_item(potion)
    
    # 8. Ledger & telemetry
    log_ledger("potion_use", player, potion, energy_restored)
    log_event("potion_used", player, potion, tolerance)
    
    return {
        "success": True,
        "energy_restored": energy_restored,
        "new_energy": new_energy,
        "tolerance_increase": potion.tolerance_increase,
        "new_tolerance": new_tolerance,
        "effectiveness": effectiveness
    }
```

---

## 3. BAĞIMLILIK (TOLERANCE) SİSTEMİ

### 3.1 Tolerans Mekanizması
**Tolerans değeri:** 0-100 aralığında integer

**Tolerans artışı:**
- Her iksir kullanımında artış (iksir tipine göre)
- Lineer artış (kümülatif)

**Tolerans azalması:**
- Doğal azalma: -1 / 6 saat (iksir kullanılmazsa)
- Antidot: -30 (anında)
- Hekim tedavisi: -50 (ücretli + süre)

### 3.2 Tolerans Eşikleri ve Etkileri
| Tolerans | Durum | İksir Etkisi | Overdose Riski | UI Renk |
|----------|-------|--------------|----------------|---------|
| 0-30 | Sağlıklı | %100 | %0 | Yeşil |
| 31-60 | Hafif Tolerans | %80 | %0 | Sarı |
| 61-80 | Bağımlı | %50 | %5 + (tolerance-60)×0.5% | Turuncu |
| 81-95 | Ağır Bağımlı | %20 | %10 + (tolerance-80)×1% | Kırmızı |
| 96-100 | Kritik | %10 | %20 + (tolerance-95)×2% | Koyu Kırmızı |

### 3.3 Etkililik Hesaplama
```python
def calculate_effectiveness(tolerance):
    if tolerance <= 30:
        return 1.0
    elif tolerance <= 60:
        return 0.8
    elif tolerance <= 80:
        return 0.5
    elif tolerance <= 95:
        return 0.2
    else:
        return 0.1
```

### 3.4 Tolerans Doğal Azalma
```python
def apply_natural_decay(player):
    now = datetime.now()
    last_use = player.last_potion_use
    
    if last_use is None:
        return
    
    hours_since_use = (now - last_use).total_seconds() / 3600
    decay_amount = int(hours_since_use / 6)  # -1 per 6 hours
    
    new_tolerance = max(player.tolerance - decay_amount, 0)
    player.tolerance = new_tolerance
    
    if decay_amount > 0:
        log_event("tolerance_decay", player, decay_amount)
```

---

## 4. OVERDOSE (AŞIRI DOZ) SİSTEMİ

### 4.1 Overdose Risk Hesaplama
```python
def calculate_overdose_risk(tolerance, potion_type):
    if tolerance < 61:
        return 0.0  # No risk below threshold
    
    # Base risk by tolerance
    if 61 <= tolerance <= 80:
        base_risk = 0.05 + (tolerance - 60) * 0.005  # 5% to 15%
    elif 81 <= tolerance <= 95:
        base_risk = 0.10 + (tolerance - 80) * 0.01   # 10% to 25%
    else:  # 96-100
        base_risk = 0.20 + (tolerance - 95) * 0.02   # 20% to 30%
    
    # Potion type multiplier
    potion_multipliers = {
        "minor": 1.0,
        "major": 1.5,
        "supreme": 2.0
    }
    
    multiplier = potion_multipliers.get(potion_type, 1.0)
    
    return min(base_risk * multiplier, 0.50)  # Cap at 50%
```

### 4.2 Overdose Sonuçları
**Hastanelik:**
- Süre: 2-12 saat (tolerans seviyesine göre)
- Formül: `duration = 120 + (tolerance - 60) × 8`
- Min: 2 saat, Max: 12 saat

**Overdose sırasında:**
- İksir tüketilir (kayıp)
- Enerji restorasyonu OLMAZ
- Tolerans artışı olur (ironi: daha kötüleşir)
- Ledger kaydı
- Security event (abuse tespiti için)

**UI feedback:**
- Dramatik animasyon (ekran titreme, kararma)
- "AŞIRI DOZ!" mesajı
- Hastane ekranına geçiş
- Tolerans seviyesi gösterimi

---

## 5. TEDAVİ SİSTEMİ

### 5.1 Antidot Kullanımı
**Özellikleri:**
- Tolerans -30 (anında)
- Enerji restorasyonu YOK
- Nadir item (pahalı)
- Üretim: high-level simya (4 saat)

**Kullanım stratejisi:**
- Oyuncu tolerans 60+ olduğunda kullanmalı
- Overdose riskini azaltır
- Ekonomik maliyet (market fiyatı yüksek)

### 5.2 Hekim Tedavisi
**NPC Hekim:**
- Şehirlerde bulunur
- Maliyet: 5,000-20,000 altın (toleransa göre)
- Süre: 30 dakika (offline beklenebilir)
- Sonuç: tolerans -50
- Tek seferlik (cooldown: 24 saat)

**Hekim API:**
```
POST /v1/treatment/healer
Body: {
  healer_id: "uuid"
}
Response: {
  success: true,
  cost: 10000,
  treatment_duration_minutes: 30,
  complete_at: "2026-01-02T11:00:00Z",
  tolerance_reduction: 50
}
```

**Tedavi sırasında:**
- Oyuncu aktivite yapabilir (görev/pazar)
- Belirli süre sonra tolerans azalır
- Bildirim: "Tedavi tamamlandı!"

### 5.3 Doğal İyileşme (Pasif)
- En ucuz yöntem: bekleme
- 6 saatte -1 tolerans
- Oyuncu iksir kullanmazsa otomatik

---

## 6. ANTİ-ABUSE & EXPLOIT ÖNLEME

### 6.1 İksir Spam Önleme
**Günlük limit:**
- Max 200 iksir kullanımı / gün
- Aşılırsa: soft warning + risk flag

**Anomali tespiti:**
- Dakikada 10+ iksir kullanımı → risk score
- Saatte 50+ iksir → security event
- Pattern: tekrar eden overdose → suspect

### 6.2 Tolerans Manipülasyonu
**Korunan değer:**
- Tolerans değeri sadece server'da
- Client'a güvenilmez
- Her iksir kullanımında server hesaplar

**Ledger zorunlu:**
- Her iksir kullanımı log
- Tolerans değişimi log
- Overdose kayıt
- Antidot kullanımı log

### 6.3 Hastane Abuse
**Gem spam önleme:**
- Günlük 3 kez limit (early release)
- Aynı hastanelikte 1 kez

**Overdose farming:**
- Aynı oyuncu günde 5+ overdose → ban risk
- Pattern: kasıtlı overdose → manual review

---

## 7. TELEMETRİ & ANALYTİCS

### 7.1 Kritik Metrikler
**Enerji:**
- Ortalama enerji seviyesi (hedef: 40-60)
- Günlük enerji tüketimi
- Enerji tam dolma oranı (% oyuncular)

**İksir:**
- Günlük iksir kullanımı (tip bazlı)
- İksir üretimi vs tüketimi
- Market fiyat trendi

**Tolerans:**
- Tolerans dağılımı (histogram)
- %'si oyuncular tolerans >60
- Ortalama tolerans

**Overdose:**
- Günlük overdose sayısı
- Overdose oranı (% aktif oyuncu)
- Ortalama hastane süresi (overdose)

**Tedavi:**
- Antidot kullanım oranı
- Hekim kullanım oranı
- Doğal iyileşme oranı

### 7.2 Dashboard Alarmları
- Overdose rate > %5/gün → ALARM
- Ortalama tolerans > 55 → WARNING
- İksir fiyatı 3x artış <12h → ALARM
- Antidot supply < demand × 2 → WARNING

### 7.3 A/B Test Parametreleri
Oyun dengesi için test edilebilir:
- Tolerans artış hızı (±%20)
- Overdose risk formülü (±%30)
- Doğal azalma hızı (±50%)
- Antidot etkisi (±%20)
- İksir etkililik eğrisi

---

## 8. OPERASYON PLAYBOOK

### Durum 1: Yüksek Overdose Oranı
**Belirti:** Overdose > %8/gün

**Aksiyon:**
1. Antidot drop rate 2x artır (48 saat)
2. Hekim NPC indirim %50 (72 saat)
3. UI uyarı mesajı güçlendir
4. Quest: "Sağlık Kampanyası" (ödül: antidot)
5. Discord/in-game announcement

### Durum 2: Düşük İksir Kullanımı
**Belirti:** İksir kullanımı <50 adet/aktif oyuncu/gün

**Aksiyon:**
1. Enerji tüketim aktiviteleri artır (event)
2. İksir drop rate artır
3. Enerji regen hızı azalt (geçici)
4. PvP/quest teşvik

### Durum 3: Tolerans Salgını
**Belirti:** %40+ oyuncular tolerans >60

**Aksiyon:**
1. Hekim ücreti düşür
2. Antidot recipe daha kolay ulaşılır
3. Awareness campaign
4. Doğal azalma hızını artır (balance patch)

---

## 9. UX/UI DETAYLARI

### 9.1 Enerji Bar
- Ana ekranda her zaman görünür
- Renk: Yeşil (>50) → Sarı (20-50) → Kırmızı (<20)
- Animasyon: dolma/azalma smooth
- Tap: detay popup (sonraki yenilenme, tam dolma süresi)

### 9.2 Tolerans Göstergesi
- İlk iksir kullanımından sonra aktif
- İcon: iksir şişesi + tolerans bar
- Renk: Yeşil → Sarı → Turuncu → Kırmızı
- Tooltip: durum açıklaması + etki
- Warning: tolerans >60 olduğunda belirgin uyarı

### 9.3 İksir Kullanım Onayı
**Tolerans <60:**
- Tek tap kullanım (hızlı)

**Tolerans 60-80:**
- Onay popup: "Dikkat! Bağımlılık riski arttı."
- Checkbox: "Bir daha gösterme" (session)

**Tolerans >80:**
- Zorunlu onay: "UYARI! Overdose riski yüksek!"
- İki kez onaylama (accidental use önleme)
- Checkbox yok (her seferinde göster)

### 9.4 Overdose Animasyonu
- Ekran sallama
- Kırmızı vignet effect
- Slow motion
- "AŞIRI DOZ!" büyük yazı
- Fade to black
- Hastane ekranı açılır

---

## 10. DEFINITION OF DONE

- [ ] Enerji hesaplama server-side çalışıyor
- [ ] İksir kullanımı doğru enerji restore ediyor
- [ ] Tolerans artışı/azalışı doğru
- [ ] Overdose risk hesaplama doğru
- [ ] Overdose → hastanelik akışı çalışıyor
- [ ] Antidot kullanımı tolerans azaltıyor
- [ ] Hekim tedavisi çalışıyor
- [ ] Günlük limitler aktif
- [ ] Ledger her işlemi kaydediyor
- [ ] Telemetri dashboard operasyonel
- [ ] UI/UX feedbackler net ve anlaşılır
- [ ] Anti-abuse sinyalleri çalışıyor

---

**Son Güncelleme:** 2 Ocak 2026  
**Versiyon:** 2.0 (Enerji & İksir Bağımlılık Sistemi)
