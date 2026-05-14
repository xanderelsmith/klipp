import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../../../core/styles/app_styles.dart';

class AudioSourceDropdown extends StatefulWidget {
  final IconData icon;
  final bool isEnabled;
  final double volume;
  final List<String> devices;
  final String? selectedDevice;
  final Color meterColor;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<String?> onDeviceSelected;

  const AudioSourceDropdown({
    super.key,
    required this.icon,
    required this.isEnabled,
    required this.volume,
    required this.devices,
    this.selectedDevice,
    this.meterColor = Colors.green,
    required this.onToggle,
    required this.onVolumeChanged,
    required this.onDeviceSelected,
  });

  @override
  State<AudioSourceDropdown> createState() => _AudioSourceDropdownState();
}

class _AudioSourceDropdownState extends State<AudioSourceDropdown> {
  final GlobalKey _iconKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  void _showDropdown() {
    if (_overlayEntry != null) return;

    final RenderBox renderBox =
        _iconKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    double currentVolume = widget.volume;

    _overlayEntry = OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setStateOverlay) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _hideDropdown,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              left: position.dx,
              top: position.dy + size.height + 4,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 250,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 4),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Volume Slider Row
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Icon(
                              widget.icon,
                              color: widget.isEnabled
                                  ? AppColors.textPrimary
                                  : Colors.white38,
                              size: 18,
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                  activeTrackColor: widget.isEnabled
                                      ? AppColors.textPrimary
                                      : Colors.white38,
                                  inactiveTrackColor: Colors.black26,
                                  thumbColor: widget.isEnabled
                                      ? Colors.white
                                      : Colors.white54,
                                ),
                                child: Slider(
                                  value: currentVolume,
                                  min: 0.0,
                                  max: 1.0,
                                  onChanged: widget.isEnabled
                                      ? (v) {
                                          setStateOverlay(() {
                                            currentVolume = v;
                                          });
                                          widget.onVolumeChanged(v);
                                        }
                                      : null,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 36,
                              child: Text(
                                '${(currentVolume * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Colors.white24),
                      // Devices List
                      if (widget.devices.isNotEmpty) ...[
                        ...widget.devices.map((device) {
                          final isSelected = device == widget.selectedDevice;
                          return InkWell(
                            onTap: () {
                              widget.onDeviceSelected(device);
                              widget.onToggle(true); // Auto-enable if disabled
                              _hideDropdown();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              color: isSelected && widget.isEnabled
                                  ? Colors.white10
                                  : Colors.transparent,
                              child: Row(
                                children: [
                                  if (isSelected && widget.isEnabled)
                                    const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  else
                                    const SizedBox(width: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      device,
                                      style: TextStyle(
                                        color: isSelected && widget.isEnabled
                                            ? Colors.white
                                            : Colors.white70,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const Divider(height: 1, color: Colors.white24),
                      ],
                      // Disable Option
                      InkWell(
                        onTap: () {
                          widget.onToggle(false);
                          _hideDropdown();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          color: !widget.isEnabled
                              ? Colors.white10
                              : Colors.transparent,
                          child: Row(
                            children: [
                              if (!widget.isEnabled)
                                const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              else
                                const SizedBox(width: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Disable',
                                style: TextStyle(
                                  color: !widget.isEnabled
                                      ? Colors.white
                                      : Colors.white70,
                                  fontSize: 12,
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
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: _iconKey,
      onTap: _showDropdown,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  color: widget.isEnabled
                      ? AppColors.textPrimary
                      : Colors.white38,
                  size: 20,
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: widget.isEnabled
                      ? AppColors.textSecondary
                      : Colors.white38,
                  size: 12,
                ),
              ],
            ),
            const SizedBox(width: 8),
            _MiniVerticalAudioMeter(
              isEnabled: widget.isEnabled,
              color: widget.meterColor,
              deviceId: widget.selectedDevice,
            ),
          ],
        ),
      ),
    );
  }
}

class SharedAudioMonitor {
  static final SharedAudioMonitor _instance = SharedAudioMonitor._internal();
  factory SharedAudioMonitor() => _instance;
  SharedAudioMonitor._internal();

  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  final ValueNotifier<double> amplitudeNotifier = ValueNotifier<double>(-60.0);
  int _listenerCount = 0;

  Future<void> startListening(String? deviceId, bool isSpeaker) async {
    _listenerCount++;
    if (_listenerCount == 1) {
      try {
        if (await _audioRecorder.hasPermission()) {
          final tempDir = await getTemporaryDirectory();
          final tempPath = '${tempDir.path}\\klipp_probe_shared.wav';

          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.pcm16bits),
            path: tempPath,
          );

          _amplitudeSubscription = _audioRecorder
              .onAmplitudeChanged(const Duration(milliseconds: 30))
              .listen((amp) {
                amplitudeNotifier.value = amp.current;
              });
        }
      } catch (e) {
        debugPrint('SharedAudioMonitor start error: $e');
      }
    }
  }

  Future<void> stopListening(String? deviceId, bool isSpeaker) async {
    _listenerCount--;
    if (_listenerCount <= 0) {
      _listenerCount = 0;
      await _amplitudeSubscription?.cancel();
      _amplitudeSubscription = null;
      try {
        if (await _audioRecorder.isRecording()) {
          await _audioRecorder.stop();
        }
      } catch (_) {}
      amplitudeNotifier.value = -60.0;
    }
  }

  ValueNotifier<double> getNotifier(bool isSpeaker) {
    return amplitudeNotifier;
  }
}

class _MiniVerticalAudioMeter extends StatefulWidget {
  final bool isEnabled;
  final Color color;
  final String? deviceId;
  const _MiniVerticalAudioMeter({
    required this.isEnabled,
    required this.color,
    this.deviceId,
  });

  @override
  State<_MiniVerticalAudioMeter> createState() =>
      _MiniVerticalAudioMeterState();
}

class _MiniVerticalAudioMeterState extends State<_MiniVerticalAudioMeter> {
  final SharedAudioMonitor _monitor = SharedAudioMonitor();
  final int _boxCount = 5;

  @override
  void initState() {
    super.initState();
    if (widget.isEnabled) {
      _monitor.startListening(widget.deviceId, widget.color == Colors.orange);
    }
  }

  @override
  void didUpdateWidget(_MiniVerticalAudioMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool isSpeaker = widget.color == Colors.orange;
    if (widget.isEnabled != oldWidget.isEnabled ||
        widget.deviceId != oldWidget.deviceId) {
      if (oldWidget.isEnabled) {
        _monitor.stopListening(oldWidget.deviceId, isSpeaker);
      }
      if (widget.isEnabled) {
        _monitor.startListening(widget.deviceId, isSpeaker);
      }
    }
  }

  @override
  void dispose() {
    if (widget.isEnabled) {
      _monitor.stopListening(widget.deviceId, widget.color == Colors.orange);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _monitor.getNotifier(widget.color == Colors.orange),
      builder: (context, currentAmplitude, child) {
        // Normalize amplitude from -50..0 to 0.0..1.0 for better sensitivity
        double normalized = ((currentAmplitude + 50) / 50).clamp(0.0, 1.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_boxCount, (index) {
            // Reverse index so bottom is 0
            final bottomIndex = _boxCount - 1 - index;

            // Thresholds for 5 boxes: 0.1, 0.3, 0.5, 0.7, 0.9
            final threshold = (bottomIndex * 0.2) + 0.1;
            final isActive = widget.isEnabled && normalized >= threshold;

            return Container(
              width: 6,
              height: 3,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: isActive ? widget.color : Colors.white10,
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        );
      },
    );
  }
}
