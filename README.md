# ScoreMob

ScoreMob to nowoczesna i dynamiczna aplikacja mobilna stworzona w technologii **Flutter**, służąca do śledzenia wyników meczów piłkarskich, tabel ligowych, statystyk zawodników oraz zarządzania ulubionymi drużynami i ligami w czasie rzeczywistym. 

Aplikacja integruje się z platformą **Supabase** w celu autoryzacji użytkowników i synchronizacji danych w chmurze, a także korzysta z zewnętrznych interfejsów API do pobierania aktualnych danych sportowych.

---

## 🌟 Kluczowe Funkcje

### 1. Autoryzacja i Profil Użytkownika
* **Rejestracja i Logowanie**: Pełne wsparcie dla uwierzytelniania za pomocą **Supabase Auth** z walidacją i spolszczonymi komunikatami o błędach.
* **Karta Kibica (ScoreMob Fan Card)**: Unikalny, animowany element wizualny w widoku profilu dla zalogowanych użytkowników oraz interaktywny podgląd (zablokowany) dla gości w celu zachęcenia do rejestracji.

### 2. Panel Ulubionych (Favorites)
* **Ligi i Drużyny**: Zalogowani użytkownicy mogą dodawać swoje ulubione rozgrywki i kluby do obserwowanych za pomocą ikon gwiazdek i serc.
* **Synchronizacja w Czasie Rzeczywistym**: Zaimplementowany mechanizm `StreamController.broadcast()` w `SupabaseService` automatycznie synchronizuje status ulubionych pomiędzy wszystkimi zakładkami i ekranami bez konieczności odświeżania widoku.

### 3. Zaawansowane Statystyki i Tabele Ligowe
* **Dynamiczne Tabele**: Widok tabeli ligowej z podziałem na punkty, mecze rozegrane, bramki oraz bilans meczów u siebie i na wyjeździe.
* **Strzelcy i Asystenci**: Zakładka statystyk prezentująca najlepszych strzelców oraz asystentów wybranej ligi wraz z odmianą językową (np. *gol*, *gole*, *goli*).
* **Inteligentny Fallback Sezonów (Free API Tier)**: Aplikacja automatycznie wykrywa ograniczenia planu API dla najnowszych sezonów (np. 2025/26) i bezpiecznie cofa zapytanie do sezonu 2024/25, wyświetlając użytkownikowi estetyczny baner informacyjny o limicie planu.

### 4. Wyszukiwarka i Szczegóły
* **Zunifikowane Wyszukiwanie**: Pojedynczy pasek wyszukiwania, który równolegle i asynchronicznie odpytuje API o pasujące kluby oraz profile zawodników.
* **Szczegóły Drużyny**: Informacje o stadionie (nazwa, pojemność, miasto), rok założenia, lista nadchodzących i minionych meczów oraz zakładka **SKŁAD** (podzielona na pozycje zawodników).
* **Szczegóły Zawodnika**: Profil zawodnika zawierający dane biograficzne oraz szczegółowe statystyki z podziałem na rozgrywki.

### 5. Personalizacja (Motyw Jasny / Ciemny)
* Dynamiczne przełączanie motywów (Light / Dark Mode) z natychmiastowym odświeżeniem kolorystyki wszystkich komponentów.
* Zapisywanie preferencji użytkownika w pamięci lokalnej urządzenia przy użyciu pakietu `shared_preferences`.

---

## 🛠️ Stos Technologiczny

* **Framework**: [Flutter](https://flutter.dev/) (Material 3)
* **Zarządzanie Stanem**: [Provider](https://pub.dev/packages/provider)
* **Baza Danych & Auth**: [Supabase](https://supabase.com/) (PostgreSQL z politykami RLS)
* **Przechowywanie Lokalne**: [SharedPreferences](https://pub.dev/packages/shared_preferences)
* **Konfiguracja Środowiskowa**: [Flutter Dotenv](https://pub.dev/packages/flutter_dotenv)

---

## 🚀 Uruchomienie Projektu

### Wymagania wstępne
1. Zainstalowany Flutter SDK (wersja >= 3.0.0).
2. Skonfigurowany emulator Android/iOS lub przeglądarka Chrome (do uruchomienia w trybie Web).
3. Aktywny projekt w Supabase oraz klucz do API-Football (RapidAPI).

### Konfiguracja środowiska
W katalogu głównym projektu utwórz plik `.env` i uzupełnij go swoimi danymi:

```env
SUPABASE_URL=https://your-supabase-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
RAPIDAPI_KEY=your-rapidapi-key
```

### Instalacja i uruchomienie

1. Pobierz zależności:
   ```bash
   flutter pub get
   ```

2. Uruchom analizator kodu, aby upewnić się, że nie ma błędów:
   ```bash
   flutter analyze
   ```

3. Uruchom aplikację:
   ```bash
   flutter run
   ```

---

## 📁 Struktura Projektu (Główne pliki)

* `lib/main.dart` - Punkt wejściowy aplikacji, inicjalizacja Dotenv, Supabase oraz ThemeProvidera.
* `lib/theme/app_theme.dart` - Definicja palety kolorów motywu jasnego/ciemnego oraz extension na `BuildContext`.
* `lib/services/`
  * `theme_provider.dart` - Zarządzanie stanem motywu i jego zapisem.
  * `supabase_service.dart` - Obsługa komunikacji z Supabase (Favorites DB, RLS, Streams).
  * `football_api.dart` - Integracja z zewnętrznymi API piłkarskimi, obsługa błędów i fallbacków.
* `lib/screens/`
  * `main_navigation_screen.dart` - Pasek nawigacyjny o nowoczesnym, półprzezroczystym designie.
  * `home_screen.dart` - Lista dzisiejszych meczów z filtrem daty.
  * `search_screen.dart` - Zunifikowana wyszukiwarka drużyn i zawodników.
  * `favorites_screen.dart` - Panel ulubionych lig i drużyn z odświeżaniem w czasie rzeczywistym.
  * `profile_screen.dart` - Zarządzanie profilem, Karta Kibica oraz przełącznik motywu.
  * `league_standings_screen.dart` - Tabele ligowe, statystyki strzelców/asystentów i baner fallback.
  * `team_detail_screen.dart` - Szczegółowy profil drużyny z meczami i składem.
  * `player_detail_screen.dart` - Szczegółowy profil zawodnika z metrykami meczowymi.
