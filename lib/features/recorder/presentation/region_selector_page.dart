import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'dart:async';

import 'recorder_controller.dart';

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
  Offset? _startPos;
  Offset? _currentPos;
  bool _isConfirmed = false;
  bool _isLocked = false;

  Timer? _mouseTracker;
  final GlobalKey _toolbarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _startMouseTracking();
  }

  void _startMouseTracking() {
    _mouseTracker = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) async {
      if (!_isLocked || !mounted) return;

      final mousePos = await screenRetriever.getCursorScreenPoint();

      // Calculate toolbar bounds in screen coordinates
      // Since the window is fullscreen, local and screen coordinates match
      final toolbarTop = _selectedRect.top - 40;
      final toolbarBottom = _selectedRect.top;
      final toolbarLeft = _selectedRect.left - 3;
      final toolbarRight = _selectedRect.right + 3;

      bool isOverToolbar =
          mousePos.dx >= toolbarLeft &&
          mousePos.dx <= toolbarRight &&
          mousePos.dy >= toolbarTop &&
          mousePos.dy <= toolbarBottom;

      if (isOverToolbar) {
        await windowManager.setIgnoreMouseEvents(false);
      } else {
        await windowManager.setIgnoreMouseEvents(true);
      }
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

  Rect get _selectedRect {
    if (_startPos == null || _currentPos == null) return Rect.zero;
    return Rect.fromPoints(_startPos!, _currentPos!);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onCancel();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Background Dimming (only when not confirmed)
            if (!_isConfirmed)
              GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _startPos = details.localPosition;
                    _currentPos = details.localPosition;
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _currentPos = details.localPosition;
                  });
                },
                onPanEnd: (details) {
                  if (_startPos != null && _currentPos != null) {
                    final rect = Rect.fromPoints(_startPos!, _currentPos!);
                    if (rect.width < 10 || rect.height < 10) {
                      setState(() {
                        _startPos = null;
                        _currentPos = null;
                      });
                    }
                  }
                },
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: Stack(
                    children: [
                      if (_startPos != null && _currentPos != null)
                        CustomPaint(
                          size: Size.infinite,
                          painter: _HolePainter(rect: _selectedRect),
                        ),
                      if (_startPos == null)
                        const Center(
                          child: Text(
                            'Click and drag to select recording area\nPress ESC to cancel',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(blurRadius: 10, color: Colors.black),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // The Selection Frame
            if (_startPos != null && _currentPos != null)
              Positioned.fromRect(
                rect: _selectedRect,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.red,
                        width: _isConfirmed ? 3 : 2,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        color: Colors.red,
                        child: Text(
                          '${_selectedRect.width.toInt()} x ${_selectedRect.height.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Integrated Controls (Draggable & Interactive)
            if (_isConfirmed && _startPos != null && _currentPos != null)
              Positioned(
                key: _toolbarKey,
                top: _selectedRect.top - 40,
                left: _selectedRect.left - 3,
                width: _selectedRect.width + 6,
                child: Opacity(
                  opacity: _isLocked ? 0.9 : 1.0, // Solid enough to see clearly
                  child: GestureDetector(
                    onPanUpdate: _isLocked
                        ? null
                        : (details) {
                            setState(() {
                              _startPos = _startPos! + details.delta;
                              _currentPos = _currentPos! + details.delta;
                            });
                          },
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black87,
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                        border: _isLocked
                            ? Border.all(
                                color: Colors.amber,
                                width: 2,
                              ) // Stronger border when locked
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ListenableBuilder(
                        listenable: widget.controller,
                        builder: (context, _) {
                          return Row(
                            children: [
                              Icon(
                                Icons.drag_indicator,
                                color: _isLocked ? Colors.amber : Colors.grey,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              // Record/Stop Button - ALWAYS AVAILABLE
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  widget.controller.isRecording
                                      ? Icons.stop
                                      : Icons.fiber_manual_record,
                                  color: Colors.red,
                                  size: 24,
                                ),
                                onPressed: () {
                                  widget.controller.toggleRecording();
                                  // Auto-lock when starting, auto-unlock when stopping
                                  if (widget.controller.isRecording) {
                                    setState(() => _isLocked = true);
                                    widget.onIgnoreMouseEvents(true);
                                  } else {
                                    setState(() => _isLocked = false);
                                    widget.onIgnoreMouseEvents(false);
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              // Timer
                              Text(
                                widget.controller.formatDuration(
                                  widget.controller.recordDuration,
                                ),
                                style: TextStyle(
                                  color: widget.controller.isRecording
                                      ? Colors.red
                                      : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Consolas',
                                ),
                              ),
                              const Spacer(),
                              // Toggle Lock
                              IconButton(
                                icon: Icon(
                                  _isLocked ? Icons.lock : Icons.lock_open,
                                  color: _isLocked
                                      ? Colors.amber
                                      : Colors.white70,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isLocked = !_isLocked;
                                    widget.onIgnoreMouseEvents(_isLocked);
                                  });
                                },
                                tooltip: _isLocked
                                    ? 'Unlock for Editing'
                                    : 'Lock for Click-through',
                              ),
                              // Back to Dashboard
                              IconButton(
                                icon: const Icon(
                                  Icons.dashboard,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                onPressed: widget.onCancel,
                                tooltip: 'Back to Dashboard',
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

            // Helper Banner (Only visible when mouse is NOT over toolbar)
            if (_isLocked)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.8),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'HOVER OVER TOOLBAR TO INTERACT | CLICK BACKGROUND TO PASS-THROUGH',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Confirmation Button
            if (!_isConfirmed && _startPos != null && _currentPos != null)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _isConfirmed = true);
                      widget.onRegionSelected(_selectedRect);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm Area'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            // Close button (when not confirmed)
            if (!_isConfirmed)
              Positioned(
                top: 40,
                right: 40,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 40),
                  onPressed: widget.onCancel,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HolePainter extends CustomPainter {
  final Rect rect;

  _HolePainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.1);
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(fullRect),
        Path()..addRect(rect),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
