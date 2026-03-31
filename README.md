# Food Expiry Tracker

A cross-platform Flutter app that helps you track food expiry dates, reduce waste, and stay on top of what's in your fridge. Built with Firebase cloud sync, barcode scanning, push notifications, and a polished dark-mode UI.

> Flutter · Firebase · SQLite · Open Food Facts API

🔗 **[Live Demo](https://food-expiry-tracker-rosy.vercel.app)**

---

## Screenshots

<!-- To add screenshots: take them on the live demo or simulator, add the image files to a /screenshots folder, then replace the placeholders below -->

| Onboarding | Home | Add Item |
|:---:|:---:|:---:|
| ![Onboarding](screenshots/onboarding.png) | ![Home](screenshots/home.png) | ![Add Item](screenshots/add_item.png) |

| Calendar | Stats | Profile |
|:---:|:---:|:---:|
| ![Calendar](screenshots/calendar.png) | ![Stats](screenshots/stats.png) | ![Profile](screenshots/profile.png) |

---

## Features

- **Barcode scanner** — scan any product and pull its name from the Open Food Facts API
- **Smart category detection** — type "chicken" and the category fills in automatically
- **Cloud sync** — sign in with Google to sync your food list across devices with automatic two-way merge
- **Push notifications** — get alerted 3 days and 1 day before food expires (iOS + Android)
- **Calendar view** — colour-coded monthly calendar showing what expires when
- **Stats & charts** — pie charts for category breakdown and freshness status
- **Demo mode** — loads 12 realistic sample items instantly so the app looks alive on first launch
- Swipe to delete with undo, search, filter, sort, animated transitions

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
| Barcode scanning | `mobile_scanner` |
| Charts | `fl_chart` |
| Product lookup | Open Food Facts REST API |
| Deployment | Vercel |

---

## Try It

Click the live demo link at the top — no account or setup required. On first launch choose **Try Demo** to load sample data instantly, or **Start for Real** to add your own items.

---

## Project Structure

```
lib/
├── main.dart                     # Entry point + splash screen routing
├── app_colors.dart               # Dark theme colour palette
├── models/
│   └── food_item.dart            # FoodItem model + expiry helpers
├── screens/
│   ├── home_screen.dart          # Main list with search, filter, sort
│   ├── add_item_screen.dart      # Barcode scan, camera, manual entry
│   ├── item_detail_screen.dart   # Full detail view
│   ├── calendar_screen.dart      # Monthly expiry calendar
│   ├── stats_screen.dart         # Charts and summary cards
│   ├── profile_screen.dart       # Google sign-in / account
│   ├── splash_screen.dart        # Animated launch screen
│   ├── onboarding_screen.dart    # First-launch walkthrough
│   ├── demo_choice_screen.dart   # Demo vs real-usage choice
│   └── welcome_screen.dart       # First-item prompt
├── services/
│   ├── database_service.dart     # SQLite / SharedPreferences CRUD
│   ├── cloud_sync_service.dart   # Firebase read/write/merge
│   ├── auth_service.dart         # Firebase Auth wrapper
│   ├── notification_service.dart # Notification scheduling
│   └── demo_service.dart         # Sample data seeding
├── widgets/
│   └── food_card.dart            # Swipeable item card
└── utils/
    └── transitions.dart          # Page transition animations
```

---

## Local Development

> For contributors only — not needed to use the app.

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
   flutter run -d chrome   # Web
   flutter run             # iOS / Android
   ```

---

## License

MIT — see [LICENSE](LICENSE) for details.
