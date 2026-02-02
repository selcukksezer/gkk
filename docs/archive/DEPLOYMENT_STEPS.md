## DEPLOYMENT CHECKLIST - Tek tek adımlar

### ✅ Step 1: FacilityManager Fixed
- `core/managers/FacilityManager.gd` - Clean version aktif, duplicate funcs kaldırıldı
- Scene referansları fixed (.tscn files)
- Ready: Network.http_post() calls implemented

### 🔴 Step 2: SQL Migration Deploy (SEN YAP!)

**Dosya:** `database/migrations/015_facilities_system.sql`

**2A: Supabase Dashboard Method (Easiest)**
1. Aç: https://app.supabase.com/projects/znvsyzstmxhqvdkkmgdt/sql/new
2. Tüm migration dosyasını kopyala
3. Paste et SQL Editor'a
4. "Run" butonuna bas
5. Expected: "Success" mesajı

**OR 2B: CLI Method**
```bash
cd c:\Users\selçuk\Documents\gkk
supabase db push database/migrations/015_facilities_system.sql --project-ref znvsyzstmxhqvdkkmgdt
```

### Expected Result
✅ 6 tables created: facilities, facility_recipes, facility_production_queue, etc.
✅ 4 views created: active_production_queue, ready_to_collect, etc.
✅ 7 RPC functions created in PostgreSQL
✅ RLS policies enabled

---

### 📋 Step 3: RPC Functions Deploy (Supabase Edge Functions)

**Supabase CLI Command:**
```bash
cd c:\Users\selçuk\Documents\gkk

# Deploy all 10 facilities functions
supabase functions deploy --project-ref znvsyzstmxhqvdkkmgdt get_player_facilities
supabase functions deploy --project-ref znvsyzstmxhqvdkkmgdt unlock_facility
supabase functions deploy --project-ref znvsyzstmxhqvdkkmgdt start_facility_production
supabase functions deploy --project-ref znvsyzstmxhqvdkkmgdt collect_facility_production
supabase functions deploy --project-ref znvsyzstmxhqvdkkmgdt upgrade_facility
supabase functions deploy --project-ref znvsyzstmxhqvdkkmgdt increment_facility_suspicion
supabase functions deploy --project-ref znvsyzstmxhqvdkkmgdt bribe_officials
supabase functions deploy --project-ref znvsyzstmxhqvdkkmgdt reduce_facility_suspicion
supabase functions deploy --project-ref znvsyzstmxhqvdkkmgdt get_facility_recipes
supabase functions deploy --project-ref znvsyzstmxhqvdkkmgdt calculate_offline_production
```

**OR Deploy via Dashboard:**
1. Aç: https://app.supabase.com/projects/znvsyzstmxhqvdkkmgdt/functions
2. "+ Create a new function" butonuna bas
3. Her .ts file'ı copy-paste et:
   - supabase/functions/facilities/get_player_facilities.ts
   - supabase/functions/facilities/unlock_facility.ts
   - ... (all 10 files)

---

### 🎮 Step 4: Godot Testing (Ben yapacağım)

```bash
cd c:\Users\selçuk\Documents\gkk
"C:\Users\selçuk\Desktop\godot2.exe" project.godot

# In Godot:
1. Open Scene > FacilitiesScreen.tscn
2. Press F5 to play
3. Check Console for Network calls
4. Verify facilities load
```

---

## 🔑 CRITICAL: API Paths

FacilityManager.gd'de RPC calls şöyle:
```gdscript
Network.http_post("/functions/v1/facilities/get_player_facilities", {})
```

Supabase expects functions at:
```
https://znvsyzstmxhqvdkkmgdt.supabase.co/functions/v1/facilities/get_player_facilities
```

✅ This is already correct in FacilityManager

---

## ⏱️ Timeline

**Step 1 (SQL Deploy):** 2 dakika
**Step 2 (RPC Deploy):** 3 dakika  
**Step 3 (Godot Test):** 5 dakika
**Total:** ~10 dakika

**→ Oyun çalışır halde!**

---

## ❓ If Something Goes Wrong

**SQL Deploy Failed?**
- Check: `database/migrations/015_facilities_system.sql` exists
- Run: `supabase status` → Linked project check

**RPC Deploy Failed?**
- Check: `supabase/functions/facilities/*.ts` all exist (10 files)
- Auth: `supabase login` → Re-authenticate

**Godot Won't Load Scenes?**
- Check: `scenes/FacilitiesScreen.gd` exists
- Check: `core/managers/FacilityManager.gd` exists
- Godot → Tools → Clear Cache

---

## 📞 Questions?

FacilityManager signals:
- facilities_updated
- facility_unlocked
- production_started
- suspicion_changed

All connected in FacilitiesScreen.gd → DetailModal.gd → FacilityCard.gd

Everything ready. Next: Deploy SQL!
