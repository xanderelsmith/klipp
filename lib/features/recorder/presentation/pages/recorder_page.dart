import 'package:flutter/material.dart';
import '../../../../core/styles/app_styles.dart';
import '../controllers/recorder_controller.dart';
import '../../../gallery/presentation/pages/gallery_page.dart';
import '../../../gallery/presentation/controllers/gallery_controller.dart';

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
          padding: AppStyles.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOutputFolderSection(),

              const SizedBox(height: 32),
              const Text('Recent Recordings', style: AppStyles.h2),
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
        color: AppColors.sidebar,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder, color: AppColors.warning, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Output Folder', style: AppStyles.caption),
                const SizedBox(height: 4),
                Text(
                  controller.outputDir,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.folder_open, color: AppColors.textSecondary),
            onPressed: () => onOpenFolder(null),
            tooltip: 'Open in Explorer',
          ),
        ],
      ),
    );
  }
}
