# Gölge Ekonomi — Plan Detaylandırma (Part 02)

> Kaynak: plan-golgeEkonomi-part-02.prompt.md
> Oyun: Gölge Krallık: Kadim Mühür'ün Çöküşü
> Amaç: Server-Client mimarisi, güvenlik sistemleri ve ilk 30 dakika deneyimi için teknik detaylar

---

## FAZA 3 — SERVER-CLIENT MİMARİSİ (Hafta 11-16)

### 3.1 Mimari Tasarım Prensipleri
**Server-Authoritative Model:**
- Tüm kritik kararlar server'da
- Client sadece UI/UX ve görselleştirme
- Offline oynanabilirlik: sınırlı (sadece okuma)

**Katmanlı Mimari:**
```
┌─────────────────────────────────────┐
│  CLIENT (Godot 4.x)                 │
│  ├── Presentation Layer             │
│  ├── Local Cache (Dictionary)       │
│  ├── Network Manager (Autoload)     │
│  └── Session Manager                │
└──────────────┬──────────────────────┘
               │ HTTPS + WSS
┌──────────────┴──────────────────────┐
│  API GATEWAY (Supabase Edge)        │
│  ├── Rate Limiting                  │
│  ├── Authentication                 │
│  ├── Request Routing                │
│  └── Response Caching               │
└──────────────┬──────────────────────┘
               │
┌──────────────┴──────────────────────┐
│  BUSINESS LOGIC (Edge Functions)    │
│  ├── Energy Manager                 │
│  ├── Quest Manager                  │
│  ├── PvP Manager                    │
│  ├── Market Manager                 │
│  └── Hospital Manager               │
└──────────────┬──────────────────────┘
               │
┌──────────────┴──────────────────────┐
│  DATA LAYER                         │
│  ├── PostgreSQL (Supabase)          │
│  ├── Redis (Cache/Session)          │
│  └── Realtime (WebSocket)           │
└─────────────────────────────────────┘
```

### 3.2 Network Protokolleri

#### 3.2.1 REST API (HTTPRequest)
**Kullanım alanları:**
- CRUD işlemleri (envanter, ekipman)
- Tek seferlik eylemler (görev başlatma, PvP saldırısı)
- State sorgulamaları
- Async işlemler (uzun süren görevler)

**Request format:**
```json
{
  "headers": {
    "Authorization": "Bearer <JWT>",
    "Content-Type": "application/json",
    "X-Device-ID": "uuid",
    "X-Session-ID": "uuid",
    "X-Client-Version": "1.0.0"
  },
  "body": {
    "action": "use_potion",
    "params": {...}
  }
}
```

**Response format:**
```json
{
  "success": true,
  "data": {...},
  "meta": {
    "timestamp": "2026-01-03T10:30:00Z",
    "request_id": "uuid"
  },
  "error": null
}
```

#### 3.2.2 WebSocket (Real-time)
**Kullanım alanları:**
- Fiyat güncellemeleri (market)
- Chat mesajları
- Enerji yenilenmesi
- PvP bildirimleri
- Lonca aktiviteleri

**Connection:**
```gdscript
var ws = WebSocketPeer.new()
var url = "wss://api.golgeekono.mi/realtime/v1"
ws.connect_to_url(url + "?token=" + jwt_token)
```

**Message format:**
```json
{
  "type": "energy_update",
  "payload": {
    "player_id": "uuid",
    "new_energy": 85,
    "timestamp": "2026-01-03T10:30:00Z"
  }
}
```

#### 3.2.3 Hibrit Yaklaşım
**Hangi veriyi nasıl çekeriz:**

| Veri Tipi | Protokol | Güncelleme Frekansı | Latency |
|-----------|----------|---------------------|---------|
| Enerji durumu | WebSocket | Real-time (5sn) | <1s |
| Envanter | REST | On-demand | 1-3s |
| Market fiyatları | WebSocket | Real-time (1sn) | <500ms |
| Chat | WebSocket | Real-time | <500ms |
| Görev sonucu | REST → Push | Async | 3-10s |
| PvP sonucu | REST → Push | Async | 3-10s |
| Lonca bildirim | WebSocket | Real-time | <1s |
| Hastane durumu | WebSocket | Real-time (60sn) | <2s |

### 3.3 Authentication & Session Management

#### 3.3.1 JWT Token Sistemi
**Token yapısı:**
- **Access token:** 15 dakika TTL
- **Refresh token:** 7 gün TTL

**Token payload:**
```json
{
  "sub": "player_uuid",
  "iat": 1704276000,
  "exp": 1704276900,
  "device_id": "uuid",
  "session_id": "uuid",
  "roles": ["player"]
}
```

#### 3.3.2 Device Fingerprinting
**Toplanacak bilgiler:**
```gdscript
func get_device_fingerprint() -> Dictionary:
    return {
        "os": OS.get_name(),
        "model": OS.get_model_name(),
        "unique_id": OS.get_unique_id(),
        "screen_size": DisplayServer.screen_get_size(),
        "locale": OS.get_locale()
    }
```

**Anti-abuse:**
- Maksimum 3 eşzamanlı cihaz
- Yeni cihaz → email/SMS onayı
- Şüpheli cihaz → captcha

#### 3.3.3 Session Management
**Session timeout:**
- Aktif kullanım: 4 saat
- İnaktif: 30 dakika
- Background: 5 dakika

**Session refresh flow:**
```
Client                Server
  |                     |
  |-- API Request ----->|
  |                     | (Access token geçersiz)
  |<-- 401 Unauthorized-|
  |                     |
  |-- Refresh Token --->|
  |                     | (Yeni access token)
  |<-- New Access Token-|
  |                     |
  |-- Retry Request --->|
  |<-- Success ---------|
```

### 3.4 Godot Network Implementation

#### 3.4.1 NetworkManager (Autoload)
```gdscript
# autoload/NetworkManager.gd
extends Node

const BASE_URL = "https://api.golgeekono.mi/v1"

var _http_client: HTTPClient
var _ws_client: WebSocketPeer
var _request_queue: Array[Dictionary] = []
var _is_connected: bool = false

func _ready():
    _http_client = HTTPClient.new()
    _ws_client = WebSocketPeer.new()
    _connect_websocket()

func request(endpoint: String, method: int, data: Dictionary = {}) -> Dictionary:
    var request_id = UUID.v4()
    var request = {
        "id": request_id,
        "endpoint": endpoint,
        "method": method,
        "data": data,
        "timestamp": Time.get_unix_time_from_system()
    }
    
    if not _is_connected:
        _request_queue.append(request)
        return {"queued": true, "request_id": request_id}
    
    return await _execute_request(request)

func _execute_request(request: Dictionary) -> Dictionary:
    var url = BASE_URL + request.endpoint
    var headers = _build_headers()
    var body = JSON.stringify(request.data)
    
    var http = HTTPRequest.new()
    add_child(http)
    
    http.request(url, headers, request.method, body)
    var result = await http.request_completed
    
    http.queue_free()
    return _parse_response(result)

func _build_headers() -> PackedStringArray:
    return PackedStringArray([
        "Authorization: Bearer " + SessionManager.get_access_token(),
        "Content-Type: application/json",
        "X-Device-ID: " + OS.get_unique_id(),
        "X-Session-ID: " + SessionManager.get_session_id(),
        "X-Client-Version: " + ProjectSettings.get_setting("application/config/version")
    ])

func _connect_websocket():
    var token = SessionManager.get_access_token()
    var ws_url = "wss://api.golgeekono.mi/realtime/v1?token=" + token
    
    var error = _ws_client.connect_to_url(ws_url)
    if error != OK:
        push_error("WebSocket connection failed: " + str(error))
        return
    
    _is_connected = true
    _process_queue()

func _process_queue():
    while _request_queue.size() > 0:
        var request = _request_queue.pop_front()
        await _execute_request(request)
```

#### 3.4.2 Request Queue (Offline Handling)
```gdscript
# autoload/RequestQueue.gd
extends Node

const QUEUE_FILE = "user://request_queue.dat"
const MAX_QUEUE_SIZE = 100

var _queue: Array[Dictionary] = []

func _ready():
    _load_queue()
    get_tree().connect("network_status_changed", _on_network_changed)

func add(request: Dictionary):
    if _queue.size() >= MAX_QUEUE_SIZE:
        _queue.pop_front()
    
    _queue.append(request)
    _save_queue()

func _on_network_changed(is_online: bool):
    if is_online:
        _process_queue()

func _process_queue():
    while _queue.size() > 0:
        var request = _queue[0]
        var result = await NetworkManager.request(
            request.endpoint,
            request.method,
            request.data
        )
        
        if result.success:
            _queue.pop_front()
            _save_queue()
        else:
            break  # Hata varsa dur, sonra tekrar dene

func _save_queue():
    var file = FileAccess.open(QUEUE_FILE, FileAccess.WRITE)
    file.store_var(_queue)
    file.close()

func _load_queue():
    if not FileAccess.file_exists(QUEUE_FILE):
        return
    
    var file = FileAccess.open(QUEUE_FILE, FileAccess.READ)
    _queue = file.get_var()
    file.close()
```

#### 3.4.3 Retry Logic (Exponential Backoff)
```gdscript
func _retry_request(request: Dictionary, attempt: int = 1) -> Dictionary:
    const MAX_ATTEMPTS = 3
    const BASE_DELAY = 1.0  # seconds
    
    var result = await _execute_request(request)
    
    if result.success or attempt >= MAX_ATTEMPTS:
        return result
    
    # Exponential backoff: 1s, 2s, 4s
    var delay = BASE_DELAY * pow(2, attempt - 1)
    await get_tree().create_timer(delay).timeout
    
    return await _retry_request(request, attempt + 1)
```

### 3.5 Caching Strategy

#### 3.5.1 Local Cache (Client)
```gdscript
# Client-side cache (Dictionary)
var _cache = {
    "player": {},
    "inventory": {},
    "market": {},
    "guild": {}
}

func get_cached(key: String, max_age: float = 60.0):
    if not _cache.has(key):
        return null
    
    var entry = _cache[key]
    var age = Time.get_unix_time_from_system() - entry.timestamp
    
    if age > max_age:
        _cache.erase(key)
        return null
    
    return entry.data

func set_cache(key: String, data):
    _cache[key] = {
        "data": data,
        "timestamp": Time.get_unix_time_from_system()
    }
```

#### 3.5.2 Cache Invalidation
**WebSocket ile senkronizasyon:**
```gdscript
func _on_ws_message(message: Dictionary):
    match message.type:
        "inventory_changed":
            _cache.erase("inventory")
            inventory_updated.emit(message.payload)
        
        "energy_updated":
            _cache["player"]["energy"] = message.payload.new_energy
            energy_updated.emit(message.payload)
        
        "market_price_update":
            _cache["market"][message.payload.item_id] = message.payload
            market_updated.emit(message.payload)
```

---

## FAZA 4 — GÜVENLİK SİSTEMLERİ (Hafta 17-22)

### 4.1 Server-Side Validation (Katmanlar)

#### 4.1.1 Validation Pipeline
```
Request → [1] Auth → [2] Rate Limit → [3] Input Validation → 
          [4] Business Rules → [5] Database Transaction → 
          [6] Audit Log → Response
```

**Her katmanın sorumluluğu:**

**[1] Authentication:**
- JWT signature doğrulama
- Token expiry kontrolü
- Device ID match
- Session validity

**[2] Rate Limiting:**
- Endpoint bazlı limit
- Player bazlı limit
- IP bazlı limit
- Token bucket algoritması

**[3] Input Validation:**
- Schema validation (JSON Schema)
- Type checking
- Range validation
- Sanitization (XSS, SQL Injection)

**[4] Business Rules:**
- Enerji yeterli mi?
- Item sahibi doğru mu?
- Cooldown geçmiş mi?
- Kısıtlamalar ihlal edilmiş mi?

**[5] Database Transaction:**
- Atomic operations
- Rollback on failure
- Optimistic locking
- Idempotency check

**[6] Audit Logging:**
- Başarılı işlemler
- Başarısız işlemler
- Şüpheli aktiviteler
- Critical events

#### 4.1.2 Örnek Edge Function (Supabase)
```typescript
// supabase/functions/use-potion/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from '@supabase/supabase-js'

serve(async (req) => {
  // [1] Authentication
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response(JSON.stringify({
      success: false,
      error: "Missing authorization"
    }), { status: 401 })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const { data: { user }, error: authError } = await supabase.auth.getUser(
    authHeader.replace('Bearer ', '')
  )

  if (authError || !user) {
    return new Response(JSON.stringify({
      success: false,
      error: "Invalid token"
    }), { status: 401 })
  }

  // [2] Rate Limiting
  const rateLimitKey = `potion_use:${user.id}`
  const rateLimitResult = await checkRateLimit(rateLimitKey, 200, 86400) // 200/day
  
  if (!rateLimitResult.allowed) {
    return new Response(JSON.stringify({
      success: false,
      error: "Rate limit exceeded",
      retry_after: rateLimitResult.retry_after
    }), { status: 429 })
  }

  // [3] Input Validation
  const body = await req.json()
  const validation = validatePotionRequest(body)
  
  if (!validation.valid) {
    return new Response(JSON.stringify({
      success: false,
      error: validation.error
    }), { status: 400 })
  }

  // [4] Business Rules
  const { data: player } = await supabase
    .from('players')
    .select('*, player_tolerance(*), player_energy(*)')
    .eq('id', user.id)
    .single()

  const { data: potion } = await supabase
    .from('inventory_items')
    .select('*, item_definition(*)')
    .eq('id', body.potion_instance_id)
    .eq('player_id', user.id)
    .single()

  if (!potion) {
    return new Response(JSON.stringify({
      success: false,
      error: "Potion not found"
    }), { status: 404 })
  }

  // Tolerance ve overdose hesaplama
  const tolerance = player.player_tolerance.tolerance
  const effectiveness = calculateEffectiveness(tolerance)
  const energyRestore = Math.floor(potion.item_definition.energy_restore * effectiveness)
  const toleranceIncrease = potion.item_definition.tolerance_increase
  const newTolerance = Math.min(tolerance + toleranceIncrease, 100)

  // Overdose riski
  const overdoseRisk = calculateOverdoseRisk(tolerance, potion.item_definition.potion_type)
  const overdoseRoll = Math.random()
  const isOverdose = overdoseRoll < overdoseRisk

  // [5] Database Transaction
  const { data: result, error: txError } = await supabase.rpc('use_potion_tx', {
    p_player_id: user.id,
    p_potion_instance_id: body.potion_instance_id,
    p_energy_restore: isOverdose ? 0 : energyRestore,
    p_tolerance_increase: toleranceIncrease,
    p_is_overdose: isOverdose
  })

  if (txError) {
    // [6] Audit Log (failure)
    await auditLog('potion_use_failed', {
      player_id: user.id,
      potion_id: body.potion_instance_id,
      error: txError.message
    })

    return new Response(JSON.stringify({
      success: false,
      error: "Transaction failed"
    }), { status: 500 })
  }

  // [6] Audit Log (success)
  await auditLog('potion_use_success', {
    player_id: user.id,
    potion_id: body.potion_instance_id,
    energy_restored: energyRestore,
    tolerance_increase: toleranceIncrease,
    is_overdose: isOverdose
  })

  // Telemetry
  await trackEvent('potion_used', {
    player_id: user.id,
    potion_type: potion.item_definition.potion_type,
    tolerance_before: tolerance,
    tolerance_after: newTolerance,
    is_overdose: isOverdose
  })

  return new Response(JSON.stringify({
    success: true,
    data: {
      energy_restored: energyRestore,
      new_energy: result.new_energy,
      tolerance_increase: toleranceIncrease,
      new_tolerance: newTolerance,
      overdose: isOverdose,
      overdose_risk: overdoseRisk
    }
  }), { status: 200 })
})
```

### 4.2 Client-Side Protection (Geciktirici)

#### 4.2.1 Memory Encryption (XOR)
```gdscript
# core/utils/SecureValue.gd
class_name SecureValue

var _value: int
var _key: int

func _init(initial_value: int = 0):
    _key = randi()
    _value = initial_value ^ _key

func get_value() -> int:
    return _value ^ _key

func set_value(new_value: int):
    _value = new_value ^ _key

func add(amount: int):
    var current = get_value()
    set_value(current + amount)

func subtract(amount: int):
    var current = get_value()
    set_value(current - amount)
```

**Kullanım:**
```gdscript
var energy = SecureValue.new(100)

# Okuma
print(energy.get_value())  # 100

# Yazma
energy.set_value(85)

# İşlem
energy.subtract(10)
print(energy.get_value())  # 75
```

#### 4.2.2 APK Signature Verification
```gdscript
func _ready():
    if OS.get_name() == "Android":
        if not _verify_apk_signature():
            _show_tamper_warning()
            get_tree().quit()

func _verify_apk_signature() -> bool:
    if OS.has_feature("debug"):
        return true  # Debug build'de atla
    
    var expected_signature = "YOUR_RELEASE_SIGNATURE_SHA256"
    var actual_signature = OS.get_unique_id()  # Gerçek uygulamada signature API kullan
    
    return actual_signature == expected_signature
```

#### 4.2.3 Certificate Pinning (HTTPS)
```gdscript
# NetworkManager.gd
func _ready():
    var tls_options = TLSOptions.new()
    tls_options.verify_mode = TLSOptions.TLS_VERIFY_FULL
    
    # Pin specific certificate
    var cert = load("res://certificates/api_cert.crt")
    tls_options.trusted_ca_chain = cert
    
    _http_client.set_tls_options(tls_options)
```

### 4.3 API Security

#### 4.3.1 Rate Limiting (Token Bucket)
```typescript
// rate-limiter.ts

interface RateLimitConfig {
  capacity: number;     // Max tokens
  refillRate: number;   // Tokens per second
  cost: number;         // Tokens per request
}

class TokenBucket {
  private tokens: number;
  private lastRefill: number;
  
  constructor(private config: RateLimitConfig) {
    this.tokens = config.capacity;
    this.lastRefill = Date.now();
  }
  
  async consume(): Promise<{ allowed: boolean; retryAfter?: number }> {
    this.refill();
    
    if (this.tokens >= this.config.cost) {
      this.tokens -= this.config.cost;
      return { allowed: true };
    }
    
    const tokensNeeded = this.config.cost - this.tokens;
    const retryAfter = Math.ceil(tokensNeeded / this.config.refillRate);
    
    return {
      allowed: false,
      retryAfter
    };
  }
  
  private refill() {
    const now = Date.now();
    const elapsed = (now - this.lastRefill) / 1000; // seconds
    const tokensToAdd = elapsed * this.config.refillRate;
    
    this.tokens = Math.min(
      this.config.capacity,
      this.tokens + tokensToAdd
    );
    
    this.lastRefill = now;
  }
}

// Rate limit configurations
const RATE_LIMITS: Record<string, RateLimitConfig> = {
  'market_order': { capacity: 30, refillRate: 0.5, cost: 1 },      // 30/min
  'market_cancel': { capacity: 60, refillRate: 1, cost: 1 },       // 60/min
  'potion_use': { capacity: 200, refillRate: 0.002315, cost: 1 },  // 200/day
  'pvp_attack': { capacity: 20, refillRate: 0.0139, cost: 1 },     // 20/day
  'quest_start': { capacity: 100, refillRate: 0.0116, cost: 1 }    // 100/day
};

export async function checkRateLimit(
  playerId: string,
  endpoint: string
): Promise<{ allowed: boolean; retryAfter?: number }> {
  const config = RATE_LIMITS[endpoint];
  if (!config) {
    return { allowed: true }; // No limit configured
  }
  
  const key = `ratelimit:${endpoint}:${playerId}`;
  const bucket = await getRateLimitBucket(key, config);
  
  return bucket.consume();
}
```

#### 4.3.2 Request Signing (HMAC)
```typescript
// request-signature.ts

import { createHmac } from 'crypto';

const SECRET_KEY = Deno.env.get('API_SECRET_KEY')!;

export function signRequest(
  method: string,
  path: string,
  timestamp: number,
  body: string
): string {
  const message = `${method}${path}${timestamp}${body}`;
  return createHmac('sha256', SECRET_KEY)
    .update(message)
    .digest('hex');
}

export function verifySignature(
  signature: string,
  method: string,
  path: string,
  timestamp: number,
  body: string
): boolean {
  const expected = signRequest(method, path, timestamp, body);
  return signature === expected;
}

export function checkTimestamp(timestamp: number): boolean {
  const now = Date.now();
  const diff = Math.abs(now - timestamp);
  const MAX_SKEW = 5 * 60 * 1000; // 5 minutes
  
  return diff < MAX_SKEW;
}
```

**Client-side (Godot):**
```gdscript
func _sign_request(method: String, path: String, body: String) -> Dictionary:
    var timestamp = Time.get_unix_time_from_system() * 1000
    var message = method + path + str(timestamp) + body
    var signature = _hmac_sha256(message, API_SECRET)
    
    return {
        "X-Signature": signature,
        "X-Timestamp": str(timestamp)
    }

func _hmac_sha256(message: String, key: String) -> String:
    var crypto = Crypto.new()
    var hash = crypto.hmac_digest(
        HashingContext.HASH_SHA256,
        key.to_utf8_buffer(),
        message.to_utf8_buffer()
    )
    return hash.hex_encode()
```

### 4.4 Enerji Sistemi Güvenliği

#### 4.4.1 Server-Side Energy Calculation
```typescript
// energy-manager.ts

interface EnergyState {
  current_energy: number;
  max_energy: number;
  last_update: number;
}

export async function calculateEnergy(playerId: string): Promise<EnergyState> {
  const { data: player } = await supabase
    .from('player_energy')
    .select('*')
    .eq('player_id', playerId)
    .single();
  
  const now = Date.now();
  const elapsed = (now - player.last_update) / 1000; // seconds
  const REGEN_RATE = 1 / (5 * 60); // 1 per 5 minutes
  
  const energyGained = Math.floor(elapsed * REGEN_RATE);
  const newEnergy = Math.min(
    player.max_energy,
    player.current_energy + energyGained
  );
  
  // Update database
  await supabase
    .from('player_energy')
    .update({
      current_energy: newEnergy,
      last_update: now
    })
    .eq('player_id', playerId);
  
  return {
    current_energy: newEnergy,
    max_energy: player.max_energy,
    last_update: now
  };
}

export async function consumeEnergy(
  playerId: string,
  amount: number
): Promise<{ success: boolean; error?: string }> {
  const energy = await calculateEnergy(playerId);
  
  if (energy.current_energy < amount) {
    return {
      success: false,
      error: "Insufficient energy"
    };
  }
  
  await supabase
    .from('player_energy')
    .update({
      current_energy: energy.current_energy - amount,
      last_update: Date.now()
    })
    .eq('player_id', playerId);
  
  return { success: true };
}
```

#### 4.4.2 Energy Validation Middleware
```typescript
export async function validateEnergy(
  req: Request,
  requiredEnergy: number
): Promise<Response | null> {
  const user = await getAuthenticatedUser(req);
  const result = await consumeEnergy(user.id, requiredEnergy);
  
  if (!result.success) {
    return new Response(JSON.stringify({
      success: false,
      error: result.error,
      code: "INSUFFICIENT_ENERGY"
    }), { status: 400 });
  }
  
  return null; // Continue
}
```

### 4.5 PvP Security

#### 4.5.1 Combat Calculation (Server-only)
```typescript
// pvp-manager.ts

interface CombatResult {
  outcome: 'critical_victory' | 'victory' | 'draw' | 'defeat' | 'critical_defeat';
  attacker_rewards: Rewards;
  defender_impact: Impact;
  combat_log: CombatLog[];
}

export async function resolveCombat(
  attackerId: string,
  defenderId: string
): Promise<CombatResult> {
  // Fetch combat stats
  const attacker = await getPlayerCombatStats(attackerId);
  const defender = await getPlayerCombatStats(defenderId);
  
  // Calculate power
  const attackerPower = calculatePower(attacker);
  const defenderPower = calculatePower(defender);
  
  // Calculate win chance
  const powerRatio = attackerPower / defenderPower;
  const baseWinChance = 0.5 + 0.3 * Math.log(powerRatio);
  const winChance = clamp(baseWinChance, 0.15, 0.85);
  
  // Server-side RNG
  const roll = Math.random();
  let outcome: string;
  
  if (roll < winChance) {
    // Attacker wins
    const critRoll = Math.random();
    outcome = critRoll < 0.10 ? 'critical_victory' : 'victory';
  } else if (roll < winChance + 0.05) {
    outcome = 'draw';
  } else {
    // Attacker loses
    const critRoll = Math.random();
    outcome = critRoll < 0.10 ? 'critical_defeat' : 'defeat';
  }
  
  // Calculate rewards
  const rewards = calculatePvPRewards(outcome, defender);
  const impact = calculatePvPImpact(outcome, attacker);
  
  // Apply hospital if critical
  if (outcome === 'critical_victory') {
    await hospitalizePlayer(defenderId, 'pvp_defeat', 4, 8);
  } else if (outcome === 'critical_defeat') {
    await hospitalizePlayer(attackerId, 'pvp_defeat', 2, 4);
  }
  
  // Audit log
  await auditLog('pvp_combat', {
    attacker_id: attackerId,
    defender_id: defenderId,
    outcome,
    attacker_power: attackerPower,
    defender_power: defenderPower,
    win_chance: winChance,
    roll
  });
  
  return {
    outcome,
    attacker_rewards: rewards,
    defender_impact: impact,
    combat_log: generateCombatLog(attacker, defender, outcome)
  };
}
```

---

## FAZA 5 — İLK 30 DAKİKA DENEYİMİ (Hafta 23-28)

### 5.1 Onboarding Flow

#### 5.1.1 Dakika Dakika Breakdown

**Dakika 0-2: Sinematik Açılış**
- Karanlık krallık hikayesi (atlanabilir)
- Kadim mühür çöküyor
- Kaos başlıyor
- "Sen de bu kaosun bir parçasısın..."

**Dakika 2-5: İlk Görev (Tutorial)**
- Görev: "Kasabayı koru!"
- %100 başarı garantili
- Ödül: 500 altın + seviye 1 kılıç
- Öğretilen: tap to action, görev seçimi

**Dakika 5-8: Ekipman Sistemi**
- "Ödülünü al!"
- Envanter açılır
- Ekipman slotları gösterilir
- Kılıç equip edilir
- Ödül: seviye 1 zırh

**Dakika 8-12: İkinci Görev**
- Görev: "Ormandaki haydutları temizle"
- %80 başarı şansı (gerçek risk)
- Ödül: 1,000 altın + XP
- Öğretilen: risk/ödül dengesi

**Dakika 12-15: İlk Geliştirme**
- Demirci tanıtımı
- Kılıç +1'e yükselt (guaranteed)
- Güç artışı gösterilir
- Ödül: +10% saldırı gücü

**Dakika 15-20: Lonca Keşfi**
- Lonca NPC konuşması
- Lonca sistemine giriş
- Davet gönderimi/alımı
- Sosyal özellikler

**Dakika 20-25: Pazar Tanıtımı**
- Market ekranı açılır
- Basit al/sat gösterimi
- İlk ticaret yapılır
- Ekonomi temeli

**Dakika 25-30: Enerji Sistemi (CORE)**
- "Enerjin azaldı!" bildirimi
- Enerji bar açıklaması
- İlk iksir hediye: 5x minör iksir
- İksir kullanımı
- Bağımlılık uyarısı (soft)
- "İksirler güçlüdür ama dikkatli ol!"

#### 5.1.2 Tutorial Quest Design

**Quest 1: Kasabayı Koru (Guaranteed Success)**
```json
{
  "id": "tutorial_001",
  "name": "Kasabayı Koru",
  "description": "Kasabaya yaklaşan goblinleri durdur!",
  "type": "tutorial",
  "energy_cost": 5,
  "success_chance": 1.0,  // %100
  "duration": 60,  // seconds
  "rewards": {
    "gold": 500,
    "xp": 100,
    "items": [
      {"id": "sword_basic", "quantity": 1}
    ]
  },
  "tutorial_flags": {
    "skip_validation": false,
    "auto_complete": false,
    "show_tips": true
  }
}
```

**Quest 2: Ormandaki Haydutlar (Real Risk)**
```json
{
  "id": "tutorial_002",
  "name": "Ormandaki Haydutlar",
  "description": "Orman yolundaki haydutları temizle.",
  "type": "tutorial",
  "energy_cost": 10,
  "base_success_chance": 0.8,  // Gear/level'a göre değişir
  "duration": 120,
  "rewards": {
    "gold": 1000,
    "xp": 250,
    "items": [
      {"id": "armor_leather", "quantity": 1}
    ]
  },
  "failure_penalty": {
    "gold_lost": 0,  // Tutorial'da para kaybı yok
    "durability_loss": 0.1
  }
}
```

### 5.2 Enerji Sistemi Onboarding

#### 5.2.1 Enerji Bildirimi (Dakika 25)
```gdscript
# scenes/tutorial/EnergyTutorial.gd

func _show_energy_tutorial():
    var current_energy = PlayerData.get_energy()
    
    if current_energy < 30:
        _show_tooltip("energy_low", {
            "current": current_energy,
            "max": PlayerData.get_max_energy()
        })
        
        await get_tree().create_timer(2.0).timeout
        
        _show_potion_offer()

func _show_potion_offer():
    var dialog = preload("res://scenes/ui/PotionOfferDialog.tscn").instantiate()
    dialog.set_text("Enerjin azaldı! İksir kullanmak ister misin?")
    dialog.set_potions([
        {"type": "minor", "quantity": 5, "free": true}
    ])
    
    add_child(dialog)
    
    var result = await dialog.choice_made
    
    if result.accepted:
        _give_free_potions(5)
        _show_tolerance_warning()

func _show_tolerance_warning():
    var warning = preload("res://scenes/ui/WarningDialog.tscn").instantiate()
    warning.set_text(
        "DİKKAT: İksirler enerji doldurur ama sık kullanım bağımlılık yaratır!\n\n" +
        "Bağımlılık arttıkça:\n" +
        "• İksir etkisi azalır\n" +
        "• Overdose riski artar\n" +
        "• Hastanelik olabilirsin\n\n" +
        "Akıllıca kullan!"
    )
    warning.set_icon("res://assets/ui/icons/warning.png")
    
    add_child(warning)
    
    await warning.closed
    
    # Tutorial tamamlandı
    TutorialManager.complete_step("energy_system")
```

#### 5.2.2 İlk İksir Kullanımı
```gdscript
func _on_first_potion_use():
    # Server'a istek
    var result = await NetworkManager.request(
        "/player/use-potion",
        HTTPClient.METHOD_POST,
        {
            "potion_instance_id": potion.id,
            "is_tutorial": true
        }
    )
    
    if result.success:
        # Enerji animasyonu
        _animate_energy_restore(result.data.energy_restored)
        
        # Tolerans gösterimi
        _show_tolerance_increase(result.data.tolerance_increase)
        
        # Achievement
        AchievementManager.unlock("first_potion")
        
        # Tooltip
        _show_tooltip("potion_used", {
            "energy_restored": result.data.energy_restored,
            "tolerance": result.data.new_tolerance
        })
```

### 5.3 Hook Points (Retention Tactics)

#### 5.3.1 Progress Bar Psychology
```gdscript
# UI/ProgressBar.gd

# Progress bar'ı %87 göster (tamamlanmamış hissi)
func _set_fake_progress():
    var actual_progress = _calculate_actual_progress()
    var displayed_progress = min(actual_progress, 0.87)
    
    progress_bar.value = displayed_progress
    
    if actual_progress >= 0.87:
        _show_completion_tease()

func _show_completion_tease():
    var label = Label.new()
    label.text = "Neredeyse tamam! Bir görev daha yap!"
    label.modulate = Color.YELLOW
    add_child(label)
```

#### 5.3.2 Daily Streak (Loss Aversion)
```gdscript
# UI/DailyStreak.gd

func _update_streak_display():
    var streak = PlayerData.get_daily_streak()
    
    streak_label.text = str(streak) + " gün üst üste!"
    
    if streak >= 3:
        streak_label.modulate = Color.GOLD
        _show_streak_bonus()
    
    # Loss aversion messaging
    if streak >= 7:
        warning_label.text = "Yarın giriş yapmazsan %d günlük serin kaybolur!" % streak
        warning_label.show()
```

#### 5.3.3 Near-Miss Animation (Gambling Psychology)
```gdscript
# scenes/anvil/EnhancementAnimation.gd

func _play_enhancement_animation(success: bool):
    # Animasyon her zaman heyecanlı
    _play_sparks()
    _shake_camera()
    _play_sound("anvil_hit")
    
    await get_tree().create_timer(1.5).timeout
    
    if success:
        _play_success_animation()
    else:
        # Near-miss effect: neredeyse başarılı görünümü
        _play_near_miss()
        await get_tree().create_timer(0.5).timeout
        _play_failure_animation()

func _play_near_miss():
    # Ekran yeşile döner (başarı gibi)
    flash_overlay.modulate = Color.GREEN
    flash_overlay.show()
    
    await get_tree().create_timer(0.2).timeout
    
    # Sonra kırmızıya döner (başarısız)
    flash_overlay.modulate = Color.RED
    
    # Mesaj: "Çok yaklaştın!"
    var label = Label.new()
    label.text = "ÇOK YAKIN!"
    label.add_theme_font_size_override("font_size", 48)
    add_child(label)
```

#### 5.3.4 Leaderboard Teaser
```gdscript
# UI/LeaderboardTeaser.gd

func _show_leaderboard_teaser():
    # Oyuncu sıralamasını göster (erken teaser)
    var rank = await NetworkManager.request("/leaderboard/my-rank", HTTPClient.METHOD_GET)
    
    if rank.data.rank > 100:
        # Yeni oyuncu
        teaser_label.text = "Sıralama: #%d\n%d oyuncuyu geç!" % [rank.data.rank, rank.data.rank - 100]
    else:
        # İyi performans
        teaser_label.text = "Sıralama: #%d\nTop 100'desin!" % rank.data.rank
    
    show()
```

### 5.4 Push Notification Stratejisi

#### 5.4.1 Notification Schedule
```gdscript
# autoload/NotificationManager.gd

const NOTIFICATIONS = {
    "energy_full": {
        "delay": 7200,  # 2 hours
        "title": "Enerji Doldu!",
        "body": "Enerjin tamamen doldu. Görevlere devam et!"
    },
    "daily_quest": {
        "delay": 14400,  # 4 hours
        "title": "Günlük Görevler",
        "body": "Günlük görevlerin seni bekliyor!"
    },
    "daily_reward": {
        "delay": 86400,  # 24 hours
        "title": "Günlük Ödül Hazır!",
        "body": "Giriş yap ve ödülünü al!"
    },
    "free_gift": {
        "delay": 259200,  # 3 days
        "title": "Özel Hediye!",
        "body": "Seni özledik! Özel hediye seni bekliyor."
    },
    "guild_waiting": {
        "delay": 604800,  # 7 days
        "title": "Lonca Daveti",
        "body": "Bir loncaya katıl ve bonuslardan faydalan!"
    }
}

func schedule_notification(type: String):
    var config = NOTIFICATIONS[type]
    var notification_id = randi()
    
    if OS.get_name() == "Android":
        var plugin = Engine.get_singleton("GodotFirebaseNotifications")
        plugin.schedule({
            "id": notification_id,
            "title": config.title,
            "body": config.body,
            "delay": config.delay,
            "icon": "res://icon.png"
        })
    elif OS.get_name() == "iOS":
        # iOS notification scheduling
        pass
```

### 5.5 Definition of Done (Faza 5)

- [ ] Tutorial flow 30 dakika testinde %80+ tamamlanma
- [ ] Enerji sistemi anlaşılıyor (survey: %90+)
- [ ] İlk iksir kullanımı %95+ oyuncu
- [ ] Bağımlılık uyarısı görülüyor (telemetry)
- [ ] Progress bar hook %60+ etkili (A/B test)
- [ ] Daily streak %40+ retention artışı
- [ ] Push notification %20+ geri dönüş

---

## TELEMETRY & MONITORING

### Kritik Metrikler
- **Tutorial completion rate:** >80%
- **Energy tutorial engagement:** >90%
- **First potion usage:** >95%
- **D1 retention:** >40%
- **Average session time:** >15 min
- **Tutorial drop-off points:** identify & fix

### Events
- `tutorial_started`
- `tutorial_step_completed`
- `tutorial_dropped` (with step_id)
- `energy_tutorial_shown`
- `first_potion_used`
- `tolerance_warning_shown`
- `tutorial_completed`

---

Bu döküman, Faza 3, 4 ve 5 için detaylı teknik spesifikasyonları, kod örneklerini ve implementasyon kılavuzunu içerir. Server-client mimarisi, güvenlik katmanları ve onboarding deneyimi için production-ready blueprint sağlar.
