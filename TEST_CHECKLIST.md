# Quick Test Checklist - Inventory & Equipment System

## ✅ Pre-Test: Migration Applied?
- [ ] `00_MASTER_FIX_ALL.sql` çalıştırıldı mı?
- [ ] Migration başarılı mesajı alındı mı?
- [ ] Supabase Dashboard SQL Editor'de unique constraints görünüyor mu?

## 🧪 Test Scenarios

### 1. Basic Equip (Empty Slot)
**Adımlar:**
1. Inventory'de bir equipment item seç (örn: kılıç)
2. Double-click veya equipment slot'a sürükle
3. **Beklenen:** Item anında inventory'den kaybolmalı, equipment'te görünmeli
4. **Kontrol:** F5 ile yenile → Item hala equipment'te mi?
- [ ] ✅ Passed / ❌ Failed

### 2. Swap Equip (Occupied Slot)
**Adımlar:**
1. Bir kılıç zaten equipli
2. Başka bir kılıcı equipment slot'a sürükle
3. **Beklenen:** Eski kılıç inventory'ye dönmeli, yeni kılıç equipli olmalı
4. **Kontrol:** İki kılıç da görünüyor mu? (biri equipment, biri inventory)
- [ ] ✅ Passed / ❌ Failed

### 3. Full Inventory Swap (20/20)
**Adımlar:**
1. Inventory'yi 20 item'le doldur
2. Equipment slot'ta bir item olsun
3. Inventory'den başka bir item'ı o equipment slot'a sürükle
4. **Beklenen:** "Inventory Full" hatası ÇIKMAMALI, swap başarılı olmalı
5. **Kontrol:** Eski equipped item inventory'de göründü mü?
- [ ] ✅ Passed / ❌ Failed

### 4. Unequip to Specific Slot
**Adımlar:**
1. Equipment'te bir item seç
2. Inventory'de boş bir slot'a sürükle
3. **Beklenen:** Item o slota gelsin
4. **Kontrol:** Doğru slotta mı?
- [ ] ✅ Passed / ❌ Failed

### 5. Inventory Swap (Grid Items)
**Adımlar:**
1. Inventory'de iki item'ı swap et (sürükle-bırak)
2. **Beklenen:** Anında yer değiştirmeli
3. **Kontrol:** F5 sonrası pozisyonlar korunuyor mu?
- [ ] ✅ Passed / ❌ Failed

### 6. Trash (Delete Equipped Item)
**Adımlar:**
1. Equipment'ten bir item'ı trash slot'a sürükle
2. Confirm dialog'da "Evet" seç
3. **Beklenen:** Item anında kaybolmalı (equipment + database)
4. **Kontrol:** F5 sonrası item geri geldi mi? (Gelmemeli!)
- [ ] ✅ Passed / ❌ Failed

### 7. Ghost Item Check
**Adımlar:**
1. Herhangi bir item'ı equip et
2. Oyundan çık
3. Tekrar gir
4. **Beklenen:** Item sadece equipment'te olmalı, inventory'de OLMAMALI
5. **Kontrol:** Inventory'de ghost item var mı?
- [ ] ✅ Passed / ❌ Failed

### 8. Stacking Check
**Adımlar:**
1. Inventory'de her slotu kontrol et
2. **Beklenen:** Hiçbir slotta birden fazla item overlay olmamalı
3. **Kontrol:** Görsel stacking bug var mı?
- [ ] ✅ Passed / ❌ Failed

### 9. Network Failure Rollback
**Adımlar:**
1. Internet bağlantısını kes (veya Supabase'i durdur)
2. Bir item'ı equip etmeye çalış
3. **Beklenen:** UI güncellenir ama sonra rollback yapılır + hata mesajı
4. **Kontrol:** Item eski yerinde mi?
- [ ] ✅ Passed / ❌ Failed

### 10. Rapid Actions (Stress Test)
**Adımlar:**
1. 5 item'ı hızlıca swap et
2. 2 item'ı hızlıca equip/unequip et
3. **Beklenen:** Hiçbir item kaybolmamalı, hepsi doğru yerde olmalı
4. **Kontrol:** F5 sonrası count doğru mu? Ghost yok mu?
- [ ] ✅ Passed / ❌ Failed

## 🐛 Bug Report Template

Eğer test fail ederse:

```
❌ Test #[numara] Failed: [Test adı]

Adımlar:
1. ...
2. ...

Beklenen:
...

Gerçekleşen:
...

Console Log:
```
[log buraya]
```

Screenshot:
[ekran görüntüsü]
```

## 📊 Success Criteria

**Tüm testler PASS olmalı:**
- [ ] 1. Basic Equip
- [ ] 2. Swap Equip
- [ ] 3. Full Inventory Swap
- [ ] 4. Unequip to Slot
- [ ] 5. Inventory Swap
- [ ] 6. Trash
- [ ] 7. Ghost Item Check
- [ ] 8. Stacking Check
- [ ] 9. Rollback
- [ ] 10. Rapid Actions

**Pass Oranı: ___/10**

## ✅ Final Approval

- [ ] Tüm testler passed
- [ ] Console'da error yok
- [ ] Ghost items yok
- [ ] Stacking bugs yok
- [ ] Performance iyi

**Status:** ⬜ Pending / ✅ Approved / ❌ Needs Fix

**Tester:** _______________
**Date:** _______________

---

**NOT:** Eğer herhangi bir test fail ederse, IMPLEMENTATION_SUMMARY.md dosyasındaki "Sorun Giderme" bölümüne bakın.
