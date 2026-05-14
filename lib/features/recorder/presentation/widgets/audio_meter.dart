import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import '../../../../core/styles/app_styles.dart';

class AudioMeter extends StatefulWidget {
  final bool isRecording;
  const AudioMeter({super.key, required this.isRecording});

  @override
  State<AudioMeter> createState() => _AudioMeterState();
}

class _AudioMeterState extends State<AudioMeter> with SingleTickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  double _currentAmplitude = -60.0;
  final List<double> _barHeights = List.filled(5, 0.1);
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    if (widget.isRecording) {
      _startMonitoring();
    }
  }

  @override
  void didUpdateWidget(AudioMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _startMonitoring();
      } else {
        _stopMonitoring();
      }
    }
  }

  Future<void> _startMonitoring() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        // Start a dummy recording to stream amplitude
        // We don't actually save this file, we just need the levels
        final config = const RecordConfig();
        await _audioRecorder.start(config, path: ''); 
        
        _amplitudeSubscription = _audioRecorder.onAmplitudeChanged(
          const Duration(milliseconds: 50)
        ).listen((amp) {
          setState(() {
            _currentAmplitude = amp.current;
            _updateBars();
          });
        });
      }
    } catch (e) {
      debugPrint('Error starting audio monitoring: $e');
    }
  }

  void _updateBars() {
    // Convert decibels to a 0.0 - 1.0 range
    // Usually -60dB is silence, 0dB is max
    double normalized = ((_currentAmplitude + 60) / 60).clamp(0.1, 1.0);
    
    for (int i = 0; i < _barHeights.length; i++) {
      // Add some random "jitter" to make it look organic/oscillating
      double jitter = (_random.nextDouble() * 0.2) - 0.1;
      _barHeights[i] = (normalized + jitter).clamp(0.1, 1.0);
    }
  }

  Future<void> _stopMonitoring() async {
    await _amplitudeSubscription?.cancel();
    await _audioRecorder.stop();
    setState(() {
      _currentAmplitude = -60.0;
      for (int i = 0; i < _barHeights.length; i++) {
        _barHeights[i] = 0.1;
      }
    });
  }

  @override
  void dispose() {
    _amplitudeSubscription?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.isRecording ? Icons.mic : Icons.mic_none,
            color: widget.isRecording ? AppColors.accent : Colors.white38,
            size: 14,
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 12,
            child: Row(
              children: List.generate(_barHeights.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 50),
                  width: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  height: 12 * _barHeights[index],
                  decoration: BoxDecoration(
                    color: widget.isRecording ? AppColors.accent : Colors.white10,
                    borderRadius: BorderRadius.circular(1),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
