# 15 TESİS SİSTEMİ - TEST CHECKLIST

**Son Güncelleme:** 30 Ocak 2026  
**Durum:** DEPLOYMENT READY ✅

---

## 🧪 UNIT TESTS (Database Level)

### Database Setup Test
```sql
-- Supabase SQL Editor'de çalıştırınız

-- 1. Tabloların oluşturulup oluşturulmadığını kontrol et
SELECT COUNT(*) as table_count 
FROM pg_tables 
WHERE schemaname='public' 
AND tablename IN ('facilities', 'facility_recipes', 'facility_production_queue', 
                  'crafted_items_log', 'prison_records', 'facility_workers');
-- Beklenen: 6

-- 2. View'ları kontrol et
SELECT COUNT(*) as view_count 
FROM pg_views 
WHERE schemaname='public' 
AND viewname LIKE '%facility%' OR viewname LIKE '%prison%';
-- Beklenen: 4+

-- 3. RLS policy'leri kontrol et
SELECT COUNT(*) 
FROM pg_policies 
WHERE tablename='facilities';
-- Beklenen: 1+

-- 4. İnitial recipe data var mı?
SELECT COUNT(*) as recipe_count FROM facility_recipes;
-- Beklenen: 15+
```

### RPC Functions Test
```bash
# PowerShell'de çalıştırınız

# 1. get_player_facilities
curl -X POST "https://[PROJECT_ID].supabase.co/functions/v1/get_player_facilities" `
  -H "Authorization: Bearer [ANON_KEY]" `
  -H "Content-Type: application/json" `
  -d "{}"

# Beklenen çıktı:
# {"success":true,"data":[],"count":0}

# 2. unlock_facility
curl -X POST "https://[PROJECT_ID].supabase.co/functions/v1/unlock_facility" `
  -H "Authorization: Bearer [ANON_KEY]" `
  -H "Content-Type: application/json" `
  -d '{"p_facility_type":"mine"}'

# Beklenen çıktı:
# {"success":false,"error":"No auth ID found"} or
# {"success":true,"facility":{...},"gold_deducted":5000}
```

---

## 🎮 INTEGRATION TESTS (Godot Level)

### Test 1: FacilitiesScreen Loading
```
✓ Godot Editor'de FacilitiesScreen.tscn açınız
✓ Play butonuna basınız
✓ 15 tesisin 4 kategorisinde gösterildiğini kontrol et
✓ Her tesinin kartı gösterilmeli
✓ Kilitli tesislerin gri olduğunu kontrol et
```

### Test 2: Facility Unlock
```
✓ "Mine" tesisin "Aç" butonuna tıklayınız
✓ Confirmation dialog çıkmalı
✓ "Aç" butonuna basınız
✓ RPC çağrısı yapılmalı
✓ Grid yenilenmeli ve Mine artık yeşil olmalı
✓ Log çıktısını kontrol et: "[FacilitiesScreen] Facility unlocked: mine"
```

### Test 3: CraftingScreen Integration
```
✓ CraftingScreen.tscn açınız
✓ Üst kısımda facility tabs gösterilmeli
✓ "Demirci" sekmesini tıklayınız
✓ Tarifler liste'de gösterilmeli
✓ Bir tarifi seçiniz
✓ Malzemeler gösterilmeli
✓ "Üret" butonuna basınız
✓ RPC çağrısı yapılmalı
✓ Queue list yenilenmeli
```

### Test 4: Suspicion System
```
✓ 10 kez production başlatınız
✓ DetailModal'da suspicion artmalı
✓ Suspicion >= 80 olunca, Prison warning çıkmalı
✓ "Memurları Rüşvet Ver" butonu aktif olmalı
✓ Rüşvet buttonuna basınız (5 gem maliyeti)
✓ Suspicion azalmalı
```

### Test 5: Prison System
```
✓ Suspicion'u 80+ yapınız
✓ PrisonScreen açılmalı otomatik
✓ Prison countdown görünmeli
✓ "Kefalet Öde" butonu kullanılabilir olmalı
✓ 1-2 dakika bekleyiniz (test için hızlı bitsin diye)
✓ Otomatik release olmalı
✓ Suspicion reset olmalı (0)
```

### Test 6: Upgrade System
```
✓ DetailModal açınız
✓ "Upgrade" tabına gidiniz
✓ Upgrade cost gösterilmeli
✓ "Yükselt" butonuna basınız
✓ Level artmalı
✓ Grid yenilenmeli
✓ İşçi sayısı artmalı
```

### Test 7: Offline Production
```
✓ Production başlatınız (Mine)
✓ Game'i kapatınız
✓ 10+ saniye bekleyiniz (offline)
✓ Game'i açınız
✓ FacilitiesScreen'de queue'ye bakınız
✓ Tamamlanan items gösterilmeli
✓ "Topla" butonu aktif olmalı
```

### Test 8: Collection System
```
✓ Tamamlanan items'ı toplayınız
✓ Collection RPC çağrısı yapılmalı
✓ Inventory'ye ürün eklenmelicontrol et
✓ Queue temizlenmeli
```

---

## 📊 PERFORMANCE TESTS

### Load Test
```
✓ 15 facility grid 60fps'de render olmalı
✓ ScrollContainer smooth olmalı
✓ DetailModal açılması < 500ms olmalı
✓ RPC çağrısı < 2 saniye olmalı
```

### Memory Test
```
✓ FacilitiesScreen'i açıp kapatsınız (5 kez)
✓ Memory leak olmamalı
✓ UI elements temizlenmeli
```

---

## 🐛 EDGE CASE TESTS

### Test 1: Yetersiz Kaynaklar
```
✓ Altın < unlock cost olunca
  - Unlock butonu disabled olmalı
  - Error mesajı gösterilmeli
  
✓ Gem < 5 olunca
  - Rüşvet butonu disabled olmalı
  
✓ Malzeme < required olunca
  - Craft butonu disabled olmalı
```

### Test 2: Network Error
```
✓ Supabase'i devre dışı yapınız (test için)
✓ RPC call fail olmalı
✓ Error dialog gösterilmeli
✓ Retry seçeneği olmalı
```

### Test 3: Concurrent Operations
```
✓ 2 production'ı aynı anda başlatınız
✓ Queue'de ikisi de görülmeli
✓ Her ikisi de tamamlanmalı
```

### Test 4: Max Level Check
```
✓ Facility'yi 20 seviyeye yükseltiniz
✓ Upgrade butonu disabled olmalı
✓ "Max level" mesajı gösterilmeli
```

---

## ✅ SIGN-OFF CHECKLIST

- [ ] Database migration başarıyla çalıştı
- [ ] 10 RPC function deployed
- [ ] FacilitiesScreen yüklendi
- [ ] FacilityCard component'ler gösterildi
- [ ] DetailModal 4 tab açıldı
- [ ] CraftingScreen facility tabs gösterildi
- [ ] Facility unlock test geçildi
- [ ] Production start test geçildi
- [ ] Suspicion increment test geçildi
- [ ] Prison trigger test geçildi
- [ ] Facility upgrade test geçildi
- [ ] Collection system test geçildi
- [ ] Performance test geçildi
- [ ] Edge cases test geçildi
- [ ] No memory leaks
- [ ] No console errors
- [ ] All signals connected
- [ ] Network calls working

---

## 🎯 SUCCESS CRITERIA

```
✅ All systems working together
✅ No database errors
✅ No RPC failures
✅ No UI crashes
✅ Smooth 60fps gameplay
✅ All features functional
✅ Ready for production
```

---

**TEST DATE:** _____________  
**TESTER NAME:** _____________  
**PASS/FAIL:** _____________  

**Notes:**
```
[Space for notes]
```
