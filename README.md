# Food Expiration Date Tracker

A cross-platform Flutter app that helps you track food expiry dates, cut down on waste, and stay on top of what's in your fridge — with push notifications, a calendar view, stats, and optional Firebase cloud sync.

---

## Screenshots

| Home | Calendar | Stats | Profile |
|------|----------|-------|---------|
| Grouped food list with expiry status | Monthly calendar with expiry dots | Pie charts & summary cards | Google / Apple sign-in + account info |

---

## Features

- **Track food items** with name, category, expiry date, and optional photo
- **Smart category detection** — type "chicken" and the category auto-fills
- **Expiry status banner** — shows expired / expiring today / expiring this week counts at a glance
- **Swipe to delete** with a 4-second undo snackbar
- **Search, filter by category, and sort** (by expiry date, name, or category)
- **Animated list** with fade/slide-in transitions
- **Barcode scanner** — scans barcodes and looks up the product name via Open Food Facts API
- **Camera photo** — attach a photo to any item
- **Push notifications** — reminds you 3 days and 1 day before expiry (mobile only)
- **Expiry calendar** — tap any date to see what's expiring
- **Statistics tab** — interactive pie charts for category breakdown and freshness status
- **Firebase cloud sync** — sign in with Google or Apple to back up and sync your data across devices
- **Web support** — fully functional in the browser (storage via localStorage)
- **Dark blue theme** throughout

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| Local storage (mobile) | SQLite via `sqflite` |
| Local storage (web) | `shared_preferences` (localStorage) |
| Cloud sync | Firebase Realtime Database |
| Auth | Firebase Auth (Google + Apple) |
| Notifications | `flutter_local_notifications` |
| Barcode scanning | `mobile_scanner` |
| Charts | `fl_chart` |
| Camera / image picker | `image_picker` |
| Product lookup | Open Food Facts REST API |

---

## Project Structure

```
lib/
├── main.dart                    # App entry, routing (onboarding / welcome / home)
├── app_colors.dart              # Global dark-blue color palette
├── models/
│   └── food_item.dart           # FoodItem data model + computed expiry helpers
├── screens/
│   ├── home_screen.dart         # Main tab: grouped list, search, filter, sort
│   ├── add_item_screen.dart     # Add / edit item: barcode scan, camera, manual entry
│   ├── item_detail_screen.dart  # Full detail view with status card and actions
│   ├── calendar_screen.dart     # Monthly calendar + upcoming expiry list
│   ├── stats_screen.dart        # Pie charts + summary cards
│   ├── profile_screen.dart      # Auth (signed-out: login, signed-in: account info)
│   ├── onboarding_screen.dart   # 3-slide first-launch walkthrough
│   └── welcome_screen.dart      # Post-onboarding prompt to add first item
├── services/
│   ├── database_service.dart    # SQLite (mobile) / SharedPreferences (web) CRUD
│   ├── cloud_sync_service.dart  # Firebase Realtime Database read/write
│   ├── auth_service.dart        # Firebase Auth (Google, Apple sign-in)
│   └── notification_service.dart# Local push notification scheduling
├── widgets/
│   └── food_card.dart           # Swipeable food item card widget
└── utils/
    └── transitions.dart         # Slide-up + fade page route transition
```

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- A Firebase project with **Authentication** and **Realtime Database** enabled
- For iOS/macOS: Xcode and valid signing certificates

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
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable **Google Authentication** and **Apple Authentication**
   - Enable **Realtime Database** (start in test mode or set rules as needed)
   - Run `flutterfire configure` and replace `lib/firebase_options.dart` with your generated config

4. **Run the app**
   ```bash
   # Mobile
   flutter run

   # Web
   flutter run -d chrome
   ```

---

## Data Model

```dart
FoodItem {
  int?   id                    // local DB id
  String name                  // e.g. "Whole Milk"
  DateTime expiryDate          // expiry date
  String category              // Dairy, Meat, Produce, etc.
  int    safeDaysAfterExpiry   // days still considered safe after expiry date
  String? imagePath            // local file path (mobile only)
}
```

**Computed helpers:**
- `daysUntilExpiry` — negative if expired
- `isExpired` — true if past expiry date
- `isStillSafe` — true if expired but within the `safeDaysAfterExpiry` window
- `statusMessage` — human-readable status string

---

## App Flow

```
First launch
  └── OnboardingScreen (3 slides)
        └── WelcomeScreen (add first item prompt)
              ├── Add Item → HomeScreen
              └── Not today → HomeScreen

Returning user
  └── HomeScreen (4 bottom tabs: Home · Calendar · Stats · Profile)
```

---

## Cloud Sync

When signed in, every insert / update / delete is mirrored to Firebase Realtime Database at:

```
/users/{uid}/food_items/{itemId}/
  name
  expiryDate
  category
  safeDaysAfterExpiry
```

On sign-in, if the cloud has items they are merged into the local store. If the cloud is empty, local items are uploaded.

---

## Notifications

Push notifications are scheduled on mobile (iOS + Android) whenever an item is saved:

| Timing | Message |
|--------|---------|
| 3 days before expiry | "Expiring Soon — {name} expires in 3 days!" |
| 1 day before expiry | "Expires Tomorrow — {name} expires tomorrow!" |

Notifications are automatically cancelled when an item is deleted or updated.

---

## Safe-Days-After-Expiry Defaults

| Category | Safe days after expiry |
|----------|----------------------|
| Meat / Seafood | 1 day |
| Dairy | 3 days |
| Produce / Bakery | 5 days |
| Beverages | 7 days |
| Snacks | 14 days |
| Frozen | 30 days |
| Canned Goods | 365 days |
| Other | 3 days |

---

## License

MIT License — see [LICENSE](LICENSE) for details.
