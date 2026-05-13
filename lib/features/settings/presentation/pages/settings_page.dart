import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/styles/app_styles.dart';
import '../controllers/settings_controller.dart';

class SettingsPage extends StatelessWidget {
  final SettingsController controller;

  const SettingsPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Padding(
          padding: AppStyles.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'System Requirements',
                style: AppStyles.h1,
              ),
              const SizedBox(height: 24),
              _buildFfmpegSection(context),
              const SizedBox(height: 32),
              const Text(
                'About Klipp',
                style: AppStyles.h2,
              ),
              const SizedBox(height: 12),
              const Text(
                'Klipp uses FFmpeg for high-performance screen recording and video conversion. '
                'Ensure FFmpeg is installed and added to your system PATH for all features to work correctly.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
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
        color: AppColors.sidebar,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: available ? AppColors.success.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                available ? Icons.check_circle : Icons.error,
                color: available ? AppColors.success : AppColors.primary,
                size: 28,
              ),
              const SizedBox(width: 16),
              const Text(
                'FFmpeg Dependency',
                style: AppStyles.h2,
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
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How to install FFmpeg:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Download from ffmpeg.org\n'
                    '2. Extract to a folder (e.g., C:\\ffmpeg)\n'
                    '3. Add the bin folder to your System PATH environment variable.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
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
              style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
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
