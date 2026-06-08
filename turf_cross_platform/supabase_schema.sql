-- Enable PostGIS extension to handle geospatial queries
CREATE EXTENSION IF NOT EXISTS postgis;

-- 1. Profiles Table (Saves username & details for authenticated users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for Profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read on profiles" ON public.profiles;
CREATE POLICY "Allow public read on profiles" ON public.profiles FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow users to update own profile" ON public.profiles;
CREATE POLICY "Allow users to update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
DROP POLICY IF EXISTS "Allow users to insert own profile" ON public.profiles;
CREATE POLICY "Allow users to insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- 2. Global Loops Table (Stores the geometric polygon path of all loops)
CREATE TABLE IF NOT EXISTS public.loops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    geom GEOMETRY(Polygon, 4326) NOT NULL, -- GeoSpatial Polygon representing loop path
    centroid GEOMETRY(Point, 4326) NOT NULL, -- Centroid for fast index filtering
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Spatial indexes for maximum geo-query performance
CREATE INDEX IF NOT EXISTS loops_geom_idx ON public.loops USING GIST (geom);
CREATE INDEX IF NOT EXISTS loops_centroid_idx ON public.loops USING GIST (centroid);

-- Enable RLS for Loops
ALTER TABLE public.loops ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read on loops" ON public.loops;
CREATE POLICY "Allow public read on loops" ON public.loops FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow users to create loops" ON public.loops;
CREATE POLICY "Allow users to create loops" ON public.loops FOR INSERT WITH CHECK (auth.uid() = created_by);
DROP POLICY IF EXISTS "Allow users to update own loops" ON public.loops;
CREATE POLICY "Allow users to update own loops" ON public.loops FOR UPDATE USING (auth.uid() = created_by);

-- 3. Competitive Loop Claims Table (Single Owner Competitive Claiming)
CREATE TABLE IF NOT EXISTS public.claims_all (
    loop_id UUID REFERENCES public.loops(id) ON DELETE CASCADE PRIMARY KEY, -- Enforces single claim per loop!
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    streak_count INTEGER DEFAULT 1 NOT NULL,
    last_covered_date DATE DEFAULT CURRENT_DATE NOT NULL,
    covered_count_today INTEGER DEFAULT 1 NOT NULL,
    claimed_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS claims_user_idx ON public.claims_all (user_id);

-- Enable RLS for Claims
ALTER TABLE public.claims_all ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow users to delete own claims" ON public.claims_all;
CREATE POLICY "Allow users to delete own claims" ON public.claims_all FOR DELETE USING (auth.uid() = user_id);

-- Expose public claims view that conditionally exposes private statistics
CREATE OR REPLACE VIEW public.claims AS
SELECT 
    loop_id,
    user_id,
    claimed_at,
    streak_count,
    last_covered_date,
    covered_count_today
FROM public.claims_all;

-- Grant permissions on the view and base table
GRANT SELECT ON public.claims TO anon, authenticated, service_role;
GRANT DELETE ON public.claims TO authenticated;
GRANT DELETE ON public.claims_all TO authenticated;

-- 4. Walk Sessions Table (Completed user walks)
CREATE TABLE IF NOT EXISTS public.walk_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    steps INTEGER NOT NULL,
    distance_km DOUBLE PRECISION NOT NULL,
    duration_seconds INTEGER NOT NULL,
    cadence INTEGER DEFAULT 0 NOT NULL,
    elevation_gain_metres DOUBLE PRECISION DEFAULT 0.0 NOT NULL,
    geom GEOMETRY(LineString, 4326), -- Live path trace
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS walk_sessions_geom_idx ON public.walk_sessions USING GIST (geom);

-- Enable RLS for Walk Sessions
ALTER TABLE public.walk_sessions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow users to view own walk sessions" ON public.walk_sessions;
CREATE POLICY "Allow users to view own walk sessions" ON public.walk_sessions FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Allow users to insert own walk sessions" ON public.walk_sessions;
CREATE POLICY "Allow users to insert own walk sessions" ON public.walk_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);


-- Core RPC Function: claim_loop_attempt
-- Evaluates a newly completed loop coordinates path, performs similarity checks via PostGIS centroid + IoU area ratios, and handles ownership claiming/takeovers.
CREATE OR REPLACE FUNCTION public.claim_loop_attempt(
    p_user_id UUID,
    p_trail_coords TEXT, -- WKT Polygon format e.g. 'POLYGON((lng1 lat1, lng2 lat2, ...))'
    p_default_name TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_new_geom GEOMETRY;
    v_new_centroid GEOMETRY;
    v_new_geom_3857 GEOMETRY;
    v_new_geom_buffered_3857 GEOMETRY;
    v_matched_loop_id UUID := NULL;
    v_matched_loop_name TEXT;
    v_matched_loop_geom GEOMETRY;
    
    r_candidate RECORD;
    r_geom_3857 GEOMETRY;
    v_iou DOUBLE PRECISION;
    v_intersection_area DOUBLE PRECISION;
    v_union_area DOUBLE PRECISION;
    
    v_claim_exists BOOLEAN;
    v_claim_owner UUID;
    v_claim_streak INTEGER;
    v_claim_last_date DATE;
    v_claim_covered_today INTEGER;
    
    v_status TEXT := 'new'; -- 'new', 'claimed', 'challenged', 'takeover'
    v_result JSONB;
BEGIN
    -- 1. Create geometry from input coordinates WKT
    BEGIN
        v_new_geom := ST_GeomFromText(p_trail_coords, 4326);
        v_new_centroid := ST_Centroid(v_new_geom);
        
        -- Project to Web Mercator (EPSG:3857) and buffer by 10.0m once to optimize calculations
        v_new_geom_3857 := ST_Transform(v_new_geom, 3857);
        v_new_geom_buffered_3857 := ST_Buffer(v_new_geom_3857, 10.0);
    EXCEPTION WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid coordinates WKT format');
    END;

    -- 2. Find candidate loops within 30-meters centroid distance (Fast indexed sargable lookup: 0.0003 deg ~= 33m)
    FOR r_candidate IN 
        SELECT id, name, geom 
        FROM public.loops 
        WHERE ST_DWithin(centroid, v_new_centroid, 0.0003)
    LOOP
        -- Calculate Area-buffered IoU using flat Cartesian math in 3857
        r_geom_3857 := ST_Transform(r_candidate.geom, 3857);
        v_intersection_area := ST_Area(ST_Intersection(v_new_geom_buffered_3857, ST_Buffer(r_geom_3857, 10.0)));
        v_union_area := ST_Area(ST_Union(v_new_geom_buffered_3857, ST_Buffer(r_geom_3857, 10.0)));
        
        IF v_union_area > 0 THEN
            v_iou := v_intersection_area / v_union_area;
            IF v_iou >= 0.70 THEN
                v_matched_loop_id := r_candidate.id;
                v_matched_loop_name := r_candidate.name;
                v_matched_loop_geom := r_candidate.geom;
                EXIT; -- Match found! Break loop
            END IF;
        END IF;
    END LOOP;

    -- 3. Handle claiming or matching logic
    IF v_matched_loop_id IS NOT NULL THEN
        -- Loop exists: Check if claimed
        SELECT EXISTS(SELECT 1 FROM public.claims_all WHERE loop_id = v_matched_loop_id) INTO v_claim_exists;
        
        IF v_claim_exists THEN
            SELECT user_id, streak_count, last_covered_date, covered_count_today 
            INTO v_claim_owner, v_claim_streak, v_claim_last_date, v_claim_covered_today
            FROM public.claims_all 
            WHERE loop_id = v_matched_loop_id;
            
            IF v_claim_owner = p_user_id THEN
                -- Same owner: Increment counts
                IF v_claim_last_date = CURRENT_DATE THEN
                    v_claim_covered_today := v_claim_covered_today + 1;
                ELSIF v_claim_last_date = (CURRENT_DATE - INTERVAL '1 day')::DATE THEN
                    v_claim_streak := v_claim_streak + 1;
                    v_claim_last_date := CURRENT_DATE;
                    v_claim_covered_today := 1;
                ELSE
                    v_claim_streak := 1;
                    v_claim_last_date := CURRENT_DATE;
                    v_claim_covered_today := 1;
                END IF;
                
                UPDATE public.claims_all 
                SET streak_count = v_claim_streak,
                    last_covered_date = v_claim_last_date,
                    covered_count_today = v_claim_covered_today
                WHERE loop_id = v_matched_loop_id;
                
                v_status := 'covered_streak';
            ELSE
                -- Different owner: Check if streak is broken (last covered older than yesterday)
                IF v_claim_last_date < (CURRENT_DATE - INTERVAL '1 day')::DATE THEN
                    -- Takeover: Capture loop!
                    UPDATE public.claims_all 
                    SET user_id = p_user_id,
                        streak_count = 1,
                        last_covered_date = CURRENT_DATE,
                        covered_count_today = 1,
                        claimed_at = now()
                    WHERE loop_id = v_matched_loop_id;
                    
                    v_status := 'takeover';
                ELSE
                    -- Owner's streak is active: Challenge increments internally but owner doesn't change
                    v_status := 'challenged';
                END IF;
            END IF;
        ELSE
            -- Loop exists but unclaimed: Claim it
            INSERT INTO public.claims_all (loop_id, user_id, streak_count, last_covered_date, covered_count_today)
            VALUES (v_matched_loop_id, p_user_id, 1, CURRENT_DATE, 1);
            v_status := 'claimed';
        END IF;
    ELSE
        -- Loop doesn't exist: Create new loop and claim it
        INSERT INTO public.loops (name, geom, centroid, created_by)
        VALUES (p_default_name, v_new_geom, v_new_centroid, p_user_id)
        RETURNING id, name, geom INTO v_matched_loop_id, v_matched_loop_name, v_matched_loop_geom;
        
        INSERT INTO public.claims_all (loop_id, user_id, streak_count, last_covered_date, covered_count_today)
        VALUES (v_matched_loop_id, p_user_id, 1, CURRENT_DATE, 1);
        v_status := 'new_loop';
    END IF;

    -- Return full result
    SELECT jsonb_build_object(
        'success', true,
        'status', v_status,
        'loop_id', v_matched_loop_id,
        'name', COALESCE(v_matched_loop_name, p_default_name),
        'streak', COALESCE(v_claim_streak, 1),
        'covered_count_today', COALESCE(v_claim_covered_today, 1)
    ) INTO v_result;

    RETURN v_result;
END;
$$;


-- RPC Function to link anonymous data to upgraded user account
CREATE OR REPLACE FUNCTION public.link_anonymous_data(p_old_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_new_user_id UUID := auth.uid();
BEGIN
    IF v_new_user_id IS NULL OR p_old_user_id = v_new_user_id THEN
        RETURN;
    END IF;

    -- Delete conflicting claims (if new user already claimed this loop)
    DELETE FROM public.claims_all c_old
    WHERE c_old.user_id = p_old_user_id
      AND EXISTS (
          SELECT 1 
          FROM public.claims_all c_new 
          WHERE c_new.loop_id = c_old.loop_id 
            AND c_new.user_id = v_new_user_id
      );

    -- Transfer claims
    UPDATE public.claims_all
    SET user_id = v_new_user_id
    WHERE user_id = p_old_user_id;

    -- Transfer walk sessions
    UPDATE public.walk_sessions
    SET user_id = v_new_user_id
    WHERE user_id = p_old_user_id;

    -- Transfer loops
    UPDATE public.loops
    SET created_by = v_new_user_id
    WHERE created_by = p_old_user_id;
END;
$$;


-- RPC Function to fetch loops in radius, returning a JSONB representation matching direct select structure
CREATE OR REPLACE FUNCTION public.get_loops_in_radius(
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION,
    p_radius_meters DOUBLE PRECISION
)
RETURNS TABLE (
    data JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT jsonb_build_object(
        'loop_id', l.id,
        'user_id', c.user_id,
        'claimed_at', c.claimed_at,
        'streak_count', c.streak_count,
        'last_covered_date', c.last_covered_date,
        'covered_count_today', c.covered_count_today,
        'loops', jsonb_build_object(
            'id', l.id,
            'name', l.name,
            'geom', ST_AsText(l.geom)
        ),
        'profiles', CASE WHEN p.username IS NOT NULL THEN jsonb_build_object('username', p.username) ELSE NULL END
    )
    FROM public.loops l
    LEFT JOIN public.claims_all c ON l.id = c.loop_id AND c.last_covered_date >= (CURRENT_DATE - INTERVAL '1 day')::DATE
    LEFT JOIN public.profiles p ON c.user_id = p.id
    WHERE ST_DWithin(l.centroid, ST_SetSRID(ST_Point(p_lng, p_lat), 4326), p_radius_meters / 111000.0);
END;
$$;

