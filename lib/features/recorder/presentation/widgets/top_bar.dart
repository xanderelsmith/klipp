import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../core/styles/app_styles.dart';
import '../controllers/recorder_controller.dart';

class TopBar extends StatelessWidget {
  final int selectedIndex;
  final RecorderController recorderController;

  const TopBar({
    super.key,
    required this.selectedIndex,
    required this.recorderController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListenableBuilder(
        listenable: recorderController,
        builder: (context, _) {
          return Row(
            children: [
              Icon(Icons.monitor, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Text(
                _getTitle(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              if (selectedIndex == 0) ...[
                const SizedBox(width: 8),
                _buildModeSelector(),
              ],
              const Spacer(),
              if (selectedIndex == 0 &&
                  recorderController.recordingRegion != null) ...[
                Text(
                  '${recorderController.recordingRegion!.width.toInt()}x${recorderController.recordingRegion!.height.toInt()} - (${recorderController.recordingRegion!.left.toInt()}, ${recorderController.recordingRegion!.top.toInt()})',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontFamily: 'Consolas',
                  ),
                ),
                const SizedBox(width: 16),
              ],
              if (selectedIndex == 0) ...[
                _buildFormatSelector(),
                const SizedBox(width: 16),
                _buildRecordButton(context),
                const SizedBox(width: 16),
                _buildDurationDisplay(),
              ],
            ],
          );
        },
      ),
    );
  }

  String _getTitle() {
    switch (selectedIndex) {
      case 0:
        return 'Screen Recording Mode - ${recorderController.recordingMode}';
      case 1:
        return 'Video Format Converter';
      case 2:
        return 'Recorded Videos';
      case 3:
        return 'Settings';
      default:
        return 'Klipp';
    }
  }

  Widget _buildModeSelector() {
    return Container(
      height: 36,
      width: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF4A80D4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.aspect_ratio, color: Colors.white, size: 20),
        offset: const Offset(0, 40),
        tooltip: 'Select Recording Area',
        onSelected: (value) {
          if (value == 'fullscreen') {
            recorderController.recordingMode = 'Fullscreen';
            recorderController.recordingRegion = null;
          } else if (value.startsWith('size:')) {
            final parts = value.substring(5).split('x');
            final w = double.parse(parts[0]);
            final h = double.parse(parts[1]);
            recorderController.recordingMode = 'Rectangle';
            recorderController.recordingRegion = Rect.fromLTWH(0, 0, w, h);
          } else if (value == 'select_area') {
            recorderController.startRegionSelection();
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'select_area',
            child: ListTile(
              leading: Icon(Icons.crop_free),
              title: Text('Select a recording area'),
              dense: true,
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            enabled: false,
            child: Text(
              'Rectangle on a screen',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const PopupMenuItem(
            value: 'size:320x240',
            child: Text('320x240 (4:3)'),
          ),
          const PopupMenuItem(
            value: 'size:640x360',
            child: Text('640x360 (16:9)'),
          ),
          const PopupMenuItem(
            value: 'size:1280x720',
            child: Text('1280x720 (16:9)'),
          ),
          const PopupMenuItem(
            value: 'size:1920x1080',
            child: Text('1920x1080 (16:9)'),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'fullscreen',
            child: ListTile(
              leading: Icon(Icons.fullscreen),
              title: Text('Fullscreen'),
              dense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSelector() {
    final formats = ['mkv', 'mp4', 'avi', 'gif'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        value: recorderController.selectedFormat,
        underline: const SizedBox(),
        dropdownColor: AppColors.surface,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        items: formats
            .map(
              (f) => DropdownMenuItem(value: f, child: Text(f.toUpperCase())),
            )
            .toList(),
        onChanged: recorderController.isRecording
            ? null
            : (v) => recorderController.selectedFormat = v!,
      ),
    );
  }

  Widget _buildDurationDisplay() {
    return Text(
      recorderController.formatDuration(recorderController.recordDuration),
      style: TextStyle(
        color: recorderController.isRecording
            ? AppColors.primary
            : AppColors.textSecondary,
        fontWeight: FontWeight.bold,
        fontFamily: 'Consolas',
      ),
    );
  }

  Widget _buildRecordButton(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.background,
      ),
      child: IconButton(
        onPressed: () async {
          try {
            final wasRecording = recorderController.isRecording;
            await recorderController.toggleRecording();

            if (wasRecording && recorderController.lastSavedFile != null) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Recording saved: ${recorderController.lastSavedFile!.split('\\').last}',
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'VIEW',
                      textColor: Colors.white,
                      onPressed: () {
                        if (recorderController.lastSavedFile != null) {
                          Process.run('explorer.exe', [
                            '/select,',
                            recorderController.lastSavedFile!,
                          ]);
                        }
                      },
                    ),
                  ),
                );
              }
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Recording Error: $e'),
                  backgroundColor: AppColors.primary,
                ),
              );
            }
          }
        },
        icon: Icon(
          recorderController.isRecording
              ? Icons.stop
              : Icons.fiber_manual_record,
          color: AppColors.primary,
        ),
        tooltip: recorderController.isRecording
            ? 'Stop Recording'
            : 'Start Recording',
      ),
    );
  }
}
