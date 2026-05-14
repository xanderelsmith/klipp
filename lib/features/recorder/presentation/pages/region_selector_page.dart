import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'dart:async';

import '../controllers/recorder_controller.dart';
import '../widgets/audio_meter.dart';
import '../widgets/audio_source_dropdown.dart';

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
  final Rect? initialRect;

  const RegionSelectorPage({
    super.key,
    required this.onRegionSelected,
    required this.onCancel,
    required this.controller,
    required this.onIgnoreMouseEvents,
    this.initialRect,
  });

  @override
  State<RegionSelectorPage> createState() => _RegionSelectorPageState();
}

class _RegionSelectorPageState extends State<RegionSelectorPage>
    with WindowListener {
  // ── Shared state ──────────────────────────────────────────────────────────
  late Rect _selectionRect;
  bool _isLocked = false;
  _ResizeMode _activeResizeMode = _ResizeMode.none;

  Timer? _mouseTracker;
  final double _handleSize = 10.0;
  final double _toolbarHeight = 44.0;
  final double _dragBarHeight = 30.0;

  // ── Draw-mode state (only when initialRect == null) ───────────────────────
  bool _isDrawMode = false;
  Offset? _drawStart;
  Offset? _drawCurrent;

  bool _isIgnoringMouseEvents = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);

    if (widget.initialRect == null) {
      // Free-draw mode: no initial rect, user draws it
      _isDrawMode = true;
      _selectionRect = Rect.zero; // placeholder; not rendered in draw mode
      // Do NOT start mouse tracking yet — we need full mouse capture for drawing
    } else {
      // Predefined size or previously-set region: go straight to adjust mode
      _selectionRect = widget.initialRect!;
      _startMouseTracking();
    }
  }

  @override
  void dispose() {
    _mouseTracker?.cancel();
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowFocus() {}

  // ── Mouse-passthrough tracking (adjust mode only) ─────────────────────────
  void _startMouseTracking() {
    _mouseTracker?.cancel();
    _mouseTracker = Timer.periodic(const Duration(milliseconds: 50), (
      timer,
    ) async {
      if (!mounted) return;

      final mousePos = await screenRetriever.getCursorScreenPoint();

      final outerRect = _selectionRect.inflate(_handleSize);
      final innerRect = _selectionRect.deflate(_handleSize);
      bool isOverBorder =
          outerRect.contains(mousePos) && !innerRect.contains(mousePos);

      bool isOverHandle = false;
      final handleRadius = _handleSize * 2;
      final handleCenters = [
        _selectionRect.topLeft,
        _selectionRect.topCenter,
        _selectionRect.topRight,
        _selectionRect.centerLeft,
        _selectionRect.centerRight,
        _selectionRect.bottomLeft,
        _selectionRect.bottomCenter,
        _selectionRect.bottomRight,
      ];
      for (final center in handleCenters) {
        if ((mousePos - center).distance <= handleRadius) {
          isOverHandle = true;
          break;
        }
      }

      final dragBarZone = Rect.fromLTWH(
        _selectionRect.left,
        _selectionRect.top - _dragBarHeight,
        _selectionRect.width,
        _dragBarHeight,
      );

      final toolbarZone = Rect.fromLTWH(
        _selectionRect.left,
        _selectionRect.bottom,
        _selectionRect.width,
        _toolbarHeight + 10,
      );

      bool isOverInteractionZone =
          isOverHandle ||
          isOverBorder ||
          dragBarZone.contains(mousePos) ||
          toolbarZone.contains(mousePos);

      if (_isLocked) {
        isOverInteractionZone = toolbarZone.contains(mousePos);
      }

      if (_activeResizeMode != _ResizeMode.none) {
        isOverInteractionZone = true;
      }

      if (isOverInteractionZone && _isIgnoringMouseEvents) {
        _isIgnoringMouseEvents = false;
        await windowManager.setIgnoreMouseEvents(false);
        await windowManager.focus();
      } else if (!isOverInteractionZone && !_isIgnoringMouseEvents) {
        _isIgnoringMouseEvents = true;
        await windowManager.setIgnoreMouseEvents(true);
      }
    });
  }

  // ── Draw-mode helpers ─────────────────────────────────────────────────────

  /// Converts two arbitrary offsets into a normalised Rect (left < right, top < bottom).
  Rect _normalise(Offset a, Offset b) => Rect.fromLTRB(
    a.dx < b.dx ? a.dx : b.dx,
    a.dy < b.dy ? a.dy : b.dy,
    a.dx > b.dx ? a.dx : b.dx,
    a.dy > b.dy ? a.dy : b.dy,
  );

  void _onDrawStart(DragStartDetails details) {
    setState(() {
      _drawStart = details.localPosition;
      _drawCurrent = details.localPosition;
    });
  }

  void _onDrawUpdate(DragUpdateDetails details) {
    setState(() => _drawCurrent = details.localPosition);
  }

  void _onDrawEnd(DragEndDetails _) {
    if (_drawStart == null || _drawCurrent == null) return;

    final drawn = _normalise(_drawStart!, _drawCurrent!);

    // Require a minimum 60×60 selection; otherwise reset and let user try again
    if (drawn.width < 60 || drawn.height < 60) {
      setState(() {
        _drawStart = null;
        _drawCurrent = null;
      });
      return;
    }

    // Transition to adjust mode
    setState(() {
      _isDrawMode = false;
      _selectionRect = drawn;
      _drawStart = null;
      _drawCurrent = null;
    });

    widget.onRegionSelected(_selectionRect);
    _startMouseTracking();
  }

  // ── Adjust-mode drag helpers ──────────────────────────────────────────────
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

      // Maintain minimum bounds
      if (_selectionRect.width < 100) {
        _selectionRect = Rect.fromLTWH(
          _selectionRect.left,
          _selectionRect.top,
          100,
          _selectionRect.height,
        );
      }
      if (_selectionRect.height < 100) {
        _selectionRect = Rect.fromLTWH(
          _selectionRect.left,
          _selectionRect.top,
          _selectionRect.width,
          100,
        );
      }

      widget.onRegionSelected(_selectionRect);
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
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
        body: _isDrawMode
            ? _buildDrawCanvas(context)
            : _buildAdjustFrame(context),
      ),
    );
  }

  // ── Draw-mode canvas ──────────────────────────────────────────────────────
  Widget _buildDrawCanvas(BuildContext context) {
    final size = MediaQuery.of(context).size;
    Rect? previewRect;
    if (_drawStart != null && _drawCurrent != null) {
      previewRect = _normalise(_drawStart!, _drawCurrent!);
    }

    return Stack(
      children: [
        // Full-screen gesture layer — must cover everything
        MouseRegion(
          cursor: SystemMouseCursors.precise,
          child: GestureDetector(
            onPanStart: _onDrawStart,
            onPanUpdate: _onDrawUpdate,
            onPanEnd: _onDrawEnd,
            child: CustomPaint(
              size: size,
              isComplex: true,
              willChange: true,
              painter: _DrawModePainter(previewRect: previewRect),
            ),
          ),
        ),

        // Cancel button (top-right)
        Positioned(
          top: 16,
          right: 16,
          child: Tooltip(
            message: 'Cancel (Esc)',
            child: InkWell(
              onTap: widget.onCancel,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),

        // Instruction hint
        if (previewRect == null)
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(child: _DrawHint()),
          ),

        // Size label while drawing
        if (previewRect != null &&
            previewRect.width >= 20 &&
            previewRect.height >= 20)
          Positioned(
            left: previewRect.left + 6,
            top: previewRect.top + 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${previewRect.width.toInt()} × ${previewRect.height.toInt()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'Consolas',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Existing adjust-mode frame ────────────────────────────────────────────
  Widget _buildAdjustFrame(BuildContext context) {
    return Stack(
      children: [
        // The Recording Frame (Hollow Center)
        Positioned.fromRect(
          rect: _selectionRect,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: 2),
            ),
            child: _isLocked ? null : _buildResizeHandles(),
          ),
        ),

        // Top Drag Handle Bar
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.drag_handle, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),

        // Main Toolbar
        Positioned(
          top: _selectionRect.bottom + 5,
          left: _selectionRect.left,
          width: _selectionRect.width,
          child: _buildToolbar(),
        ),

        // Floating Close Button
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
    );
  }

  Widget _buildResizeHandles() {
    return Stack(
      children: [
        _buildHandle(Alignment.topLeft, _ResizeMode.topLeft, Icons.north_west),
        _buildHandle(
          Alignment.topRight,
          _ResizeMode.topRight,
          Icons.north_east,
        ),
        _buildHandle(
          Alignment.bottomLeft,
          _ResizeMode.bottomLeft,
          Icons.south_west,
        ),
        _buildHandle(
          Alignment.bottomRight,
          _ResizeMode.bottomRight,
          Icons.south_east,
        ),
        _buildHandle(Alignment.topCenter, _ResizeMode.topCenter, Icons.north),
        _buildHandle(
          Alignment.bottomCenter,
          _ResizeMode.bottomCenter,
          Icons.south,
        ),
        _buildHandle(Alignment.centerLeft, _ResizeMode.centerLeft, Icons.west),
        _buildHandle(
          Alignment.centerRight,
          _ResizeMode.centerRight,
          Icons.east,
        ),
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
          width: _handleSize * 2.5,
          height: _handleSize * 2.5,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Icon(icon, size: 12, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Center(
      child: Container(
        height: _toolbarHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
          border: _isLocked ? Border.all(color: Colors.amber, width: 2) : null,
        ),
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Record/Stop Button
                IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    widget.controller.isRecording
                        ? Icons.stop
                        : Icons.fiber_manual_record,
                    color: Colors.red,
                    size: 24,
                  ),
                  onPressed: () async {
                    try {
                      final wasRecording = widget.controller.isRecording;
                      await widget.controller.toggleRecording();

                      if (wasRecording &&
                          widget.controller.lastSavedFile != null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Recording saved: ${widget.controller.lastSavedFile!.split('\\').last}',
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              action: SnackBarAction(
                                label: 'VIEW',
                                textColor: Colors.white,
                                onPressed: () {
                                  Process.run('explorer.exe', [
                                    '/select,',
                                    widget.controller.lastSavedFile!,
                                  ]);
                                },
                              ),
                            ),
                          );
                        }
                      }

                      setState(() => _isLocked = widget.controller.isRecording);
                      widget.onIgnoreMouseEvents(_isLocked);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),

                const SizedBox(width: 8),

                 const SizedBox(width: 8),
                
                // Pause Button
                IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    widget.controller.isPaused ? Icons.play_arrow : Icons.pause,
                    color: widget.controller.isRecording
                        ? (widget.controller.isPaused ? Colors.amber : Colors.white)
                        : Colors.white38,
                    size: 20,
                  ),
                  onPressed: widget.controller.isRecording
                      ? () => widget.controller.togglePause()
                      : null,
                ),

                const SizedBox(width: 8),

                // Audio Meter
                AudioMeter(isRecording: widget.controller.isRecording),

                const SizedBox(width: 12),

                // Duration Timer
                Text(
                  widget.controller.formatDuration(
                    widget.controller.recordDuration,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Consolas',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(width: 12),

                const VerticalDivider(
                  color: Colors.white24,
                  width: 1,
                  indent: 10,
                  endIndent: 10,
                ),

                // Lock Interaction Toggle
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

                // Exit to Dashboard
                IconButton(
                  icon: const Icon(
                    Icons.dashboard,
                    color: Colors.white70,
                    size: 18,
                  ),
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

// ── CustomPainter for draw-mode canvas ────────────────────────────────────────
class _DrawModePainter extends CustomPainter {
  final Rect? previewRect;

  const _DrawModePainter({this.previewRect});

  @override
  void paint(Canvas canvas, Size size) {
    // saveLayer is required so BlendMode.clear punches through to transparency
    canvas.saveLayer(Offset.zero & size, Paint());

    // Very subtle dark vignette to signal draw mode without blocking the screen
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0x33000000), // ~20% opacity
    );

    if (previewRect != null) {
      // Punch a transparent hole in the overlay for the selected area
      canvas.drawRect(
        previewRect!,
        Paint()
          ..blendMode = BlendMode.clear
          ..color = Colors.transparent,
      );

      // Selection border
      canvas.drawRect(
        previewRect!,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xFFFF4444)
          ..strokeWidth = 2.0,
      );

      // Corner ticks for visual clarity
      _drawCornerTicks(canvas, previewRect!);
    }

    canvas.restore();
  }

  void _drawCornerTicks(Canvas canvas, Rect r) {
    const tickLen = 14.0;
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Top-left
    canvas.drawLine(r.topLeft, r.topLeft + const Offset(tickLen, 0), p);
    canvas.drawLine(r.topLeft, r.topLeft + const Offset(0, tickLen), p);
    // Top-right
    canvas.drawLine(r.topRight, r.topRight + const Offset(-tickLen, 0), p);
    canvas.drawLine(r.topRight, r.topRight + const Offset(0, tickLen), p);
    // Bottom-left
    canvas.drawLine(r.bottomLeft, r.bottomLeft + const Offset(tickLen, 0), p);
    canvas.drawLine(r.bottomLeft, r.bottomLeft + const Offset(0, -tickLen), p);
    // Bottom-right
    canvas.drawLine(
      r.bottomRight,
      r.bottomRight + const Offset(-tickLen, 0),
      p,
    );
    canvas.drawLine(
      r.bottomRight,
      r.bottomRight + const Offset(0, -tickLen),
      p,
    );
  }

  @override
  bool shouldRepaint(_DrawModePainter old) => old.previewRect != previewRect;
}

// ── Static hint widget ─────────────────────────────────────────────────────────
class _DrawHint extends StatelessWidget {
  const _DrawHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.crop_free, color: Colors.white70, size: 18),
          SizedBox(width: 10),
          Text(
            'Click and drag to select a recording area  •  Esc to cancel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
