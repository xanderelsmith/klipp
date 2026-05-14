class AppInfo {
  static const String version = '1.0.0';
  static const String developer = 'Xander';

  static const List<Map<String, String>> usageRules = [
    {
      'title': 'Ghost Frame Interaction',
      'description': 'When recording, the center area becomes transparent to clicks. Hover over the border or toolbar to regain control.'
    },
    {
      'title': 'High DPI Recording',
      'description': 'Klipp automatically adjusts for Windows Display Scaling (125%, 150%, etc.) to ensure pixel-perfect capture.'
    },
    {
      'title': 'Video Formats',
      'description': 'MKV is recommended for safety (prevents corruption if the app crashes). Use the built-in converter to switch to MP4.'
    },
    {
      'title': 'Keyboard Shortcuts',
      'description': 'Press [ESC] to cancel region selection. [F2] in the gallery to rename a file.'
    },
    {
      'title': 'File Management',
      'description': 'Recordings are stored in your Documents/klippvideos folder by default. You can open this folder directly from the gallery.'
    },
  ];

  static const List<String> technicalSpecs = [
    'FFmpeg-based recording pipeline',
    'Real-time mouse tracking (50ms polling)',
    'Lossless region resizing',
    'Windows native window management',
  ];
}
