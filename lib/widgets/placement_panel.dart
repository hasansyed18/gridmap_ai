import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/cell_type.dart';
import '../state/app_state.dart';

class PlacementPanel extends StatelessWidget {
  const PlacementPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Drawer(
      width: 320,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brand.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tune,
                        color: AppColors.brand, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Placement',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 28),

              _sectionLabel('Mode'),
              const SizedBox(height: 10),
              Row(
                children: [
                  _modeChip(state, PlacementMode.quick, 'Quick',
                      'Set size, tap to place'),
                  const SizedBox(width: 8),
                  _modeChip(state, PlacementMode.custom, 'Custom',
                      'Drag to select area'),
                ],
              ),

              if (state.placementMode == PlacementMode.quick) ...[
                const SizedBox(height: 28),
                _sectionLabel('Block size'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _sizeBox(
                      state.quickWidth,
                      (v) => state.setQuickSize(v, state.quickHeight),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('×', style: TextStyle(fontSize: 20)),
                    ),
                    _sizeBox(
                      state.quickHeight,
                      (v) => state.setQuickSize(state.quickWidth, v),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.brand.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${state.quickWidth * state.quickHeight} cells',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Presets
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    [2, 2],
                    [3, 3],
                    [4, 4],
                    [5, 5],
                    [2, 4],
                    [4, 2],
                    [1, 1],
                  ].map((p) {
                    final sel = state.quickWidth == p[0] &&
                        state.quickHeight == p[1];
                    return GestureDetector(
                      onTap: () => state.setQuickSize(p[0], p[1]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.brand
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${p[0]}×${p[1]}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                sel ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                _sectionLabel('What to place'),
                const SizedBox(height: 10),
                _typeGrid(state, quick: true),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.brand.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.touch_app,
                          size: 18, color: AppColors.brand),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tap anywhere on the canvas to place a ${state.quickWidth}×${state.quickHeight} ${state.quickType.label.toLowerCase()}',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.brand),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 28),
                _sectionLabel('What to place'),
                const SizedBox(height: 10),
                _typeGrid(state, quick: false),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.brand.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.crop_free,
                          size: 18, color: AppColors.brand),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Drag on the canvas to select an area, then confirm',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.brand),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),
              _sectionLabel('Canvas'),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear floor?'),
                        content: const Text(
                            'This removes all rooms, landmarks and cells on this floor.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () {
                              state.clearFloor();
                              Navigator.pop(ctx);
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Clear floor'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String t) => Text(
        t.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: Colors.black45,
        ),
      );

  Widget _modeChip(AppState state, PlacementMode mode, String title,
      String subtitle) {
    final sel = state.placementMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => state.setPlacementMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: sel ? AppColors.brand : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: sel ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: sel
                      ? Colors.white.withOpacity(0.8)
                      : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sizeBox(int value, void Function(int) onChange) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onChange(value - 1),
            child: Container(
              width: 36,
              height: 40,
              alignment: Alignment.center,
              child: const Icon(Icons.remove, size: 16),
            ),
          ),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.brand,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onChange(value + 1),
            child: Container(
              width: 36,
              height: 40,
              alignment: Alignment.center,
              child: const Icon(Icons.add, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeGrid(AppState state, {required bool quick}) {
    final types = [
      CellType.room,
      CellType.corridor,
      CellType.blocked,
      CellType.walkable,
      CellType.stairs,
      CellType.lift,
      CellType.ramp,
      CellType.entrance,
      CellType.exit,
      CellType.landmark,
      CellType.washroom,
      CellType.empty,
    ];
    final activeType = quick ? state.quickType : state.activeTool;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((t) {
        final sel = activeType == t;
        return GestureDetector(
          onTap: () => quick ? state.setQuickType(t) : state.setActiveTool(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: sel
                  ? t.color.withOpacity(0.2)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: sel ? t.color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: t.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  t == CellType.empty ? 'Erase' : t.label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight:
                        sel ? FontWeight.w700 : FontWeight.w500,
                    color: sel ? AppColors.brand : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}