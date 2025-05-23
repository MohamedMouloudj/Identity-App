# Flutter Auth App

A modern authentication app built with Flutter, featuring support for traditional email/password sign-in, Google authentication, and a custom email + Face ID flow.

> ✅ This is my first **complete Flutter app**, combining Firebase-like backend power from Supabase with on-device machine learning using Google ML Kit.

---

## ✨ Features

- 🔐 **Authentication**
  - Email & password sign-in
  - Google account authentication
  - Face ID login using email + on-device facial recognition

- ☁️ **Backend**
  - Supabase as the backend (Auth, Database, and Storage)

- 🤖 **Machine Learning**
  - Face detection powered by `google_mlkit_face_detection`

- 📸 **Media Integration**
  - Camera access for capturing face images
  - Upload/download from Supabase Storage

- 🎯 **Cross-platform**
  - Fully compatible with both Android and iOS

---

## 🧰 Dependencies

| Package | Purpose |
|--------|---------|
| `flutter` | Flutter SDK |
| `cupertino_icons` | iOS-style icons |
| `supabase_flutter` | Supabase integration (Auth + DB + Storage) |
| `flutter_dotenv` | Environment variable management |
| `google_sign_in` | Google login |
| `google_mlkit_face_detection` | Face detection via ML Kit |
| `camera` | Camera preview and capture |
| `image_picker` | Pick images from gallery or camera |
| `audioplayers` | Feedback sounds |
| `permission_handler` | Runtime permissions (camera, storage) |
| `path_provider`, `path` | Local file access and paths |

---

## 📦 Getting Started

### 1. Clone this repo

```bash
git clone https://github.com/your-username/flutter-auth-app.git
cd flutter-auth-app
```

### 2. Set up environment

Create a `.env` file in the root directory:

Follow `.env.example` to set up your environment variables.

### 3. Run the app

```bash
flutter pub get
flutter run
```

---

## 🧪 Login Flows

- **Email/Password:** Standard auth flow using Supabase Auth.
- **Google Sign-In:** Uses OAuth via `google_sign_in` + Supabase integration.
- **Face ID Login:**
    1. User enters email.
    2. App fetches stored face image from Supabase Storage.
    3. Captures live face with camera.
    4. Compares faces locally using `google_mlkit_face_detection`.

---

## 🔐 Supabase Security

- All private data is protected using **Row-Level Security (RLS)**.
- A limited unauthenticated read is allowed for email-based face verification.

---

## 🛠️ Future Improvements

- Face comparison via embedding & distance metrics.
- Onboarding walkthrough for new users.
- Dark mode support.

---

## 🙌 Acknowledgments

- [Supabase](https://supabase.com)
- [Google ML Kit](https://developers.google.com/ml-kit)
- [Flutter Dev](https://flutter.dev)

---

## 📄 License

This project is licensed under the MIT License.

