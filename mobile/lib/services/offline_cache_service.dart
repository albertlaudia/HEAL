// HEAL — Offline cache service.
// Downloads MP3s into the app's documents directory so they play without
// internet. Uses HTTP Range headers to handle Cloudflare caching gracefully,
// then writes the bytes to <docs>/heal_audio/<slug>.mp3.
//
// Each song has 3 states:
//   - notCached:   no local file
//   - downloading: in-flight download with progress (0.0 - 1.0)
//   - cached:      file on disk, plays offline
//
// audioplayers' setSource(DeviceFileSource) plays local files.

import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class CacheDownloadProgress {
  final double progress;     // 0.0 - 1.0
  final int receivedBytes;
  final int? totalBytes;
  const CacheDownloadProgress({required this.progress, required this.receivedBytes, this.totalBytes});
}

class OfflineCacheState {
  final Set<String> cachedSlugs;
  final Map<String, CacheDownloadProgress> inProgress;
  final String? lastError;

  const OfflineCacheState({
    required this.cachedSlugs,
    required this.inProgress,
    this.lastError,
  });

  bool isCached(String slug) => cachedSlugs.contains(slug);
  bool isDownloading(String slug) => inProgress.containsKey(slug);
  CacheDownloadProgress? progressFor(String slug) => inProgress[slug];

  OfflineCacheState copyWith({
    Set<String>? cachedSlugs,
    Map<String, CacheDownloadProgress>? inProgress,
    String? lastError,
    bool clearError = false,
  }) =>
      OfflineCacheState(
        cachedSlugs: cachedSlugs ?? this.cachedSlugs,
        inProgress: inProgress ?? this.inProgress,
        lastError: clearError ? null : (lastError ?? this.lastError),
      );
}

class OfflineCacheService extends StateNotifier<OfflineCacheState> {
  OfflineCacheService()
      : super(const OfflineCacheState(cachedSlugs: {}, inProgress: {})) {
    _scanExisting();
  }

  /// On startup, scan the disk to find what's already downloaded.
  /// (Avoids re-downloading songs the user already saved.)
  Future<void> _scanExisting() async {
    try {
      final dir = await _audioDir();
      if (!await dir.exists()) return;
      final files = await dir.list().toList();
      final slugs = <String>{};
      for (final f in files) {
        if (f is File && f.path.endsWith('.mp3')) {
          final name = f.uri.pathSegments.last;
          slugs.add(name.replaceAll('.mp3', ''));
        }
      }
      state = state.copyWith(cachedSlugs: slugs);
    } catch (_) {
      // Non-fatal — empty cache is fine.
    }
  }

  Future<Directory> _audioDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/heal_audio');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _fileFor(String slug) async {
    final dir = await _audioDir();
    return File('${dir.path}/$slug.mp3');
  }

  /// Returns the local file path for a slug if cached.
  Future<String?> localPath(String slug) async {
    if (!state.isCached(slug)) return null;
    final f = await _fileFor(slug);
    if (await f.exists()) return f.path;
    // Cached state was stale — file got cleaned by OS. Refresh.
    final next = Set<String>.from(state.cachedSlugs)..remove(slug);
    state = state.copyWith(cachedSlugs: next);
    return null;
  }

  /// Download a song's MP3. Calls `onProgress` as bytes arrive.
  Future<bool> download(
    String slug,
    String url, {
    void Function(CacheDownloadProgress)? onProgress,
  }) async {
    if (state.isCached(slug)) return true;
    if (state.isDownloading(slug)) return false;

    // Mark downloading
    final progress = <String, CacheDownloadProgress>{
      ...state.inProgress,
      slug: const CacheDownloadProgress(progress: 0, receivedBytes: 0),
    };
    state = state.copyWith(inProgress: progress, clearError: true);

    try {
      final f = await _fileFor(slug);
      final tmp = File('${f.path}.part');
      if (await tmp.exists()) await tmp.delete();

      final request = http.Request('GET', Uri.parse(url));
      // Cloudflare-friendly: ask for full content
      final response = await http.Client().send(request);
      if (response.statusCode != 200) {
        _finishDownload(slug, success: false, error: 'HTTP ${response.statusCode}');
        return false;
      }

      final total = response.contentLength;
      final sink = tmp.openWrite();
      int received = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        final p = total == null || total == 0
            ? 0.5
            : (received / total).clamp(0.0, 1.0);
        final next = <String, DownloadProgress>{
          ...state.inProgress,
          slug: CacheDownloadProgress(progress: p, receivedBytes: received, totalBytes: total),
        };
        state = state.copyWith(inProgress: next);
        onProgress?.call(next[slug]!);
      }
      await sink.close();
      await tmp.rename(f.path);

      _finishDownload(slug, success: true);
      return true;
    } catch (e) {
      _finishDownload(slug, success: false, error: e.toString());
      return false;
    }
  }

  void _finishDownload(String slug, {required bool success, String? error}) {
    final progress = Map<String, CacheDownloadProgress>.from(state.inProgress)..remove(slug);
    if (success) {
      final cached = Set<String>.from(state.cachedSlugs)..add(slug);
      state = state.copyWith(cachedSlugs: cached, inProgress: progress, clearError: true);
    } else {
      state = state.copyWith(inProgress: progress, lastError: error);
    }
  }

  /// Remove a song from the offline cache (frees disk space).
  Future<void> remove(String slug) async {
    try {
      final f = await _fileFor(slug);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    final next = Set<String>.from(state.cachedSlugs)..remove(slug);
    state = state.copyWith(cachedSlugs: next);
  }

  /// Total bytes used by all cached audio on disk.
  Future<int> totalBytes() async {
    final dir = await _audioDir();
    int total = 0;
    await for (final f in dir.list()) {
      if (f is File) total += await f.length();
    }
    return total;
  }
}

final offlineCacheProvider =
    StateNotifierProvider<OfflineCacheService, OfflineCacheState>(
  (ref) => OfflineCacheService(),
);
