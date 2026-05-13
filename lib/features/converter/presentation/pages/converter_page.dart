import 'dart:io';

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
                  const Text('Input Source', style: AppStyles.h2),
                  const SizedBox(height: 16),
                  _buildInputFileSection(context),
                  const SizedBox(height: 32),
                  const Text('Output Configuration', style: AppStyles.h2),
                  const SizedBox(height: 16),
                  _buildSettingsSection(context),
                  const Spacer(),
                  if (controller.isConverting) _buildProcessingIndicator(),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sidebar.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.movie_outlined, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.inputFile ?? 'Drag and drop a video here or browse',
              style: TextStyle(
                color: controller.inputFile == null
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
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
            icon: const Icon(Icons.folder_open_outlined, size: 20),
            tooltip: 'Browse Files',
            style: IconButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              hoverColor: Colors.white10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    final formats = ['mkv', 'mp4', 'avi', 'gif'];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.sidebar,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          _buildMinimalDropdown('Format', controller.targetFormat, formats, (
            v,
          ) {
            controller.targetFormat = v!;
            if (v == 'gif') controller.compress = false;
          }),
          const SizedBox(width: 40),
          _buildMinimalToggle(
            'Reduce Size',
            controller.compress,
            (controller.isConverting || controller.targetFormat == 'gif')
                ? null
                : (v) => controller.compress = v,
          ),
          const SizedBox(width: 40),
          _buildMinimalToggle(
            'Save in same directory',
            controller.exportToSameDir,
            (v) => controller.exportToSameDir = v,
            infoText:
                'If unselected, files will be stored in your default klippvideos folder.',
          ),
          const Spacer(),
          _buildMinimalConvertTrigger(context),
        ],
      ),
    );
  }

  Widget _buildMinimalDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.caption),
        DropdownButton<String>(
          value: value,
          dropdownColor: AppColors.surface,
          underline: const SizedBox(),
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          items: items
              .map(
                (f) => DropdownMenuItem(
                  value: f,
                  child: Text(
                    f.toUpperCase(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              )
              .toList(),
          onChanged: controller.isConverting ? null : onChanged,
        ),
      ],
    );
  }

  Widget _buildMinimalToggle(
    String label,
    bool value,
    Function(bool)? onChanged, {
    String? infoText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppStyles.caption.copyWith(
                color: onChanged == null
                    ? Colors.white24
                    : AppColors.textSecondary,
              ),
            ),
            if (infoText != null) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: infoText,
                child: Icon(
                  Icons.info_outline,
                  size: 12,
                  color: onChanged == null ? Colors.white10 : Colors.white38,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _SquareToggle(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _buildMinimalConvertTrigger(BuildContext context) {
    return Column(
      children: [
        Text('Run', style: AppStyles.caption),
        const SizedBox(height: 4),
        IconButton(
          onPressed: controller.inputFile == null || controller.isConverting
              ? null
              : () async {
                  try {
                    await controller.convert();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Task completed successfully'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          width: 320,
                          action: SnackBarAction(
                            label: 'VIEW',
                            textColor: Colors.white,
                            onPressed: () {
                              if (controller.lastOutputFile != null) {
                                Process.run('explorer.exe', [
                                  '/select,',
                                  controller.lastOutputFile!,
                                ]);
                              }
                            },
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  }
                },
          icon: Icon(
            Icons.play_circle_filled_outlined,
            color: controller.inputFile == null
                ? Colors.white24
                : AppColors.primary,
            size: 32,
          ),
          tooltip: 'Start Conversion',
        ),
      ],
    );
  }

  Widget _buildProcessingIndicator() {
    return Center(
      child: Column(
        children: const [
          SizedBox(
            width: 150,
            child: LinearProgressIndicator(
              backgroundColor: Colors.white10,
              color: AppColors.primary,
              minHeight: 2,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'PROCESSING VIDEO...',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SquareToggle({required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onChanged != null;

    return GestureDetector(
      onTap: isEnabled ? () => onChanged?.call(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 20,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isEnabled
              ? (value ? AppColors.primary : Colors.white10)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.4,
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
