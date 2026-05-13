import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'converter_controller.dart';

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
                ? Colors.red.withOpacity(0.05)
                : Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Input File',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildInputFileSection(context),
                  const SizedBox(height: 32),
                  const Text(
                    'Conversion Settings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              controller.inputFile ?? 'No file selected',
              style: TextStyle(
                color: controller.inputFile == null
                    ? Colors.grey.shade600
                    : Colors.white,
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
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text('Target Format:', style: TextStyle(color: Colors.grey)),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: controller.targetFormat,
            dropdownColor: const Color(0xFF2D2D2D),
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
          const Text('Compress (H.264):', style: TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          Switch(
            value: controller.compress,
            activeThumbColor: Colors.red,
            onChanged: controller.isConverting || controller.targetFormat == 'gif'
                ? null
                : (v) => controller.compress = v,
          ),
          const SizedBox(width: 48),
          const Text('Same Directory:', style: TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          Switch(
            value: controller.exportToSameDir,
            activeThumbColor: Colors.red,
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
                CircularProgressIndicator(color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'CONVERTING...',
                  style: TextStyle(
                    color: Colors.red,
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
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Conversion Error: $e'),
                              backgroundColor: Colors.red,
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
                backgroundColor: Colors.red,
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
