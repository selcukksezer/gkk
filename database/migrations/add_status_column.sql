-- Add status column to market_orders if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'market_orders' 
        AND column_name = 'status'
    ) THEN
        ALTER TABLE public.market_orders ADD COLUMN status TEXT DEFAULT 'active';
        RAISE NOTICE 'Added status column to market_orders';
    END IF;
END $$;
