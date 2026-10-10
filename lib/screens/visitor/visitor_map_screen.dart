import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/colors.dart';
import '../../models/models.dart';
import '../../services/map_service.dart';
import '../../services/routing_service.dart';
import '../../services/search_service.dart';
import '../../widgets/grid_canvas.dart';

class VisitorMapScreen extends StatefulWidget {
  final String buildingId;
  const VisitorMapScreen({super.key, required this.buildingId});

  @override
  State<VisitorMapScreen> createState() => _VisitorMapScreenState();
}

class _VisitorMapScreenState extends State<VisitorMapScreen> {
  Floor? _floor;
  bool _loading = true;
  String? _error;

  Room? _startRoom;
  CellPos? _start;
  CellPos? _goal;
  List<CellPos>? _route;
  bool _wheelchair = false;

  final _searchCtrl = TextEditingController();
  List<Room> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final f = await MapService.loadFloor(widget.buildingId);
      if (!mounted) return;
      setState(() {
        _floor = f;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String v) {
    if (_floor == null) return;
    setState(() {
      _suggestions = SearchService.searchRooms(_floor!.rooms, v);
    });
  }

  void _pickDestination(Room r) {
    setState(() {
      _goal = SearchService.representativePoint(r);
      _searchCtrl.text = r.name;
      _suggestions = [];
      _route = null;
    });
    if (_start != null) {
      _compute();
    } else {
      _showStartPicker();
    }
  }

  void _pickStart(Room r) {
    setState(() {
      _startRoom = r;
      _start = SearchService.representativePoint(r);
      _route = null;
    });
    if (_goal != null) _compute();
  }

  void _compute() {
    if (_floor == null || _start == null || _goal == null) return;
    final path = RoutingService.findPath(
      cells: _floor!.cells,
      start: _start!,
      goal: _goal!,
      wheelchair: _wheelchair,
    );
    setState(() => _route = path);
  }

  void _toggleWheelchair(bool v) {
    setState(() => _wheelchair = v);
    _compute();
  }

  void _clearRoute() {
    setState(() {
      _route = null;
      _start = null;
      _goal = null;
      _startRoom = null;
      _searchCtrl.clear();
      _suggestions = [];
    });
  }

  Future<void> _showStartPicker() async {
    if (_floor == null) return;
    final picked = await showModalBottomSheet<Room>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _StartPickerSheet(rooms: _floor!.rooms),
    );
    if (picked != null) _pickStart(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigate'),
        actions: [
          if (_route != null)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Clear route',
              onPressed: _clearRoute,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _floor == null
                  ? const Center(child: Text('No floor found'))
                  : Column(
                      children: [
                        _searchArea(),
                        if (_route != null) _routeInfoBar(),
                        Expanded(
                          child: GridCanvas(
                            floor: _floor!,
                            panMode: true,
                            pickingEntrance: false,
                            onSelectionComplete: (_, _) {},
                            onTapPlace: (_) {},
                            onEntrancePick: (_) {},
                            route: _route,
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _searchArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Where do you want to go?',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onSearchChanged('');
                        setState(() {
                          _goal = null;
                          _route = null;
                        });
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
          ),
          if (_suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 6),
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Material(
                color: Colors.transparent,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  itemBuilder: (_, i) {
                    final r = _suggestions[i];
                    return ListTile(
                      dense: true,
                      leading:
                          const Icon(Icons.place, color: AppColors.brand),
                      title: Text(r.name),
                      onTap: () => _pickDestination(r),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _showStartPicker,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: _startRoom != null
                          ? AppColors.brand.withOpacity(0.08)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _startRoom != null
                            ? AppColors.brand.withOpacity(0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.my_location,
                            size: 18,
                            color: _startRoom != null
                                ? AppColors.brand
                                : Colors.black45),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _startRoom?.name ?? 'Select your location',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: _startRoom != null
                                  ? AppColors.brand
                                  : Colors.black45,
                              fontWeight: _startRoom != null
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => _toggleWheelchair(!_wheelchair),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _wheelchair
                        ? const Color(0xFF1E88E5).withOpacity(0.12)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _wheelchair
                          ? const Color(0xFF1E88E5)
                          : Colors.transparent,
                    ),
                  ),
                  child: Icon(
                    Icons.accessible,
                    color: _wheelchair
                        ? const Color(0xFF1E88E5)
                        : Colors.black45,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _routeInfoBar() {
    final ok = _route != null && _route!.isNotEmpty;
    final distance = ok ? _route!.length : 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: ok ? Colors.teal.shade50 : Colors.red.shade50,
      child: Row(
        children: [
          Icon(
            ok ? Icons.directions_walk : Icons.warning_amber_rounded,
            color: ok ? AppColors.brand : Colors.red.shade700,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ok
                  ? '$distance steps · ${_wheelchair ? "Accessible route" : "Shortest route"}'
                  : 'No route found. Try different start or destination.',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ok ? AppColors.brand : Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartPickerSheet extends StatefulWidget {
  final List<Room> rooms;
  const _StartPickerSheet({required this.rooms});

  @override
  State<_StartPickerSheet> createState() => _StartPickerSheetState();
}

class _StartPickerSheetState extends State<_StartPickerSheet> {
  final _ctrl = TextEditingController();
  List<Room> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.rooms;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    setState(() {
      _filtered = SearchService.searchRooms(widget.rooms, v);
      if (v.isEmpty) _filtered = widget.rooms;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Where are you now?',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _ctrl,
            onChanged: _onChanged,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search room or landmark…',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 320),
            child: Material(
              color: Colors.transparent,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final r = _filtered[i];
                  return ListTile(
                    leading: const Icon(Icons.place_outlined,
                        color: AppColors.brand),
                    title: Text(r.name),
                    onTap: () => Navigator.pop(context, r),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}