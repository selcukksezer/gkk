# Authentication System Documentation

## Overview

Complete authentication system for the game with user registration, login, and profile management.

## Database Structure

### Users Table (`public.users`)

Main game profile table that extends Supabase Auth:

**Columns:**
- `id` - UUID primary key
- `auth_id` - Links to auth.users(id)
- `username` - Unique username (3-20 characters)
- `email` - Unique email address
- `display_name` - Display name for UI
- `avatar_url` - Profile picture URL
- `level` - Player level (default: 1)
- `experience` - XP points
- `gold` - In-game currency (starting: 1000)
- `energy` - Current energy (max: 100)
- `max_energy` - Maximum energy capacity
- `attack`, `defense`, `health`, `max_health`, `power` - Combat stats
- `is_online`, `is_banned` - Status flags
- `tutorial_completed` - First-time user flag
- `guild_id`, `guild_role` - Guild membership
- `referral_code` - Unique 8-character referral code (auto-generated)
- `referred_by` - User who referred this player
- Timestamps: `created_at`, `updated_at`, `last_login_at`

### Automatic Profile Creation

When a user signs up via Supabase Auth, a trigger automatically creates their game profile:

```sql
-- Trigger: on_auth_user_created
-- Creates user profile in public.users after auth.users insert
```

## Edge Functions

### `/functions/v1/auth-register`

Registers a new user with email verification.

**Request:**
```json
{
  "email": "user@example.com",
  "username": "player123",
  "password": "securepass123",
  "referral_code": "ABC12345" // optional
}
```

**Validation:**
- Email: Valid format
- Username: 3-20 characters, unique
- Password: Minimum 8 characters
- Referral code: Must exist if provided

**Response (Success):**
```json
{
  "success": true,
  "message": "Kayıt başarılı!",
  "data": {
    "session": {
      "access_token": "...",
      "refresh_token": "...",
      "expires_in": 3600
    },
    "user": {
      "id": "uuid",
      "username": "player123",
      "email": "user@example.com",
      "level": 1,
      "gold": 1000,
      // ... all user fields
    }
  }
}
```

**Response (Error):**
```json
{
  "success": false,
  "error": {
    "message": "Bu kullanıcı adı zaten kullanılıyor"
  }
}
```

### `/functions/v1/auth-login`

Authenticates user with email/username and password.

**Request:**
```json
{
  "email": "user@example.com",  // OR
  "username": "player123",       // username instead of email
  "password": "securepass123"
}
```

**Features:**
- Accepts either email or username
- If username provided, looks up email automatically
- Updates `last_login_at` and `is_online` status

**Response (Success):**
```json
{
  "success": true,
  "message": "Giriş başarılı!",
  "data": {
    "session": {
      "access_token": "...",
      "refresh_token": "...",
      "expires_in": 3600
    },
    "user": {
      "id": "uuid",
      "username": "player123",
      "level": 5,
      "gold": 15000,
      // ... all user fields
    }
  }
}
```

**Response (Error):**
```json
{
  "success": false,
  "error": {
    "message": "E-posta veya şifre hatalı"
  }
}
```

## RPC Functions

### `get_current_user()`

Gets current authenticated user's profile.

```sql
SELECT * FROM get_current_user();
```

**Returns:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "username": "player123",
    // ... all user fields
  }
}
```

### `update_user_profile(p_display_name, p_avatar_url)`

Updates user profile fields.

```sql
SELECT * FROM update_user_profile('NewName', 'https://...');
```

### `update_last_login()`

Updates last_login_at timestamp.

```sql
SELECT * FROM update_last_login();
```

## Security

### Row Level Security (RLS)

Enabled on `public.users` table:

1. **users_select_own**: Users can read their own data
2. **users_update_own**: Users can update their own data
3. **users_select_public**: All users can read public profile data (for leaderboards, PvP)

### Permissions

- `authenticated` role: SELECT, INSERT, UPDATE on users
- `anon` role: SELECT only (public profiles)
- Service role: Full access via Edge Functions

## Game Integration

### SessionManager.gd

Handles authentication flow:

```gdscript
# Register
Session.register(email, username, password, referral_code)

# Login
Session.login(username_or_email, password)

# Get current user
var user = await Network.http_get(APIEndpoints.PLAYER_PROFILE)
```

### LoginScreen.gd

UI for login:
- Username/email input
- Password input (minimum 8 characters)
- Remember me checkbox (saves credentials locally)
- Status messages in Turkish

### RegisterDialog.gd

UI for registration:
- Email validation
- Username validation (3-20 characters)
- Password confirmation
- Optional referral code
- Status messages in Turkish

## Setup Instructions

### 1. Run SQL Migration

```bash
psql -U postgres -d your_database -f supabase/sql/00_auth_users_table.sql
```

This creates:
- `public.users` table
- Indexes for performance
- RLS policies
- Triggers for auto-profile creation
- RPC functions

### 2. Deploy Edge Functions

```bash
supabase functions deploy auth-register
supabase functions deploy auth-login
```

### 3. Update Environment Variables

Ensure these are set in Supabase:
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

### 4. Configure APIEndpoints.gd

Update the BASE_URL in `core/network/APIEndpoints.gd`:

```gdscript
const BASE_URL = "https://your-project.supabase.co"
```

## Testing

### Register New User

```bash
curl -X POST https://your-project.supabase.co/functions/v1/auth-register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "username": "testuser",
    "password": "testpass123"
  }'
```

### Login

```bash
curl -X POST https://your-project.supabase.co/functions/v1/auth-login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "testpass123"
  }'
```

### Verify User Profile

```sql
SELECT * FROM public.users WHERE username = 'testuser';
```

## Troubleshooting

### "No public.users row found"

**Problem:** Auth user created but no game profile.

**Solution:** Run the SQL migration to create the trigger:
```sql
-- The trigger handles this automatically
CREATE TRIGGER on_auth_user_created ...
```

### "User profile not found"

**Problem:** Session valid but profile missing.

**Solution:** Create profile manually or re-register:
```sql
INSERT INTO public.users (auth_id, email, username)
SELECT id, email, raw_user_meta_data->>'username'
FROM auth.users
WHERE id = 'user-auth-id';
```

### "Username already exists"

**Problem:** Username taken during registration.

**Solution:** Choose a different username. Usernames are unique.

### Edge Function Not Found

**Problem:** 404 on `/functions/v1/auth-login`

**Solution:** Deploy the functions:
```bash
supabase functions deploy auth-login
supabase functions deploy auth-register
```

## Features

### ✅ Email & Username Login
Users can login with either email or username

### ✅ Auto-Profile Creation
User profile automatically created on signup

### ✅ Referral System
Players can refer friends using unique codes

### ✅ Password Validation
Minimum 8 characters enforced

### ✅ Remember Me
Credentials saved locally (optional)

### ✅ Turkish UI
All messages in Turkish for target audience

### ✅ Session Management
JWT tokens with refresh capability

### ✅ Starting Resources
New players get 1000 gold, level 1

### ✅ Security
RLS policies, CORS headers, input validation

## Future Enhancements

- [ ] Email verification (currently auto-confirmed)
- [ ] Password reset flow
- [ ] OAuth providers (Google, Discord, etc.)
- [ ] Two-factor authentication
- [ ] Account linking (multiple providers)
- [ ] Session management UI (active sessions, logout all)
- [ ] Account deletion
- [ ] Username change (with cooldown)
