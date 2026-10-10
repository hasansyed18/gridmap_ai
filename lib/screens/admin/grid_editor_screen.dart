import '../../services/auth_service.dart';
import '../../services/map_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/colors.dart';
import '../../models/cell_type.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/grid_canvas.dart';
import '../../widgets/placement_panel.dart';

class GridEditorScreen extends StatefulWidget {
  const GridEditorScreen({super.key});
  @override
  State<GridEditorScreen> createState() => _GridEditorScreenState();
}

class _GridEditorScreenState extends State<GridEditorScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _panMode = false;
  bool _saving = false;

  Future<void> _saveAndPublish(AppState state) async {
    if (_saving) return;
    final org = state.organization;
    if (org == null || org.buildings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No organization or building to save')),
      );
      return;
    }

    setState(() => _saving = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final orgId = await context.read<AuthService>().ensureOrgId(
            name: org.name,
            description: org.description,
          );
      await MapService.saveAndPublish(orgId: orgId, organization: org);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Published! Visitors can now find this map.')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final floor = state.currentFloor;
    if (floor == null) {
      return const Scaffold(body: Center(child: Text('No map')));
    }

    final isQuick = state.placementMode == PlacementMode.quick;
    final ghostType = isQuick ? state.quickType : null;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const PlacementPanel(),
      appBar: AppBar(
        title: Text('${state.currentBuilding?.name ?? ""} · ${floor.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers_outlined),
            tooltip: 'Add Floor',
            onPressed: () => state.addFloor(),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined),
            tooltip: 'Save & Publish',
            onPressed: () => _saveAndPublish(state),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _statsBar(state, floor),
              if (state.isPickingEntrance) _entranceBanner(state),
              Expanded(
                child: GridCanvas(
                  floor: floor,
                  panMode: _panMode,
                  pickingEntrance: state.isPickingEntrance,
                  pendingRoomId: state.pendingEntranceRoomId,
                  ghostType: ghostType,
                  ghostW: state.quickWidth,
                  ghostH: state.quickHeight,
                  onSelectionComplete: _handleSelection,
                  onTapPlace: _handleTapPlace,
                  onEntrancePick: _handleEntrancePick,
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(child: _drawerTab()),
          ),
        ],
      ),
    );
  }

  Widget _drawerTab() {
    return Material(
      color: AppColors.brand,
      elevation: 6,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      ),
      child: InkWell(
        onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        child: Container(
          width: 44,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tune, color: Colors.white, size: 22),
              const SizedBox(height: 8),
              RotatedBox(
                quarterTurns: 3,
                child: Text(
                  'TOOLS',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsBar(AppState state, Floor floor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.teal.shade50,
      child: Row(
        children: [
          _stat('${floor.rooms.length}', 'Rooms'),
          _dot(),
          _stat('${floor.cells.length}', 'Cells'),
          const Spacer(),
          _modeToggle(),
        ],
      ),
    );
  }

  Widget _entranceBanner(AppState state) {
    final room = state.roomById(state.pendingEntranceRoomId!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFFFFB703),
      child: Row(
        children: [
          const Icon(Icons.login, color: Colors.black87, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Where is the entrance for "${room?.name ?? "Room"}"?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Tap a glowing cell around the room',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => state.cancelEntrancePick(),
            child:
                const Text('Skip', style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _modeToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeBtn(Icons.pan_tool_outlined, 'Pan', _panMode,
              () => setState(() => _panMode = true)),
          _modeBtn(Icons.crop_free, 'Draw', !_panMode,
              () => setState(() => _panMode = false)),
        ],
      ),
    );
  }

  Widget _modeBtn(
      IconData icon, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 14, color: active ? Colors.white : Colors.black54),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : Colors.black54,
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTapPlace(CellPos topLeft) async {
    final state = context.read<AppState>();
    if (state.placementMode != PlacementMode.quick) return;

    if (state.quickType == CellType.room) {
      final roomId = state.placeQuickBlock(topLeft);
      if (roomId == null) return;
      final name = await _promptRoomName();
      if (!mounted) return;
      if (name != null && name.trim().isNotEmpty) {
        state.renameRoom(roomId, name.trim());
      }
      state.startEntrancePick(roomId);
    } else {
      state.placeQuickBlock(topLeft);
    }
  }

  Future<void> _handleEntrancePick(CellPos cell) async {
    final state = context.read<AppState>();
    final ok = state.applyEntranceAndWalls(cell);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Entrance must be on a glowing cell next to the room')),
      );
    }
  }

  Future<void> _handleSelection(CellPos start, CellPos end) async {
    final state = context.read<AppState>();
    final floor = state.currentFloor!;

    if (state.placementMode != PlacementMode.custom) return;

    final minX = start.x < end.x ? start.x : end.x;
    final maxX = start.x > end.x ? start.x : end.x;
    final minY = start.y < end.y ? start.y : end.y;
    final maxY = start.y > end.y ? start.y : end.y;

    final cells = <CellPos>[];
    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        cells.add(CellPos(x, y));
      }
    }

    final result = await showModalBottomSheet<_MarkResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _MarkAreaSheet(
        cellCount: cells.length,
        floor: floor,
        cells: cells,
        initialType: state.activeTool,
      ),
    );

    if (result == null || !mounted) return;

    if (result.type == CellType.empty) {
      state.placeCustomBlock(cells, CellType.empty);
      return;
    }

    if (result.mergeIntoRoomId != null) {
      state.placeCustomBlock(cells, CellType.room);
      final existing = state.roomById(result.mergeIntoRoomId!);
      if (existing != null) {
        final f = state.currentFloor!;
        final idx = f.rooms.indexWhere((r) => r.id == existing.id);
        if (idx != -1) {
          final existingKeys = existing.cells.map((c) => c.key).toSet();
          final merged = List<CellPos>.from(existing.cells);
          for (final c in cells) {
            if (!existingKeys.contains(c.key)) {
              merged.add(c);
              existingKeys.add(c.key);
            }
          }
          f.rooms[idx] = Room(
            id: existing.id,
            name: existing.name,
            cells: merged,
          );
          for (final c in merged) {
            f.setCell(c.x, c.y, CellType.room);
          }
          state.startEntrancePick(existing.id);
        }
      }
      return;
    }

    if (result.type == CellType.room) {
      final name = result.name?.trim();
      state.placeCustomBlock(cells, CellType.room,
          name: (name == null || name.isEmpty)
              ? 'Room ${floor.rooms.length + 1}'
              : name);
      final newRoom = state.currentFloor!.rooms.last;
      state.startEntrancePick(newRoom.id);
      return;
    }

    state.placeCustomBlock(cells, result.type);
  }

  Future<String?> _promptRoomName() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Name this room'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. CSE Department'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _stat(String v, String l) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            Text(v,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand)),
            const SizedBox(width: 4),
            Text(l,
                style:
                    GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
          ],
        ),
      );

  Widget _dot() => Container(
        width: 3,
        height: 3,
        decoration: const BoxDecoration(
            color: Colors.black26, shape: BoxShape.circle),
      );
}

class _MarkResult {
  final CellType type;
  final String? name;
  final String? mergeIntoRoomId;
  _MarkResult({required this.type, this.name, this.mergeIntoRoomId});
}

class _MarkAreaSheet extends StatefulWidget {
  final int cellCount;
  final Floor floor;
  final List<CellPos> cells;
  final CellType initialType;
  const _MarkAreaSheet({
    required this.cellCount,
    required this.floor,
    required this.cells,
    required this.initialType,
  });
  @override
  State<_MarkAreaSheet> createState() => _MarkAreaSheetState();
}

class _MarkAreaSheetState extends State<_MarkAreaSheet> {
  late CellType _type;
  final _nameCtrl = TextEditingController();
  String? _mergeRoomId;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  List<Room> get _adjacentRooms {
    final selSet = widget.cells.map((c) => c.key).toSet();
    final result = <Room>[];
    for (final room in widget.floor.rooms) {
      for (final rc in room.cells) {
        final neighbors = [
          CellPos(rc.x + 1, rc.y),
          CellPos(rc.x - 1, rc.y),
          CellPos(rc.x, rc.y + 1),
          CellPos(rc.x, rc.y - 1),
        ];
        if (neighbors.any((n) => selSet.contains(n.key))) {
          result.add(room);
          break;
        }
      }
    }
    return result;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final types = [
      CellType.walkable,
      CellType.corridor,
      CellType.room,
      CellType.blocked,
      CellType.stairs,
      CellType.lift,
      CellType.ramp,
      CellType.entrance,
      CellType.exit,
      CellType.landmark,
      CellType.washroom,
      CellType.empty,
    ];

    final isNamed = _type == CellType.room ||
        _type == CellType.landmark ||
        _type == CellType.washroom;
    final adj = _adjacentRooms;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Mark ${widget.cellCount} cell${widget.cellCount > 1 ? "s" : ""}',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: types.map((t) {
                final sel = _type == t;
                return GestureDetector(
                  onTap: () => setState(() {
                    _type = t;
                    _mergeRoomId = null;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel
                          ? t.color.withOpacity(0.18)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel ? t.color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t.icon, size: 16, color: Colors.black87),
                        const SizedBox(width: 6),
                        Text(
                          t == CellType.empty ? 'Erase' : t.label,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight:
                                sel ? FontWeight.w600 : FontWeight.w500,
                            color: sel ? AppColors.brand : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (isNamed) ...[
              const SizedBox(height: 20),
              if (_type == CellType.room && adj.isNotEmpty) ...[
                Text('Add to existing room?',
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: adj.map((r) {
                    final sel = _mergeRoomId == r.id;
                    return ChoiceChip(
                      label: Text(r.name),
                      selected: sel,
                      onSelected: (_) => setState(() {
                        _mergeRoomId = sel ? null : r.id;
                        if (!sel) _nameCtrl.clear();
                      }),
                      selectedColor: AppColors.brand.withOpacity(0.15),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                if (_mergeRoomId == null)
                  Text('…or create a new room:',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 6),
              ],
              if (_mergeRoomId == null)
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g. CSE Department',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    _MarkResult(
                      type: _type,
                      name: _mergeRoomId != null
                          ? null
                          : _nameCtrl.text.trim(),
                      mergeIntoRoomId: _mergeRoomId,
                    ),
                  );
                },
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}