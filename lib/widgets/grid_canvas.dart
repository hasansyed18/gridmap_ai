import 'package:flutter/material.dart';
import '../models/cell_type.dart';
import '../models/models.dart';

class GridCanvas extends StatefulWidget {
  final Floor floor;
  final bool panMode;
  final bool pickingEntrance;
  final String? pendingRoomId;
  final CellType? ghostType;
  final int ghostW;
  final int ghostH;
  final List<CellPos>? route;
  final void Function(CellPos start, CellPos end) onSelectionComplete;
  final void Function(CellPos topLeft) onTapPlace;
  final void Function(CellPos cell) onEntrancePick;

  const GridCanvas({
    super.key,
    required this.floor,
    required this.panMode,
    required this.pickingEntrance,
    required this.onSelectionComplete,
    required this.onTapPlace,
    required this.onEntrancePick,
    this.pendingRoomId,
    this.ghostType,
    this.ghostW = 0,
    this.ghostH = 0,
    this.route,
  });

  @override
  State<GridCanvas> createState() => _GridCanvasState();
}

class _GridCanvasState extends State<GridCanvas> {
  static const double kCellSize = 30.0;
  static const double kWorldSize = 3000.0;

  final _transform = TransformationController();
  CellPos? _selStart;
  CellPos? _selEnd;
  CellPos? _ghost;
  bool _initialized = false;
  Size? _viewportSize;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant GridCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((!_initialized || oldWidget.floor.id != widget.floor.id) &&
        widget.floor.cells.isNotEmpty &&
        _viewportSize != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _viewportSize != null) _fitToContent(_viewportSize!);
      });
      _initialized = true;
    }
  }

  void _fitToContent(Size size) {
    if (widget.floor.cells.isEmpty || !mounted) return;
    if (size.width <= 0 || size.height <= 0) return;

    int minX = 1 << 30, minY = 1 << 30, maxX = 0, maxY = 0;
    widget.floor.cells.forEach((key, _) {
      final p = key.split(',');
      final x = int.parse(p[0]);
      final y = int.parse(p[1]);
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    });

    const pad = 3;
    minX = (minX - pad).clamp(0, 999);
    minY = (minY - pad).clamp(0, 999);
    maxX = maxX + pad;
    maxY = maxY + pad;

    final contentW = (maxX - minX + 1) * kCellSize;
    final contentH = (maxY - minY + 1) * kCellSize;

    final availW = size.width;
    final availH = size.height;
    final scaleW = (availW / contentW).clamp(0.2, 2.0);
    final scaleH = (availH / contentH).clamp(0.2, 2.0);
    final finalScale = scaleW < scaleH ? scaleW : scaleH;

    final centerX = (minX + maxX + 1) * kCellSize / 2;
    final centerY = (minY + maxY + 1) * kCellSize / 2;

    final tx = availW / 2 - centerX * finalScale;
    final ty = availH / 2 - centerY * finalScale;

    final m = Matrix4.identity();
    m.setEntry(0, 0, finalScale);
    m.setEntry(1, 1, finalScale);
    m.setEntry(0, 3, tx);
    m.setEntry(1, 3, ty);
    _transform.value = m;
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  CellPos _cellFromWorld(Offset world) => CellPos(
        (world.dx / kCellSize).floor(),
        (world.dy / kCellSize).floor(),
      );

  @override
  Widget build(BuildContext context) {
    Room? pendingRoom;
    if (widget.pendingRoomId != null) {
      for (final r in widget.floor.rooms) {
        if (r.id == widget.pendingRoomId) {
          pendingRoom = r;
          break;
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _viewportSize = size;
        if (!_initialized &&
            widget.floor.cells.isNotEmpty &&
            size.width > 0 &&
            size.height > 0) {
          _initialized = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _fitToContent(size);
          });
        }

        return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transform,
          constrained: false,
          minScale: 0.2,
          maxScale: 4.0,
          boundaryMargin: const EdgeInsets.all(2000),
          panEnabled: widget.panMode,
          scaleEnabled: true,
          child: SizedBox(
            width: kWorldSize,
            height: kWorldSize,
            child: MouseRegion(
              onHover: (d) {
                if (widget.ghostType != null &&
                    widget.ghostW > 0 &&
                    widget.ghostH > 0) {
                  setState(() => _ghost = _cellFromWorld(d.localPosition));
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: widget.panMode
                    ? null
                    : (d) {
                        final c = _cellFromWorld(d.localPosition);
                        if (widget.pickingEntrance) {
                          widget.onEntrancePick(c);
                        } else if (widget.ghostType != null) {
                          widget.onTapPlace(c);
                        }
                      },
                onPanStart: (widget.panMode || widget.pickingEntrance)
                    ? null
                    : (d) {
                        setState(() {
                          _selStart = _cellFromWorld(d.localPosition);
                          _selEnd = _selStart;
                        });
                      },
                onPanUpdate: (widget.panMode || widget.pickingEntrance)
                    ? null
                    : (d) {
                        setState(() {
                          _selEnd = _cellFromWorld(d.localPosition);
                        });
                      },
                onPanEnd: (widget.panMode || widget.pickingEntrance)
                    ? null
                    : (_) {
                        if (_selStart != null && _selEnd != null) {
                          final start = _selStart!;
                          final end = _selEnd!;
                          setState(() {
                            _selStart = null;
                            _selEnd = null;
                          });
                          if (start != end) {
                            widget.onSelectionComplete(start, end);
                          }
                        }
                      },
                child: CustomPaint(
                  size: const Size(kWorldSize, kWorldSize),
                  painter: _GridPainter(
                    floor: widget.floor,
                    cellSize: kCellSize,
                    worldSize: kWorldSize,
                    selStart: _selStart,
                    selEnd: _selEnd,
                    pendingRoom: pendingRoom,
                    ghost: _ghost,
                    ghostW: widget.ghostW,
                    ghostH: widget.ghostH,
                    ghostType: widget.ghostType,
                    route: widget.route,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            children: [
              _fbtn(Icons.add, () => _zoomBy(1.25)),
              const SizedBox(height: 8),
              _fbtn(Icons.remove, () => _zoomBy(1 / 1.25)),
              const SizedBox(height: 8),
              _fbtn(Icons.center_focus_strong, _resetView),
            ],
          ),
        ),
      ],
    );
      },
    );
  }

  void _zoomBy(double factor) {
    final current = _transform.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(0.2, 4.0);
    final t = _transform.value.getTranslation();
    final m = Matrix4.identity();
    m.setEntry(0, 0, next);
    m.setEntry(1, 1, next);
    m.setEntry(0, 3, t.x);
    m.setEntry(1, 3, t.y);
    _transform.value = m;
  }

  void _resetView() {
    if (_viewportSize != null && widget.floor.cells.isNotEmpty) {
      _fitToContent(_viewportSize!);
    } else {
      _transform.value = Matrix4.identity();
    }
  }

  Widget _fbtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFF0D7377), size: 20),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Floor floor;
  final double cellSize;
  final double worldSize;
  final CellPos? selStart;
  final CellPos? selEnd;
  final Room? pendingRoom;
  final CellPos? ghost;
  final int ghostW;
  final int ghostH;
  final CellType? ghostType;
  final List<CellPos>? route;

  _GridPainter({
    required this.floor,
    required this.cellSize,
    required this.worldSize,
    this.selStart,
    this.selEnd,
    this.pendingRoom,
    this.ghost,
    this.ghostW = 0,
    this.ghostH = 0,
    this.ghostType,
    this.route,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFFF8FAFC));

    final linePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 0.6;
    final n = (worldSize / cellSize).ceil();
    for (var i = 0; i <= n; i++) {
      final p = i * cellSize;
      canvas.drawLine(Offset(p, 0), Offset(p, worldSize), linePaint);
      canvas.drawLine(Offset(0, p), Offset(worldSize, p), linePaint);
    }

    // Painted cells
    final cellPaint = Paint();
    floor.cells.forEach((key, type) {
      final parts = key.split(',');
      final x = int.parse(parts[0]);
      final y = int.parse(parts[1]);
      cellPaint.color = type.color;
      canvas.drawRect(
        Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
        cellPaint,
      );

      if (type == CellType.stairs ||
          type == CellType.lift ||
          type == CellType.ramp ||
          type == CellType.entrance ||
          type == CellType.exit ||
          type == CellType.washroom) {
        final tp = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(type.icon.codePoint),
            style: TextStyle(
              fontSize: cellSize * 0.55,
              fontFamily: type.icon.fontFamily,
              color: Colors.white,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(
            x * cellSize + (cellSize - tp.width) / 2,
            y * cellSize + (cellSize - tp.height) / 2,
          ),
        );
      }
    });

    // Room labels
    for (final room in floor.rooms) {
      if (room.cells.isEmpty) continue;
      double sx = 0, sy = 0;
      for (final c in room.cells) {
        sx += c.x;
        sy += c.y;
      }
      final cx = (sx / room.cells.length + 0.5) * cellSize;
      final cy = (sy / room.cells.length + 0.5) * cellSize;

      final tp = TextPainter(
        text: TextSpan(
          text: room.name,
          style: TextStyle(
            color: Colors.white,
            fontSize: (cellSize * 0.42).clamp(8.0, 15.0),
            fontWeight: FontWeight.w700,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: cellSize * 8);

      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }

    // Landmarks
    for (final l in floor.landmarks) {
      final cx = (l.position.x + 0.5) * cellSize;
      final cy = (l.position.y + 0.5) * cellSize;
      canvas.drawCircle(
          Offset(cx, cy), cellSize * 0.28, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(cx, cy), cellSize * 0.18,
          Paint()..color = const Color(0xFFF472B6));
    }

    // Pending entrance highlight
    if (pendingRoom != null && pendingRoom!.cells.isNotEmpty) {
      final roomKeys = pendingRoom!.cells.map((c) => c.key).toSet();
      final perimeter = <String, CellPos>{};
      for (final rc in pendingRoom!.cells) {
        final neighbors = [
          CellPos(rc.x + 1, rc.y),
          CellPos(rc.x - 1, rc.y),
          CellPos(rc.x, rc.y + 1),
          CellPos(rc.x, rc.y - 1),
        ];
        for (final nn in neighbors) {
          if (!roomKeys.contains(nn.key)) perimeter[nn.key] = nn;
        }
      }
      for (final p in perimeter.values) {
        final rect = Rect.fromLTWH(
            p.x * cellSize, p.y * cellSize, cellSize, cellSize);
        canvas.drawRect(rect,
            Paint()..color = const Color(0xFFFFB703).withOpacity(0.35));
        canvas.drawRect(
          rect,
          Paint()
            ..color = const Color(0xFFFFB703)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      for (final rc in pendingRoom!.cells) {
        final rect = Rect.fromLTWH(
            rc.x * cellSize, rc.y * cellSize, cellSize, cellSize);
        canvas.drawRect(
          rect,
          Paint()
            ..color = const Color(0xFF0D7377)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }

    // Ghost preview
    if (ghost != null &&
        ghostType != null &&
        ghostW > 0 &&
        ghostH > 0 &&
        pendingRoom == null) {
      final rect = Rect.fromLTWH(
        ghost!.x * cellSize,
        ghost!.y * cellSize,
        ghostW * cellSize,
        ghostH * cellSize,
      );
      canvas.drawRect(rect,
          Paint()..color = ghostType!.color.withOpacity(0.35));
      canvas.drawRect(
        rect,
        Paint()
          ..color = ghostType!.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // Selection rectangle
    if (selStart != null && selEnd != null) {
      final minX = selStart!.x < selEnd!.x ? selStart!.x : selEnd!.x;
      final maxX = selStart!.x > selEnd!.x ? selStart!.x : selEnd!.x;
      final minY = selStart!.y < selEnd!.y ? selStart!.y : selEnd!.y;
      final maxY = selStart!.y > selEnd!.y ? selStart!.y : selEnd!.y;

      final rect = Rect.fromLTWH(
        minX * cellSize,
        minY * cellSize,
        (maxX - minX + 1) * cellSize,
        (maxY - minY + 1) * cellSize,
      );

      canvas.drawRect(rect, Paint()..color = Colors.white.withOpacity(0.35));
      canvas.drawRect(
        rect,
        Paint()
          ..color = const Color(0xFF0D7377)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // ---------- ROUTE ----------
    if (route != null && route!.length > 1) {
      // Blue polyline
      final path = Path();
      for (var i = 0; i < route!.length; i++) {
        final c = route![i];
        final cx = (c.x + 0.5) * cellSize;
        final cy = (c.y + 0.5) * cellSize;
        if (i == 0) {
          path.moveTo(cx, cy);
        } else {
          path.lineTo(cx, cy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF1E88E5)
          ..strokeWidth = cellSize * 0.42
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );

      // White directional arrows every few steps
      final arrowPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = cellSize * 0.11
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (var i = 1; i < route!.length - 1; i += 3) {
        final prev = route![i - 1];
        final curr = route![i];
        final dx = (curr.x - prev.x).toDouble();
        final dy = (curr.y - prev.y).toDouble();
        if (dx == 0 && dy == 0) continue;

        final cx = (curr.x + 0.5) * cellSize;
        final cy = (curr.y + 0.5) * cellSize;
        final arrowSize = cellSize * 0.22;

        // unit vector along direction of travel
        final len = dx.abs() + dy.abs();
        final ux = dx / len;
        final uy = dy / len;
        // perpendicular
        final px = -uy;
        final py = ux;

        final tip = Offset(cx + ux * arrowSize, cy + uy * arrowSize);
        final left = Offset(
          cx - ux * arrowSize + px * arrowSize,
          cy - uy * arrowSize + py * arrowSize,
        );
        final right = Offset(
          cx - ux * arrowSize - px * arrowSize,
          cy - uy * arrowSize - py * arrowSize,
        );

        final arrowPath = Path()
          ..moveTo(left.dx, left.dy)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(right.dx, right.dy);
        canvas.drawPath(arrowPath, arrowPaint);
      }

      // Start marker (green dot)
      final s = route!.first;
      final sx = (s.x + 0.5) * cellSize;
      final sy = (s.y + 0.5) * cellSize;
      canvas.drawCircle(
          Offset(sx, sy), cellSize * 0.38, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(sx, sy), cellSize * 0.28,
          Paint()..color = const Color(0xFF43A047));
      canvas.drawCircle(
        Offset(sx, sy),
        cellSize * 0.28,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // End marker (red dot)
      final e = route!.last;
      final ex = (e.x + 0.5) * cellSize;
      final ey = (e.y + 0.5) * cellSize;
      canvas.drawCircle(
          Offset(ex, ey), cellSize * 0.38, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(ex, ey), cellSize * 0.28,
          Paint()..color = const Color(0xFFE53935));
      canvas.drawCircle(
        Offset(ex, ey),
        cellSize * 0.28,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => true;
}