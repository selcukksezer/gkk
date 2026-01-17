-- Enable RLS and Grants for Facilities System

-- 1. Facilities
ALTER TABLE public.facilities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own facilities" 
ON public.facilities FOR SELECT 
TO authenticated 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own facilities" 
ON public.facilities FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own facilities" 
ON public.facilities FOR UPDATE 
TO authenticated 
USING (auth.uid() = user_id);

-- Grants
GRANT SELECT, INSERT, UPDATE, DELETE ON public.facilities TO authenticated;
GRANT SELECT ON public.facilities TO service_role;

-- 2. Facility Recipes (Public Read)
ALTER TABLE public.facility_recipes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view recipes" 
ON public.facility_recipes FOR SELECT 
TO authenticated, anon 
USING (true);

-- Grants
GRANT SELECT ON public.facility_recipes TO authenticated, anon;
GRANT SELECT ON public.facility_recipes TO service_role;

-- 3. Facility Queue
ALTER TABLE public.facility_queue ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own facility queue" 
ON public.facility_queue FOR SELECT 
TO authenticated 
USING (
  EXISTS (
    SELECT 1 FROM public.facilities f 
    WHERE f.id = facility_queue.facility_id 
    AND f.user_id = auth.uid()
  )
);

CREATE POLICY "Users can insert into their own queue" 
ON public.facility_queue FOR INSERT 
TO authenticated 
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.facilities f 
    WHERE f.id = facility_queue.facility_id 
    AND f.user_id = auth.uid()
  )
);

-- Grants
GRANT SELECT, INSERT, UPDATE, DELETE ON public.facility_queue TO authenticated;
GRANT SELECT ON public.facility_queue TO service_role;
