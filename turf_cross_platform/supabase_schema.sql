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
CREATE POLICY "Allow public read on profiles" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Allow users to update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
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
CREATE POLICY "Allow public read on loops" ON public.loops FOR SELECT USING (true);
CREATE POLICY "Allow users to create loops" ON public.loops FOR INSERT WITH CHECK (auth.uid() = created_by);

-- 3. Competitive Loop Claims Table (Single Owner Competitive Claiming)
CREATE TABLE IF NOT EXISTS public.claims (
    loop_id UUID REFERENCES public.loops(id) ON DELETE CASCADE PRIMARY KEY, -- Enforces single claim per loop!
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    streak_count INTEGER DEFAULT 1 NOT NULL,
    last_covered_date DATE DEFAULT CURRENT_DATE NOT NULL,
    covered_count_today INTEGER DEFAULT 1 NOT NULL,
    claimed_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS claims_user_idx ON public.claims (user_id);

-- Enable RLS for Claims
ALTER TABLE public.claims ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read on claims" ON public.claims FOR SELECT USING (true);
CREATE POLICY "Allow users to upsert claims" ON public.claims FOR ALL USING (true);

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
CREATE POLICY "Allow users to view own walk sessions" ON public.walk_sessions FOR SELECT USING (auth.uid() = user_id);
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
    v_matched_loop_id UUID := NULL;
    v_matched_loop_name TEXT;
    v_matched_loop_geom GEOMETRY;
    
    r_candidate RECORD;
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
    EXCEPTION WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid coordinates WKT format');
    END;

    -- 2. Find candidate loops within 30-meters centroid distance (Fast indexing lookup)
    FOR r_candidate IN 
        SELECT id, name, geom 
        FROM public.loops 
        WHERE ST_DWithin(centroid::geography, v_new_centroid::geography, 30.0)
    LOOP
        -- Calculate Area-buffered IoU (10m buffer to smooth minor GPS variations)
        v_intersection_area := ST_Area(ST_Intersection(ST_Buffer(v_new_geom::geography, 10.0), ST_Buffer(r_candidate.geom::geography, 10.0)));
        v_union_area := ST_Area(ST_Union(ST_Buffer(v_new_geom::geography, 10.0), ST_Buffer(r_candidate.geom::geography, 10.0)));
        
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
        SELECT EXISTS(SELECT 1 FROM public.claims WHERE loop_id = v_matched_loop_id) INTO v_claim_exists;
        
        IF v_claim_exists THEN
            SELECT user_id, streak_count, last_covered_date, covered_count_today 
            INTO v_claim_owner, v_claim_streak, v_claim_last_date, v_claim_covered_today
            FROM public.claims 
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
                
                UPDATE public.claims 
                SET streak_count = v_claim_streak,
                    last_covered_date = v_claim_last_date,
                    covered_count_today = v_claim_covered_today
                WHERE loop_id = v_matched_loop_id;
                
                v_status := 'covered_streak';
            ELSE
                -- Different owner: Check if streak is broken (last covered older than yesterday)
                IF v_claim_last_date < (CURRENT_DATE - INTERVAL '1 day')::DATE THEN
                    -- Takeover: Capture loop!
                    UPDATE public.claims 
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
            INSERT INTO public.claims (loop_id, user_id, streak_count, last_covered_date, covered_count_today)
            VALUES (v_matched_loop_id, p_user_id, 1, CURRENT_DATE, 1);
            v_status := 'claimed';
        END IF;
    ELSE
        -- Loop doesn't exist: Create new loop and claim it
        INSERT INTO public.loops (name, geom, centroid, created_by)
        VALUES (p_default_name, v_new_geom, v_new_centroid, p_user_id)
        RETURNING id, name, geom INTO v_matched_loop_id, v_matched_loop_name, v_matched_loop_geom;
        
        INSERT INTO public.claims (loop_id, user_id, streak_count, last_covered_date, covered_count_today)
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
