import 'package:flutter/material.dart';
import '../core/colors.dart';

enum CellType {
  empty,
  walkable,
  blocked,
  room,
  corridor,
  stairs,
  lift,
  ramp,
  entrance,
  exit,
  landmark,
  washroom,
}

extension CellTypeX on CellType {
  String get label {
    switch (this) {
      case CellType.empty: return 'Empty';
      case CellType.walkable: return 'Walkable';
      case CellType.blocked: return 'Blocked';
      case CellType.room: return 'Room';
      case CellType.corridor: return 'Corridor';
      case CellType.stairs: return 'Stairs';
      case CellType.lift: return 'Lift';
      case CellType.ramp: return 'Ramp';
      case CellType.entrance: return 'Entrance';
      case CellType.exit: return 'Exit';
      case CellType.landmark: return 'Landmark';
      case CellType.washroom: return 'Washroom';
    }
  }

  Color get color {
    switch (this) {
      case CellType.empty: return AppColors.cellEmpty;
      case CellType.walkable: return AppColors.cellWalkable;
      case CellType.blocked: return AppColors.cellBlocked;
      case CellType.room: return AppColors.cellRoom;
      case CellType.corridor: return AppColors.cellCorridor;
      case CellType.stairs: return AppColors.cellStairs;
      case CellType.lift: return AppColors.cellLift;
      case CellType.ramp: return AppColors.cellRamp;
      case CellType.entrance: return AppColors.cellEntrance;
      case CellType.exit: return AppColors.cellExit;
      case CellType.landmark: return AppColors.cellLandmark;
      case CellType.washroom: return AppColors.cellWashroom;
    }
  }

  IconData get icon {
    switch (this) {
      case CellType.empty: return Icons.crop_square;
      case CellType.walkable: return Icons.directions_walk;
      case CellType.blocked: return Icons.block;
      case CellType.room: return Icons.meeting_room;
      case CellType.corridor: return Icons.horizontal_rule;
      case CellType.stairs: return Icons.stairs;
      case CellType.lift: return Icons.elevator;
      case CellType.ramp: return Icons.accessible;
      case CellType.entrance: return Icons.login;
      case CellType.exit: return Icons.logout;
      case CellType.landmark: return Icons.place;
      case CellType.washroom: return Icons.wc;
    }
  }

  double get height3D {
    switch (this) {
      case CellType.empty: return 0.05;
      case CellType.walkable: return 0.08;
      case CellType.blocked: return 2.5;
      case CellType.room: return 1.2;
      case CellType.corridor: return 0.1;
      case CellType.stairs: return 1.5;
      case CellType.lift: return 2.5;
      case CellType.ramp: return 0.5;
      case CellType.entrance: return 0.8;
      case CellType.exit: return 0.8;
      case CellType.landmark: return 0.6;
      case CellType.washroom: return 1.0;
    }
  }

  bool get isWalkable =>
      this == CellType.walkable ||
      this == CellType.corridor ||
      this == CellType.room ||
      this == CellType.entrance ||
      this == CellType.exit ||
      this == CellType.landmark ||
      this == CellType.washroom ||
      this == CellType.ramp ||
      this == CellType.lift ||
      this == CellType.stairs;

  bool get isWheelchairAccessible =>
      this == CellType.walkable ||
      this == CellType.corridor ||
      this == CellType.room ||
      this == CellType.entrance ||
      this == CellType.exit ||
      this == CellType.landmark ||
      this == CellType.washroom ||
      this == CellType.ramp ||
      this == CellType.lift;
      // Note: stairs is intentionally excluded

  bool get isNamed => this == CellType.room ||
      this == CellType.landmark ||
      this == CellType.washroom;

  bool get isPortal => this == CellType.stairs ||
      this == CellType.lift ||
      this == CellType.ramp;
}