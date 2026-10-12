import 'package:flutter/foundation.dart';
import 'database_service.dart';

class ProEntitlementService extends ChangeNotifier {
  static final ProEntitlementService _instance = ProEntitlementService._internal();
  factory ProEntitlementService() => _instance;
  ProEntitlementService._internal();

  bool _isPro = false;
  final Set<int> _unlockedLessonIds = <int>{};
  bool _isInitialized = false;

  bool get isPro => _isPro;
  Set<int> get unlockedLessonIds => Set.unmodifiable(_unlockedLessonIds);

  /// Initializes entitlement state from local persistent storage.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final db = DatabaseService();
      final proVal = await db.getUserStatInt('pro_membership_active') ?? 0;
      _isPro = proVal == 1;

      final unlockedCsv = await db.getUserStatText('ad_unlocked_lessons') ?? '';
      if (unlockedCsv.isNotEmpty) {
        final parsedIds = unlockedCsv
            .split(',')
            .map((s) => int.tryParse(s.trim()))
            .whereType<int>();
        _unlockedLessonIds.addAll(parsedIds);
      }
    } catch (e) {
      debugPrint('Failed to load pro entitlements: $e');
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Lessons 1 through 27 are free preview.
  /// Lessons 28 through 50 require PRO or a rewarded ad unlock.
  bool isLessonUnlocked(int lessonId) {
    if (lessonId <= 27) return true;
    if (_isPro) return true;
    return _unlockedLessonIds.contains(lessonId);
  }

  /// Kanji is unlocked if its associated lesson is unlocked.
  bool isKanjiUnlocked(int lessonId) {
    return isLessonUnlocked(lessonId);
  }

  /// Unlocks a specific lesson (e.g. after watching a rewarded video ad).
  Future<void> unlockLessonWithReward(int lessonId) async {
    if (_unlockedLessonIds.contains(lessonId)) return;

    _unlockedLessonIds.add(lessonId);
    notifyListeners();

    try {
      final db = DatabaseService();
      final csv = _unlockedLessonIds.join(',');
      await db.setUserStatText('ad_unlocked_lessons', csv);
    } catch (e) {
      debugPrint('Failed to save unlocked lesson: $e');
    }
  }

  /// Toggles or updates PRO subscription status.
  Future<void> setProStatus(bool pro) async {
    _isPro = pro;
    notifyListeners();

    try {
      final db = DatabaseService();
      await db.setUserStatInt('pro_membership_active', pro ? 1 : 0);
    } catch (e) {
      debugPrint('Failed to save pro status: $e');
    }
  }
}
