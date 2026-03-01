# Einhod Pure Water - Management System

Water delivery management system with Flutter frontend and Node.js backend.

## 📁 Project Structure

```
einhod-longterm/
├── einhod-water-backend/        # Backend (Node.js + Express + PostgreSQL)
├── einhod-water-flutter/        # Frontend (Flutter)
├── docs/                        # Documentation
└── README.md                    # This file
```

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
