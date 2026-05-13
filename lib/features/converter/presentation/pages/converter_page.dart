import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/styles/app_styles.dart';
import '../controllers/converter_controller.dart';

class ConverterPage extends StatelessWidget {
  final ConverterController controller;

  const ConverterPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) {
        if (detail.files.isNotEmpty) {
          controller.inputFile = detail.files.first.path;
        }
      },
      onDragEntered: (detail) => controller.isDragging = true,
      onDragExited: (detail) => controller.isDragging = false,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return Container(
            color: controller.isDragging
                ? AppColors.primary.withValues(alpha: 0.05)
                : Colors.transparent,
            child: Padding(
              padding: AppStyles.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Input File',
                    style: AppStyles.h2,
                  ),
                  const SizedBox(height: 12),
                  _buildInputFileSection(context),
                  const SizedBox(height: 32),
                  const Text(
                    'Conversion Settings',
                    style: AppStyles.h2,
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsSection(),
                  const Spacer(),
                  _buildConvertButton(context),
                  const Spacer(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputFileSection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              controller.inputFile ?? 'No file selected',
              style: TextStyle(
                color: controller.inputFile == null
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: controller.isConverting
              ? null
              : () async {
                  FilePickerResult? result = await FilePicker.pickFiles(
                    type: FileType.video,
                  );
                  if (result != null) {
                    controller.inputFile = result.files.single.path;
                  }
                },
          icon: const Icon(Icons.file_upload, size: 18),
          label: const Text('Browse'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF333333),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    final formats = ['mkv', 'mp4', 'avi', 'gif'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sidebar,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text('Target Format:', style: AppStyles.caption),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: controller.targetFormat,
            dropdownColor: AppColors.surface,
            items: formats
                .map((f) => DropdownMenuItem(value: f, child: Text(f.toUpperCase())))
                .toList(),
            onChanged: controller.isConverting
                ? null
                : (v) {
                    controller.targetFormat = v!;
                    if (v == 'gif') controller.compress = false;
                  },
          ),
          const SizedBox(width: 48),
          const Text('Compress (H.264):', style: AppStyles.caption),
          const SizedBox(width: 8),
          Switch(
            value: controller.compress,
            activeThumbColor: AppColors.primary,
            onChanged: controller.isConverting || controller.targetFormat == 'gif'
                ? null
                : (v) => controller.compress = v,
          ),
          const SizedBox(width: 48),
          const Text('Same Directory:', style: AppStyles.caption),
          const SizedBox(width: 8),
          Switch(
            value: controller.exportToSameDir,
            activeThumbColor: AppColors.primary,
            onChanged: controller.isConverting ? null : (v) => controller.exportToSameDir = v,
          ),
        ],
      ),
    );
  }

  Widget _buildConvertButton(BuildContext context) {
    return Center(
      child: controller.isConverting
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text(
                  'CONVERTING...',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            )
          : ElevatedButton.icon(
              onPressed: controller.inputFile == null
                  ? null
                  : () async {
                      try {
                        await controller.convert();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Conversion completed successfully!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Conversion Error: $e'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      }
                    },
              icon: const Icon(Icons.transform, size: 24),
              label: const Text(
                'START CONVERSION',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF333333),
                disabledForegroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
    );
  }
}
