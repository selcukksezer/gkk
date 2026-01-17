-- Create market_history table for tracking transactions
CREATE TABLE IF NOT EXISTS public.market_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    item_id TEXT NOT NULL,
    seller_id UUID NOT NULL, -- auth_id or user_id matching users table
    buyer_id UUID NOT NULL,
    quantity INT NOT NULL,
    price INT NOT NULL,
    sold_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.market_history ENABLE ROW LEVEL SECURITY;

-- Allow read access to authenticated users (optional, maybe only own history?)
-- For now, allow public read as it might be used for "Last Sold" price charts
CREATE POLICY "Public read market history" ON public.market_history
    FOR SELECT USING (true);

-- Allow system (security definer functions) to insert
-- No direct insert policy needed for users if only RPCs use it
