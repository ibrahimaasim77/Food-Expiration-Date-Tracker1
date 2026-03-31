# Food Expiry Tracker

A cross-platform Flutter app that helps you track food expiry dates, reduce waste, and stay on top of what's in your fridge. Built with a full production stack — Firebase cloud sync, barcode scanning via the Open Food Facts API, push notifications, analytics, and a polished dark-mode UI.

> Built with Flutter · Firebase · SQLite · Open Food Facts API

🔗 **[Live Demo](https://food-expiry-tracker-g2nkhwv63-ibrahimaasim77s-projects.vercel.app)**

---

## Features

### Core
- Add food items with name, category, expiry date, and photo
- **Smart category auto-detection** — type "chicken" and the category fills in automatically
- **Barcode scanner** — scan any product and fetch its name from the Open Food Facts API (iOS, Android, Chrome)
- Swipe to delete with a 4-second undo snackbar
- Search, filter by category, and sort by expiry date, name, or category
- Animated list with fade/slide-in item transitions

### Notifications
- Push notifications 3 days and 1 day before expiry (iOS + Android)
- Notifications rescheduled on every app launch — never miss an alert after a reinstall

### Calendar & Stats
- Monthly expiry calendar — colour-coded dates, tap to see items expiring that day
- Stats tab with interactive pie charts for category breakdown and freshness status

### Cloud Sync
- Sign in with Google to sync your food list across devices
- Two-way merge on sign-in — local-only and cloud-only items are reconciled automatically

### Demo Mode
- On first launch, choose between **Try Demo** or **Start for Real**
- Demo mode pre-loads 12 realistic sample items across all categories (expired, expiring soon, and fresh) so the app looks alive instantly — no setup required
- Perfect for trying out the UI before committing to your own data

### First-run Experience
- 3-slide onboarding walkthrough
- Demo vs real-usage choice screen after onboarding

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3 (Dart) |
| Local storage — mobile | SQLite via `sqflite` |
| Local storage — web | `shared_preferences` (localStorage) |
| Cloud sync | Firebase Realtime Database |
| Auth | Firebase Auth + Google Sign-In |
| Notifications | `flutter_local_notifications` |
| Barcode scanning | `mobile_scanner` (iOS, Android, Chrome) |
| Charts | `fl_chart` |
| Camera / image picker | `image_picker` |
| Product lookup | Open Food Facts REST API |
| Deployment | Vercel (Flutter Web) |

---

## Project Structure

```
lib/
├── main.dart                     # Entry point, routing (onboarding / demo choice / home)
├── app_colors.dart               # Centralised dark theme colour palette
├── models/
│   └── food_item.dart            # FoodItem model + computed expiry helpers
├── screens/
│   ├── home_screen.dart          # Main tab: grouped list, search, filter, sort
│   ├── add_item_screen.dart      # Add / edit: barcode scan, camera, manual entry
│   ├── item_detail_screen.dart   # Full detail view with status card and actions
│   ├── calendar_screen.dart      # Monthly calendar + upcoming expiry list
│   ├── stats_screen.dart         # Pie charts + summary cards
│   ├── profile_screen.dart       # Auth: sign-in / account info
│   ├── onboarding_screen.dart    # 3-slide first-launch walkthrough
│   ├── demo_choice_screen.dart   # Demo vs real-usage choice after onboarding
│   └── welcome_screen.dart       # First-item prompt for real-usage path
├── services/
│   ├── database_service.dart     # SQLite (mobile) / SharedPreferences (web) CRUD
│   ├── cloud_sync_service.dart   # Firebase Realtime Database read/write/merge
│   ├── auth_service.dart         # Firebase Auth wrapper (Google Sign-In)
│   ├── notification_service.dart # Local notification scheduling + rescheduling
│   └── demo_service.dart         # Seeds database with realistic sample data
├── widgets/
│   └── food_card.dart            # Swipeable food item card
└── utils/
    └── transitions.dart          # Slide-up + fade page route transition
```

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- A Firebase project with **Authentication** (Google) and **Realtime Database** enabled

### Setup

1. **Clone the repo**
   ```bash
   git clone https://github.com/ibrahimaasim77/Food-Expiration-Date-Tracker1.git
   cd Food-Expiration-Date-Tracker1/food_expiry_tracker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable **Google Authentication** and **Realtime Database**
   - Run `flutterfire configure` to generate `lib/firebase_options.dart`

4. **Run the app**
   ```bash
   # Web (Chrome)
   flutter run -d chrome

   # iOS / Android
   flutter run
   ```

---

## App Flow

```
First launch
  └── OnboardingScreen (3 slides)
        └── DemoChoiceScreen
              ├── Try Demo  → seeds 12 sample items → HomeScreen
              └── Start for Real → WelcomeScreen → HomeScreen

Returning user
  └── HomeScreen
        ├── Home tab    — grouped list, search, filter, sort
        ├── Calendar tab — monthly expiry calendar
        ├── Stats tab   — charts and summary
        └── Profile tab — Google sign-in / account info
```

---

## Data Model

```dart
FoodItem {
  int?     id                   // local DB primary key
  String   name                 // e.g. "Whole Milk"
  DateTime expiryDate           // label expiry date
  String   category             // Dairy | Meat | Produce | Seafood | Bakery | ...
  int      safeDaysAfterExpiry  // days still considered usable after expiry
  String?  imagePath            // local file path (mobile only)
}
```

Computed helpers: `daysUntilExpiry`, `isExpired`, `isStillSafe`, `statusMessage`

---

## Cloud Sync

All writes are mirrored to Firebase Realtime Database at `/users/{uid}/food_items/{id}`. On sign-in, a two-way merge runs — cloud-only items are inserted locally and local-only items are uploaded to the cloud.

---

## Notification Schedule

| Trigger | Message |
|---------|---------|
| 3 days before expiry | "Expiring Soon — {name} expires in 3 days!" |
| 1 day before expiry | "Expires Tomorrow — {name} expires tomorrow!" |

Notifications are rescheduled on every app launch and cancelled automatically on item delete or update.

---

## Safe Days After Expiry

| Category | Safe days |
|----------|-----------|
| Meat / Seafood | 1 |
| Dairy | 3 |
| Produce / Bakery | 5 |
| Beverages | 7 |
| Snacks | 14 |
| Frozen | 30 |
| Canned Goods | 365 |

---

## License

MIT — see [LICENSE](LICENSE) for details.
