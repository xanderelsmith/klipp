import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class AudioSourceDropdown extends StatefulWidget {
  final IconData icon;
  final bool isEnabled;
  final double volume;
  final List<String> devices;
  final String? selectedDevice;
  final Color meterColor;
  final Function(bool, int index) onToggle;
  final Function(double) onVolumeChanged;
  final Function(String) onDeviceSelected;

  const AudioSourceDropdown({
    super.key,
    required this.icon,
    required this.isEnabled,
    required this.volume,
    required this.devices,
    this.selectedDevice,
    required this.meterColor,
    required this.onToggle,
    required this.onVolumeChanged,
    required this.onDeviceSelected,
  });

  @override
  State<AudioSourceDropdown> createState() => _AudioSourceDropdownState();
}

class _AudioSourceDropdownState extends State<AudioSourceDropdown> {
  OverlayEntry? _overlayEntry;
  final GlobalKey _iconKey = GlobalKey();

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      _showDropdown();
    } else {
      _hideDropdown();
    }
  }

  void _showDropdown() {
    final renderBox = _iconKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _hideDropdown,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.transparent,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
          ),
          Positioned(
            left: offset.dx,
            top: offset.dy + renderBox.size.height + 8,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 280,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Disable Option
                    InkWell(
                      onTap: () {
                        widget.onToggle(false, 0);
                        _hideDropdown();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: !widget.isEnabled 
                            ? Colors.redAccent.withValues(alpha: 0.15) 
                            : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: !widget.isEnabled ? [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ] : null,
                        ),
                        width: double.infinity,
                        child: Row(
                          children: [
                            if (!widget.isEnabled)
                              Container(
                                width: 3,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              )
                            else
                              const SizedBox(width: 3),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.block,
                              color: Colors.redAccent,
                              size: 14,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Disable',
                              style: TextStyle(
                                color: !widget.isEnabled ? Colors.white : Colors.white70,
                                fontSize: 13,
                                fontWeight: !widget.isEnabled ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                            if (!widget.isEnabled)
                              const Icon(Icons.check, color: Colors.redAccent, size: 14),
                          ],
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    if (widget.devices.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No devices found',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      )
                    else
                      ...widget.devices.asMap().entries.map((entry) {
                        final index = entry.key;
                        final device = entry.value;
                        return _buildDropdownItem(device, onSelect: () {
                          widget.onToggle(true, index + 1);
                          widget.onDeviceSelected(device);
                          _hideDropdown();
                        });
                      }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildDropdownItem(String device, {required VoidCallback onSelect}) {
    final isSelected = widget.isEnabled && widget.selectedDevice == device;
    return InkWell(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? widget.meterColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        width: double.infinity,
        child: Row(
          children: [
            if (isSelected)
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: widget.meterColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            else
              const SizedBox(width: 3),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                device,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: widget.meterColor, size: 14),
          ],
        ),
      ),
    );
  }

  void _hideDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(6),
          ),
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  key: _iconKey,
                  onTap: () => widget.onToggle(!widget.isEnabled, 0),
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Icon(
                      widget.icon,
                      color: widget.isEnabled ? widget.meterColor : Colors.white38,
                      size: 18,
                    ),
                  ),
                ),
                const VerticalDivider(width: 1, color: Colors.white10),
                InkWell(
                  onTap: _toggleDropdown,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: widget.isEnabled
                          ? widget.meterColor.withValues(alpha: 0.5)
                          : Colors.white24,
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _buildMeter(),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeter() {
    return _MiniVerticalAudioMeter(
      isEnabled: widget.isEnabled,
      color: widget.meterColor,
    );
  }
}

class _MiniVerticalAudioMeter extends StatefulWidget {
  final bool isEnabled;
  final Color color;

  const _MiniVerticalAudioMeter({
    required this.isEnabled,
    required this.color,
  });

  @override
  State<_MiniVerticalAudioMeter> createState() => _MiniVerticalAudioMeterState();
}

class _MiniVerticalAudioMeterState extends State<_MiniVerticalAudioMeter> {
  final int _boxCount = 10;
  double _simulatedLevel = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.isEnabled) {
      _startSimulatedLevel();
    }
  }

  @override
  void didUpdateWidget(_MiniVerticalAudioMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEnabled != oldWidget.isEnabled) {
      if (widget.isEnabled) {
        _startSimulatedLevel();
      } else {
        _stopSimulatedLevel();
      }
    }
  }

  void _startSimulatedLevel() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          // Subtle idle flicker
          _simulatedLevel = 0.1 + (math.Random().nextDouble() * 0.2);
        });
      }
    });
  }

  void _stopSimulatedLevel() {
    _timer?.cancel();
    _timer = null;
    if (mounted) {
      setState(() {
        _simulatedLevel = 0.0;
      });
    }
  }

  @override
  void dispose() {
    _stopSimulatedLevel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_boxCount, (index) {
        final bottomIndex = _boxCount - 1 - index;
        final threshold = bottomIndex / _boxCount;
        final isActive = widget.isEnabled && _simulatedLevel > threshold;

        return Container(
          width: 6,
          height: 2,
          margin: const EdgeInsets.symmetric(vertical: 0.5),
          decoration: BoxDecoration(
            color: isActive ? widget.color : Colors.white10,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}
