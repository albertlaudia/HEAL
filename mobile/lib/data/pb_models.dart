// HEAL — PocketBase data models.
import 'dart:convert';

// Mirror the HEAL_* collections on https://pocketbase.scaleupcrm.com.

class Meditation {
  final String id;
  final String slug;
  final String title;
  final String subtitle;
  final String body;
  final String audioUrl;
  final String illustrationUrl;
  final String? theme;
  final int durationSeconds;
  final String? voiceName;
  final String? category; // 'guided', 'sleep', 'morning', 'scripture', 'breath'
  final List<String> tags;
  final List<String> bestFor;
  final bool isPublished;
  final int sortOrder;

  const Meditation({
    required this.id,
    required this.slug,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.audioUrl,
    required this.illustrationUrl,
    this.theme,
    this.durationSeconds = 0,
    this.voiceName,
    this.category,
    this.tags = const [],
    this.bestFor = const [],
    this.isPublished = true,
    this.sortOrder = 0,
  });

  factory Meditation.fromJson(Map<String, dynamic> json) {
    return Meditation(
      id: json['id'] as String,
      slug: (json['slug'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      subtitle: (json['subtitle'] ?? '') as String,
      body: (json['body'] ?? '') as String,
      audioUrl: (json['audio_url'] ?? '') as String,
      illustrationUrl: (json['illustration_url'] ?? '') as String,
      theme: json['theme'] as String?,
      durationSeconds: (json['duration_seconds'] ?? 0) as int,
      voiceName: json['voice_name'] as String?,
      category: json['category'] as String?,
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      bestFor: (json['best_for'] as List?)?.cast<String>() ?? const [],
      isPublished: (json['is_published'] ?? true) as bool,
      sortOrder: (json['sort_order'] ?? 0) as int,
    );
  }

  String get cdnIllustration => illustrationUrl.isNotEmpty
      ? illustrationUrl
      : 'https://resources.positiveness.club/heal/images/meditations/$slug.jpg';

  String get cdnAudio => audioUrl.isNotEmpty
      ? audioUrl
      : 'https://resources.positiveness.club/heal/audio/meditations/$slug.mp3';
}

class PraiseSong {
  final String id;
  final String slug;
  final String title;
  final String subtitle;
  final String description;
  final String lyrics;
  final String reflection;
  final String chords;
  final String keySignature;
  final String meter;
  final int? tempoBpm;
  final String audioUrl;
  final String illustrationUrl;
  final String? category;
  final String? emotion;
  final String? mood;
  final List<String> bestFor;
  final List<String> tags;
  final List<String> scriptureRefs;
  final int? bpm;
  final bool isPublished;
  final int dayOfYear;

  const PraiseSong({
    required this.id,
    required this.slug,
    required this.title,
    required this.subtitle,
    required this.lyrics,
    required this.audioUrl,
    required this.illustrationUrl,
    this.category,
    this.emotion,
    this.mood,
    this.bestFor = const [],
    this.tags = const [],
    this.bpm,
    this.isPublished = true,
  });

  factory PraiseSong.fromJson(Map<String, dynamic> json) {
    List<String> _toList(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      if (v is String && v.isNotEmpty) {
        try { return (jsonDecode(v) as List).map((e) => e.toString()).toList(); }
        catch (_) { return v.split(',').map((e) => e.trim()).toList(); }
      }
      return const [];
    }
    return PraiseSong(
      id: json['id'] as String,
      slug: (json['slug'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      subtitle: (json['subtitle'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      lyrics: (json['lyrics'] ?? '') as String,
      reflection: (json['reflection'] ?? '') as String,
      chords: (json['chords'] ?? '') as String,
      keySignature: (json['key_signature'] ?? '') as String,
      meter: (json['meter'] ?? '') as String,
      tempoBpm: (json['tempo_bpm'] ?? json['bpm']) as int?,
      audioUrl: (json['audio_url'] ?? '') as String,
      illustrationUrl: (json['illustration_url'] ?? '') as String,
      category: json['category'] as String?,
      emotion: json['emotion'] as String?,
      mood: json['mood'] as String?,
      bestFor: _toList(json['best_for']),
      tags: _toList(json['tags']),
      scriptureRefs: _toList(json['scripture_refs']),
      bpm: json['bpm'] as int?,
      isPublished: (json['is_published'] ?? true) as bool,
      dayOfYear: (json['day_of_year'] ?? 0) as int,
    );
  }

  String get cdnIllustration => illustrationUrl.isNotEmpty
      ? illustrationUrl
      : 'https://resources.positiveness.club/heal/images/praise/$slug.jpg';

  String get cdnAudio => audioUrl.isNotEmpty
      ? audioUrl
      : 'https://resources.positiveness.club/heal/audio/praise/$slug.mp3';
}

class Prayer {
  final String id;
  final String slug;
  final String title;
  final String body;
  final String? category;
  final String? emotion;
  final List<String> tags;
  final String? attribution;
  final String illustrationUrl;
  final bool isPublished;
  final bool isEventPrayer;
  final String? sourceEvent;
  final DateTime? eventDate;

  const Prayer({
    required this.id,
    required this.slug,
    required this.title,
    required this.body,
    this.category,
    this.emotion,
    this.tags = const [],
    this.attribution,
    this.illustrationUrl = '',
    this.isPublished = true,
    this.isEventPrayer = false,
    this.sourceEvent,
    this.eventDate,
  });

  factory Prayer.fromJson(Map<String, dynamic> json) {
    return Prayer(
      id: json['id'] as String,
      slug: (json['slug'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      body: (json['body'] ?? '') as String,
      category: json['category'] as String?,
      emotion: json['emotion'] as String?,
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      attribution: json['attribution'] as String?,
      illustrationUrl: (json['illustration_url'] ?? '') as String,
      isPublished: (json['is_published'] ?? true) as bool,
      isEventPrayer: (json['is_event_prayer'] ?? false) as bool,
      sourceEvent: json['source_event'] as String?,
      eventDate: json['event_date'] != null
          ? DateTime.tryParse(json['event_date'] as String)
          : null,
    );
  }

  String get cdnIllustration => illustrationUrl.isNotEmpty
      ? illustrationUrl
      : 'https://resources.positiveness.club/heal/images/prayers/$slug.jpg';
}

class Scripture {
  final String id;
  final String slug;
  final String reference;
  final String text;
  final String? translation;
  final String? theme;
  final String? reflectionPrompt;
  final String? emotion;
  final List<String> tags;
  final bool isPublished;

  const Scripture({
    required this.id,
    required this.slug,
    required this.reference,
    required this.text,
    this.translation,
    this.theme,
    this.reflectionPrompt,
    this.emotion,
    this.tags = const [],
    this.isPublished = true,
  });

  factory Scripture.fromJson(Map<String, dynamic> json) {
    return Scripture(
      id: json['id'] as String,
      slug: (json['slug'] ?? '') as String,
      reference: (json['reference'] ?? '') as String,
      text: (json['text'] ?? '') as String,
      translation: json['translation'] as String?,
      theme: json['theme'] as String?,
      reflectionPrompt: json['reflection_prompt'] as String?,
      emotion: json['emotion'] as String?,
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      isPublished: (json['is_published'] ?? true) as bool,
    );
  }
}

class Quote {
  final String id;
  final String slug;
  final String text;
  final String attribution;
  final String? category;
  final String? emotion;
  final List<String> tags;
  final bool isPublished;

  const Quote({
    required this.id,
    required this.slug,
    required this.text,
    required this.attribution,
    this.category,
    this.emotion,
    this.tags = const [],
    this.isPublished = true,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] as String,
      slug: (json['slug'] ?? '') as String,
      text: (json['text'] ?? '') as String,
      attribution: (json['attribution'] ?? '') as String,
      category: json['category'] as String?,
      emotion: json['emotion'] as String?,
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      isPublished: (json['is_published'] ?? true) as bool,
    );
  }
}

class BreathPattern {
  final String id;
  final String slug;
  final String name;
  final String description;
  final int inhaleSeconds;
  final int holdInSeconds;
  final int exhaleSeconds;
  final int holdOutSeconds;
  final String? bestFor;
  final String illustrationUrl;
  final List<String> tags;

  const BreathPattern({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.inhaleSeconds,
    required this.holdInSeconds,
    required this.exhaleSeconds,
    required this.holdOutSeconds,
    this.bestFor,
    this.illustrationUrl = '',
    this.tags = const [],
  });

  factory BreathPattern.fromJson(Map<String, dynamic> json) {
    return BreathPattern(
      id: json['id'] as String,
      slug: (json['slug'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      inhaleSeconds: (json['inhale_seconds'] ?? 4) as int,
      holdInSeconds: (json['hold_in_seconds'] ?? 4) as int,
      exhaleSeconds: (json['exhale_seconds'] ?? 6) as int,
      holdOutSeconds: (json['hold_out_seconds'] ?? 2) as int,
      bestFor: json['best_for'] as String?,
      illustrationUrl: (json['illustration_url'] ?? '') as String,
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
    );
  }

  String get cdnIllustration => illustrationUrl.isNotEmpty
      ? illustrationUrl
      : 'https://resources.positiveness.club/heal/images/breath/$slug.jpg';
}

class Essay {
  final String id;
  final String slug;
  final String title;
  final String subtitle;
  final String body;
  final String illustrationUrl;
  final String? category;
  final List<String> tags;
  final int readMinutes;
  final bool isPublished;

  const Essay({
    required this.id,
    required this.slug,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.illustrationUrl,
    this.category,
    this.tags = const [],
    this.readMinutes = 0,
    this.isPublished = true,
  });

  factory Essay.fromJson(Map<String, dynamic> json) {
    return Essay(
      id: json['id'] as String,
      slug: (json['slug'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      subtitle: (json['subtitle'] ?? '') as String,
      body: (json['body'] ?? '') as String,
      illustrationUrl: (json['illustration_url'] ?? '') as String,
      category: json['category'] as String?,
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      readMinutes: (json['read_minutes'] ?? 0) as int,
      isPublished: (json['is_published'] ?? true) as bool,
    );
  }

  String get cdnIllustration => illustrationUrl.isNotEmpty
      ? illustrationUrl
      : 'https://resources.positiveness.club/heal/images/essays/$slug.jpg';
}
/// HEALWorld — a daily "world invitation" piece.
class WorldDay {
  final String id;
  final String slug;
  final String title;
  final String prompt;
  final String? promptKind;  // 'challenge' | 'grace' | 'gratitude'
  final String? tone;
  final String? scriptureRef;
  final String? scriptureText;
  final String prayer;
  final String reflection;
  final String expectation;
  final List<String>? tags;
  final String? illustrationUrl;
  final int? dayOfYear;
  final bool? isPublished;
  final DateTime? publishedAt;

  const WorldDay({
    required this.id,
    required this.slug,
    required this.title,
    required this.prompt,
    required this.prayer,
    required this.reflection,
    required this.expectation,
    this.promptKind,
    this.tone,
    this.scriptureRef,
    this.scriptureText,
    this.tags,
    this.illustrationUrl,
    this.dayOfYear,
    this.isPublished,
    this.publishedAt,
  });

  factory WorldDay.fromJson(Map<String, dynamic> json) {
    return WorldDay(
      id:            (json['id'] ?? '') as String,
      slug:          (json['slug'] ?? '') as String,
      title:         (json['title'] ?? '') as String,
      prompt:        (json['prompt'] ?? '') as String,
      promptKind:    json['prompt_kind'] as String?,
      tone:          json['tone'] as String?,
      scriptureRef:  json['scripture_ref'] as String?,
      scriptureText: json['scripture_text'] as String?,
      prayer:        (json['prayer'] ?? '') as String,
      reflection:    (json['reflection'] ?? '') as String,
      expectation:   (json['expectation'] ?? '') as String,
      tags:          (json['tags'] as List?)?.cast<String>(),
      illustrationUrl: json['illustration_url'] as String?,
      dayOfYear:     json['day_of_year'] as int?,
      isPublished:   json['is_published'] as bool?,
      publishedAt:   _parseDate(json['published_at']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    try { return DateTime.parse(s); } catch (_) { return null; }
  }
}



/// HEALBibleReading — one day in the Bible-in-a-Year plan.
class BibleReading {
  final String id;
  final int dayNumber;
  final String title;
  final List<BibleReadingItem> readings;
  final String reflectionPrompt;

  const BibleReading({
    required this.id,
    required this.dayNumber,
    required this.title,
    required this.readings,
    this.reflectionPrompt = '',
  });

  factory BibleReading.fromJson(Map<String, dynamic> json) {
    final rawReadings = json['readings'];
    List<BibleReadingItem> parsedReadings = <BibleReadingItem>[];
    if (rawReadings is String) {
      try {
        parsedReadings = (jsonDecode(rawReadings) as List)
            .map((e) => BibleReadingItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    } else if (rawReadings is List) {
      parsedReadings = rawReadings.map((e) => BibleReadingItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    return BibleReading(
      id: json['id'] as String,
      dayNumber: (json['day_number'] ?? 0) as int,
      title: (json['title'] ?? '') as String,
      readings: parsedReadings,
      reflectionPrompt: (json['reflection_prompt'] ?? '') as String,
    );
  }
}

class BibleReadingItem {
  final String book;
  final int chapterStart;
  final int chapterEnd;
  const BibleReadingItem({
    required this.book,
    required this.chapterStart,
    required this.chapterEnd,
  });

  factory BibleReadingItem.fromJson(Map<String, dynamic> json) => BibleReadingItem(
    book: (json['book'] ?? '') as String,
    chapterStart: (json['chapter_start'] ?? 1) as int,
    chapterEnd: (json['chapter_end'] ?? 1) as int,
  );

  String get label {
    if (chapterStart == chapterEnd) return '$book $chapterStart';
    return '$book $chapterStart–$chapterEnd';
  }

  String get bibleGatewayUrl {
    if (chapterStart == chapterEnd) {
      return 'https://www.biblegateway.com/passage/?search=${Uri.encodeComponent(book)}+${chapterStart}&version=NIV';
    }
    return 'https://www.biblegateway.com/passage/?search=${Uri.encodeComponent(book)}+${chapterStart}-${chapterEnd}&version=NIV';
  }
}


/// HEALBibleProgress — a single completed day.
class BibleProgress {
  final String id;
  final String userId;
  final int dayNumber;
  final DateTime completedAt;
  final String notes;
  final int readingSeconds;

  const BibleProgress({
    required this.id,
    required this.userId,
    required this.dayNumber,
    required this.completedAt,
    this.notes = '',
    this.readingSeconds = 0,
  });

  factory BibleProgress.fromJson(Map<String, dynamic> json) {
    return BibleProgress(
      id: json['id'] as String,
      userId: (json['user_id'] ?? '') as String,
      dayNumber: (json['day_number'] ?? 0) as int,
      completedAt: DateTime.tryParse(json['completed_at'] as String? ?? '') ?? DateTime.now(),
      notes: (json['notes'] ?? '') as String,
      readingSeconds: (json['reading_seconds'] ?? 0) as int,
    );
  }
}
