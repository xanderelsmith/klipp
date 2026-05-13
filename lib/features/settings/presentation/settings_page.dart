import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'settings_controller.dart';

class SettingsPage extends StatelessWidget {
  final SettingsController controller;

  const SettingsPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'System Requirements',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildFfmpegSection(context),
              const SizedBox(height: 32),
              const Text(
                'About Klipp',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Klipp uses FFmpeg for high-performance screen recording and video conversion. '
                'Ensure FFmpeg is installed and added to your system PATH for all features to work correctly.',
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFfmpegSection(BuildContext context) {
    final bool available = controller.isFfmpegAvailable;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: available ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                available ? Icons.check_circle : Icons.error,
                color: available ? Colors.green : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 16),
              const Text(
                'FFmpeg Dependency',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: controller.checkFfmpeg,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Re-check'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF333333),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Status', controller.ffmpegStatus),
          if (controller.ffmpegVersion != null)
            _buildInfoRow('Version', controller.ffmpegVersion!),
          if (!available) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How to install FFmpeg:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Download from ffmpeg.org\n'
                    '2. Extract to a folder (e.g., C:\\ffmpeg)\n'
                    '3. Add the bin folder to your System PATH environment variable.',
                    style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: 'https://ffmpeg.org/download.html'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy Download Link'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'Consolas', fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
