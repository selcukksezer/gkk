-- Supabase SQL Functions for Hospital System
-- Run this in Supabase SQL Editor

-- Function: get_hospital_status
-- Fetches current hospital status for a user
CREATE OR REPLACE FUNCTION public.get_hospital_status(p_auth_id UUID)
RETURNS TABLE(
  in_hospital BOOLEAN,
  release_time BIGINT,
  hospital_reason TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(u.hospital_until > NOW(), FALSE),
    EXTRACT(EPOCH FROM u.hospital_until)::BIGINT,
    u.hospital_reason
  FROM public.users u
  WHERE u.auth_id = p_auth_id
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: admit_to_hospital
-- Admits a user to hospital (server-side)
CREATE OR REPLACE FUNCTION public.admit_to_hospital(
  p_auth_id UUID,
  p_duration_minutes INT,
  p_reason TEXT
)
RETURNS TABLE(
  success BOOLEAN,
  hospital_until TIMESTAMP,
  release_time BIGINT
) AS $$
DECLARE
  v_release_time TIMESTAMP;
BEGIN
  v_release_time := NOW() + (p_duration_minutes || ' minutes')::INTERVAL;
  
  UPDATE public.users
  SET 
    hospital_until = v_release_time,
    hospital_reason = p_reason,
    updated_at = NOW()
  WHERE auth_id = p_auth_id;
  
  RETURN QUERY
  SELECT 
    TRUE,
    v_release_time,
    EXTRACT(EPOCH FROM v_release_time)::BIGINT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: release_from_hospital
-- Releases a user from hospital
CREATE OR REPLACE FUNCTION public.release_from_hospital(
  p_auth_id UUID,
  p_method TEXT,
  p_cost INT DEFAULT 0
)
RETURNS TABLE(
  success BOOLEAN,
  new_gems INT
) AS $$
DECLARE
  v_current_gems INT;
BEGIN
  -- Get current gems
  SELECT gems INTO v_current_gems
  FROM public.users
  WHERE auth_id = p_auth_id;
  
  -- Check if player has enough gems
  IF p_method = 'gems' AND v_current_gems < p_cost THEN
    RETURN QUERY SELECT FALSE, v_current_gems;
    RETURN;
  END IF;
  
  -- Update user
  UPDATE public.users
  SET 
    hospital_until = NULL,
    hospital_reason = NULL,
    gems = CASE WHEN p_method = 'gems' THEN gems - p_cost ELSE gems END,
    updated_at = NOW()
  WHERE auth_id = p_auth_id;
  
  -- Return success with new gems count
  SELECT gems INTO v_current_gems
  FROM public.users
  WHERE auth_id = p_auth_id;
  
  RETURN QUERY SELECT TRUE, v_current_gems;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
