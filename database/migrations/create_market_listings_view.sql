-- Create a view to join market orders with user profiles (for seller names)
CREATE OR REPLACE VIEW public.market_listings_view AS
SELECT
    m.id,
    m.seller_id,
    m.item_id,
    m.quantity,
    m.price,
    m.listed_at,
    m.item_data,
    p.username AS seller_name,
    p.avatar_url AS seller_avatar
FROM public.market_orders m
LEFT JOIN public.users p ON m.seller_id = p.auth_id OR m.seller_id = p.id
WHERE m.quantity > 0;

-- Grant access
GRANT SELECT ON public.market_listings_view TO authenticated;
GRANT SELECT ON public.market_listings_view TO anon;
