# Gölge Krallık: Kadim Mühür'ün Çöküşü
## Godot 4.x Proje Yapısı ve Mimari Dokümantasyonu

> Tarih: 2 Ocak 2026
> Engine: Godot 4.x
> Platform: Mobile (iOS/Android)
> Mimari: MVC-inspired, Signal-driven, Manager Pattern

---

## 📁 PROJE KLASÖR YAPISI

```
golge-krallik/
│
├── 📁 project.godot              # Godot proje dosyası
├── 📁 export_presets.cfg         # Export ayarları
├── 📁 .gitignore
├── 📁 README.md
│
├── 📂 autoload/                  # Singleton sistemler (Autoload)
│   ├── NetworkManager.gd         # HTTP/WebSocket yönetimi
│   ├── SessionManager.gd         # Auth & session
│   ├── StateStore.gd             # Global state cache
│   ├── RequestQueue.gd           # Offline/retry queue
│   ├── TelemetryClient.gd        # Analytics
│   ├── AudioManager.gd           # Müzik/SFX
│   ├── SceneManager.gd           # Scene geçişleri
│   └── ConfigManager.gd          # Server config
│
├── 📂 core/                      # Çekirdek sistemler
│   ├── 📂 network/
│   │   ├── HTTPClient.gd         # REST API wrapper
│   │   ├── WebSocketClient.gd    # WS wrapper
│   │   ├── APIEndpoints.gd       # Endpoint constants
│   │   └── RequestBuilder.gd     # Request helper
│   │
│   ├── 📂 data/
│   │   ├── PlayerData.gd         # Player model
│   │   ├── ItemData.gd           # Item model
│   │   ├── QuestData.gd          # Quest model
│   │   ├── MarketData.gd         # Market model
│   │   └── GuildData.gd          # Guild model
│   │
│   ├── 📂 managers/
│   │   ├── EnergyManager.gd      # Enerji sistemi
│   │   ├── PotionManager.gd      # İksir & bağımlılık
│   │   ├── InventoryManager.gd   # Envanter
│   │   ├── QuestManager.gd       # Görev sistemi
│   │   ├── PvPManager.gd         # PvP sistemi
│   │   ├── HospitalManager.gd    # Hastane
│   │   ├── MarketManager.gd      # Market
│   │   └── GuildManager.gd       # Lonca
│   │
│   └── 📂 utils/
│       ├── DateTimeUtils.gd      # Tarih/saat helper
│       ├── MathUtils.gd          # Matematik helper
│       ├── StringUtils.gd        # String helper
│       ├── ValidationUtils.gd    # Input validation
│       └── CryptoUtils.gd        # Şifreleme (XOR vb)
│
├── 📂 scenes/                    # Tüm sahneler
│   ├── 📂 main/
│   │   ├── Main.tscn             # Ana oyun sahne
│   │   ├── Main.gd
│   │   └── GameCanvas.tscn       # Oyun canvas container
│   │
│   ├── 📂 ui/                    # UI sahneleri
│   │   ├── 📂 screens/
│   │   │   ├── LoginScreen.tscn
│   │   │   ├── HomeScreen.tscn
│   │   │   ├── MapScreen.tscn
│   │   │   ├── InventoryScreen.tscn
│   │   │   ├── MarketScreen.tscn
│   │   │   ├── QuestScreen.tscn
│   │   │   ├── PvPScreen.tscn
│   │   │   ├── GuildScreen.tscn
│   │   │   ├── ProfileScreen.tscn
│   │   │   └── SettingsScreen.tscn
│   │   │
│   │   ├── 📂 dialogs/
│   │   │   ├── ConfirmDialog.tscn
│   │   │   ├── LoadingDialog.tscn
│   │   │   ├── ErrorDialog.tscn
│   │   │   ├── PotionUseDialog.tscn
│   │   │   ├── AttackDialog.tscn
│   │   │   └── HospitalDialog.tscn
│   │   │
│   │   ├── 📂 components/
│   │   │   ├── EnergyBar.tscn    # Enerji UI component
│   │   │   ├── ToleranceBar.tscn # Tolerans gösterge
│   │   │   ├── ItemCard.tscn     # Item görüntüleme
│   │   │   ├── QuestCard.tscn    # Görev kartı
│   │   │   ├── PlayerCard.tscn   # Oyuncu kartı
│   │   │   ├── ChatMessage.tscn  # Chat mesaj
│   │   │   └── Notification.tscn # Bildirim
│   │   │
│   │   └── 📂 hud/
│   │       ├── TopBar.tscn       # Üst bar (enerji, altın)
│   │       ├── BottomNav.tscn    # Alt navigasyon
│   │       └── QuickActions.tscn # Hızlı aksiyonlar
│   │
│   ├── 📂 gameplay/              # Gameplay sahneleri
│   │   ├── QuestBattle.tscn      # Görev savaş sahne
│   │   ├── PvPBattle.tscn        # PvP savaş sahne
│   │   ├── Anvil.tscn            # Geliştirme sahne
│   │   └── Hospital.tscn         # Hastane sahne
│   │
│   └── 📂 prefabs/               # Tekrar kullanılabilir
│       ├── Character.tscn        # Karakter prefab
│       ├── Enemy.tscn            # Düşman prefab
│       └── Effect.tscn           # Efekt prefab
│
├── 📂 scripts/                   # UI & Gameplay scripts
│   ├── 📂 screens/
│   │   ├── LoginScreen.gd
│   │   ├── HomeScreen.gd
│   │   ├── MapScreen.gd
│   │   ├── InventoryScreen.gd
│   │   ├── MarketScreen.gd
│   │   ├── QuestScreen.gd
│   │   ├── PvPScreen.gd
│   │   └── GuildScreen.gd
│   │
│   ├── 📂 components/
│   │   ├── EnergyBar.gd
│   │   ├── ToleranceBar.gd
│   │   ├── ItemCard.gd
│   │   └── QuestCard.gd
│   │
│   └── 📂 gameplay/
│       ├── QuestBattle.gd
│       ├── PvPBattle.gd
│       └── Anvil.gd
│
├── 📂 resources/                 # Resource dosyaları
│   ├── 📂 items/
│   │   ├── ItemResource.gd       # Item resource script
│   │   ├── weapon_template.tres  # Silah template
│   │   ├── armor_template.tres   # Zırh template
│   │   └── potion_template.tres  # İksir template
│   │
│   ├── 📂 quests/
│   │   ├── QuestResource.gd      # Quest resource script
│   │   └── quest_list.tres       # Quest listesi
│   │
│   ├── 📂 configs/
│   │   ├── GameConfig.gd         # Oyun config script
│   │   ├── game_balance.tres     # Balance değerleri
│   │   └── server_endpoints.tres # API endpoints
│   │
│   └── 📂 themes/
│       ├── default_theme.tres    # UI teması
│       └── fonts.tres            # Font ayarları
│
├── 📂 assets/                    # Tüm asset'ler
│   ├── 📂 sprites/
│   │   ├── 📂 characters/
│   │   │   ├── player/
│   │   │   └── enemies/
│   │   │
│   │   ├── 📂 items/
│   │   │   ├── weapons/
│   │   │   ├── armors/
│   │   │   └── potions/
│   │   │
│   │   ├── 📂 ui/
│   │   │   ├── buttons/
│   │   │   ├── icons/
│   │   │   └── backgrounds/
│   │   │
│   │   └── 📂 effects/
│   │       ├── particles/
│   │       └── animations/
│   │
│   ├── 📂 audio/
│   │   ├── 📂 music/
│   │   │   ├── menu_theme.ogg
│   │   │   ├── battle_theme.ogg
│   │   │   └── town_theme.ogg
│   │   │
│   │   └── 📂 sfx/
│   │       ├── ui_click.wav
│   │       ├── battle_hit.wav
│   │       ├── potion_drink.wav
│   │       └── level_up.wav
│   │
│   └── 📂 fonts/
│       ├── main_font.ttf
│       └── title_font.ttf
│
├── 📂 addons/                    # Godot eklentileri
│   └── (plugin klasörleri)
│
└── 📂 tests/                     # Test dosyaları (opsiyonel)
    └── unit/
        └── test_energy_system.gd
```

---

## 🔧 AUTOLOAD SİSTEMLERİ (Singleton)

Godot'ta Project Settings → Autoload'da kayıtlı singletonlar:

| Singleton | Path | Açıklama |
|-----------|------|----------|
| **Network** | `autoload/NetworkManager.gd` | HTTP/WS yönetimi |
| **Session** | `autoload/SessionManager.gd` | Auth & token |
| **State** | `autoload/StateStore.gd` | Global state |
| **Queue** | `autoload/RequestQueue.gd` | Offline queue |
| **Telemetry** | `autoload/TelemetryClient.gd` | Analytics |
| **Audio** | `autoload/AudioManager.gd` | Ses sistemi |
| **Scenes** | `autoload/SceneManager.gd` | Sahne geçişi |
| **Config** | `autoload/ConfigManager.gd` | Config cache |

---

## 📋 DOSYA İSİMLENDİRME KURALLARI

### Scene Dosyaları (.tscn)
- **PascalCase** kullan: `LoginScreen.tscn`, `EnergyBar.tscn`
- Anlamlı, açıklayıcı isimler
- Klasör ismi ile uyumlu

### Script Dosyaları (.gd)
- Scene ile **aynı isim**: `LoginScreen.gd`
- Manager'lar: `EnergyManager.gd`
- Utils: `DateTimeUtils.gd`

### Resource Dosyaları (.tres, .res)
- **snake_case** kullan: `game_balance.tres`
- Template'ler: `weapon_template.tres`

### Asset Dosyaları
- **snake_case** kullan: `player_idle.png`, `battle_theme.ogg`
- Açıklayıcı prefix: `ui_button_normal.png`

---

## 🏗️ MİMARİ YAPISI

### 1. Manager Pattern
Her sistem bir manager ile yönetilir:
- **EnergyManager:** Enerji hesaplama, yenilenme
- **PotionManager:** İksir kullanımı, tolerans, overdose
- **InventoryManager:** Envanter CRUD
- **QuestManager:** Görev başlatma/bitirme
- **PvPManager:** Saldırı, sonuç hesaplama
- **HospitalManager:** Hastane süresi, çıkış

### 2. Signal-Driven Communication
Manager'lar arası iletişim **signal** ile:
```gdscript
# EnergyManager.gd
signal energy_changed(new_value, max_value)
signal energy_depleted()

# PotionManager.gd
signal potion_used(potion_type, energy_restored)
signal tolerance_changed(new_tolerance)
signal overdose_occurred()
```

### 3. Data Models
Her veri tipi için ayrı class:
```gdscript
# PlayerData.gd
class_name PlayerData
extends Resource

var id: String
var name: String
var level: int
var current_energy: int
var max_energy: int
var tolerance: int
var gold: int
```

### 4. Network Layer
3 katmanlı network yapısı:
1. **NetworkManager:** Genel yönetim
2. **HTTPClient / WebSocketClient:** Transport
3. **APIEndpoints:** Endpoint tanımları

---

## 🎮 SAHNE AKIŞI

```
Splash (0.5s)
  ↓
LoginScreen
  ↓
HomeScreen ←→ MapScreen
  ↓            ↓
InventoryScreen  QuestScreen
  ↓            ↓
MarketScreen  PvPScreen
  ↓            ↓
GuildScreen  ProfileScreen
```

### Scene Geçiş Örneği
```gdscript
# SceneManager.gd kullanımı
Scenes.change_scene("res://scenes/ui/screens/HomeScreen.tscn")
Scenes.change_scene_with_loading("res://scenes/gameplay/QuestBattle.tscn")
```

---

## 💾 STATE YÖNETİMİ

### StateStore Yapısı
```gdscript
# StateStore.gd
var player: PlayerData
var inventory: Array[ItemData]
var active_quests: Array[QuestData]
var market_cache: Dictionary
var guild_info: GuildData

signal state_updated(key: String)
```

### Cache Stratejisi
- **player:** Her ekranda cache
- **inventory:** 30s TTL
- **market:** 10s TTL
- **quests:** 60s TTL

---

## 🔌 API ENTEGRASYON AKIŞI

### 1. Request Gönderme
```gdscript
# LoginScreen.gd
func _on_login_pressed():
    var body = {
        "username": username_input.text,
        "password": password_input.text
    }
    
    Network.post(APIEndpoints.LOGIN, body, _on_login_response)

func _on_login_response(result: Dictionary):
    if result.success:
        Session.set_tokens(result.data.access_token, result.data.refresh_token)
        Scenes.change_scene("res://scenes/ui/screens/HomeScreen.tscn")
    else:
        show_error(result.error_message)
```

### 2. WebSocket Subscribe
```gdscript
# HomeScreen.gd
func _ready():
    Network.ws_subscribe("market.ticker", _on_market_update)
    Network.ws_subscribe("chat.message", _on_chat_message)

func _on_market_update(data: Dictionary):
    update_market_ui(data)
```

---

## 🎨 UI COMPONENT PATTERN

### Tekrar Kullanılabilir Component
```gdscript
# EnergyBar.gd
extends Control
class_name EnergyBar

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label: Label = $Label

func update_energy(current: int, max: int):
    progress_bar.max_value = max
    progress_bar.value = current
    label.text = "%d / %d" % [current, max]
    
    # Renk değişimi
    if current < 20:
        progress_bar.modulate = Color.RED
    elif current < 50:
        progress_bar.modulate = Color.YELLOW
    else:
        progress_bar.modulate = Color.GREEN
```

### Component Kullanımı
```gdscript
# HomeScreen.gd
@onready var energy_bar: EnergyBar = $TopBar/EnergyBar

func _ready():
    EnergyManager.energy_changed.connect(_on_energy_changed)

func _on_energy_changed(current: int, max: int):
    energy_bar.update_energy(current, max)
```

---

## 🔐 GÜVENLİK UYGULAMALARI

### 1. Client-Side Değer Koruması (Basit)
```gdscript
# CryptoUtils.gd
static func xor_encrypt(value: int, key: int = 0x5A5A5A5A) -> int:
    return value ^ key

static func xor_decrypt(encrypted: int, key: int = 0x5A5A5A5A) -> int:
    return encrypted ^ key
```

### 2. Request İmzalama
```gdscript
# RequestBuilder.gd
func sign_request(body: Dictionary) -> String:
    var timestamp = Time.get_unix_time_from_system()
    var payload = JSON.stringify(body) + str(timestamp)
    return payload.sha256_text()
```

### 3. Session Yönetimi
```gdscript
# SessionManager.gd
var access_token: String
var refresh_token: String
var device_id: String

func auto_refresh():
    if is_token_expired():
        await refresh_access_token()
```

---

## 📱 MOBILE OPTİMİZASYONLAR

### 1. Touch Input
```gdscript
# Tüm butonlar minimum 44x44 dp
# SwipeDetector component kullan
```

### 2. Memory Management
```gdscript
# Scene değişiminde cache temizle
func _exit_tree():
    Network.cancel_pending_requests()
    clear_cached_resources()
```

### 3. Battery Optimization
```gdscript
# Background'da WS kapat
func _notification(what):
    match what:
        NOTIFICATION_APPLICATION_PAUSED:
            Network.disconnect_websocket()
        NOTIFICATION_APPLICATION_RESUMED:
            Network.connect_websocket()
```

---

## 🧪 TEST STRATEJİSİ

### Unit Test Örneği
```gdscript
# tests/unit/test_energy_system.gd
extends GutTest

func test_energy_regen():
    var manager = EnergyManager.new()
    manager.current_energy = 50
    manager.simulate_time(300) # 5 dakika
    assert_eq(manager.current_energy, 51, "5 dakikada 1 enerji yenilenmeli")
```

---

## 📝 GELİŞTİRME SİRASI

### Sprint 1 (Hafta 1-2): Temel Altyapı
- [ ] Proje kurulumu
- [ ] Autoload sistemleri
- [ ] Network layer (HTTP/WS)
- [ ] StateStore
- [ ] Scene geçiş sistemi

### Sprint 2 (Hafta 3-4): Enerji & İksir
- [ ] EnergyManager
- [ ] PotionManager
- [ ] EnergyBar component
- [ ] ToleranceBar component
- [ ] Potion kullanım UI

### Sprint 3 (Hafta 5-6): Auth & Home
- [ ] LoginScreen
- [ ] SessionManager
- [ ] HomeScreen
- [ ] TopBar/BottomNav
- [ ] Profile basics

### Sprint 4 (Hafta 7-8): Envanter & Market
- [ ] InventoryManager
- [ ] MarketManager
- [ ] InventoryScreen
- [ ] MarketScreen
- [ ] Item transaction

### Sprint 5 (Hafta 9-10): Görev Sistemi
- [ ] QuestManager
- [ ] QuestScreen
- [ ] QuestBattle scene
- [ ] Loot sistemi

### Sprint 6 (Hafta 11-12): PvP
- [ ] PvPManager
- [ ] PvPScreen
- [ ] PvPBattle scene
- [ ] Reputation sistemi

### Sprint 7 (Hafta 13-14): Hastane
- [ ] HospitalManager
- [ ] Hospital scene
- [ ] Healer sistem
- [ ] Guild heal

### Sprint 8 (Hafta 15-16): Lonca
- [ ] GuildManager
- [ ] GuildScreen
- [ ] Chat sistemi
- [ ] Guild features

---

## 🚀 EXPORT AYARLARI

### Android
```
Target SDK: 33
Min SDK: 21
Permissions: INTERNET, ACCESS_NETWORK_STATE
```

### iOS
```
Target iOS: 13.0+
Permissions: NSCameraUsageDescription (opsiyonel)
```

---

## 📚 BAĞIMLILIKLAR

### Godot Plugins (Önerilen)
- **HTTPRequest** (built-in)
- **WebSocketClient** (built-in)
- **Firebase Analytics** (addon)
- **AdMob** (addon, gelecek)

### External Services
- Supabase (backend)
- Firebase Analytics
- Discord (community)

---

**Bu yapı production-ready, ölçeklenebilir ve bakımı kolay bir mobil MMORPG projesi için tasarlanmıştır.**

**Versiyon:** 1.0  
**Tarih:** 2 Ocak 2026  
**Engine:** Godot 4.3+
