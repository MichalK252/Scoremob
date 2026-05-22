# ScoreMob

ScoreMob is a modern and dynamic mobile application built using **Flutter**, designed to track football match scores, league standings, player statistics, and manage favorite teams and leagues in real-time.

The application integrates with the **Supabase** platform for user authentication and cloud data synchronization, and uses external football APIs to retrieve up-to-date sports data.

---

## 🌟 Key Features

### 1. User Authentication & Profile
* **Sign Up and Sign In**: Full support for authentication using **Supabase Auth** with validation and localized Polish error messages.
* **Fan Card (ScoreMob Fan Card)**: A unique, animated visual element in the profile view for logged-in users, and an interactive locked preview for guests to encourage sign-ups.

### 2. Favorites Panel
* **Leagues and Teams**: Logged-in users can add their favorite competitions and clubs to their watch list using star and heart icons.
* **Real-Time Synchronization**: An implemented `StreamController.broadcast()` mechanism in `SupabaseService` automatically synchronizes the favorites status across all tabs and screens without requiring a manual page refresh.

### 3. Advanced Statistics & League Standings
* **Dynamic Standings**: League standings view showing points, matches played, goals, and home/away match records.
* **Top Scorers & Assist Makers**: A statistics tab displaying the league's top scorers and assist makers with correct Polish grammatical suffix forms (e.g. *gol*, *gole*, *goli*).
* **Smart Season Fallback (Free API Tier)**: The application automatically detects API plan limitations for the latest seasons (e.g., 2025/26) and seamlessly falls back to the 2024/25 season, presenting an elegant information banner explaining the API plan constraints.

### 4. Search & Details
* **Unified Search**: A single search bar that queries matching clubs and player profiles in parallel and asynchronously.
* **Team Details**: Information about the stadium (name, capacity, city), founding year, lists of upcoming and past matches, and a **SQUAD** tab (grouped by player positions).
* **Player Details**: A player profile showing biographical data and detailed statistics broken down by competitions.

### 5. Personalization (Light / Dark Theme)
* Dynamic theme switching (Light / Dark Mode) with instant color updates across all UI components.
* Saves user preferences locally on the device using the `shared_preferences` package.

---

## 🛠️ Tech Stack

* **Framework**: [Flutter](https://flutter.dev/) (Material 3)
* **State Management**: [Provider](https://pub.dev/packages/provider)
* **Database & Auth**: [Supabase](https://supabase.com/) (PostgreSQL with RLS policies)
* **Local Storage**: [SharedPreferences](https://pub.dev/packages/shared_preferences)
* **Environment Configuration**: [Flutter Dotenv](https://pub.dev/packages/flutter_dotenv)

---

## 🚀 Getting Started

### Prerequisites
1. Installed Flutter SDK (version >= 3.0.0).
2. Configured Android/iOS emulator or Chrome browser (for web debugging).
3. Active Supabase project and credentials for Football API and Football Data API.

### Environment Setup
Create a `.env` file in the root directory of the project and fill it with your data:

```env
SUPABASE_URL=https://your-supabase-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
FOOTBALL_DATA_KEY=your-football-data-key
FOOTBALL_API_KEY=your-football-api-key
```

### Installation and Execution

1. Get dependencies:
   ```bash
   flutter pub get
   ```

2. Run the analyzer to ensure there are no compilation errors:
   ```bash
   flutter analyze
   ```

3. Run the application:
   ```bash
   flutter run
   ```

---

## 📁 Project Structure (Main Files)

* `lib/main.dart` - Application entry point, initializing Dotenv, Supabase, and ThemeProvider.
* `lib/theme/app_theme.dart` - Definition of the Light/Dark theme colors and BuildContext extension.
* `lib/services/`
  * `theme_provider.dart` - Manages active theme state and persistence.
  * `supabase_service.dart` - Handles communication with Supabase (Favorites DB, RLS, Streams).
  * `football_api.dart` - Integrates external football APIs with robust error handling and season fallback.
* `lib/screens/`
  * `main_navigation_screen.dart` - Navigation bar with a modern, glassmorphic design.
  * `home_screen.dart` - Today's matches list with a date picker.
  * `search_screen.dart` - Unified search screen for teams and players.
  * `favorites_screen.dart` - Favorites dashboard for leagues and teams with real-time refresh.
  * `profile_screen.dart` - Profile page featuring the Fan Card and theme toggle.
  * `league_standings_screen.dart` - League tables, stats (scorers/assists), and the fallback warning banner.
  * `team_detail_screen.dart` - Detailed team profile with match schedules and the squad roster.
  * `player_detail_screen.dart` - Detailed player biography and seasonal performance stats.
