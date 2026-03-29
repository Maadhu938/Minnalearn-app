# MinnaLearn - Japanese N5 Learning App

**MinnaLearn** is a Flutter-based mobile application for **JLPT N5 learners** studying Japanese vocabulary, kana, and kanji through flashcards, quizzes, interactive mini-games, and writing practice inspired by the *Minna no Nihongo* learning approach.

---

## Features

### 25 Structured Lessons
- Vocabulary from *Minna no Nihongo* textbook
- 4 kanji per lesson with readings (on/kun)
- Grammar points loaded from lesson-specific files
- Progress tracking per lesson (0-100%)

### Kanji Learning
- **Flashcards** - Tap to reveal meaning and readings
- **Writing Practice** - Stroke tracing on a drawing board
- **Kanji Quiz** - Multiple choice meaning quiz
- 107 JLPT N5 kanji across all lessons

### Interactive Learning Modes
- **Flashcards** - Swipeable cards with text-to-speech pronunciation
- **Learn Mode** - Browse vocabulary list with bookmarks and audio
- **Test Mode** - 10-question quiz (kana to English / English to kana)

### Mini Games
- **Matching Game** - Match Japanese words with meanings against the clock
- **True or False** - Quick-fire kana and meaning matching
- **Typing Test** - Type English meanings of Japanese words
- **Kana Puzzle** - Timed drag-and-drop kana building

### Progress Tracking
- Daily study streak counter
- Weekly study time chart
- Vocabulary and kanji mastery meters
- Lesson completion tracking
- Game score history

### Achievements
- 9 unlockable achievements across 5 categories:
  - **Lessons** - Complete 1 / 12 lessons
  - **Streak** - Reach 3 / 7 day streaks
  - **Vocabulary** - Learn 50 / 100 vocabulary items
  - **Kanji** - Learn 10 / 25 kanji
  - **Score** - Get 100% on any quiz

### Notifications
- Auto-requests notification permission on Android 13+
- Daily reminder at 6:00 PM to continue studying
- Streak reminder at 8:00 PM if yesterday's study was missed

### Cloud Sync
- Firebase Authentication (email/password + Google Sign-In)
- Cloud Firestore sync for progress, achievements, bookmarks, and learned kanji

---

## Getting Started

```bash
# Clone the repository
git clone https://github.com/Maadhu938/MinnaLearn-FlutterApp.git

# Navigate to the project
cd MinnaLearn-FlutterApp/flutter_minnalearn

# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## Project Structure

```
flutter_minnalearn/
  android/                        # Android native config
  assets/
    audio/                        # Sound effects (correct, wrong, click, success)
    grammar/                      # grammarbai1.txt - grammarbai25.txt
    vocab/                        # bai1.txt - bai25.txt (vocabulary files)
  lib/
    main.dart                     # App entry, Firebase init, MaterialApp
    data/
      n5_kanji_data.dart          # 107 JLPT N5 kanji entries
    models/
      lesson.dart                 # Vocabulary, Kanji, Lesson models
    screens/
      auth_screen.dart            # Email/password + Google Sign-In
      home_screen.dart            # Dashboard with stats and feature cards
      main_screen.dart            # PageView bottom nav (Home/Lessons/Games/Stats/Profile)
      lessons_screen.dart         # List of 25 lessons with progress
      lesson_detail_screen.dart   # Lesson hub (Flashcards/Learn/Test/Grammar)
      flashcards_screen.dart      # Swipeable vocabulary flashcards
      quiz_screen.dart            # Vocabulary quiz with lesson completion popup
      kanji_screen.dart           # Kanji flashcards, writing, and quiz
      vocabulary_list_screen.dart # Vocabulary list with speak/bookmark
      grammar_screen.dart         # Grammar points per lesson
      games_screen.dart           # Games hub with recent scores
      matching_game_screen.dart   # Match words to meanings game
      true_or_false_screen.dart   # Quick-fire true/false kana quiz
      typing_test_screen.dart     # Typing speed test game
      kana_puzzle_screen.dart     # Timed kana building puzzle
      stats_screen.dart           # Progress charts and mastery bars
      profile_screen.dart         # Profile, achievements, privacy policy
      onboarding_screen.dart      # First-time user onboarding
      startup_screen.dart         # Bootstrap (DB init, notifications, routing)
    services/
      achievement_service.dart    # Achievement definitions and unlocking
      audio_service.dart          # Sound effects (audioplayers)
      auth_service.dart           # Firebase Authentication
      cloud_service.dart          # Firestore sync
      database_service.dart       # SQLite database (all CRUD operations)
      data_seeder.dart            # Loads vocab/kanji from bundled assets
      notification_service.dart   # Local scheduled notifications with auto permission
      quiz_engine.dart            # Quiz question generation
      speech_service.dart         # Text-to-speech (flutter_tts)
      study_timer_service.dart    # Background study time tracker
    utils/
      vocabulary_display.dart     # Vocabulary display helpers
    widgets/
      bottom_nav.dart             # Bottom navigation bar
      feature_card.dart           # Reusable feature card
      kanji_drawing_board.dart    # Kanji stroke drawing canvas
      stat_card.dart              # Stat display card widget
  docs/
    index.html                    # Privacy policy (GitHub Pages)
```

---

## Tech Stack

| Component | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Database | SQLite (sqflite) |
| Auth | Firebase Auth |
| Cloud Sync | Cloud Firestore |
| Notifications | flutter_local_notifications |
| TTS | flutter_tts |
| Audio | audioplayers |
| Fonts | Google Fonts (Inter) |
| Icons | Lucide Icons |
| Timezone | timezone package |

---

## Build

### Debug APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Play Store (AAB)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

---

## License

MIT License
