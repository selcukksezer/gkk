-- ============================================================
-- GUILD SYSTEM — gkk-web uyumlu
-- Kaynak: scenes/ui/screens/GuildScreen.gd (350+ satır)
-- RPCs: get_my_guild, search_guilds, join_guild, leave_guild,
--        create_guild, guild_member_manage, invite_to_guild
-- ============================================================

-- ============================================================
-- 1. GUILDS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.guilds (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    name            TEXT        UNIQUE NOT NULL,
    description     TEXT,
    tag             TEXT        UNIQUE,  -- Short 3-5 char tag
    leader_id       UUID        NOT NULL REFERENCES auth.users(id),
    level           INT         NOT NULL DEFAULT 1,
    experience      BIGINT      NOT NULL DEFAULT 0,
    gold            BIGINT      NOT NULL DEFAULT 0,
    max_members     INT         NOT NULL DEFAULT 20,
    member_count    INT         NOT NULL DEFAULT 1,
    total_power     BIGINT      NOT NULL DEFAULT 0,
    is_public       BOOLEAN     NOT NULL DEFAULT TRUE,
    min_level_required INT      NOT NULL DEFAULT 1,
    emblem          TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_guilds_name ON public.guilds(name);
CREATE INDEX IF NOT EXISTS idx_guilds_leader_id ON public.guilds(leader_id);
CREATE INDEX IF NOT EXISTS idx_guilds_total_power ON public.guilds(total_power DESC);

-- ============================================================
-- 2. GUILD MEMBERS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.guild_members (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    guild_id        UUID        NOT NULL REFERENCES public.guilds(id) ON DELETE CASCADE,
    user_id         UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role            TEXT        NOT NULL DEFAULT 'member', -- leader, officer, member
    contribution    BIGINT      NOT NULL DEFAULT 0,
    weekly_contribution BIGINT  NOT NULL DEFAULT 0,
    joined_at       TIMESTAMPTZ DEFAULT NOW(),
    last_online_at  TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

CREATE INDEX IF NOT EXISTS idx_guild_members_guild_id ON public.guild_members(guild_id);
CREATE INDEX IF NOT EXISTS idx_guild_members_user_id ON public.guild_members(user_id);

-- ============================================================
-- 3. GUILD INVITATIONS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.guild_invitations (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    guild_id        UUID        NOT NULL REFERENCES public.guilds(id) ON DELETE CASCADE,
    inviter_id      UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    invitee_id      UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status          TEXT        NOT NULL DEFAULT 'pending', -- pending, accepted, declined, expired
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    expires_at      TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),
    UNIQUE(guild_id, invitee_id)
);

CREATE INDEX IF NOT EXISTS idx_guild_invitations_invitee_id ON public.guild_invitations(invitee_id);

-- ============================================================
-- 4. RPC: get_my_guild
-- Godot: GuildManager.get_player_guild()
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_my_guild()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id UUID;
    v_user    RECORD;
    v_guild   RECORD;
    v_members JSONB;
    v_my_role TEXT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    -- Check if user is in a guild
    SELECT guild_id INTO v_user FROM public.users WHERE auth_id = v_user_id;
    IF v_user.guild_id IS NULL THEN
        RETURN jsonb_build_object('in_guild', FALSE);
    END IF;

    -- Get guild data
    SELECT * INTO v_guild FROM public.guilds WHERE id = v_user.guild_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('in_guild', FALSE);
    END IF;

    -- Get user's role
    SELECT gm.role INTO v_my_role FROM public.guild_members gm WHERE gm.guild_id = v_user.guild_id AND gm.user_id = v_user_id;

    -- Get members with user info
    SELECT jsonb_agg(
        jsonb_build_object(
            'id',           gm.id,
            'user_id',      gm.user_id,
            'username',     u.username,
            'display_name', u.display_name,
            'level',        u.level,
            'role',         gm.role,
            'contribution', gm.contribution,
            'is_online',    (u.updated_at > NOW() - INTERVAL '5 minutes'),
            'joined_at',    gm.joined_at,
            'last_online',  gm.last_online_at
        )
        ORDER BY
            CASE gm.role WHEN 'leader' THEN 1 WHEN 'officer' THEN 2 ELSE 3 END,
            u.level DESC
    )
    INTO v_members
    FROM public.guild_members gm
    JOIN public.users u ON u.auth_id = gm.user_id
    WHERE gm.guild_id = v_user.guild_id;

    RETURN jsonb_build_object(
        'in_guild',     TRUE,
        'id',           v_guild.id,
        'name',         v_guild.name,
        'description',  v_guild.description,
        'tag',          v_guild.tag,
        'level',        v_guild.level,
        'experience',   v_guild.experience,
        'gold',         v_guild.gold,
        'max_members',  v_guild.max_members,
        'member_count', v_guild.member_count,
        'total_power',  v_guild.total_power,
        'is_public',    v_guild.is_public,
        'emblem',       v_guild.emblem,
        'my_role',      v_my_role,
        'members',      COALESCE(v_members, '[]'::jsonb),
        'created_at',   v_guild.created_at
    );
END;
$$;

-- ============================================================
-- 5. RPC: search_guilds
-- Godot: GuildManager — search for guilds to join
-- ============================================================
CREATE OR REPLACE FUNCTION public.search_guilds(
    p_search TEXT DEFAULT '',
    p_limit  INT  DEFAULT 20
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id UUID;
    v_result  JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT jsonb_agg(
        jsonb_build_object(
            'id',           g.id,
            'name',         g.name,
            'description',  g.description,
            'tag',          g.tag,
            'level',        g.level,
            'member_count', g.member_count,
            'max_members',  g.max_members,
            'total_power',  g.total_power,
            'min_level',    g.min_level_required,
            'is_public',    g.is_public,
            'emblem',       g.emblem
        )
        ORDER BY g.total_power DESC, g.member_count DESC
    )
    INTO v_result
    FROM public.guilds g
    WHERE g.is_public = TRUE
      AND g.member_count < g.max_members
      AND (p_search = '' OR g.name ILIKE '%' || p_search || '%' OR g.tag ILIKE '%' || p_search || '%')
    LIMIT p_limit;

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- ============================================================
-- 6. RPC: create_guild
-- Godot: (Web extra) — create a new guild
-- ============================================================
CREATE OR REPLACE FUNCTION public.create_guild(
    p_name        TEXT,
    p_description TEXT DEFAULT '',
    p_tag         TEXT DEFAULT NULL,
    p_is_public   BOOLEAN DEFAULT TRUE,
    p_min_level   INT DEFAULT 1
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id    UUID;
    v_user       RECORD;
    v_new_guild_id UUID;
    v_create_cost INT := 1000; -- 1000 gold to create guild
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT * INTO v_user FROM public.users WHERE auth_id = v_user_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Kullanıcı bulunamadı');
    END IF;

    -- Already in guild?
    IF v_user.guild_id IS NOT NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Zaten bir loncadasınız');
    END IF;

    -- Gold check
    IF v_user.gold < v_create_cost THEN
        RETURN jsonb_build_object('success', false, 'error', format('%s altın gerekli', v_create_cost));
    END IF;

    -- Name validation
    IF length(p_name) < 3 OR length(p_name) > 30 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Lonca adı 3-30 karakter olmalı');
    END IF;

    -- Check name uniqueness
    IF EXISTS (SELECT 1 FROM public.guilds WHERE name ILIKE p_name) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Bu isimde lonca mevcut');
    END IF;

    -- Deduct gold
    UPDATE public.users SET gold = gold - v_create_cost, updated_at = NOW() WHERE auth_id = v_user_id;

    -- Create guild
    INSERT INTO public.guilds (name, description, tag, leader_id, is_public, min_level_required, member_count, total_power)
    VALUES (p_name, p_description, p_tag, v_user_id, p_is_public, p_min_level, 1, COALESCE(v_user.power, 0))
    RETURNING id INTO v_new_guild_id;

    -- Add leader as member
    INSERT INTO public.guild_members (guild_id, user_id, role, contribution)
    VALUES (v_new_guild_id, v_user_id, 'leader', 0);

    -- Update user guild_id
    UPDATE public.users SET guild_id = v_new_guild_id, guild_role = 'leader', updated_at = NOW() WHERE auth_id = v_user_id;

    RETURN jsonb_build_object(
        'success',   TRUE,
        'guild_id',  v_new_guild_id,
        'name',      p_name,
        'cost',      v_create_cost
    );
END;
$$;

-- ============================================================
-- 7. RPC: join_guild
-- Godot: GuildManager — join an existing guild
-- ============================================================
CREATE OR REPLACE FUNCTION public.join_guild(p_guild_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id UUID;
    v_user    RECORD;
    v_guild   RECORD;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT * INTO v_user FROM public.users WHERE auth_id = v_user_id;

    IF v_user.guild_id IS NOT NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Zaten bir loncadasınız');
    END IF;

    SELECT * INTO v_guild FROM public.guilds WHERE id = p_guild_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Lonca bulunamadı');
    END IF;

    IF v_guild.member_count >= v_guild.max_members THEN
        RETURN jsonb_build_object('success', false, 'error', 'Lonca dolu');
    END IF;

    IF v_guild.is_public = FALSE THEN
        -- Check for invitation
        IF NOT EXISTS (
            SELECT 1 FROM public.guild_invitations
            WHERE guild_id = p_guild_id AND invitee_id = v_user_id AND status = 'pending' AND expires_at > NOW()
        ) THEN
            RETURN jsonb_build_object('success', false, 'error', 'Bu lonca davetsiz kabul etmiyor');
        END IF;
        -- Accept invitation
        UPDATE public.guild_invitations SET status = 'accepted' WHERE guild_id = p_guild_id AND invitee_id = v_user_id;
    END IF;

    IF v_user.level < v_guild.min_level_required THEN
        RETURN jsonb_build_object('success', false, 'error', format('Seviye %s gerekli', v_guild.min_level_required));
    END IF;

    -- Add member
    INSERT INTO public.guild_members (guild_id, user_id, role)
    VALUES (p_guild_id, v_user_id, 'member')
    ON CONFLICT (user_id) DO NOTHING;

    -- Update guild stats
    UPDATE public.guilds
    SET member_count = member_count + 1,
        total_power = total_power + COALESCE(v_user.power, 0),
        updated_at = NOW()
    WHERE id = p_guild_id;

    -- Update user
    UPDATE public.users SET guild_id = p_guild_id, guild_role = 'member', updated_at = NOW() WHERE auth_id = v_user_id;

    RETURN jsonb_build_object('success', TRUE, 'guild_name', v_guild.name);
END;
$$;

-- ============================================================
-- 8. RPC: leave_guild
-- Godot: GuildManager.leave_guild()
-- ============================================================
CREATE OR REPLACE FUNCTION public.leave_guild()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id  UUID;
    v_user     RECORD;
    v_guild    RECORD;
    v_new_leader UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT * INTO v_user FROM public.users WHERE auth_id = v_user_id;
    IF v_user.guild_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Bir loncada değilsiniz');
    END IF;

    SELECT * INTO v_guild FROM public.guilds WHERE id = v_user.guild_id;

    -- If leader leaving
    IF v_guild.leader_id = v_user_id THEN
        -- Find next officer or member
        SELECT gm.user_id INTO v_new_leader
        FROM public.guild_members gm
        WHERE gm.guild_id = v_user.guild_id
          AND gm.user_id <> v_user_id
        ORDER BY CASE gm.role WHEN 'officer' THEN 1 ELSE 2 END, gm.joined_at
        LIMIT 1;

        IF v_new_leader IS NOT NULL THEN
            -- Transfer leadership
            UPDATE public.guilds SET leader_id = v_new_leader, updated_at = NOW() WHERE id = v_user.guild_id;
            UPDATE public.guild_members SET role = 'leader' WHERE guild_id = v_user.guild_id AND user_id = v_new_leader;
            UPDATE public.users SET guild_role = 'leader' WHERE auth_id = v_new_leader;
        ELSE
            -- Last member — dissolve guild
            DELETE FROM public.guilds WHERE id = v_user.guild_id;
        END IF;
    END IF;

    -- Remove member
    DELETE FROM public.guild_members WHERE guild_id = v_user.guild_id AND user_id = v_user_id;

    -- Update guild stats if guild still exists
    UPDATE public.guilds
    SET member_count = GREATEST(0, member_count - 1),
        total_power  = GREATEST(0, total_power - COALESCE(v_user.power, 0)),
        updated_at   = NOW()
    WHERE id = v_user.guild_id;

    -- Clear user guild
    UPDATE public.users SET guild_id = NULL, guild_role = NULL, updated_at = NOW() WHERE auth_id = v_user_id;

    RETURN jsonb_build_object('success', TRUE, 'message', 'Loncadan ayrıldınız');
END;
$$;

-- ============================================================
-- 9. RPC: guild_member_manage (promote/demote/kick)
-- Godot: GuildManager — member management (leader/officer only)
-- ============================================================
CREATE OR REPLACE FUNCTION public.guild_member_manage(
    p_target_user_id UUID,
    p_action         TEXT  -- 'promote', 'demote', 'kick'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id    UUID;
    v_my_role    TEXT;
    v_guild_id   UUID;
    v_target_role TEXT;
    v_new_role   TEXT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    -- Get actor's guild and role
    SELECT guild_id INTO v_guild_id FROM public.users WHERE auth_id = v_user_id;
    IF v_guild_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Loncada değilsiniz');
    END IF;

    SELECT role INTO v_my_role FROM public.guild_members WHERE guild_id = v_guild_id AND user_id = v_user_id;
    IF v_my_role NOT IN ('leader', 'officer') THEN
        RETURN jsonb_build_object('success', false, 'error', 'Yetkiniz yok');
    END IF;

    -- Cannot act on self
    IF v_user_id = p_target_user_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'Kendinize bu işlemi yapamazsınız');
    END IF;

    -- Get target's role
    SELECT role INTO v_target_role FROM public.guild_members WHERE guild_id = v_guild_id AND user_id = p_target_user_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Üye bulunamadı');
    END IF;

    -- Officers can only manage members
    IF v_my_role = 'officer' AND v_target_role IN ('leader', 'officer') THEN
        RETURN jsonb_build_object('success', false, 'error', 'Subay veya lider üzerinde işlem yapamazsınız');
    END IF;

    CASE p_action
        WHEN 'promote' THEN
            v_new_role := CASE v_target_role WHEN 'member' THEN 'officer' ELSE v_target_role END;
            IF v_my_role <> 'leader' THEN
                RETURN jsonb_build_object('success', false, 'error', 'Yalnızca lider terfi verebilir');
            END IF;
            UPDATE public.guild_members SET role = v_new_role WHERE guild_id = v_guild_id AND user_id = p_target_user_id;
            UPDATE public.users SET guild_role = v_new_role, updated_at = NOW() WHERE auth_id = p_target_user_id;
        WHEN 'demote' THEN
            v_new_role := CASE v_target_role WHEN 'officer' THEN 'member' ELSE v_target_role END;
            IF v_my_role <> 'leader' THEN
                RETURN jsonb_build_object('success', false, 'error', 'Yalnızca lider tenzil edebilir');
            END IF;
            UPDATE public.guild_members SET role = v_new_role WHERE guild_id = v_guild_id AND user_id = p_target_user_id;
            UPDATE public.users SET guild_role = v_new_role, updated_at = NOW() WHERE auth_id = p_target_user_id;
        WHEN 'kick' THEN
            DELETE FROM public.guild_members WHERE guild_id = v_guild_id AND user_id = p_target_user_id;
            UPDATE public.guilds SET member_count = GREATEST(0, member_count - 1), updated_at = NOW() WHERE id = v_guild_id;
            UPDATE public.users SET guild_id = NULL, guild_role = NULL, updated_at = NOW() WHERE auth_id = p_target_user_id;
            v_new_role := 'removed';
        ELSE
            RETURN jsonb_build_object('success', false, 'error', 'Geçersiz işlem');
    END CASE;

    RETURN jsonb_build_object(
        'success', TRUE,
        'action',  p_action,
        'new_role', v_new_role
    );
END;
$$;

-- ============================================================
-- 10. RPC: invite_to_guild
-- Godot: GuildManager — send guild invitation
-- ============================================================
CREATE OR REPLACE FUNCTION public.invite_to_guild(p_target_username TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_user_id    UUID;
    v_guild_id   UUID;
    v_my_role    TEXT;
    v_target_id  UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT guild_id INTO v_guild_id FROM public.users WHERE auth_id = v_user_id;
    IF v_guild_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Loncada değilsiniz');
    END IF;

    SELECT role INTO v_my_role FROM public.guild_members WHERE guild_id = v_guild_id AND user_id = v_user_id;
    IF v_my_role NOT IN ('leader', 'officer') THEN
        RETURN jsonb_build_object('success', false, 'error', 'Davet etme yetkiniz yok');
    END IF;

    -- Find target user
    SELECT auth_id INTO v_target_id FROM public.users WHERE username ILIKE p_target_username;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Oyuncu bulunamadı');
    END IF;

    -- Already in a guild?
    IF EXISTS (SELECT 1 FROM public.users WHERE auth_id = v_target_id AND guild_id IS NOT NULL) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Oyuncu zaten bir loncada');
    END IF;

    -- Send invitation
    INSERT INTO public.guild_invitations (guild_id, inviter_id, invitee_id, status)
    VALUES (v_guild_id, v_user_id, v_target_id, 'pending')
    ON CONFLICT (guild_id, invitee_id) DO UPDATE SET status = 'pending', expires_at = NOW() + INTERVAL '7 days', created_at = NOW();

    RETURN jsonb_build_object('success', TRUE, 'message', 'Davet gönderildi');
END;
$$;

NOTIFY pgrst, 'reload schema';
