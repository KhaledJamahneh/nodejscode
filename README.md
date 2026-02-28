# Einhod Pure Water - Management System

Water delivery management system with Flutter frontend and Node.js backend.

## 📁 Project Structure

```
einhod-longterm/
├── src/                         # Backend source (for Render deployment)
├── package.json                 # Backend dependencies (for Render)
├── .env                         # Backend config (for Render)
│
├── einhod-water-backend/        # Backend development folder
├── einhod-water-flutter/        # Frontend development folder
├── docs/                        # Documentation
└── README.md                    # This file
```

**Note**: Backend files exist in both root (for Render) and `einhod-water-backend/` (for organization). When making backend changes, update both locations or copy from `einhod-water-backend/` to root before pushing.

## 🚀 Quick Start

### Backend (Node.js)
```bash
cd einhod-water-backend
npm install
npm start
```

### Frontend (Flutter)
```bash
cd einhod-water-flutter
flutter pub get
flutter run
```

## 📱 Build APK
```bash
cd einhod-water-flutter
flutter build apk --release
```

## 🌐 Production

- **Backend**: https://nodejscode-33ip.onrender.com
- **Database**: Neon PostgreSQL (eu-central-1)
- **Repository**: https://github.com/KhaledJamahneh/nodejscode

## 📚 Documentation

See `/docs` folder for:
- Production fixes
- Deployment guides
- API testing docs
- Migration guides

## ✅ Recent Fixes (2026-02-28)

1. ✅ PostgreSQL role array comparison fixed
2. ✅ Notification routes added
3. ✅ Role detection bug fixed (roles vs role field)
4. ✅ Empty gallons field name fixed
5. ✅ Expense payment method fixed
6. ✅ APK rebuilt with all fixes

## 🔧 Tech Stack

**Backend:**
- Node.js + Express
- PostgreSQL + PostGIS
- JWT Authentication
- Bcrypt

**Frontend:**
- Flutter 3.x
- Riverpod (State Management)
- GoRouter (Navigation)
- Dio (HTTP Client)
- Material 3 Design

## 👥 User Roles

- Owner
- Administrator
- Delivery Worker
- Onsite Worker
- Client

## 📄 License

Proprietary - Einhod Pure Water
