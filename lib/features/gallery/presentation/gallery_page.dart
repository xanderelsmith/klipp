import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'gallery_controller.dart';

class GalleryPage extends StatelessWidget {
  final GalleryController controller;
  final Function(String?) onOpenFolder;

  const GalleryPage({
    super.key,
    required this.controller,
    required this.onOpenFolder,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.files.isEmpty) {
          return const Center(
            child: Text(
              'No videos found in your klippvideos folder.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.files.length,
          itemBuilder: (context, index) {
            final file = controller.files[index];
            final stat = file.statSync();
            final fileName = p.basename(file.path);
            final sizeMb = (stat.size / (1024 * 1024)).toStringAsFixed(2);

            return _VideoTile(
              file: file,
              fileName: fileName,
              stat: stat,
              sizeMb: sizeMb,
              onRename: (newName) => controller.renameFile(file, newName),
              onDelete: () => controller.deleteFile(file),
              onOpenFolder: () => onOpenFolder(file.path),
            );
          },
        );
      },
    );
  }
}

class _VideoTile extends StatelessWidget {
  final FileSystemEntity file;
  final String fileName;
  final FileStat stat;
  final String sizeMb;
  final Function(String) onRename;
  final VoidCallback onDelete;
  final VoidCallback onOpenFolder;

  const _VideoTile({
    required this.file,
    required this.fileName,
    required this.stat,
    required this.sizeMb,
    required this.onRename,
    required this.onDelete,
    required this.onOpenFolder,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.f2) {
          _showRenameDialog(context);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Card(
        color: const Color(0xFF252525),
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.movie, color: Colors.redAccent, size: 36),
          title: Text(
            fileName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${stat.modified.toString().split('.')[0]} • $sizeMb MB',
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            tooltip: 'Menu',
            onSelected: (value) async {
              if (value == 'rename') {
                _showRenameDialog(context);
              } else if (value == 'delete') {
                onDelete();
              } else if (value == 'open') {
                onOpenFolder();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'open',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.folder_open, size: 20),
                  title: Text('Show in folder'),
                ),
              ),
              const PopupMenuItem(
                value: 'rename',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.edit, size: 20),
                  title: Text('Rename (F2)'),
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.delete, color: Colors.red, size: 20),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
          onTap: () {
            Process.run('explorer.exe', [file.path]);
          },
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) async {
    final fileNameWithoutExt = p.basenameWithoutExtension(file.path);
    final controller = TextEditingController(text: fileNameWithoutExt);

    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename File'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'New Name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (val) => Navigator.of(context).pop(val),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != fileNameWithoutExt) {
      onRename(newName);
    }
  }
}
