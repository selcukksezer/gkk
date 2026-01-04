# Gölge Ekonomi — Chat Sistemi Detaylı Belge

> Kaynak: plan-golgeEkonomi-part-04.prompt.md (Faza 11)
> Oyun: Gölge Krallık: Kadim Mühür'ün Çöküşü
> Amaç: 4 chat tipi, küfür filtresi, cooldown, anti-spam, moderasyon

---

## 1. CHAT SİSTEMİ GENEL BAKIŞ

### 1.1 Tasarım Prensipleri
- **Sosyal etkileşim:** Oyuncular arası iletişim
- **Anti-toxicity:** Küfür/hakaret filtreleme
- **Anti-spam:** Rate limiting ve cooldown
- **Moderasyon:** Otomatik + manuel sistemler
- **Privacy:** DM şifreleme (optional)

### 1.2 Chat Tipleri
- **Genel Chat:** Tüm oyuncular (bölge bazlı)
- **Lonca Chat:** Sadece lonca üyeleri
- **Özel Mesaj (DM):** 1-1 iletişim
- **Bölge Chat:** Şehir/kasaba bazlı
- **Ticaret Chat:** Sadece market duyuruları (optional)

---

## 2. GENEL CHAT (GLOBAL)

### 2.1 Özellikler
**Erişim:**
- Level 5+ oyuncular
- Banlı değilse
- Muted değilse

**Cooldown:**
```
Normal oyuncu: 30 saniye
Premium oyuncu: 15 saniye
VIP oyuncu: 5 saniye
Moderatör: cooldown yok
```

**Mesaj limitleri:**
```
Minimum karakter: 3
Maksimum karakter: 200
URL/Link: yasak
Emoji: max 5/mesaj
```

### 2.2 Format ve Görünüm

**Mesaj yapısı:**
```json
{
  "id": "uuid",
  "sender_id": "uuid",
  "sender_name": "KaraSavaşçı",
  "sender_level": 45,
  "sender_title": "Savaş Ustası",
  "guild_tag": "[KŞ]",
  "message": "Yeni oyuncular gelsin, yardım edelim!",
  "timestamp": "2026-01-03T12:30:00Z",
  "channel": "global",
  "color": "#FFD700"  // VIP için özel renk
}
```

**Görünüm:**
```
[KŞ] KaraSavaşçı (Lv 45) 🏆: Yeni oyuncular gelsin, yardım edelim!
      ↑        ↑        ↑    ↑           ↑
   Guild    Name    Level Title       Message
```

### 2.3 Premium Özellikler (💎)

**İsim Rengi:**
- Varsayılan: Beyaz
- Premium: Altın (#FFD700) - 200💎
- VIP: Mor (#9B30FF) - 500💎

**Chat Efektleri:**
- Parıltı efekti - 150💎
- Animasyonlu giriş - 300💎
- Özel emojiler - 200💎

---

## 3. LONCA CHAT (GUILD)

### 3.1 Özellikler

**Erişim:**
- Sadece lonca üyeleri
- Rol bazlı izinler (mute edilebilir)

**Cooldown:**
```
Tüm roller: 10 saniye (daha sık iletişim)
```

**Özel komutlar:**
```
/invite [oyuncu_adı] - Davet gönder (Şövalye+)
/kick [oyuncu_adı] - Üye çıkar (Komutan+)
/mute [oyuncu_adı] - Sustur (Komutan+)
/promote [oyuncu_adı] - Terfi (Lord)
```

### 3.2 Bildirimler

**Push notification:**
```
@KaraSavaşçı merhaba!  → Push notification gönder
@everyone lonca savaşı! → Tüm üyelere bildirim (sadece Lord/Komutan)
```

**Offline mesajlar:**
- Son 50 mesaj offline'ken de görülebilir
- Önemli duyurular vurgulanır

---

## 4. ÖZEL MESAJ (DM / WHISPER)

### 4.1 Özellikler

**Erişim:**
- Level 10+ oyuncular
- DM engelleme ayarı

**Privacy ayarları:**
```typescript
enum DMPrivacy {
  EVERYONE = "everyone",           // Herkes mesaj atabilir
  FRIENDS_ONLY = "friends_only",   // Sadece arkadaşlar
  GUILD_ONLY = "guild_only",       // Sadece lonca üyeleri
  NONE = "none"                    // Kimse
}
```

**Rate limiting:**
```
Aynı kişiye: 10 mesaj/dakika
Farklı kişilere: 30 mesaj/dakika
Yeni hesaplar (7 gün<): 5 mesaj/dakika
```

### 4.2 Spam ve Abuse Önleme

**Auto-block:**
- Aynı mesaj 3 kez tekrar → auto-block
- 5+ farklı kişiye aynı mesaj → spam flag
- URL/link içeriyorsa → auto-reject

**Report sistemi:**
```
Rapor sebepleri:
• Spam
• Hakaret
• Cinsel içerik
• Dolandırıcılık
• RMT (real money trading)
```

---

## 5. BÖLGE CHAT (LOCAL)

### 5.1 Özellikler

**Kapsam:**
- Aynı şehir/kasabada oyuncular
- Maksimum 100 oyuncu/kanal

**Kullanım alanları:**
- Grup arama ("Tank arıyoruz!")
- Local ticaret
- Bölge event koordinasyonu

**Cooldown:**
```
20 saniye
```

---

## 6. KÜFÜR/HAKARET FİLTRESİ

### 6.1 Filtre Katmanları

**Katman 1: Kelime listesi (Blacklist)**
```typescript
const PROFANITY_LIST = [
  "küfür1", "küfür2", // Türkçe
  "profanity1", "profanity2" // İngilizce
  // ... 1000+ kelime
];

function containsProfanity(message: string): boolean {
  const normalized = message.toLowerCase()
    .replace(/[^a-zçğıöşü0-9\s]/gi, '')
    .replace(/\s+/g, ' ');
  
  return PROFANITY_LIST.some(word => normalized.includes(word));
}
```

**Katman 2: Leet-speak detection**
```typescript
const LEET_MAP = {
  '0': 'o',
  '1': 'i',
  '3': 'e',
  '4': 'a',
  '5': 's',
  '7': 't',
  '8': 'b',
  '@': 'a',
  '$': 's'
};

function decodeLeetSpeak(message: string): string {
  let decoded = message.toLowerCase();
  for (const [leet, char] of Object.entries(LEET_MAP)) {
    decoded = decoded.replace(new RegExp(leet, 'g'), char);
  }
  return decoded;
}
```

**Katman 3: Spacing/character insertion**
```typescript
// "k ü f ü r" → "küfür"
function removeSpacing(message: string): string {
  return message.replace(/\s+/g, '');
}

// "k*ü*f*ü*r" → "küfür"
function removeSpecialChars(message: string): string {
  return message.replace(/[^a-zçğıöşü0-9\s]/gi, '');
}
```

**Katman 4: ML-based detection (gelecek)**
- Transformer model
- Context-aware filtering
- False positive azaltma

### 6.2 Filtre Aksiyonları

**Tespit edildiğinde:**
```typescript
enum FilterAction {
  REPLACE_ASTERISK = "replace",     // k***r
  BLOCK_MESSAGE = "block",          // Mesaj gönderilmez
  AUTO_MUTE = "auto_mute",          // 10 dk susturma
  WARNING = "warning"               // Uyarı ver
}

function applyFilter(message: string, severity: number): FilterAction {
  if (severity >= 3) return FilterAction.AUTO_MUTE;
  if (severity === 2) return FilterAction.BLOCK_MESSAGE;
  return FilterAction.REPLACE_ASTERISK;
}
```

**Ceza sistemi:**
```
1. İhlal: Uyarı + mesaj engellenir
2. İhlal (24 saat içinde): 10 dakika mute
3. İhlal: 1 saat mute
4. İhlal: 24 saat mute
5. İhlal: 7 gün chat ban
6. İhlal: Kalıcı chat ban
```

---

## 7. ANTI-SPAM SİSTEMİ

### 7.1 Spam Tespit Metrikleri

**Rate limits:**
```typescript
interface RateLimit {
  channel: string;
  max_messages: number;
  window_seconds: number;
}

const RATE_LIMITS: RateLimit[] = [
  { channel: "global", max_messages: 2, window_seconds: 60 },
  { channel: "guild", max_messages: 10, window_seconds: 60 },
  { channel: "dm", max_messages: 10, window_seconds: 60 }
];
```

**Duplicate detection:**
```typescript
function isDuplicateMessage(
  playerId: string,
  message: string,
  windowSeconds: number = 300
): boolean {
  const recentMessages = getRecentMessages(playerId, windowSeconds);
  const similarCount = recentMessages.filter(m => 
    similarity(m.text, message) > 0.8
  ).length;
  
  return similarCount >= 3;
}
```

**Spam score:**
```typescript
function calculateSpamScore(
  playerId: string,
  message: string
): number {
  let score = 0;
  
  // Çok fazla büyük harf
  if (message.replace(/[^A-Z]/g, '').length / message.length > 0.5) {
    score += 2;
  }
  
  // Çok fazla emoji
  const emojiCount = (message.match(/[\u{1F600}-\u{1F64F}]/gu) || []).length;
  if (emojiCount > 5) score += 3;
  
  // Tekrarlayan karakter (!!!!!!)
  if (/(.)\1{4,}/.test(message)) score += 2;
  
  // Aynı mesajı tekrar
  if (isDuplicateMessage(playerId, message)) score += 5;
  
  return score;
}
```

**Auto-mute threshold:**
```
Spam score >= 10 → 10 dakika mute
Spam score >= 20 → 1 saat mute
```

### 7.2 Captcha Challenge

**Tetikleme:**
- 5 mesaj/10 saniye
- Spam score > 15
- Yeni hesap (<24 saat)

**Implementation:**
```gdscript
func _show_captcha_challenge():
    var captcha = preload("res://scenes/ui/CaptchaDialog.tscn").instantiate()
    captcha.set_challenge(generate_math_question())  # "5 + 3 = ?"
    
    add_child(captcha)
    
    var result = await captcha.solved
    
    if result.correct:
        allow_message_send()
    else:
        mute_player(600)  # 10 dakika
```

---

## 8. MODERASYON SİSTEMİ

### 8.1 Otomatik Moderasyon

**Auto-flag kriterleri:**
```typescript
interface AutoFlagRule {
  condition: string;
  action: string;
  severity: number;
}

const AUTO_FLAG_RULES: AutoFlagRule[] = [
  {
    condition: "contains_profanity",
    action: "block_message",
    severity: 2
  },
  {
    condition: "spam_score > 10",
    action: "auto_mute_10min",
    severity: 3
  },
  {
    condition: "repeated_reports > 3",
    action: "temp_ban_24h",
    severity: 5
  }
];
```

**Flagged mesajlar:**
```typescript
interface FlaggedMessage {
  message_id: string;
  sender_id: string;
  content: string;
  flag_reason: string;
  flag_timestamp: Date;
  reviewed: boolean;
  moderator_id?: string;
  action_taken?: string;
}
```

### 8.2 Manuel Moderasyon

**Moderatör yetkileri:**
```
• Mesaj silme
• Oyuncu susturma (mute)
• Chat ban (geçici/kalıcı)
• Uyarı verme
• Ban geçmişi görme
• Report log inceleme
```

**Moderatör komutları:**
```
/mute [oyuncu] [süre] [sebep]
/unmute [oyuncu]
/ban [oyuncu] [süre] [sebep]
/warn [oyuncu] [mesaj]
/history [oyuncu]
/delete [mesaj_id]
```

**Moderasyon paneli (Web):**
```
┌─────────────────────────────────────────────┐
│  MODERASYON PANELİ                          │
├─────────────────────────────────────────────┤
│  🚩 Bekleyen Raporlar: 12                   │
│  🔇 Aktif Mute'lar: 5                       │
│  🚫 Aktif Ban'lar: 2                        │
│                                             │
│  ──── SON RAPORLAR ────                     │
│  • KaraSavaşçı: Spam (3 rapor)              │
│    [İNCELE] [MUTE] [REDDET]                 │
│                                             │
│  • AteşKılıcı: Küfür (5 rapor)              │
│    [İNCELE] [BAN 24H] [REDDET]              │
└─────────────────────────────────────────────┘
```

### 8.3 Report Sistemi

**Report akışı:**
```
1. Oyuncu mesaja uzun bas → [RAPOR ET]
2. Sebep seç (spam/küfür/dolandırıcılık)
3. Optional: açıklama yaz
4. Server'a gönder
5. Auto-flag sistemi kontrol eder
6. Threshold geçerse otomatik aksiyon
7. Yoksa moderatör kuyruğuna gir
```

**Report abuse önleme:**
```
• Aynı mesajı 1 kez raporlayabilir
• Günlük report limiti: 10
• False report yapan kişiye ceza
• Report history tracking
```

---

## 9. UI/UX TASARIMI

### 9.1 Chat Ana Ekranı

```
┌─────────────────────────────────────────────┐
│  [GENEL] [LONCA] [BÖLGE] [ÖM (2)]          │
├─────────────────────────────────────────────┤
│  [KŞ] KaraTanrı: Yeni event başladı!       │
│  GölgeNinja: Parti arıyorum, katılın!       │
│  [AK] AteşRuhu: Market'te +8 kılıç          │
│  BuzKralı: Level 50 oldum! 🎉              │
│                                             │
│  ────────────────────────────────────────   │
│  [mesajınızı yazın...]        [GÖNDER]     │
└─────────────────────────────────────────────┘
```

### 9.2 Özel Mesaj Ekranı

```
┌─────────────────────────────────────────────┐
│  ◀ KaraSavaşçı (Online)              [⋮]   │
├─────────────────────────────────────────────┤
│                                             │
│  Sen: Merhaba, parti kuralım mı?            │
│                                12:30        │
│                                             │
│            KaraSavaşçı: Evet, gelirim!      │
│         12:31                               │
│                                             │
│  Sen: Harika, +8 zindan                     │
│                                12:32        │
│                                             │
│  ────────────────────────────────────────   │
│  [mesajınızı yazın...]        [GÖNDER]     │
└─────────────────────────────────────────────┘
```

### 9.3 Filtre Uyarısı

```
┌─────────────────────────────────────────────┐
│  ⚠️ UYARI                                   │
├─────────────────────────────────────────────┤
│  Mesajınız uygunsuz içerik içerdiği için    │
│  gönderilemedi.                             │
│                                             │
│  Lütfen saygılı bir dil kullanın.           │
│                                             │
│  ⚠️ Tekrarlanması durumunda chat'ten       │
│  geçici olarak uzaklaştırılabilirsiniz.     │
│                                             │
│  [ANLADIM]                                  │
└─────────────────────────────────────────────┘
```

---

## 10. SERVER-SIDE IMPLEMENTATION

### 10.1 Chat Message API

```
POST /v1/chat/send
Body: {
  "channel": "global",
  "message": "Merhaba dünya!",
  "recipient_id": null  // DM için doldurulur
}
```

**Response:**
```json
{
  "success": true,
  "message_id": "uuid",
  "timestamp": "2026-01-03T12:30:00Z",
  "cooldown_remaining": 28
}
```

### 10.2 Message Processing Pipeline

```typescript
async function processMessage(
  playerId: string,
  channel: string,
  message: string
): Promise<MessageResult> {
  // [1] Rate limit check
  if (!await checkRateLimit(playerId, channel)) {
    return { success: false, error: "Rate limit exceeded" };
  }
  
  // [2] Profanity filter
  const filterResult = checkProfanity(message);
  if (filterResult.blocked) {
    await logViolation(playerId, "profanity", message);
    return { success: false, error: "Message contains profanity" };
  }
  
  // [3] Spam detection
  const spamScore = calculateSpamScore(playerId, message);
  if (spamScore >= 10) {
    await autoMute(playerId, 600);  // 10 min
    return { success: false, error: "Spam detected" };
  }
  
  // [4] Save message
  const messageId = await saveMessage({
    sender_id: playerId,
    channel,
    content: filterResult.filtered_message,
    timestamp: new Date()
  });
  
  // [5] Broadcast via WebSocket
  await broadcastMessage(channel, {
    id: messageId,
    sender: await getPlayerInfo(playerId),
    message: filterResult.filtered_message,
    timestamp: new Date()
  });
  
  // [6] Telemetry
  await trackEvent('chat_message_sent', {
    player_id: playerId,
    channel,
    message_length: message.length,
    spam_score: spamScore
  });
  
  return { success: true, message_id: messageId };
}
```

---

## 11. ANTI-ABUSE VE EXPLOIT ÖNLEME

### 11.1 Chat Flooding
**Önlem:**
- Token bucket rate limiting
- Exponential backoff
- Auto-mute threshold

### 11.2 Harassment via DM
**Önlem:**
- Block/report özelliği
- Privacy ayarları
- Auto-block spam

### 11.3 Advertising/RMT
**Önlem:**
- URL detection + block
- Keyword filtering ("satılık", "rmt", "ucuz gem")
- Manual moderation

---

## 12. TELEMETRY VE METRIKLER

### 12.1 Tracked Events
```typescript
trackEvent('chat_message_sent', {...});
trackEvent('chat_message_filtered', {...});
trackEvent('chat_player_muted', {...});
trackEvent('chat_player_reported', {...});
```

### 12.2 KPI'lar
- Günlük aktif chatter oranı: >40%
- Ortalama mesaj/oyuncu/gün: 10-20
- Filter accuracy: >95%
- False positive rate: <5%
- Report resolution time: <24 saat

---

## 13. DEFINITION OF DONE

- [ ] 4 chat tipi çalışıyor (global, guild, local, DM)
- [ ] Küfür filtresi aktif (>95% accuracy)
- [ ] Rate limiting çalışıyor
- [ ] Anti-spam sistemi aktif
- [ ] Report sistemi çalışıyor
- [ ] Moderasyon paneli hazır
- [ ] WebSocket real-time mesajlaşma
- [ ] Telemetry toplanuyor

---

Bu döküman, chat sisteminin tam teknik spesifikasyonunu, moderasyon araçlarını ve production-ready implementasyon detaylarını içerir.
