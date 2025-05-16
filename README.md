Admin App (Flutter, Android/iOS): Can upload, manage, pin/unpin APKs.

User App (Flutter, Android/iOS):

Can only view, download, and install APKs

No upload, no delete, no pinning

See pinned apps on top (set by admin)

✅ FINALIZED FEATURE PLAN (FOR DEVELOPMENT)
👨‍💼 Admin App Features (Flutter - Android & iOS)
Feature	Description
Login with Firebase	Secure admin access
Upload APK	Upload .apk + icon + metadata
Edit APK Info	Update name, description, icon
Delete APK	Remove from storage + database
Pin/Unpin APK	Promote apps to show on top in user app
APK List View	Shows all uploaded apps with controls

👤 User App Features (Flutter - Android & iOS)
Feature	Description
Splash Screen	App launch branding
APK List	Shows pinned apps on top, others below
APK Info	Icon, name, description
Download Button	Downloads APK from Firebase Storage
Session-based Install (Android only)	Installs via PackageInstaller API
iOS	APK install disabled, optional info message

🔒 Users cannot upload, delete, or pin anything. All data is read-only from Firestore.

📦 BACKEND STRUCTURE (Firebase Firestore)
📁 Collection: apks
Each APK document:

json
Copy
Edit
{
  "name": "My Cool App",
  "description": "This is a demo app",
  "apk_url": "https://firebase.storage.url/app.apk",
  "icon_url": "https://firebase.storage.url/icon.png",
  "is_pinned": true,
  "uploaded_at": "2025-05-14T08:00:00Z"
}
🧠 SYSTEM ARCHITECTURE
plaintext
Copy
Edit
[Admin Flutter App] ---> [Firebase Storage & Firestore] <--- [User Flutter App]
                                 |                                  
                            Stores APKs, Metadata                    
📱 UI Overview
User App – APK List
Pinned Apps Section (Always on top)

All Other Apps

Each item:

Icon (left)

App Name + Description

“Download & Install” button (right)

Admin App – Management Panel
Upload screen

APK manager screen (edit/delete/pin)

🧰 REQUIRED PACKAGES
Plugin	Purpose
firebase_core	Firebase setup
firebase_auth	Admin login (Admin app only)
firebase_storage	Store APK files and icons
cloud_firestore	Store metadata
file_picker	Select APK files (Admin)
path_provider	Download to device
install_plugin / Native channel	Session-based install (Android)

