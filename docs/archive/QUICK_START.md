# ⚡ QUICK START GUIDE - 15 TESİS SİSTEMİ

**5 Dakikada Deploy Et!**

---

## 🚀 3 ADIM

### ADIM 1: Database Deploy (2 dakika)

```powershell
# PowerShell'i aç
cd c:\Users\selçuk\Documents\gkk

# Supabase CLI'ye gir
supabase login

# Migration çalıştır
supabase db push database/migrations/015_facilities_system.sql

# ✅ Tamamlandı
```

**Alternative (GUI):**
- Supabase Dashboard açınız
- SQL Editor → New Query
- `database/migrations/015_facilities_system.sql` içeriğini paste et
- Run tıklayınız

---

### ADIM 2: RPC Functions Deploy (2 dakika)

```powershell
# supabase/functions/facilities/ klasöründe 10 fonksiyon var:

$functions = @(
    "get_player_facilities",
    "unlock_facility", 
    "start_facility_production",
    "collect_facility_production",
    "upgrade_facility",
    "increment_facility_suspicion",
    "bribe_officials",
    "reduce_facility_suspicion",
    "get_facility_recipes",
    "calculate_offline_production"
)

foreach ($func in $functions) {
    supabase functions deploy $func
    echo "✅ Deployed: $func"
}

# ✅ Tamamlandı
```

---

### ADIM 3: Godot Test (1 dakika)

```gdscript
# Godot Editor'de:
1. File → Open Scene
2. res://scenes/FacilitiesScreen.tscn aç
3. Play button tıkla (F5)
4. 15 tesisin grid'ini göreceksin

# ✅ DONE!
```

---

## 📋 DOSYA CHECKLIST

```
✅ database/migrations/015_facilities_system.sql (Deploy edilecek)
✅ supabase/functions/facilities/*.ts (10 dosya - Deploy edilecek)
✅ scenes/FacilitiesScreen.gd (Godot'ta import olacak)
✅ scenes/FacilitiesScreen.tscn (Scene file)
✅ scenes/components/FacilityCard.gd
✅ scenes/components/FacilityCard.tscn
✅ scenes/components/DetailModal.gd
✅ scenes/components/DetailModal.tscn
✅ scenes/ui/screens/CraftingScreen.gd (Güncellendi)
✅ core/managers/FacilityManager.gd (Güncellendi)
✅ core/data/ItemDatabase.gd (Güncellendi)
```

---

## 🎮 GAME FLOW

```
1. CraftingScreen aç
2. "Demirci" tesisini seç
3. "Demir Kılıç" tarifini seç
4. "Üret" tıkla
   ↓
   RPC: start_facility_production
   ↓
5. Queue'ye eklenir
6. Tamamlanınca "Topla"
   ↓
   RPC: collect_facility_production
   ↓
7. Inventory'ye eklenir
```

---

## 🧪 QUICK TEST

```gdscript
# Godot console'de çalıştırınız:

# Test 1: Facilities yükle
var result = await FacilityManager.fetch_my_facilities()
print("Facilities: ", result.success, result.data.size())

# Test 2: Mine'ı aç
var unlock = await FacilityManager.unlock_facility("mine")
print("Unlock: ", unlock.success)

# Test 3: Üretim başlat
var production = await FacilityManager.start_production("mine", "recipe_id", 1)
print("Production: ", production.success, production.data)

# Hepsi true/success dönerse = WORKING! ✅
```

---

## 🐛 TROUBLESHOOTING

| Sorun | Çözüm |
|-------|-------|
| "Auth failed" | State.user kontrol et |
| "Table not found" | Migration çalıştırıldı mı? |
| "RPC not found" | Functions deploy edildi mi? |
| "Scene not found" | .tscn dosyaları var mı? |
| "Empty data" | Database'de recipe data var mı? |

---

## ✅ SUCCESS INDICATORS

- [ ] Database migration hata vermedi
- [ ] 10 RPC function deployed
- [ ] FacilitiesScreen 60fps'de açılıyor
- [ ] Facility unlock çalışıyor
- [ ] Production start çalışıyor
- [ ] Suspicion artiyor
- [ ] Prison trigger oluyor

---

**READY? LET'S GO! 🚀**

```
Estimated deployment time: 5 minutes
Estimated testing time: 10 minutes
Total: 15 minutes to production ✅
```
