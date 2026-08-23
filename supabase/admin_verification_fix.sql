-- ============================================================
-- ADMIN VERIFICATION FIX — run this WHOLE FILE once in the
-- Supabase SQL Editor. It is safe to re-run.
-- ============================================================

-- 1) Columns used by verification flow
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS rejection_reason TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS rejected_documents TEXT[] DEFAULT '{}';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;

-- 2) Make sure EVERY auth user has a profile row
--    (admin accounts created before the auto-create trigger exist only in auth.users,
--     which silently breaks every admin policy below)
INSERT INTO profiles (id, phone, name, role, is_admin)
SELECT
  u.id,
  COALESCE(u.raw_user_meta_data->>'phone', split_part(u.email, '@', 1)),
  COALESCE(u.raw_user_meta_data->>'name', 'User'),
  'passenger',
  FALSE
FROM auth.users u
WHERE NOT EXISTS (SELECT 1 FROM profiles p WHERE p.id = u.id);

-- 3) Flag your admin account(s).
--    >>> CHANGE THE PHONE to the exact number you type in the Admin Login <<<
UPDATE profiles SET is_admin = TRUE
WHERE phone = REPLACE(REPLACE('0900000000', ' ', ''), '-', '');

-- Also flag admins by their login email prefix, just in case:
-- UPDATE profiles SET is_admin = TRUE WHERE phone = '<prefix-of-admin-email>';

-- Show current admins so you can confirm step 3 worked:
SELECT id, phone, name, is_admin FROM profiles WHERE is_admin = TRUE;

-- 4) RLS policies (belt)
DROP POLICY IF EXISTS "Admins can update any profile" ON profiles;
CREATE POLICY "Admins can update any profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (
    id = auth.uid()
    OR EXISTS (SELECT 1 FROM profiles a WHERE a.id = auth.uid() AND a.is_admin = TRUE)
  )
  WITH CHECK (true);

DROP POLICY IF EXISTS "Admins can delete any profile" ON profiles;
CREATE POLICY "Admins can delete any profile"
  ON profiles FOR DELETE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles a WHERE a.id = auth.uid() AND a.is_admin = TRUE)
  );

-- Notifications: allow marking read
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- 5) SUSPENDERS: RPC functions with SECURITY DEFINER.
--    These bypass RLS completely and do the write as the table owner.
--    Only callers whose profile row has is_admin = TRUE may use them.

CREATE OR REPLACE FUNCTION public.admin_verify_driver(p_driver_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  updated JSON;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE) THEN
    RAISE EXCEPTION 'NOT_ADMIN';
  END IF;

  UPDATE profiles
  SET is_verified = TRUE,
      verification_status = 'verified',
      rejection_reason = NULL,
      rejected_documents = '{}',
      updated_at = NOW()
  WHERE id = p_driver_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'DRIVER_NOT_FOUND';
  END IF;

  SELECT to_json(p) INTO updated FROM profiles p WHERE p.id = p_driver_id;
  RETURN updated;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_decline_driver(
  p_driver_id UUID,
  p_reason TEXT,
  p_docs TEXT[] DEFAULT '{}'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  updated JSON;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE) THEN
    RAISE EXCEPTION 'NOT_ADMIN';
  END IF;

  UPDATE profiles
  SET is_verified = FALSE,
      verification_status = 'rejected',
      rejection_reason = NULLIF(p_reason, ''),
      rejected_documents = p_docs,
      updated_at = NOW()
  WHERE id = p_driver_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'DRIVER_NOT_FOUND';
  END IF;

  SELECT to_json(p) INTO updated FROM profiles p WHERE p.id = p_driver_id;
  RETURN updated;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_revoke_driver(p_driver_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  updated JSON;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE) THEN
    RAISE EXCEPTION 'NOT_ADMIN';
  END IF;

  UPDATE profiles
  SET is_verified = FALSE,
      verification_status = 'none',
      rejection_reason = NULL,
      rejected_documents = '{}',
      updated_at = NOW()
  WHERE id = p_driver_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'DRIVER_NOT_FOUND';
  END IF;

  SELECT to_json(p) INTO updated FROM profiles p WHERE p.id = p_driver_id;
  RETURN updated;
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_verify_driver(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_decline_driver(UUID, TEXT, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_revoke_driver(UUID) TO authenticated;
