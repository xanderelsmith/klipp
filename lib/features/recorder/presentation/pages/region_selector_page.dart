import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'dart:async';

import '../controllers/recorder_controller.dart';

enum _ResizeMode {
  none,
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
  move,
}

class RegionSelectorPage extends StatefulWidget {
  final Function(Rect) onRegionSelected;
  final VoidCallback onCancel;
  final RecorderController controller;
  final Function(bool) onIgnoreMouseEvents;

  const RegionSelectorPage({
    super.key,
    required this.onRegionSelected,
    required this.onCancel,
    required this.controller,
    required this.onIgnoreMouseEvents,
  });

  @override
  State<RegionSelectorPage> createState() => _RegionSelectorPageState();
}

class _RegionSelectorPageState extends State<RegionSelectorPage>
    with WindowListener {
  late Rect _selectionRect;
  bool _isLocked = false;
  _ResizeMode _activeResizeMode = _ResizeMode.none;

  Timer? _mouseTracker;
  final double _handleSize = 10.0;
  final double _toolbarHeight = 40.0;
  final double _dragBarHeight = 30.0;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    
    // Default 800x600 centered rectangle
    _selectionRect = const Rect.fromLTWH(240, 60, 800, 600);
    
    _startMouseTracking();
  }

  void _startMouseTracking() {
    _mouseTracker = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!mounted) return;

      final mousePos = await screenRetriever.getCursorScreenPoint();
      
      // Calculate active zones
      // Zones are: Drag bar, Toolbar, Resize handles
      
      // Expand rect slightly for handles
      final expandedRect = _selectionRect.inflate(_handleSize);
      
      // Drag Bar Zone
      final dragBarZone = Rect.fromLTWH(
        _selectionRect.left,
        _selectionRect.top - _dragBarHeight,
        _selectionRect.width,
        _dragBarHeight,
      );

      // Toolbar Zone
      final toolbarZone = Rect.fromLTWH(
        _selectionRect.left,
        _selectionRect.bottom,
        _selectionRect.width,
        _toolbarHeight + 10,
      );

      bool isOverInteractionZone = expandedRect.contains(mousePos) ||
          dragBarZone.contains(mousePos) ||
          toolbarZone.contains(mousePos);

      // If locked, we only care about the toolbar
      if (_isLocked) {
        isOverInteractionZone = toolbarZone.contains(mousePos);
      }

      // If we are currently resizing/moving, don't ignore events
      if (_activeResizeMode != _ResizeMode.none) {
        isOverInteractionZone = true;
      }

      await windowManager.setIgnoreMouseEvents(!isOverInteractionZone);
    });
  }

  @override
  void dispose() {
    _mouseTracker?.cancel();
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowFocus() {
    if (_isLocked && mounted) {
      setState(() => _isLocked = false);
      widget.onIgnoreMouseEvents(false);
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isLocked) return;

    setState(() {
      switch (_activeResizeMode) {
        case _ResizeMode.move:
          _selectionRect = _selectionRect.shift(details.delta);
          break;
        case _ResizeMode.topLeft:
          _selectionRect = Rect.fromLTRB(
            _selectionRect.left + details.delta.dx,
            _selectionRect.top + details.delta.dy,
            _selectionRect.right,
            _selectionRect.bottom,
          );
          break;
        case _ResizeMode.topRight:
          _selectionRect = Rect.fromLTRB(
            _selectionRect.left,
            _selectionRect.top + details.delta.dy,
            _selectionRect.right + details.delta.dx,
            _selectionRect.bottom,
          );
          break;
        case _ResizeMode.bottomLeft:
          _selectionRect = Rect.fromLTRB(
            _selectionRect.left + details.delta.dx,
            _selectionRect.top,
            _selectionRect.right,
            _selectionRect.bottom + details.delta.dy,
          );
          break;
        case _ResizeMode.bottomRight:
          _selectionRect = Rect.fromLTRB(
            _selectionRect.left,
            _selectionRect.top,
            _selectionRect.right + details.delta.dx,
            _selectionRect.bottom + details.delta.dy,
          );
          break;
        case _ResizeMode.topCenter:
          _selectionRect = Rect.fromLTRB(
            _selectionRect.left,
            _selectionRect.top + details.delta.dy,
            _selectionRect.right,
            _selectionRect.bottom,
          );
          break;
        case _ResizeMode.bottomCenter:
          _selectionRect = Rect.fromLTRB(
            _selectionRect.left,
            _selectionRect.top,
            _selectionRect.right,
            _selectionRect.bottom + details.delta.dy,
          );
          break;
        case _ResizeMode.centerLeft:
          _selectionRect = Rect.fromLTRB(
            _selectionRect.left + details.delta.dx,
            _selectionRect.top,
            _selectionRect.right,
            _selectionRect.bottom,
          );
          break;
        case _ResizeMode.centerRight:
          _selectionRect = Rect.fromLTRB(
            _selectionRect.left,
            _selectionRect.top,
            _selectionRect.right + details.delta.dx,
            _selectionRect.bottom,
          );
          break;
        default:
          break;
      }

      // Ensure minimum size
      if (_selectionRect.width < 50) {
         _selectionRect = Rect.fromLTWH(_selectionRect.left, _selectionRect.top, 50, _selectionRect.height);
      }
      if (_selectionRect.height < 50) {
         _selectionRect = Rect.fromLTWH(_selectionRect.left, _selectionRect.top, _selectionRect.width, 50);
      }

      widget.onRegionSelected(_selectionRect);
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onCancel();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // The Recording Frame
            Positioned.fromRect(
              rect: _selectionRect,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: _isLocked ? null : _buildResizeHandles(),
              ),
            ),

            // Top Drag Bar
            if (!_isLocked)
              Positioned(
                top: _selectionRect.top - _dragBarHeight,
                left: _selectionRect.left,
                width: _selectionRect.width,
                child: GestureDetector(
                  onPanStart: (_) => _activeResizeMode = _ResizeMode.move,
                  onPanUpdate: _handleDragUpdate,
                  onPanEnd: (_) => _activeResizeMode = _ResizeMode.none,
                  child: Container(
                    height: _dragBarHeight,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.8),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                    child: const Center(
                      child: Icon(Icons.drag_handle, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),

            // Toolbar (Interactive Island)
            Positioned(
              top: _selectionRect.bottom + 5,
              left: _selectionRect.left,
              width: _selectionRect.width,
              child: _buildToolbar(),
            ),

            // Close Button (Floating)
            if (!_isLocked)
               Positioned(
                top: _selectionRect.top - 40,
                right: MediaQuery.of(context).size.width - _selectionRect.right,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 24),
                  onPressed: widget.onCancel,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResizeHandles() {
    return Stack(
      children: [
        // Corners
        _buildHandle(Alignment.topLeft, _ResizeMode.topLeft, Icons.north_west),
        _buildHandle(Alignment.topRight, _ResizeMode.topRight, Icons.north_east),
        _buildHandle(Alignment.bottomLeft, _ResizeMode.bottomLeft, Icons.south_west),
        _buildHandle(Alignment.bottomRight, _ResizeMode.bottomRight, Icons.south_east),
        
        // Midpoints
        _buildHandle(Alignment.topCenter, _ResizeMode.topCenter, Icons.north),
        _buildHandle(Alignment.bottomCenter, _ResizeMode.bottomCenter, Icons.south),
        _buildHandle(Alignment.centerLeft, _ResizeMode.centerLeft, Icons.west),
        _buildHandle(Alignment.centerRight, _ResizeMode.centerRight, Icons.east),
      ],
    );
  }

  Widget _buildHandle(Alignment alignment, _ResizeMode mode, IconData icon) {
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onPanStart: (_) => _activeResizeMode = mode,
        onPanUpdate: _handleDragUpdate,
        onPanEnd: (_) => _activeResizeMode = _ResizeMode.none,
        child: Container(
          width: _handleSize * 2,
          height: _handleSize * 2,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 10, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Center(
      child: Container(
        height: _toolbarHeight,
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 10, spreadRadius: 1),
          ],
          border: _isLocked ? Border.all(color: Colors.amber, width: 2) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    widget.controller.isRecording ? Icons.stop : Icons.fiber_manual_record,
                    color: Colors.red,
                    size: 24,
                  ),
                  onPressed: () async {
                    try {
                      final wasRecording = widget.controller.isRecording;
                      await widget.controller.toggleRecording();
                      
                      if (wasRecording && widget.controller.lastSavedFile != null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Recording saved: ${widget.controller.lastSavedFile!.split('\\').last}'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                      
                      if (widget.controller.isRecording) {
                        setState(() => _isLocked = true);
                        widget.onIgnoreMouseEvents(true);
                      } else {
                        setState(() => _isLocked = false);
                        widget.onIgnoreMouseEvents(false);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(width: 12),
                Text(
                  widget.controller.formatDuration(widget.controller.recordDuration),
                  style: TextStyle(
                    color: widget.controller.isRecording ? Colors.red : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Consolas',
                  ),
                ),
                const SizedBox(width: 12),
                VerticalDivider(color: Colors.grey.shade700, indent: 10, endIndent: 10),
                IconButton(
                  icon: Icon(
                    _isLocked ? Icons.lock : Icons.lock_open,
                    color: _isLocked ? Colors.amber : Colors.white70,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      _isLocked = !_isLocked;
                      widget.onIgnoreMouseEvents(_isLocked);
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.dashboard, color: Colors.white70, size: 18),
                  onPressed: widget.onCancel,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
