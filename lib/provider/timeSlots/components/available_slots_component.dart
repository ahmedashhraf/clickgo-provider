import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/provider/timeSlots/components/slot_widget.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:nb_utils/nb_utils.dart';

class AvailableSlotsComponent extends StatefulWidget {
  final List<String>? selectedSlots;
  final List<String> availableSlots;
  final Function(List<String> selectedSlots) onChanged;
  final bool? isProvider;

  AvailableSlotsComponent({
    this.selectedSlots,
    required this.availableSlots,
    required this.onChanged,
    this.isProvider = true,
    Key? key,
  }) : super(key: key);

  @override
  _AvailableSlotsComponentState createState() => _AvailableSlotsComponentState();
}

class _AvailableSlotsComponentState extends State<AvailableSlotsComponent> {
  List<String> localSelectedSlot = [];
  int selectedIndex = -1;

  // Drag state
  bool _isDragging = false;
  bool _dragSelecting = true; // true = selecting, false = deselecting
  String? _lastDraggedValue; // to avoid re-toggling same slot

  // One GlobalKey per slot so we can hit-test during drag
  final List<GlobalKey> _slotKeys = [];

  @override
  void initState() {
    super.initState();
    afterBuildCreated(() => init());
  }

  void init() async {
    if (widget.selectedSlots.validate().isNotEmpty) {
      localSelectedSlot = widget.selectedSlots.validate();
      widget.onChanged.call(localSelectedSlot);
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  // ─── Provider mode helpers ────────────────────────────────────────────────

  /// Called when a drag gesture updates in provider mode.
  void _handleProviderDragUpdate(Offset globalPosition) {
    for (int i = 0; i < _slotKeys.length; i++) {
      final key = _slotKeys[i];
      final ctx = key.currentContext;
      if (ctx == null) continue;

      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;

      final localPos = box.globalToLocal(globalPosition);
      if (!box.paintBounds.contains(localPos)) continue;

      final value = "${((i + 1).toString().length >= 2 ? i + 1 : '0${i + 1}')}:00:00";
      if (_lastDraggedValue == value) return; // already handled this slot
      _lastDraggedValue = value;

      setState(() {
        if (_dragSelecting) {
          if (!localSelectedSlot.contains(value)) localSelectedSlot.add(value);
        } else {
          localSelectedSlot.remove(value);
        }
      });
      widget.onChanged.call(localSelectedSlot);
      return;
    }
  }

  // ─── User mode helpers ────────────────────────────────────────────────────

  /// Called when a drag gesture updates in user (single-select) mode.
  void _handleUserDragUpdate(Offset globalPosition) {
    for (int i = 0; i < _slotKeys.length; i++) {
      final key = _slotKeys[i];
      final ctx = key.currentContext;
      if (ctx == null) continue;

      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;

      final localPos = box.globalToLocal(globalPosition);
      if (!box.paintBounds.contains(localPos)) continue;

      final value = widget.availableSlots[i];
      if (_lastDraggedValue == value) return;
      _lastDraggedValue = value;

      final isAvailable = widget.availableSlots.contains(value);
      if (!isAvailable) return;

      setState(() {
        if (_dragSelecting) {
          // Select the slot under finger
          selectedIndex = i;
          widget.onChanged.call([value]);
        } else {
          // Deselect: if the finger re-enters the originally-selected slot, clear it
          if (selectedIndex == i) {
            selectedIndex = -1;
            widget.onChanged.call([]);
          }
        }
      });
      return;
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return widget.isProvider.validate() ? _buildProviderSlots() : _buildUserSlots();
  }

  Widget _buildProviderSlots() {
    // Rebuild keys list to match slot count (24 slots)
    while (_slotKeys.length < 24) _slotKeys.add(GlobalKey());

    return GestureDetector(
      // Drag starts: record whether we're in select or deselect mode
      onPanStart: (details) {
        _isDragging = true;
        _lastDraggedValue = null;

        // Determine drag intent from the first touched slot
        for (int i = 0; i < _slotKeys.length; i++) {
          final ctx = _slotKeys[i].currentContext;
          if (ctx == null) continue;
          final box = ctx.findRenderObject() as RenderBox?;
          if (box == null) continue;
          final localPos = box.globalToLocal(details.globalPosition);
          if (box.paintBounds.contains(localPos)) {
            final value = "${((i + 1).toString().length >= 2 ? i + 1 : '0${i + 1}')}:00:00";
            _dragSelecting = !localSelectedSlot.contains(value);
            break;
          }
        }
      },
      onPanUpdate: (details) {
        if (_isDragging) _handleProviderDragUpdate(details.globalPosition);
      },
      onPanEnd: (_) {
        _isDragging = false;
        _lastDraggedValue = null;
      },
      onPanCancel: () {
        _isDragging = false;
        _lastDraggedValue = null;
      },
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: List.generate(24, (index) {
          final value = "${((index + 1).toString().length >= 2 ? index + 1 : '0${index + 1}')}:00:00";
          final isSelected = localSelectedSlot.contains(value);

          return SlotWidget(
            key: _slotKeys[index],
            isAvailable: false,
            isSelected: isSelected,
            activeColor: primaryColor,
            value: value,
            onTap: () {
              if (isSelected) {
                localSelectedSlot.remove(value);
              } else {
                localSelectedSlot.add(value);
              }
              setState(() {});
              widget.onChanged.call(localSelectedSlot);
            },
          );
        }),
      ),
    );
  }

  Widget _buildUserSlots() {
    final slotCount = widget.availableSlots.length;
    while (_slotKeys.length < slotCount) _slotKeys.add(GlobalKey());

    return GestureDetector(
      onPanStart: (details) {
        _isDragging = true;
        _lastDraggedValue = null;

        // Determine drag intent from the first touched slot
        for (int i = 0; i < _slotKeys.length; i++) {
          final ctx = _slotKeys[i].currentContext;
          if (ctx == null) continue;
          final box = ctx.findRenderObject() as RenderBox?;
          if (box == null) continue;
          final localPos = box.globalToLocal(details.globalPosition);
          if (box.paintBounds.contains(localPos)) {
            // If drag starts on the currently selected slot → deselect mode
            _dragSelecting = selectedIndex != i;
            break;
          }
        }
      },
      onPanUpdate: (details) {
        if (_isDragging) _handleUserDragUpdate(details.globalPosition);
      },
      onPanEnd: (_) {
        _isDragging = false;
        _lastDraggedValue = null;
      },
      onPanCancel: () {
        _isDragging = false;
        _lastDraggedValue = null;
      },
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: List.generate(slotCount, (index) {
          final value = widget.availableSlots[index];

          // Sync selectedIndex from parent prop on first build
          if (widget.selectedSlots.validate().isNotEmpty) {
            if (widget.selectedSlots.validate().first == value) {
              selectedIndex = index;
            }
          }

          final isSelected = selectedIndex == index;
          final isAvailable = widget.availableSlots.contains(value);

          return SlotWidget(
            key: _slotKeys[index],
            isAvailable: isAvailable,
            isSelected: isSelected,
            value: value,
            onTap: () {
              if (isAvailable) {
                if (isSelected) {
                  selectedIndex = -1;
                  widget.onChanged.call([]);
                } else {
                  selectedIndex = index;
                  widget.onChanged.call([value]);
                }
                setState(() {});
              } else {
                toast(languages.thisSlotIsNotAvailable);
              }
            },
          );
        }),
      ),
    );
  }
}