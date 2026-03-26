import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../core/models/download_item.dart';
import '../../core/theme/app_theme.dart';

/// Internal full-featured media player for both video and audio.
/// Uses media_kit for hardware-accelerated playback of local files.
class PlayerScreen extends StatefulWidget {
  final DownloadItem item;
  const PlayerScreen({super.key, required this.item});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player;
  late final VideoController _videoController;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);

    // Open local file
    final path = widget.item.filePath;
    if (path != null) {
      _player.open(Media('file://$path'));
    }
  }

  @override
  void dispose() {
    _player.dispose();
    // Restore orientation
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // ── Video / Audio display ──
              if (widget.item.isVideo)
                AspectRatio(
                  aspectRatio: _isFullscreen ? 16 / 9 : 16 / 9,
                  child: Video(controller: _videoController),
                )
              else
                _AudioArtwork(item: widget.item),

              // ── Controls ──
              Expanded(
                child: Container(
                  color: AppTheme.surface,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          widget.item.title,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.tajawal(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.item.platform} • ${widget.item.quality}',
                        style: GoogleFonts.tajawal(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 20),

                      // Progress slider
                      StreamBuilder<Duration>(
                        stream: _player.stream.position,
                        builder: (ctx, snapPos) {
                          final pos = snapPos.data ?? Duration.zero;
                          return StreamBuilder<Duration>(
                            stream: _player.stream.duration,
                            builder: (ctx, snapDur) {
                              final dur = snapDur.data ?? Duration.zero;
                              final progress = dur.inMilliseconds > 0
                                  ? pos.inMilliseconds / dur.inMilliseconds
                                  : 0.0;
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: SliderTheme(
                                      data: SliderThemeData(
                                        thumbColor: AppTheme.primary,
                                        activeTrackColor: AppTheme.primary,
                                        inactiveTrackColor: AppTheme.surfaceVariant,
                                        trackHeight: 3,
                                        overlayShape: SliderComponentShape.noOverlay,
                                      ),
                                      child: Slider(
                                        value: progress.clamp(0.0, 1.0),
                                        onChanged: (v) {
                                          _player.seek(Duration(milliseconds: (v * dur.inMilliseconds).round()));
                                        },
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(_formatDuration(pos), style: GoogleFonts.tajawal(fontSize: 12, color: AppTheme.textSecondary)),
                                        Text(_formatDuration(dur), style: GoogleFonts.tajawal(fontSize: 12, color: AppTheme.textSecondary)),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Playback controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Back 10s
                          IconButton(
                            icon: const Icon(Icons.replay_10_rounded, size: 32, color: AppTheme.textSecondary),
                            onPressed: () async {
                              final pos = _player.state.position;
                              await _player.seek(pos - const Duration(seconds: 10));
                            },
                          ),

                          // Play/Pause
                          StreamBuilder<bool>(
                            stream: _player.stream.playing,
                            builder: (ctx, snap) {
                              final playing = snap.data ?? false;
                              return GestureDetector(
                                onTap: _player.playOrPause,
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                              );
                            },
                          ),

                          // Forward 10s
                          IconButton(
                            icon: const Icon(Icons.forward_10_rounded, size: 32, color: AppTheme.textSecondary),
                            onPressed: () async {
                              final pos = _player.state.position;
                              await _player.seek(pos + const Duration(seconds: 10));
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Extra controls row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Speed
                            _SpeedButton(player: _player),

                            // Fullscreen (video only)
                            if (widget.item.isVideo)
                              IconButton(
                                icon: Icon(
                                  _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen_rounded,
                                  color: AppTheme.textSecondary,
                                  size: 28,
                                ),
                                onPressed: _toggleFullscreen,
                              ),

                            // Volume
                            IconButton(
                              icon: const Icon(Icons.volume_up_rounded, color: AppTheme.textSecondary, size: 26),
                              onPressed: () {}, // Could show volume slider
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }
}

// ── Audio Artwork ──

class _AudioArtwork extends StatelessWidget {
  final DownloadItem item;
  const _AudioArtwork({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      color: Colors.black,
      child: Center(
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: AppTheme.primary.withOpacity(0.5), blurRadius: 40),
            ],
          ),
          child: const Icon(Icons.audiotrack_rounded, size: 60, color: Colors.white),
        ),
      ),
    );
  }
}

// ── Speed Button ──

class _SpeedButton extends StatefulWidget {
  final Player player;
  const _SpeedButton({required this.player});

  @override
  State<_SpeedButton> createState() => _SpeedButtonState();
}

class _SpeedButtonState extends State<_SpeedButton> {
  final List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  int _index = 2;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _index = (_index + 1) % _speeds.length);
        widget.player.setRate(_speeds[_index]);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${_speeds[_index]}x',
          style: GoogleFonts.tajawal(
            fontSize: 13,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
