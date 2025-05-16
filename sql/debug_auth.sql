-- Check if the user exists in auth.users table
SELECT id, email, created_at, last_sign_in_at 
FROM auth.users 
WHERE email = 'uic02421@gmail.com';

-- Check if the user has a profile with admin role
SELECT * 
FROM profiles 
WHERE email = 'uic02421@gmail.com';

-- Check if user has appropriate role
SELECT * 
FROM profiles 
WHERE id = 'ad3c0cb1-cbb9-42d1-ac5f-44f0fdd97c59';

-- Check RLS policies on profiles table
SELECT * 
FROM pg_policies 
WHERE tablename = 'profiles';

-- Check RLS policies on apk_uploads table
SELECT * 
FROM pg_policies 
WHERE tablename = 'apk_uploads';

-- Check failed auth attempts
SELECT * 
FROM auth.audit_log_entries 
ORDER BY created_at DESC 
LIMIT 10;

-- Check all admin users
SELECT * 
FROM profiles 
WHERE role = 'admin';

-- Check database schema
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';

-- Show columns in profiles table
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'profiles';

-- Show columns in apk_uploads table
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'apk_uploads'; 