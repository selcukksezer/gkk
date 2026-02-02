-- Optimization: Add indexes for facilities system

CREATE INDEX IF NOT EXISTS idx_facilities_user_id ON public.facilities(user_id);
CREATE INDEX IF NOT EXISTS idx_facilities_type ON public.facilities(type);

CREATE INDEX IF NOT EXISTS idx_facility_queue_facility_id ON public.facility_queue(facility_id);
CREATE INDEX IF NOT EXISTS idx_facility_queue_status ON public.facility_queue(status);
CREATE INDEX IF NOT EXISTS idx_facility_queue_completed_at ON public.facility_queue(completed_at);

-- Analyze tables to update statistics
ANALYZE public.facilities;
ANALYZE public.facility_queue;
