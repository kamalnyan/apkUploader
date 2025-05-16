-- Create profiles table to store user profiles
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  role TEXT DEFAULT 'user',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create RLS (Row Level Security) policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policy to allow users to read their own profiles
CREATE POLICY "Users can view their own profile" 
  ON profiles 
  FOR SELECT 
  USING (auth.uid() = id);

-- Create policy to allow users to update their own profiles
CREATE POLICY "Users can update their own profile" 
  ON profiles 
  FOR UPDATE 
  USING (auth.uid() = id);

-- Create policy to allow authenticated users with admin role to view all profiles
CREATE POLICY "Admins can view all profiles" 
  ON profiles 
  FOR SELECT 
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

-- Create policy to allow authenticated users with admin role to update all profiles
CREATE POLICY "Admins can update all profiles" 
  ON profiles 
  FOR UPDATE 
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

-- Create apk_uploads table
CREATE TABLE IF NOT EXISTS apk_uploads (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  package_name TEXT NOT NULL,
  version_name TEXT NOT NULL,
  version_code INTEGER NOT NULL,
  apk_url TEXT NOT NULL,
  icon_url TEXT,
  min_sdk INTEGER NOT NULL,
  target_sdk INTEGER NOT NULL,
  description TEXT,
  changelog TEXT,
  screenshots TEXT[],
  user_id UUID REFERENCES auth.users NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create RLS policies for apk_uploads
ALTER TABLE apk_uploads ENABLE ROW LEVEL SECURITY;

-- Create policy to allow all users to view APK uploads
CREATE POLICY "APK uploads are viewable by everyone" 
  ON apk_uploads 
  FOR SELECT 
  USING (true);

-- Create policy to allow authenticated users with admin role to insert APK uploads
CREATE POLICY "Only admins can add APK uploads" 
  ON apk_uploads 
  FOR INSERT 
  WITH CHECK (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

-- Create policy to allow authenticated users with admin role to update APK uploads
CREATE POLICY "Only admins can update APK uploads" 
  ON apk_uploads 
  FOR UPDATE 
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

-- Create policy to allow authenticated users with admin role to delete APK uploads
CREATE POLICY "Only admins can delete APK uploads" 
  ON apk_uploads 
  FOR DELETE 
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

-- Create function to handle user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (new.id, new.email);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to handle new user creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user(); 