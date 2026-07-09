// HEAL — Microcopy library
// ============================================================================
// All user-facing strings live here. Key rules:
//   - First-person ("you", never "the user")
//   - Concrete verbs ("Read today's verse", not "Begin a 5-min practice")
//   - Reverent register — no "world-class", "AI-powered", "level up", "unlock"
//   - No guilt, no streak-shame — even when reminding
//   - Maximum 12 words per line where possible — single glancable message
//   - All scripture references use a stable book-chapter-verse format
//
// Reference for banned phrases: see Sigil/Investos linter. Anything resembling
// "synced across devices" / "AI" / "free forever" / generic marketing speak
// must NOT appear.
// ============================================================================

abstract class Copy {
  // ── Brand voice ──────────────────────────────────────────────
  static const wordmark  = 'HEAL';
  static const tagline   = 'A quiet place to be still.';
  static const subTag    = 'For the hurried and the weary.';

  // ── Onboarding ───────────────────────────────────────────────
  static const onboardingGreeting = 'Welcome to HEAL.';
  static const onboardingIntro = 'A few breaths and a verse. That is all.';
  static const onboardingPledge = 'No tracking. No noise. No account needed.';

  // First-breath screen: instruction is short, third-person-positioned
  // so it feels guided, not lectured.
  static const firstBreathTitle   = 'Breathe with me';
  static const firstBreathBody    =
      'Three slow breaths.\nFeel the body settle.\nYou have all the time you need.';
  static const firstBreathCta     = 'I\'m ready';

  // Permission ask (after first session, never before)
  static const permissionTitle    = 'A gentle nudge?';
  static const permissionBody     =
      'Tomorrow at 7am, we\'ll quietly remind you to come back. '
      'That is all — once a day, never twice.';
  static const permissionYes      = 'Yes, once a day';
  static const permissionNo       = 'Not now';

  // ── Home / Today ─────────────────────────────────────────────
  static const homeGreeting       = 'Good morning'; // prefix only
  static const homeGreetingBody   = 'The Word is waiting, friend.';

  // Hero CTA — by time-of-day
  static String heroCtaMorning() =>
      'Begin today\'s practice';
  static String heroCtaEvening() =>
      'Wind down for the night';
  static String heroCtaDefault() =>
      'A practice for you';
  static const heroPreviewLine   = '5 min · a verse · a breath · a prayer';

  // Lumen's words — first-person
  static String lumenGreeting(int dayStreak) => dayStreak == 0
      ? 'I\'m here whenever you are.'
      : dayStreak == 1
      ? 'You came back. I noticed.'
      : 'Day $dayStreak. We\'re doing this together.';

  // ── Now page (90-second ritual) ──────────────────────────────
  static const ritualStepPause   = 'Pause';
  static const ritualStepRead    = 'Read';
  static const ritualStepBreathe = 'Breathe';
  static const ritualStepPray    = 'Pray';

  // ── Practice grid (post-staging) ─────────────────────────────
  static const practiceBreathe   = 'Breathe';
  static const practiceBreatheSub = '~1 min · Start here';
  static const practiceMeditate  = 'Meditate';
  static const practiceMeditateSub = '~5 min · Guided stillness';
  static const practicePray      = 'Pray';
  static const practicePraySub   = '~3 min · Words for the hour';
  static const practicePraise    = 'Praise';
  static const practicePraiseSub = '~4 min · Songs & hymns';
  static const practiceReflections = 'Reflections';
  static const practiceReflectionsSub = '~7 min · Slow reading';
  static const practiceSleep     = 'Sleep';
  static const practiceSleepSub  = '~10 min · Wind down';
  static const practiceStickerBook = 'Stickers';
  static const practiceStickerBookSub = '~moments · What you\'ve earned';

  // ── Praise library ──────────────────────────────────────────
  static const todaysPraiseLabel = "TODAY'S PRAISE";
  static const morePraiseLabel   = 'MORE PRAISE';
  static const praiseFavorites   = 'Favorites';
  static const praiseDownloaded  = 'Downloaded';
  static const praiseAll         = 'All';
  static const praiseEmpty       =
      'No hymns here yet. Try the All tab, or come back tomorrow.';

  // ── Sticker book ─────────────────────────────────────────────
  static const stickersDaily     = 'Daily';
  static const stickersFirsts    = 'Firsts';
  static const stickersStories   = 'Stories';
  static const stickersNextMilestone = 'NEXT MILESTONES';
  static const stickersEarned    = 'Earned';
  static const stickersLocked    = 'Yet to come';
  static const stickersMotivational =
      '"The practice has roots now." — for you, friend.';

  // ── Sleep stories ────────────────────────────────────────────
  static const sleepHeroHeader   = 'BEDTIME';
  static const sleepHeroBody     =
      'Slow your breathing. Lower the day. Lie in the Word.';
  static const sleepAmbientTitle = 'Soundscapes';
  static const sleepAmbientBody  = 'Six layers. Lift the volume to taste.';

  // ── Profile ──────────────────────────────────────────────────
  static const profileIdentity   = 'You are the kind of person who shows up.';
  static const profileStatsCurrent = 'Current';
  static const profileStatsLongest = 'Longest';
  static const profileStatsTotal   = 'Total';
  static const profileStatsMinutes = 'minutes';
  static const profileStatsSessions = 'sessions';

  // ── Notifications ───────────────────────────────────────────
  static const notifMorningDefault =
      'The Word, today';
  static const notifMorningBodyDefault =
      'Day {n}. Whatever you give is enough.';

  static const notifMissedDefault =
      'Tomorrow\'s reading is here. Three chapters, ten minutes.';

  static const notifComebackDefault =
      'Welcome back. Day {n} is here.';

  // ── Errors & empty states ────────────────────────────────────
  static const errNetwork =
      'The signal is thin. Try once more.';
  static const errNotFound =
      'We couldn\'t find that. Maybe try a different word.';
  static const errGeneric =
      'Something went quietly wrong. Try again in a moment.';

  // ── Scripture attributions ───────────────────────────────────
  /// Used in scripture cards. Format: short book-name + chapter:verse
  /// e.g. "Psalm 23:1" — never abbrev with period for visual consistency.
  static String scripture(String book, int chapter, int? verse) {
    if (verse == null) return '$book $chapter';
    return '$book $chapter:$verse';
  }

  // ── Calendar / time-of-day helpers ───────────────────────────
  static String greetingForHour(int hour) {
    if (hour < 5)  return 'Still up?';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Wind down';
  }
}
