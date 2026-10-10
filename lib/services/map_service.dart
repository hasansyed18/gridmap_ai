import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../models/cell_type.dart';

class MapService {
  static final _supabase = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> _fetchAllCells(
      String floorId) async {
    final all = <Map<String, dynamic>>[];
    const pageSize = 1000;
    var from = 0;
    while (true) {
      final page = await _supabase
          .from('cells')
          .select()
          .eq('floor_id', floorId)
          .range(from, from + pageSize - 1);
      final list = (page as List).cast<Map<String, dynamic>>();
      all.addAll(list);
      if (list.length < pageSize) break;
      from += pageSize;
    }
    return all;
  }

  static Future<List<Map<String, dynamic>>> _fetchAllRooms(
      String floorId) async {
    final all = <Map<String, dynamic>>[];
    const pageSize = 1000;
    var from = 0;
    while (true) {
      final page = await _supabase
          .from('rooms')
          .select()
          .eq('floor_id', floorId)
          .range(from, from + pageSize - 1);
      final list = (page as List).cast<Map<String, dynamic>>();
      all.addAll(list);
      if (list.length < pageSize) break;
      from += pageSize;
    }
    return all;
  }

  static Future<String> saveAndPublish({
    required String orgId,
    required Organization organization,
  }) async {
    final building = organization.buildings.first;
    final floor = building.floors.first;

    await _supabase.from('organizations').upsert({
      'id': orgId,
      'name': organization.name,
      'description': organization.description,
    });

    final existingBuildings = await _supabase
        .from('buildings')
        .select('id')
        .eq('org_id', orgId)
        .order('created_at', ascending: false);
    final buildingsList =
        (existingBuildings as List).cast<Map<String, dynamic>>();

    String buildingId;
    if (buildingsList.isNotEmpty) {
      buildingId = buildingsList.first['id'] as String;
      await _supabase.from('buildings').update({
        'name': building.name,
        'floor_count': building.floors.length,
        'published': true,
      }).eq('id', buildingId);

      final oldFloors = await _supabase
          .from('floors')
          .select('id')
          .eq('building_id', buildingId);
      for (final f in (oldFloors as List)) {
        final fid = f['id'] as String;
        await _supabase.from('cells').delete().eq('floor_id', fid);
        await _supabase.from('rooms').delete().eq('floor_id', fid);
      }
      await _supabase.from('floors').delete().eq('building_id', buildingId);

      // Clean up any extra duplicate buildings for this org
      for (var i = 1; i < buildingsList.length; i++) {
        final dupId = buildingsList[i]['id'] as String;
        final dupFloors = await _supabase
            .from('floors')
            .select('id')
            .eq('building_id', dupId);
        for (final f in (dupFloors as List)) {
          final fid = f['id'] as String;
          await _supabase.from('cells').delete().eq('floor_id', fid);
          await _supabase.from('rooms').delete().eq('floor_id', fid);
        }
        await _supabase.from('floors').delete().eq('building_id', dupId);
        await _supabase.from('buildings').delete().eq('id', dupId);
      }
    } else {
      final buildingRes = await _supabase
          .from('buildings')
          .insert({
            'org_id': orgId,
            'name': building.name,
            'lat': organization.lat,
            'lng': organization.lng,
            'width_cells': 100,
            'height_cells': 100,
            'floor_count': building.floors.length,
            'published': true,
          })
          .select()
          .single();
      buildingId = buildingRes['id'] as String;
    }

    final floorRes = await _supabase
        .from('floors')
        .insert({
          'building_id': buildingId,
          'level': 0,
          'name': floor.name,
          'grid_width': 100,
          'grid_height': 100,
        })
        .select()
        .single();
    final floorId = floorRes['id'] as String;

    final roomIdMap = <String, String>{};
    for (final r in floor.rooms) {
      final res = await _supabase
          .from('rooms')
          .insert({
            'floor_id': floorId,
            'name': r.name,
            'aliases': r.aliases,
            'is_accessible': r.isAccessible,
          })
          .select()
          .single();
      roomIdMap[r.id] = (res['id'] ?? '').toString();
    }

    if (floor.rooms.length == 1 && floor.rooms.first.cells.isEmpty) {
      floor.cells.forEach((key, type) {
        if (type == CellType.room) {
          floor.rooms.first.cells.add(CellPos.fromKey(key));
        }
      });
    }

    final cellKeyToRoomId = <String, String>{};
    for (final r in floor.rooms) {
      for (final c in r.cells) {
        cellKeyToRoomId[c.key] = r.id;
      }
    }

    final cellRows = <Map<String, dynamic>>[];
    final addedKeys = <String>{};

    floor.cells.forEach((key, type) {
      final parts = key.split(',');
      final x = int.parse(parts[0]);
      final y = int.parse(parts[1]);

      String? roomUuid;
      final inMemRoomId = cellKeyToRoomId[key];
      if (inMemRoomId != null && roomIdMap.containsKey(inMemRoomId)) {
        roomUuid = roomIdMap[inMemRoomId];
      }

      cellRows.add({
        'floor_id': floorId,
        'x': x,
        'y': y,
        'type': type.name,
        'room_id': roomUuid,
      });
      addedKeys.add(key);
    });

    for (final r in floor.rooms) {
      final roomUuid = roomIdMap[r.id];
      for (final c in r.cells) {
        if (!addedKeys.contains(c.key)) {
          cellRows.add({
            'floor_id': floorId,
            'x': c.x,
            'y': c.y,
            'type': CellType.room.name,
            'room_id': roomUuid,
          });
          addedKeys.add(c.key);
        }
      }
    }

    if (cellRows.isNotEmpty) {
      const chunkSize = 500;
      for (var i = 0; i < cellRows.length; i += chunkSize) {
        final end = (i + chunkSize < cellRows.length)
            ? i + chunkSize
            : cellRows.length;
        await _supabase.from('cells').insert(cellRows.sublist(i, end));
      }
    }

    return buildingId;
  }

  static Future<List<Map<String, dynamic>>> listPublishedBuildings() async {
    final res = await _supabase
        .from('buildings')
        .select(
            'id, name, org_id, floor_count, organizations(name, description)')
        .eq('published', true)
        .order('created_at', ascending: false);
    final list = (res as List).cast<Map<String, dynamic>>();
    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];
    for (final b in list) {
      final key = '${b['org_id']}_${b['name']}';
      if (seen.add(key)) {
        unique.add(b);
      }
    }
    return unique;
  }

  static Future<Floor?> loadFloor(String buildingId) async {
    final floorRes = await _supabase
        .from('floors')
        .select()
        .eq('building_id', buildingId)
        .order('level')
        .limit(1)
        .maybeSingle();
    if (floorRes == null) return null;

    final floorId = floorRes['id'] as String;

    final cellRes = await _fetchAllCells(floorId);
    final roomRes = await _fetchAllRooms(floorId);

    final roomIdToModel = <String, Room>{};
    for (final r in roomRes) {
      final id = (r['id'] ?? '').toString();
      final room = Room(
        id: id,
        name: r['name'] as String? ?? 'Room',
        aliases: (r['aliases'] as List?)?.cast<String>() ?? const [],
        cells: [],
        isAccessible: r['is_accessible'] as bool? ?? true,
      );
      roomIdToModel[id] = room;
    }

    final cells = <String, CellType>{};
    for (final c in cellRes) {
      final x = c['x'] as int;
      final y = c['y'] as int;
      final typeStr = c['type'] as String;
      final type = CellType.values.firstWhere(
        (t) => t.name == typeStr,
        orElse: () => CellType.empty,
      );
      cells['$x,$y'] = type;

      final roomId = c['room_id']?.toString();
      if (roomId != null && roomIdToModel.containsKey(roomId)) {
        roomIdToModel[roomId]!.cells.add(CellPos(x, y));
      }
    }

    if (roomIdToModel.length == 1 && roomIdToModel.values.first.cells.isEmpty) {
      cells.forEach((key, type) {
        if (type == CellType.room) {
          roomIdToModel.values.first.cells.add(CellPos.fromKey(key));
        }
      });
    }

    return Floor(
      id: floorId,
      name: floorRes['name'] as String? ?? 'Ground Floor',
      level: floorRes['level'] as int? ?? 0,
      cells: cells,
      rooms: roomIdToModel.values.toList(),
    );
  }

  static Future<Organization?> loadAdminOrg(String ownerId) async {
    final orgRes = await _supabase
        .from('organizations')
        .select()
        .eq('owner_id', ownerId)
        .maybeSingle();
    if (orgRes == null) return null;

    final orgId = orgRes['id'] as String;
    final org = Organization(
      id: orgId,
      name: orgRes['name'] as String? ?? 'Organization',
      description: orgRes['description'] as String? ?? '',
      category: 'college',
    );

    final buildingRes = await _supabase
        .from('buildings')
        .select()
        .eq('org_id', orgId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (buildingRes == null) return org;

    final buildingId = buildingRes['id'] as String;
    final building = Building(
      id: buildingId,
      name: buildingRes['name'] as String? ?? 'Building',
    );

    final floorsRes = await _supabase
        .from('floors')
        .select()
        .eq('building_id', buildingId)
        .order('level');

    for (final f in (floorsRes as List)) {
      final floorId = f['id'] as String;
      final cellRes = await _fetchAllCells(floorId);
      final roomRes = await _fetchAllRooms(floorId);

      final roomMap = <String, Room>{};
      for (final r in roomRes) {
        final id = (r['id'] ?? '').toString();
        final room = Room(
          id: id,
          name: r['name'] as String? ?? 'Room',
          aliases: (r['aliases'] as List?)?.cast<String>() ?? const [],
          cells: [],
          isAccessible: r['is_accessible'] as bool? ?? true,
        );
        roomMap[id] = room;
      }

      final cells = <String, CellType>{};
      for (final c in cellRes) {
        final x = c['x'] as int;
        final y = c['y'] as int;
        final typeStr = c['type'] as String;
        final type = CellType.values.firstWhere(
          (t) => t.name == typeStr,
          orElse: () => CellType.empty,
        );
        cells['$x,$y'] = type;

        final roomId = c['room_id']?.toString();
        if (roomId != null && roomMap.containsKey(roomId)) {
          roomMap[roomId]!.cells.add(CellPos(x, y));
        }
      }

      if (roomMap.length == 1 && roomMap.values.first.cells.isEmpty) {
        cells.forEach((key, type) {
          if (type == CellType.room) {
            roomMap.values.first.cells.add(CellPos.fromKey(key));
          }
        });
      }

      building.floors.add(Floor(
        id: floorId,
        name: f['name'] as String? ?? 'Floor ${f['level']}',
        level: f['level'] as int? ?? 0,
        cells: cells,
        rooms: roomMap.values.toList(),
      ));
    }

    org.buildings.add(building);
    return org;
  }
}