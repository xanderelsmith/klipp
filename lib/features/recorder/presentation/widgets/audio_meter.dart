import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/styles/app_styles.dart';
import 'audio_source_dropdown.dart';

class AudioMeter extends StatefulWidget {
  final bool isRecording;
  const AudioMeter({super.key, required this.isRecording});

  @override
  State<AudioMeter> createState() => _AudioMeterState();
}

class _AudioMeterState extends State<AudioMeter> {
  final SharedAudioMonitor _monitor = SharedAudioMonitor();
  final Random _random = Random();
  final List<double> _barHeights = List.filled(5, 0.1);

  @override
  void initState() {
    super.initState();
    // Border meter always listens to Mic for feedback
    _monitor.startListening(null, false);
  }

  @override
  void dispose() {
    _monitor.stopListening(null, false);
    super.dispose();
  }

  void _updateBars(double amplitude) {
    // Convert decibels to a 0.0 - 1.0 range
    double normalized = ((amplitude + 50) / 50).clamp(0.1, 1.0);
    
    for (int i = 0; i < _barHeights.length; i++) {
      double jitter = (_random.nextDouble() * 0.2) - 0.1;
      _barHeights[i] = (normalized + jitter).clamp(0.1, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _monitor.getNotifier(false),
      builder: (context, amplitude, child) {
        _updateBars(amplitude);
        
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
                        color: widget.isRecording ? AppColors.accent : Colors.white70,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
