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

-- Grant permissions to anonymous and authenticated users
GRANT SELECT ON public.users TO anon, authenticated;
GRANT SELECT ON public.artisan_profiles TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.check_account_by_email(text) TO anon, authenticated;


