import 'package:flutter/material.dart';
import 'recorder_controller.dart';
import '../../gallery/presentation/gallery_page.dart';
import '../../gallery/presentation/gallery_controller.dart';

class RecorderPage extends StatelessWidget {
  final RecorderController controller;
  final GalleryController galleryController;
  final Function(String?) onOpenFolder;

  const RecorderPage({
    super.key,
    required this.controller,
    required this.galleryController,
    required this.onOpenFolder,
  });

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
              _buildOutputFolderSection(),
              if (controller.lastSavedFile != null) ...[
                const SizedBox(height: 20),
                _buildLastFileSection(),
              ],
              const SizedBox(height: 32),
              const Text(
                'Recent Recordings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GalleryPage(
                  controller: galleryController,
                  onOpenFolder: onOpenFolder,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOutputFolderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder, color: Colors.amber, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Output Folder',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.outputDir,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.folder_open, color: Colors.grey),
            onPressed: () => onOpenFolder(null),
            tooltip: 'Open in Explorer',
          ),
        ],
      ),
    );
  }

  Widget _buildLastFileSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          const Text(
            'Saved:',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              controller.lastSavedFile!.split('\\').last,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton.icon(
            onPressed: () => onOpenFolder(controller.lastSavedFile),
            icon: const Icon(Icons.play_arrow, color: Colors.green),
            label: const Text(
              'Play File',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}
