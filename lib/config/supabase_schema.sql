-- DriveOn Supabase Database Schema
-- Run this in your Supabase SQL Editor

-- ========================
-- PROFILES TABLE
-- ========================
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT '',
  phone TEXT NOT NULL DEFAULT '',
  role TEXT NOT NULL DEFAULT 'passenger' CHECK (role IN ('driver', 'passenger')),
  is_admin BOOLEAN DEFAULT FALSE,
  is_verified BOOLEAN DEFAULT FALSE,
  verification_status TEXT DEFAULT 'none' CHECK (verification_status IN ('none', 'under_review', 'verified', 'rejected')),
  is_online BOOLEAN DEFAULT FALSE,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  profile_image TEXT,
  vehicle_model TEXT,
  plate_number TEXT,
  profile_photo_url TEXT,
  id_front_url TEXT,
  id_back_url TEXT,
  license_url TEXT,
  car_photo_url TEXT,
  rejection_reason TEXT,
  rejected_documents TEXT[] DEFAULT '{}',
  updated_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========================
-- POSTS TABLE (Ride Listings)
-- ========================
CREATE TABLE IF NOT EXISTS posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  driver_name TEXT NOT NULL DEFAULT '',
  "from" TEXT NOT NULL DEFAULT '',
  "to" TEXT NOT NULL DEFAULT '',
  time TEXT NOT NULL DEFAULT '',
  price TEXT NOT NULL DEFAULT '0',
  seats TEXT NOT NULL DEFAULT '0',
  total_seats INTEGER NOT NULL DEFAULT 0,
  available_seats INTEGER NOT NULL DEFAULT 0,
  vehicle_model TEXT DEFAULT 'Economy',
  is_online BOOLEAN DEFAULT TRUE,
  is_full BOOLEAN DEFAULT FALSE,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'full', 'completed')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========================
-- RIDE REQUESTS TABLE
-- ========================
CREATE TABLE IF NOT EXISTS ride_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ride_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  driver_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  passenger_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  driver_name TEXT,
  driver_phone TEXT,
  driver_plate TEXT,
  passenger_name TEXT,
  passenger_phone TEXT,
  "from" TEXT NOT NULL DEFAULT '',
  "to" TEXT NOT NULL DEFAULT '',
  price TEXT NOT NULL DEFAULT '0',
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'completed')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========================
-- RIDE HISTORY TABLE
-- ========================
CREATE TABLE IF NOT EXISTS ride_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ride_id UUID,
  driver_id UUID NOT NULL,
  passenger_id UUID,
  driver_name TEXT,
  driver_phone TEXT,
  driver_plate TEXT,
  passenger_name TEXT,
  passenger_phone TEXT,
  "from" TEXT NOT NULL DEFAULT '',
  "to" TEXT NOT NULL DEFAULT '',
  price TEXT NOT NULL DEFAULT '0',
  status TEXT DEFAULT 'completed',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========================
-- NOTIFICATIONS TABLE
-- ========================
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL DEFAULT '',
  body TEXT DEFAULT '',
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========================
-- INDEXES
-- ========================
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_verification ON profiles(verification_status);
CREATE INDEX IF NOT EXISTS idx_profiles_online ON profiles(is_online);
CREATE INDEX IF NOT EXISTS idx_posts_driver ON posts(driver_id);
CREATE INDEX IF NOT EXISTS idx_posts_status ON posts(status);
CREATE INDEX IF NOT EXISTS idx_ride_requests_driver ON ride_requests(driver_id);
CREATE INDEX IF NOT EXISTS idx_ride_requests_passenger ON ride_requests(passenger_id);
CREATE INDEX IF NOT EXISTS idx_ride_requests_status ON ride_requests(status);
CREATE INDEX IF NOT EXISTS idx_ride_history_driver ON ride_history(driver_id);
CREATE INDEX IF NOT EXISTS idx_ride_history_passenger ON ride_history(passenger_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);

-- ========================
-- MIGRATION: optional pickup / drop points on posts
-- Run this once in the Supabase SQL editor if your table already exists
-- ========================
ALTER TABLE posts ADD COLUMN IF NOT EXISTS pickup_location TEXT;
ALTER TABLE posts ADD COLUMN IF NOT EXISTS drop_location TEXT;

-- ========================
-- MIGRATION: driver verification rejection details
-- Run this once in the Supabase SQL editor if your table already exists
-- ========================
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS rejection_reason TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS rejected_documents TEXT[] DEFAULT '{}';

-- ========================
-- MIGRATION: notification read state
-- Run this once in the Supabase SQL editor if your table already exists
-- ========================
CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ========================
-- MIGRATION: admin access
-- Run this once in the Supabase SQL editor if your table already exists,
-- then flag your admin account:
--   UPDATE profiles SET is_admin = TRUE WHERE phone = '<ADMIN_PHONE>';
-- ========================
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

CREATE POLICY "Admins can update any profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (
    id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles a
      WHERE a.id = auth.uid() AND a.is_admin = TRUE
    )
  )
  WITH CHECK (true);

CREATE POLICY "Admins can delete any profile"
  ON profiles FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles a
      WHERE a.id = auth.uid() AND a.is_admin = TRUE
    )
  );

-- ========================
-- ROW LEVEL SECURITY (RLS)
-- ========================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE ride_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE ride_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- PROFILES: Users can read all profiles (for map markers, driver info)
-- but only update their own
CREATE POLICY "Profiles are viewable by authenticated users"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

-- POSTS: Anyone can view, only driver can modify their own
CREATE POLICY "Posts are viewable by authenticated users"
  ON posts FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Drivers can insert posts"
  ON posts FOR INSERT
  TO authenticated
  WITH CHECK (driver_id = auth.uid());

CREATE POLICY "Drivers can update own posts"
  ON posts FOR UPDATE
  TO authenticated
  USING (driver_id = auth.uid());

CREATE POLICY "Drivers can delete own posts"
  ON posts FOR DELETE
  TO authenticated
  USING (driver_id = auth.uid());

-- RIDE REQUESTS: Driver and passenger can view their own requests
CREATE POLICY "Users can view own ride requests"
  ON ride_requests FOR SELECT
  TO authenticated
  USING (driver_id = auth.uid() OR passenger_id = auth.uid());

CREATE POLICY "Passengers can create ride requests"
  ON ride_requests FOR INSERT
  TO authenticated
  WITH CHECK (passenger_id = auth.uid());

CREATE POLICY "Driver can update ride requests"
  ON ride_requests FOR UPDATE
  TO authenticated
  USING (driver_id = auth.uid());

CREATE POLICY "Passenger can delete own pending requests"
  ON ride_requests FOR DELETE
  TO authenticated
  USING (passenger_id = auth.uid());

-- RIDE HISTORY: Users can view their own history
CREATE POLICY "Users can view own ride history"
  ON ride_history FOR SELECT
  TO authenticated
  USING (driver_id = auth.uid() OR passenger_id = auth.uid());

CREATE POLICY "System can insert ride history"
  ON ride_history FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- NOTIFICATIONS: Users can view their own
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "System can insert notifications"
  ON notifications FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can delete own notifications"
  ON notifications FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- ========================
-- AUTO-CREATE PROFILE ON SIGNUP
-- ========================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, phone, name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    COALESCE(NEW.raw_user_meta_data->>'name', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ========================
-- STORAGE BUCKETS
-- ========================
INSERT INTO storage.buckets (id, name, public) VALUES ('driver-docs', 'driver-docs', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) VALUES ('profile-images', 'profile-images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
CREATE POLICY "Authenticated users can upload driver docs"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'driver-docs');

CREATE POLICY "Anyone can view driver docs"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'driver-docs');

CREATE POLICY "Authenticated users can upload profile images"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'profile-images');

CREATE POLICY "Anyone can view profile images"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'profile-images');
