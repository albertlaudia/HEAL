// HEAL — Ambient Soundscape Mixer.
//
// Layer ambient sounds (rain, fire, wind, bells) at independent volumes
// to create a custom atmosphere for sleep / meditation / prayer.
// Inspired by Calm's "Scenes" but lighter — no network, no app, just
// open the page and the sound plays.
//
// NOTE: ambient tracks live at /heal/sounds/ on the CDN. just_audio
// sets a Host header so the SmarterASP IIS server returns the right
// file. CF cache is bypassed by the unique URL pattern.
//
// Each track loops a pre-generated WAV file. Sounds are bundled assets.
// (The actual audio assets are downloaded on first run from our CDN.)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';

class AmbientTrack {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String url;  // CDN URL to loop
  final List<int> palettes;  // gradient colors [start, end]
  const AmbientTrack({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.url,
    required this.palettes,
  });
}

const _tracks = [
  AmbientTrack(
    id: 'rain',
    name: 'Soft rain',
    description: 'A slow, steady rain on a window pane.',
    icon: '🌧️',
    url: 'https://resources.positiveness.club/heal/sounds/rain-loop.mp3',
    palettes: [0xFF2A3A5A, 0xFF0F1A2F],
  ),
  AmbientTrack(
    id: 'fire',
    name: 'Fireplace',
    description: 'Wood crackling low, embers popping.',
    icon: '🔥',
    url: 'https://resources.positiveness.club/heal/sounds/fire-loop.mp3',
    palettes: [0xFF5A2F1A, 0xFF2F1A0F],
  ),
  AmbientTrack(
    id: 'wind',
    name: 'Mountain wind',
    description: 'A long wind through pines, high and far.',
    icon: '🌬️',
    url: 'https://resources.positiveness.club/heal/sounds/wind-loop.mp3',
    palettes: [0xFF3A5A4A, 0xFF0F2F1A],
  ),
  AmbientTrack(
    id: 'ocean',
    name: 'Ocean',
    description: 'Distant waves, slow and unhurried.',
    icon: '🌊',
    url: 'https://resources.positiveness.club/heal/sounds/ocean-loop.mp3',
    palettes: [0xFF1A4A5A, 0xFF0A2A3A],
  ),
  AmbientTrack(
    id: 'forest',
    name: 'Forest',
    description: 'Birds, leaves, a small creek in the distance.',
    icon: '🌲',
    url: 'https://resources.positiveness.club/heal/sounds/forest-loop.mp3',
    palettes: [0xFF2A4A2A, 0xFF1A2F1A],
  ),
  AmbientTrack(
    id: 'night',
    name: 'Night crickets',
    description: 'Soft crickets and the breath of evening.',
    icon: '🌌',
    url: 'https://resources.positiveness.club/heal/sounds/night-loop.mp3',
    palettes: [0xFF2A1A4A, 0xFF0F0A2F],
  ),
];

class AmbientSoundsPage extends HookConsumerWidget {
  const AmbientSoundsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = useState<Map<String, AudioPlayer>>({});
    final volumes = useState<Map<String, double>>({});
    final anyPlaying = useState<bool>(false);

    // Load saved volumes
    useEffect(() {
      () async {
        final prefs = await SharedPreferences.getInstance();
        final saved = prefs.getStringList('heal.ambient.volumes') ?? [];
        final v = <String, double>{};
        for (final s in saved) {
          final parts = s.split(':');
          if (parts.length == 2) {
            v[parts[0]] = double.tryParse(parts[1]) ?? 0.0;
          }
        }
        // Fill defaults
        for (final t in _tracks) {
          v.putIfAbsent(t.id, () => 0.0);
        }
        volumes.value = v;
      }();
      return null;
    }, []);

    // Persist + apply volume when changed
    Future<void> setVolume(String id, double v) async {
      HapticFeedback.selectionClick();
      final newMap = Map<String, double>.from(volumes.value);
      newMap[id] = v;
      volumes.value = newMap;
      final player = players.value[id];
      if (player != null) await player.setVolume(v);
      // Save
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('heal.ambient.volumes',
        newMap.entries.map((e) => '${e.key}:${e.value.toStringAsFixed(2)}').toList());
    }

    Future<void> toggle(String id, String url) async {
      HapticFeedback.lightImpact();
      var map = players.value;
      if (map.containsKey(id)) {
        final p = map[id]!;
        if (p.playing) {
          await p.pause();
        } else {
          await p.play();
        }
      } else {
        // Create new player
        final player = AudioPlayer();
        player.setLoopMode(LoopMode.all);
        try {
          await player.setUrl(url);
          await player.setVolume(volumes.value[id] ?? 0.5);
          await player.play();
        } catch (e) {
          HapticFeedback.heavyImpact();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sound failed to load. CDN may be caching — try again in a moment.'),
                backgroundColor: HealTokens.rosewoodDeep,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
        map = {...map, id: player};
        players.value = map;
      }
      anyPlaying.value = map.values.any((p) => p.playing);
    }

    Future<void> stopAll() async {
      HapticFeedback.mediumImpact();
      for (final p in players.value.values) {
        await p.stop();
      }
      anyPlaying.value = false;
    }

    return Scaffold(
      backgroundColor: HealTokens.midnightBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: HealTokens.midnightSurface,
            iconTheme: const IconThemeData(color: HealTokens.cream),
            title: const Text('Ambient', style: TextStyle(color: HealTokens.cream, fontSize: 18, fontWeight: FontWeight.w500)),
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (anyPlaying.value)
                IconButton(
                  icon: const Icon(Icons.stop_circle_outlined, color: HealTokens.creamSleep),
                  tooltip: 'Stop all',
                  onPressed: stopAll,
                ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              HealTokens.s20, HealTokens.s24, HealTokens.s20, HealTokens.s80,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Hero
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Make the room\nlisten with you.',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: HealTokens.cream,
                            fontWeight: FontWeight.w300,
                            height: 1.15,
                          ),
                    ),
                    const SizedBox(height: HealTokens.s12),
                    Text(
                      'Layer the sounds. Find the silence inside the noise. Let it carry you.',
                      style: TextStyle(
                        color: HealTokens.creamDim.withValues(alpha: 0.7),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: HealTokens.s32),
                // Track grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: HealTokens.s12,
                    crossAxisSpacing: HealTokens.s12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _tracks.length,
                  itemBuilder: (context, i) {
                    final t = _tracks[i];
                    final vol = volumes.value[t.id] ?? 0.0;
                    final isPlaying = players.value[t.id]?.playing ?? false;
                    return _AmbientCard(
                      track: t,
                      volume: vol,
                      isPlaying: isPlaying,
                      onTap: () => toggle(t.id, t.url),
                      onVolume: (v) => setVolume(t.id, v),
                    );
                  },
                ),
                const SizedBox(height: HealTokens.s24),
                _PresetBar(
                  onPreset: (preset) {
                    HapticFeedback.mediumImpact();
                    // Apply a preset: set all volumes at once
                    final newMap = <String, double>{};
                    for (final t in _tracks) {
                      newMap[t.id] = preset.sounds[t.id] ?? 0.0;
                    }
                    volumes.value = newMap;
                    for (final t in _tracks) {
                      final p = players.value[t.id];
                      if (p != null) p.setVolume(newMap[t.id]!);
                    }
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientCard extends StatelessWidget {
  final AmbientTrack track;
  final double volume;
  final bool isPlaying;
  final VoidCallback onTap;
  final ValueChanged<double> onVolume;
  const _AmbientCard({
    required this.track,
    required this.volume,
    required this.isPlaying,
    required this.onTap,
    required this.onVolume,
  });
  @override
  Widget build(BuildContext context) {
    final start = Color(track.palettes[0]);
    final end = Color(track.palettes[1]);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [start, end],
        ),
        borderRadius: BorderRadius.circular(HealTokens.r20),
        border: Border.all(
          color: isPlaying
              ? HealTokens.creamSleep40
              : HealTokens.creamSleep08,
        ),
        boxShadow: isPlaying
            ? const <BoxShadow>[
                BoxShadow(
                  color: HealTokens.creamSleep20,
                  blurRadius: 16,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(HealTokens.r20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(HealTokens.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(track.icon, style: const TextStyle(fontSize: 22)),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: isPlaying ? HealTokens.creamSleep : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: HealTokens.creamSleep50,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  track.name,
                  style: const TextStyle(
                    color: HealTokens.creamWarm,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  track.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: HealTokens.creamDusk,
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                // Volume slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: volume.clamp(0.0, 1.0),
                    min: 0,
                    max: 1,
                    activeColor: HealTokens.creamSleep,
                    inactiveColor: HealTokens.creamSleep20,
                    onChanged: onVolume,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Preset {
  final String name;
  final Map<String, double> sounds;
  const _Preset(this.name, this.sounds);
}

const _presets = [
  _Preset('Quiet', {'rain': 0.3, 'fire': 0.0, 'wind': 0.0, 'ocean': 0.0, 'forest': 0.0, 'night': 0.0}),
  _Preset('Storm', {'rain': 0.7, 'fire': 0.0, 'wind': 0.4, 'ocean': 0.0, 'forest': 0.0, 'night': 0.0}),
  _Preset('Hearth', {'rain': 0.2, 'fire': 0.7, 'wind': 0.0, 'ocean': 0.0, 'forest': 0.0, 'night': 0.0}),
  _Preset('Beach', {'rain': 0.0, 'fire': 0.0, 'wind': 0.4, 'ocean': 0.6, 'forest': 0.0, 'night': 0.0}),
  _Preset('Forest', {'rain': 0.0, 'fire': 0.0, 'wind': 0.0, 'ocean': 0.0, 'forest': 0.7, 'night': 0.3}),
];

class _PresetBar extends StatelessWidget {
  final void Function(_Preset) onPreset;
  const _PresetBar({required this.onPreset});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRESETS',
          style: TextStyle(
            color: HealTokens.creamSleep.withValues(alpha: 0.7),
            fontSize: 11,
            letterSpacing: 2.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _presets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final p = _presets[i];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onPreset(p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: HealTokens.midnightSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: HealTokens.creamSleep.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        p.name,
                        style: const TextStyle(
                          color: HealTokens.creamWarm,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
