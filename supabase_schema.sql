-- ==============================================================================
-- WARISAN KITA: SUPABASE DATABASE SCHEMA MIGRATION SCRIPT
-- ==============================================================================
-- Module: User Authentication, Dual-Role (Artisan & Tourist), & Admin Moderation
-- Database: PostgreSQL / Supabase
-- Target Table: public.users
-- ==============================================================================

-- 1. Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Create or Update `public.users` Table
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    username TEXT UNIQUE,
    full_name TEXT,
    display_name TEXT,
    role TEXT NOT NULL DEFAULT 'Tourist',
    roles TEXT[] NOT NULL DEFAULT ARRAY['Tourist']::TEXT[],
    status TEXT NOT NULL DEFAULT 'ACTIVE',
    
    -- Master Artisan Studio Metadata
    studio_name TEXT,
    craft_category TEXT,
    ssm_number TEXT,
    ssm_file_url TEXT,
    cert_file_url TEXT,
    workshop_photos TEXT[] DEFAULT ARRAY[]::TEXT[],
    bio TEXT,
    phone TEXT,
    state TEXT,
    address TEXT,
    plaques INTEGER DEFAULT 1,
    is_live_open BOOLEAN DEFAULT TRUE,
    
    -- Account Flags & Timestamps
    is_suspended BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Ensure Missing Columns Exist (for existing tables)
DO $$ 
BEGIN
    -- Username & Display Names
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='username') THEN
        ALTER TABLE public.users ADD COLUMN username TEXT UNIQUE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='display_name') THEN
        ALTER TABLE public.users ADD COLUMN display_name TEXT;
    END IF;
    
    -- Dual Roles & Status
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='roles') THEN
        ALTER TABLE public.users ADD COLUMN roles TEXT[] NOT NULL DEFAULT ARRAY['Tourist']::TEXT[];
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='status') THEN
        ALTER TABLE public.users ADD COLUMN status TEXT NOT NULL DEFAULT 'ACTIVE';
    END IF;

    -- Drop outdated/restrictive CHECK constraints from old migrations
    ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_role_check;
    ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_status_check;

    -- Artisan Details
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='studio_name') THEN
        ALTER TABLE public.users ADD COLUMN studio_name TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='craft_category') THEN
        ALTER TABLE public.users ADD COLUMN craft_category TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='ssm_number') THEN
        ALTER TABLE public.users ADD COLUMN ssm_number TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='ssm_file_url') THEN
        ALTER TABLE public.users ADD COLUMN ssm_file_url TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='cert_file_url') THEN
        ALTER TABLE public.users ADD COLUMN cert_file_url TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='workshop_photos') THEN
        ALTER TABLE public.users ADD COLUMN workshop_photos TEXT[] DEFAULT ARRAY[]::TEXT[];
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='bio') THEN
        ALTER TABLE public.users ADD COLUMN bio TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='phone') THEN
        ALTER TABLE public.users ADD COLUMN phone TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='state') THEN
        ALTER TABLE public.users ADD COLUMN state TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='plaques') THEN
        ALTER TABLE public.users ADD COLUMN plaques INTEGER DEFAULT 1;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='is_live_open') THEN
        ALTER TABLE public.users ADD COLUMN is_live_open BOOLEAN DEFAULT TRUE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='is_suspended') THEN
        ALTER TABLE public.users ADD COLUMN is_suspended BOOLEAN DEFAULT FALSE;
    END IF;
END $$;

-- 4. Create Performance & Lookup Indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_status ON public.users(status);

-- 5. Automatic `updated_at` Trigger Function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_users_updated_at ON public.users;
CREATE TRIGGER set_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- 6. Automatic User Sync Trigger on Auth Signup
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER AS $$
DECLARE
    v_username TEXT;
    v_fullname TEXT;
    v_role TEXT;
    v_status TEXT;
    v_studio TEXT;
    v_craft TEXT;
    v_ssm TEXT;
BEGIN
    v_username := NEW.raw_user_meta_data->>'username';
    v_fullname := COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.raw_user_meta_data->>'full_name', v_username, split_part(NEW.email, '@', 1));
    v_role := COALESCE(NEW.raw_user_meta_data->>'role', 'Tourist');
    v_status := COALESCE(NEW.raw_user_meta_data->>'status', CASE WHEN v_role LIKE '%Artisan%' THEN 'PENDING_APPROVAL' ELSE 'ACTIVE' END);
    v_studio := NEW.raw_user_meta_data->>'studio_name';
    v_craft := COALESCE(NEW.raw_user_meta_data->>'craft_category', 'Pottery & Ceramics');
    v_ssm := NEW.raw_user_meta_data->>'ssm_number';

    -- 1. Insert core identity into public.users
    INSERT INTO public.users (
        id,
        email,
        username,
        full_name,
        display_name,
        role,
        status,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        NEW.email,
        v_username,
        v_fullname,
        v_fullname,
        v_role,
        v_status,
        now(),
        now()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        username = COALESCE(EXCLUDED.username, public.users.username),
        full_name = COALESCE(EXCLUDED.full_name, public.users.full_name),
        display_name = COALESCE(EXCLUDED.display_name, public.users.display_name),
        role = EXCLUDED.role,
        status = EXCLUDED.status,
        updated_at = now();

    -- 2. If Artisan, insert professional details into public.artisan_profiles
    IF v_role LIKE '%Artisan%' OR (v_studio IS NOT NULL AND v_studio != '') THEN
        INSERT INTO public.artisan_profiles (
            user_id,
            studio_name,
            craft_category,
            ssm_number,
            bio,
            address,
            state,
            status,
            created_at,
            updated_at
        ) VALUES (
            NEW.id,
            COALESCE(v_studio, v_fullname, 'Master Artisan Studio'),
            v_craft,
            v_ssm,
            'Master artisan dedicated to traditional Malaysian craft.',
            'Malaysia',
            'Melaka',
            v_status,
            now(),
            now()
        )
        ON CONFLICT DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

-- 7. Helper Function for Admin Check
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid()
        AND role = 'Admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Public Security-Definer RPC Function for Registration Account Lookup
CREATE OR REPLACE FUNCTION public.check_account_by_email(p_email text)
RETURNS TABLE (
    user_id uuid,
    email text,
    username text,
    full_name text,
    display_name text,
    role text,
    status text,
    studio_name text,
    craft_category text,
    ssm_number text
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id AS user_id,
        u.email,
        u.username,
        u.full_name,
        u.display_name,
        u.role,
        u.status,
        ap.studio_name,
        ap.craft_category,
        ap.ssm_number
    FROM public.users u
    LEFT JOIN public.artisan_profiles ap ON ap.user_id = u.id
    WHERE lower(u.email) = lower(trim(p_email));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Public Security-Definer RPC Function for Moderation (Approve / Reject / Suspend)
CREATE OR REPLACE FUNCTION public.admin_update_user_status(
    p_email text,
    p_status text,
    p_role text DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_user_id uuid;
    v_artisan_status text;
BEGIN
    -- 1. Find user id
    SELECT id INTO v_user_id
    FROM public.users
    WHERE lower(trim(email)) = lower(trim(p_email));

    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'User not found');
    END IF;

    -- 2. Update public.users status and role
    UPDATE public.users
    SET 
        status = p_status,
        role = COALESCE(p_role, role),
        updated_at = now()
    WHERE id = v_user_id;

    -- 3. Update auth.users user_metadata status and role if auth user exists
    UPDATE auth.users
    SET raw_user_meta_data = raw_user_meta_data || 
        jsonb_build_object(
            'status', p_status,
            'role', COALESCE(p_role, raw_user_meta_data->>'role')
        )
    WHERE id = v_user_id;

    -- 4. Update public.artisan_profiles status
    IF upper(p_status) IN ('ACTIVE', 'APPROVED') THEN
        v_artisan_status := 'APPROVED';
    ELSE
        v_artisan_status := p_status;
    END IF;

    UPDATE public.artisan_profiles
    SET 
        status = v_artisan_status,
        updated_at = now()
    WHERE user_id = v_user_id;

    RETURN jsonb_build_object('success', true, 'user_id', v_user_id, 'status', p_status);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions on tables and RPC functions
GRANT SELECT, INSERT, UPDATE ON public.users TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON public.artisan_profiles TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON public.artisan_documents TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.check_account_by_email(text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_update_user_status(text, text, text) TO anon, authenticated;

-- Policies for public.users and public.artisan_profiles
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.artisan_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.artisan_documents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public select users" ON public.users;
CREATE POLICY "Public select users" ON public.users FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public update users" ON public.users;
CREATE POLICY "Public update users" ON public.users FOR UPDATE USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public insert users" ON public.users;
CREATE POLICY "Public insert users" ON public.users FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Public select artisan_profiles" ON public.artisan_profiles;
CREATE POLICY "Public select artisan_profiles" ON public.artisan_profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public update artisan_profiles" ON public.artisan_profiles;
CREATE POLICY "Public update artisan_profiles" ON public.artisan_profiles FOR UPDATE USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public select artisan_documents" ON public.artisan_documents;
CREATE POLICY "Public select artisan_documents" ON public.artisan_documents FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public update artisan_documents" ON public.artisan_documents;
CREATE POLICY "Public update artisan_documents" ON public.artisan_documents FOR UPDATE USING (true) WITH CHECK (true);

-- ==============================================================================
-- 7. Forum Module Tables, Voting, & Stored Procedures
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.forum_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    tag TEXT DEFAULT 'General',
    community TEXT DEFAULT 'c/General',
    title TEXT NOT NULL,
    content TEXT,
    upvotes INTEGER DEFAULT 0,
    is_solved BOOLEAN DEFAULT FALSE,
    is_edited BOOLEAN DEFAULT FALSE,
    is_reported BOOLEAN DEFAULT FALSE,
    report_reason TEXT,
    report_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.forum_replies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES public.forum_posts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    parent_reply_id UUID REFERENCES public.forum_replies(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    upvotes INTEGER DEFAULT 0,
    is_verified_answer BOOLEAN DEFAULT FALSE,
    is_edited BOOLEAN DEFAULT FALSE,
    is_reported BOOLEAN DEFAULT FALSE,
    report_reason TEXT,
    report_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.forum_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID REFERENCES public.forum_posts(id) ON DELETE CASCADE,
    reply_id UUID REFERENCES public.forum_replies(id) ON DELETE CASCADE,
    reporter_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    reason TEXT NOT NULL,
    notes TEXT,
    status TEXT DEFAULT 'pending', -- pending, dismissed, actioned
    resolution_notes TEXT,
    action_type TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    resolved_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.forum_post_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES public.forum_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    vote INTEGER NOT NULL CHECK (vote IN (-1, 1)),
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(post_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.forum_reply_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reply_id UUID NOT NULL REFERENCES public.forum_replies(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    vote INTEGER NOT NULL CHECK (vote IN (-1, 1)),
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(reply_id, user_id)
);

-- Stored procedure for atomic post voting
CREATE OR REPLACE FUNCTION public.vote_forum_post(p_post_id UUID, p_vote INT)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_current_vote INT := 0;
    v_new_vote INT := 0;
    v_delta INT := 0;
    v_new_upvotes INT := 0;
BEGIN
    IF v_user_id IS NULL THEN
        -- Fallback to system mock ID if unauthenticated in dev
        v_user_id := '00000000-0000-4000-8000-000000000001'::UUID;
    END IF;

    -- Get existing vote
    SELECT vote INTO v_current_vote FROM public.forum_post_votes WHERE post_id = p_post_id AND user_id = v_user_id;
    IF v_current_vote IS NULL THEN
        v_current_vote := 0;
    END IF;

    -- If user clicks same vote direction, toggle off (0)
    IF v_current_vote = p_vote THEN
        v_new_vote := 0;
        DELETE FROM public.forum_post_votes WHERE post_id = p_post_id AND user_id = v_user_id;
    ELSE
        v_new_vote := p_vote;
        INSERT INTO public.forum_post_votes(post_id, user_id, vote, updated_at)
        VALUES (p_post_id, v_user_id, v_new_vote, now())
        ON CONFLICT (post_id, user_id) DO UPDATE SET vote = v_new_vote, updated_at = now();
    END IF;

    -- Calculate delta and update forum_posts
    v_delta := v_new_vote - v_current_vote;
    UPDATE public.forum_posts SET upvotes = COALESCE(upvotes, 0) + v_delta WHERE id = p_post_id RETURNING upvotes INTO v_new_upvotes;

    RETURN jsonb_build_object('success', true, 'upvotes', v_new_upvotes, 'user_vote', v_new_vote);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Stored procedure for atomic reply voting
CREATE OR REPLACE FUNCTION public.vote_forum_reply(p_reply_id UUID, p_vote INT)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_current_vote INT := 0;
    v_new_vote INT := 0;
    v_delta INT := 0;
    v_new_upvotes INT := 0;
BEGIN
    IF v_user_id IS NULL THEN
        v_user_id := '00000000-0000-4000-8000-000000000001'::UUID;
    END IF;

    SELECT vote INTO v_current_vote FROM public.forum_reply_votes WHERE reply_id = p_reply_id AND user_id = v_user_id;
    IF v_current_vote IS NULL THEN
        v_current_vote := 0;
    END IF;

    IF v_current_vote = p_vote THEN
        v_new_vote := 0;
        DELETE FROM public.forum_reply_votes WHERE reply_id = p_reply_id AND user_id = v_user_id;
    ELSE
        v_new_vote := p_vote;
        INSERT INTO public.forum_reply_votes(reply_id, user_id, vote, updated_at)
        VALUES (p_reply_id, v_user_id, v_new_vote, now())
        ON CONFLICT (reply_id, user_id) DO UPDATE SET vote = v_new_vote, updated_at = now();
    END IF;

    v_delta := v_new_vote - v_current_vote;
    UPDATE public.forum_replies SET upvotes = COALESCE(upvotes, 0) + v_delta WHERE id = p_reply_id RETURNING upvotes INTO v_new_upvotes;

    RETURN jsonb_build_object('success', true, 'upvotes', v_new_upvotes, 'user_vote', v_new_vote);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Stored procedure for reporting a post
CREATE OR REPLACE FUNCTION public.report_forum_post(p_post_id UUID, p_reason TEXT, p_notes TEXT)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID := auth.uid();
BEGIN
    INSERT INTO public.forum_reports(post_id, reporter_id, reason, notes, status, created_at)
    VALUES (p_post_id, v_user_id, p_reason, p_notes, 'pending', now());

    UPDATE public.forum_posts
    SET is_reported = true, report_reason = p_reason, report_notes = p_notes
    WHERE id = p_post_id;

    RETURN jsonb_build_object('success', true, 'already_reported', false);
EXCEPTION
    WHEN unique_violation THEN
        RETURN jsonb_build_object('success', false, 'already_reported', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Stored procedure for reporting a reply
CREATE OR REPLACE FUNCTION public.report_forum_reply(p_reply_id UUID, p_reason TEXT, p_notes TEXT)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID := auth.uid();
BEGIN
    INSERT INTO public.forum_reports(reply_id, reporter_id, reason, notes, status, created_at)
    VALUES (p_reply_id, v_user_id, p_reason, p_notes, 'pending', now());

    UPDATE public.forum_replies
    SET is_reported = true, report_reason = p_reason, report_notes = p_notes
    WHERE id = p_reply_id;

    RETURN jsonb_build_object('success', true, 'already_reported', false);
EXCEPTION
    WHEN unique_violation THEN
        RETURN jsonb_build_object('success', false, 'already_reported', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Stored procedure for dismissing reports
CREATE OR REPLACE FUNCTION public.dismiss_forum_reports(p_post_id UUID, p_reply_id UUID)
RETURNS JSONB AS $$
BEGIN
    IF p_post_id IS NOT NULL THEN
        UPDATE public.forum_reports
        SET status = 'dismissed', resolved_at = now()
        WHERE post_id = p_post_id AND status = 'pending';

        UPDATE public.forum_posts
        SET is_reported = false, report_reason = NULL, report_notes = NULL
        WHERE id = p_post_id;
    END IF;

    IF p_reply_id IS NOT NULL THEN
        UPDATE public.forum_reports
        SET status = 'dismissed', resolved_at = now()
        WHERE reply_id = p_reply_id AND status = 'pending';

        UPDATE public.forum_replies
        SET is_reported = false, report_reason = NULL, report_notes = NULL
        WHERE id = p_reply_id;
    END IF;

    RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Stored procedure for admin deleting forum content
CREATE OR REPLACE FUNCTION public.admin_delete_forum_content(p_post_id UUID, p_reply_id UUID, p_deletion_reason TEXT)
RETURNS JSONB AS $$
BEGIN
    IF p_post_id IS NOT NULL THEN
        UPDATE public.forum_reports
        SET status = 'actioned', action_type = 'deleted', resolution_notes = p_deletion_reason, resolved_at = now()
        WHERE post_id = p_post_id;

        DELETE FROM public.forum_posts WHERE id = p_post_id;
    END IF;

    IF p_reply_id IS NOT NULL THEN
        UPDATE public.forum_reports
        SET status = 'actioned', action_type = 'deleted', resolution_notes = p_deletion_reason, resolved_at = now()
        WHERE reply_id = p_reply_id;

        DELETE FROM public.forum_replies WHERE id = p_reply_id;
    END IF;

    RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_posts TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_replies TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_reports TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_post_votes TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_reply_votes TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.vote_forum_post(UUID, INT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.vote_forum_reply(UUID, INT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.report_forum_post(UUID, TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.report_forum_reply(UUID, TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.dismiss_forum_reports(UUID, UUID) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_delete_forum_content(UUID, UUID, TEXT) TO anon, authenticated;

-- Enable RLS
ALTER TABLE public.forum_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_replies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_post_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_reply_votes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public select forum_posts" ON public.forum_posts FOR SELECT USING (true);
CREATE POLICY "Public insert forum_posts" ON public.forum_posts FOR INSERT WITH CHECK (true);
CREATE POLICY "Public update forum_posts" ON public.forum_posts FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Public delete forum_posts" ON public.forum_posts FOR DELETE USING (true);

CREATE POLICY "Public select forum_replies" ON public.forum_replies FOR SELECT USING (true);
CREATE POLICY "Public insert forum_replies" ON public.forum_replies FOR INSERT WITH CHECK (true);
CREATE POLICY "Public update forum_replies" ON public.forum_replies FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Public delete forum_replies" ON public.forum_replies FOR DELETE USING (true);

CREATE POLICY "Public select forum_reports" ON public.forum_reports FOR SELECT USING (true);
CREATE POLICY "Public insert forum_reports" ON public.forum_reports FOR INSERT WITH CHECK (true);
CREATE POLICY "Public update forum_reports" ON public.forum_reports FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Public delete forum_reports" ON public.forum_reports FOR DELETE USING (true);

CREATE POLICY "Public select forum_post_votes" ON public.forum_post_votes FOR SELECT USING (true);
CREATE POLICY "Public insert forum_post_votes" ON public.forum_post_votes FOR INSERT WITH CHECK (true);
CREATE POLICY "Public update forum_post_votes" ON public.forum_post_votes FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Public delete forum_post_votes" ON public.forum_post_votes FOR DELETE USING (true);

CREATE POLICY "Public select forum_reply_votes" ON public.forum_reply_votes FOR SELECT USING (true);
CREATE POLICY "Public insert forum_reply_votes" ON public.forum_reply_votes FOR INSERT WITH CHECK (true);
CREATE POLICY "Public update forum_reply_votes" ON public.forum_reply_votes FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Public delete forum_reply_votes" ON public.forum_reply_votes FOR DELETE USING (true);
