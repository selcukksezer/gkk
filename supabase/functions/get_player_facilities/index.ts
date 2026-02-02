// DEPRECATED: This Edge Function is no longer used.
// Instead, use direct RPC call via REST API:
// POST /rest/v1/rpc/get_player_facilities_with_queue
// 
// The RPC function is defined in:
// database/migrations/create_get_player_facilities_rpc.sql

Deno.serve(async (req) => {
  return new Response(
    JSON.stringify({ error: 'This endpoint is deprecated. Use /rest/v1/rpc/get_player_facilities_with_queue instead.' }),
    { status: 410, headers: { 'Content-Type': 'application/json' } }
  )
})

