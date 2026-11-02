import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'emblem_registry.g.dart';
import 'emblem_spec.dart';

/// Renders any [EmblemSpec] with the canonical Acoustic palette.
///
/// This is the single interpreter that replaced the six hand-written
/// `_drawYorgia` / `_drawDickinsonia` / `_drawKimberella` / `_drawCursus` /
/// `_drawFractofusus` / `_drawDefaultEmblem` methods in `shell.dart`.
///
/// Callers draw the medal body themselves (grid, rim gradient, rim stroke) and
/// then hand the organism region to [paint].
class EmblemRenderer {
  const EmblemRenderer._();

  /// Reference radius the spec stroke widths are expressed against.
  static const double _refRadius = 90.0;

  /// Anatomy accent for the duration of one [paint] call. Painting is
  /// synchronous, so a per-call override cannot leak between widgets. Mirrors
  /// `emblem/livery.py` exactly: two channels, or a mark loses its depth.
  static Color? _accent;
  static Color? _accentDim;

  /// [theme] overrides the gradient palette of any layer that names one, so a
  /// festival / mood reskin is a single argument at paint time — no new assets.
  ///
  /// [livery] applies a seasonal [EmblemOccasion]: the anatomy strokes take the
  /// occasion accent. The caller still draws the medal rim, so it should use
  /// `livery.rim` there — the whole point is that rim, glow and ornament agree.
  static void paint(
    Canvas canvas,
    Offset center,
    double radius,
    EmblemSpec spec, {
    String? theme,
    EmblemOccasion? livery,
  }) {
    final Color? previous = _accent;
    final Color? previousDim = _accentDim;
    if (livery != null) {
      _accent = Color(livery.accent);
      _accentDim = Color(livery.accentDim);
    }
    try {
      if (spec.isRelief) {
        for (final EmblemLayer layer in spec.layers) {
          _paintLayer(canvas, center, radius, layer, theme);
        }
      } else if (spec.volume != null) {
        _paintVolume(canvas, center, radius, spec.volume!);
      }
    } finally {
      _accent = previous;
      _accentDim = previousDim;
    }
  }

  // ------------------------------------------------------------------ tokens

  static Color? _token(String? name) {
    // A seasonal livery re-points the anatomy channels and nothing else: the
    // plate, the rim metal and the type colours are structural.
    final Color? accent = _accent;
    if (accent != null) {
      if (name == 'sonarCyan' || name == 'sonarCyanDim') return accent;
      if (name == 'sonarBlue') return _accentDim ?? accent;
    }
    switch (name) {
      case 'black':
        return AcousticColors.black;
      case 'obsidian':
        return AcousticColors.obsidian;
      case 'darkCarbon':
        return AcousticColors.darkCarbon;
      case 'panelBg':
        return AcousticColors.panelBg;
      case 'activeCard':
        return AcousticColors.activeCard;
      case 'midGray':
        return AcousticColors.midGray;
      case 'steel':
        return AcousticColors.steel;
      case 'titanium':
        return AcousticColors.titanium;
      case 'sonarCyan':
        return AcousticColors.sonarCyan;
      case 'sonarBlue':
        return AcousticColors.sonarBlue;
      case 'sonarCyanDim':
        return AcousticColors.sonarCyanDim;
      case 'warnOrange':
        return AcousticColors.warnOrange;
      case 'white':
        return const Color(0xFFFFFFFF);
      default:
        return null;
    }
  }

  static Offset _pt(EmblemPoint p, Offset c, double r) =>
      Offset(c.dx + p.x * r, c.dy - p.y * r); // spec is +Y up

  /// Stroke width for one layer: logical px at radius 90, through the
  /// family-wide weight knob (`tokens.json` -> `geometry.strokeScale`).
  static double _w(double specWidth, double radius) =>
      specWidth * kEmblemStrokeScale / _refRadius * radius;

  // ------------------------------------------------------------------ layers

  static void _paintLayer(
      Canvas canvas, Offset c, double r, EmblemLayer l, String? theme) {
    switch (l.kind) {
      case 'disc':
        _disc(canvas, c, r, l, theme);
        break;
      case 'poly':
        _poly(canvas, c, r, l);
        break;
      case 'arc':
        _arc(canvas, c, r, l);
        break;
      case 'ring':
        canvas.drawCircle(
          Offset(c.dx + l.cx * r, c.dy - l.cy * r),
          l.r * r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = _w(l.width, r)
            ..color = (_token(l.color) ?? AcousticColors.sonarCyan)
                .withValues(alpha: l.opacity),
        );
        break;
      case 'dot':
        _dot(canvas, c, r, l);
        break;
      case 'line':
        _line(canvas, c, r, l);
        break;
      case 'phyllotaxis':
        _phyllotaxis(canvas, c, r, l);
        break;
      default:
        _line(canvas, c, r, l);
        break;
    }
  }

  // --------------------------------------------------------- phyllotaxis

  /// Vogel spiral of crescent leaves — one primitive, no longer used by the
  /// corporate mark (that is the `| > < |` medallion from `mark_monogram.py`).
  ///
  /// The maths is mirrored from `phyllotaxis_leaf` in
  /// `logos/3d/emblem/emblem3d.py` and `emblem2d.py`; the PNG, the SVG and this
  /// fallback all have to describe the same wreath, so keep them in lockstep.
  static void _phyllotaxis(
      Canvas canvas, Offset c, double r, EmblemLayer l) {
    final Map<String, dynamic> p = l.raw;

    double num_(String key, double fallback) {
      final Object? v = p[key];
      return v is num ? v.toDouble() : fallback;
    }

    int int_(String key, int fallback) {
      final Object? v = p[key];
      return v is num ? v.toInt() : fallback;
    }

    final int count = math.max(2, int_('count', 64));
    final double r0 = num_('rInner', 0.05);
    final double r1 = num_('rOuter', 0.42);
    final double golden = _rad(num_('angleDeg', 137.50776405));
    final double swirl = _rad(num_('swirlDeg', -20.0));
    final double length = num_('length', 0.28);
    final double lengthTaper = num_('lengthTaper', 0.30);
    final double width = num_('width', 0.030);
    final double widthTaper = num_('widthTaper', 0.50);
    final double lean = _rad(num_('leanDeg', 38.0));
    final double bend = _rad(num_('bendDeg', 45.0));
    final double lead = _rad(num_('leadDeg', 0.0));
    final double sense = ((p['clockwise'] as bool?) ?? true) ? -1.0 : 1.0;
    final int steps = math.max(4, int_('steps', 14));
    final int altEvery = int_('altEvery', 0);
    final int veinEvery = int_('veinEvery', 0);
    final int veinOffset = int_('veinOffset', 0);

    final Color? fill = _token(l.fill);
    final Color? alt = _token(p['altFill'] as String?) ?? fill;
    final Color? edge = _token(l.edge);
    final Color? vein = _token(p['vein'] as String?);
    final double veinWidth = _w(num_('veinWidth', 0.0), r);

    for (int i = 0; i < count; i++) {
      final double u = (i + 0.5) / count;
      final double baseR = r0 + (r1 - r0) * u;
      final double a0 = lead + i * golden + swirl * baseR;
      final double span = sense * lean;
      final double curl = sense * bend;
      final double reach = length * (1.0 - lengthTaper * (1.0 - u));
      final double wmax = width * (1.0 - widthTaper * (1.0 - u));

      Offset centre(double t) {
        final double ang = a0 + span * t + curl * t * t;
        final double rad = baseR + reach * t;
        return Offset(rad * math.cos(ang), rad * math.sin(ang));
      }

      Offset edgeAt(double t, double sign) {
        final Offset p0 = centre(t);
        const double h = 1e-3;
        final Offset a = centre(math.max(0.0, t - h));
        final Offset b = centre(math.min(1.0, t + h));
        final Offset d = b - a;
        final double norm = d.distance == 0 ? 1.0 : d.distance;
        final double w = wmax * _leafWeight(t);
        return Offset(
          p0.dx - sign * d.dy / norm * w,
          p0.dy + sign * d.dx / norm * w,
        );
      }

      final List<Offset> poly = <Offset>[centre(0.0)];
      for (int k = 1; k < steps; k++) {
        poly.add(edgeAt(k / steps, 1.0));
      }
      poly.add(centre(1.0));
      for (int k = steps - 1; k >= 1; k--) {
        poly.add(edgeAt(k / steps, -1.0));
      }

      final Path path = Path();
      for (int k = 0; k < poly.length; k++) {
        final Offset o = _xy(poly[k].dx, poly[k].dy, c, r);
        if (k == 0) {
          path.moveTo(o.dx, o.dy);
        } else {
          path.lineTo(o.dx, o.dy);
        }
      }
      path.close();

      final Color? leafFill = (altEvery > 0 && i % altEvery == 0) ? alt : fill;
      if (leafFill != null) {
        canvas.drawPath(
          path,
          Paint()..color = leafFill.withValues(alpha: l.opacity),
        );
      }
      if (edge != null && l.edgeWidth > 0) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = _w(l.edgeWidth, r)
            ..color = edge.withValues(alpha: l.edgeOpacity),
        );
      }

      if (vein != null &&
          veinWidth > 0 &&
          (veinEvery <= 0 || (i + veinOffset) % veinEvery == 0)) {
        final Path vp = Path();
        for (int k = 0; k <= steps; k++) {
          final Offset o =
              centre(0.10 + 0.80 * k / steps);
          final Offset q = _xy(o.dx, o.dy, c, r);
          if (k == 0) {
            vp.moveTo(q.dx, q.dy);
          } else {
            vp.lineTo(q.dx, q.dy);
          }
        }
        final Color base = vein.withValues(
            alpha: l.opacity * num_('veinOpacity', 0.9));
        canvas.drawPath(
          vp,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = veinWidth * 2.6
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = base.withValues(alpha: 0.30)
            ..maskFilter =
                MaskFilter.blur(BlurStyle.normal, veinWidth * 1.6),
        );
        canvas.drawPath(
          vp,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = veinWidth
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = base,
        );
      }
    }
  }

  /// Leaf half-width profile, mirrored from the Python generators.
  static double _leafWeight(double t) =>
      (math.pow(t, 0.55) * math.pow(1.0 - t, 1.1)) / 0.3480;

  static double _rad(double deg) => deg * math.pi / 180.0;

  static Offset _xy(double x, double y, Offset c, double r) =>
      Offset(c.dx + x * r, c.dy - y * r);
  static void _disc(
      Canvas canvas, Offset c, double r, EmblemLayer l, String? theme) {
    final Rect rect = Rect.fromCenter(
      center: Offset(c.dx + l.cx * r, c.dy - l.cy * r),
      width: l.rx * 2 * r,
      height: l.ry * 2 * r,
    );
    final Paint? gradient = _gradientPaint(l, theme, rect);
    if (gradient != null) {
      canvas.drawOval(rect, gradient);
    }
    final Color? fill = _token(l.fill);
    if (gradient == null && fill != null) {
      canvas.drawOval(rect, Paint()..color = fill.withValues(alpha: l.opacity));
    }
    final Color? edge = _token(l.edge);
    if (edge != null && l.edgeWidth > 0) {
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _w(l.edgeWidth, r)
          ..color = edge.withValues(alpha: l.edgeOpacity),
      );
    }
  }

  /// Linear gradient across `rect`, matching the SVG and Blender ramps: the
  /// axis spans the disc's own extent (not its bounding square) so the shape's
  /// extreme points land exactly on the first and last stops.
  static Paint? _gradientPaint(EmblemLayer l, String? theme, Rect rect) {
    if (l.gradient == null) return null;
    final EmblemTheme t = emblemThemeOf(theme ?? l.gradient);
    if (t.stops.length < 2) return null;
    final double a = t.angleDeg * math.pi / 180.0;
    // spec space is +Y up, canvas is +Y down
    final Offset dir = Offset(math.sin(a), -math.cos(a));
    final double ext = math.max(rect.width, rect.height) / 2;
    final Offset mid = rect.center;
    return Paint()
      ..shader = ui.Gradient.linear(
        mid - dir * ext,
        mid + dir * ext,
        <Color>[
          for (final int v in t.stops)
            Color(v).withValues(alpha: l.opacity),
        ],
        <double>[
          for (int i = 0; i < t.stops.length; i++)
            i / (t.stops.length - 1),
        ],
      );
  }

  static void _poly(
      Canvas canvas, Offset c, double r, EmblemLayer l) {
    final Path path = _pathFrom(l.points, c, r, l.smooth, l.closed);
    final Color? fill = _token(l.fill);
    if (fill != null) {
      canvas.drawPath(path, Paint()..color = fill.withValues(alpha: l.opacity));
    }
    final Color? edge = _token(l.edge);
    if (edge != null && l.edgeWidth > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = _w(l.edgeWidth, r)
          ..color = edge.withValues(alpha: l.edgeOpacity),
      );
    }
  }

  static void _arc(
      Canvas canvas, Offset c, double r, EmblemLayer l) {
    // Sampled instead of addArc so the +Y-up spec never fights Flutter's
    // clockwise-from-+X-with-Y-down angle convention.
    final int steps = 32;
    final List<EmblemPoint> pts = <EmblemPoint>[];
    for (int i = 0; i <= steps; i++) {
      final double deg = l.startDeg + l.sweepDeg * (i / steps);
      final double rad = deg * math.pi / 180.0;
      pts.add(EmblemPoint(
        l.cx + math.cos(rad) * l.rx,
        l.cy + math.sin(rad) * l.ry,
      ));
    }
    final Path path = _pathFrom(pts, c, r, false, false);
    if (l.closed) path.close();

    final Color? fill = _token(l.fill);
    if (fill != null) {
      canvas.drawPath(path, Paint()..color = fill.withValues(alpha: l.opacity));
    }
    final Color? edge = _token(l.edge);
    if (edge != null && l.edgeWidth > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _w(l.edgeWidth, r)
          ..color = edge.withValues(alpha: l.edgeOpacity),
      );
    }
  }

  static void _dot(
      Canvas canvas, Offset c, double r, EmblemLayer l) {
    final Color col = (_token(l.color) ?? AcousticColors.sonarCyan)
        .withValues(alpha: l.opacity);
    final Paint paint = Paint()..color = col;
    if (l.blur > 0) {
      paint.maskFilter =
          MaskFilter.blur(BlurStyle.normal, l.blur / _refRadius * r);
    }
    canvas.drawCircle(Offset(c.dx + l.cx * r, c.dy - l.cy * r), l.r * r, paint);
  }

  static void _line(
      Canvas canvas, Offset c, double r, EmblemLayer l) {
    if (l.points.length < 2) return;
    final Path path = _pathFrom(l.points, c, r, l.smooth, false);
    final Color base = (_token(l.color) ?? AcousticColors.sonarCyan)
        .withValues(alpha: l.opacity);
    final double width = _w(l.width, r);

    if (l.glow) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 2.6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = base.withValues(alpha: 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 1.8),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = base,
    );
  }

  // ------------------------------------------------------------------ volume

  static void _paintVolume(
      Canvas canvas, Offset c, double r, EmblemVolume v) {
    final Color shellFill = AcousticColors.panelBg;
    final Color edge = AcousticColors.titanium;
    final Color emissive = AcousticColors.sonarCyan;
    final Color emissiveDim = AcousticColors.sonarCyanDim;

    // carapace
    if (v.shellType == 'bivalve') {
      for (final double sign in <double>[-1, 1]) {
        _shellOval(canvas, c, r, v, sign, shellFill, edge);
      }
    } else if (v.shellType == 'ellipsoid') {
      _shellOval(canvas, c, r, v, 0, shellFill, edge);
    }

    // spine
    if (v.spine.length >= 2 && v.spineRadius > 0) {
      _smoothStroke(canvas, v.spine, c, r, v.spineRadius * r, emissive);
    }

    // ribs
    if (v.ribCount > 1) {
      for (int i = 0; i < v.ribCount; i++) {
        final double t = i / (v.ribCount - 1);
        final double mx = v.ribFrom.x + (v.ribTo.x - v.ribFrom.x) * t;
        final double my = v.ribFrom.y + (v.ribTo.y - v.ribFrom.y) * t;
        final double grow = 1.0 - v.ribFalloff * ((t - 0.5).abs() * 2.0);
        final double span = v.ribLength * grow;
        if (v.ribMirror) {
          for (final double sign in <double>[-1, 1]) {
            _smoothStroke(
              canvas,
              <EmblemPoint>[
                EmblemPoint(mx, my),
                EmblemPoint(
                  mx + sign * span * 0.55,
                  my + (i.isEven ? 0.30 : -0.24) * span,
                ),
              ],
              c,
              r,
              v.ribRadius * r,
              emissiveDim,
            );
          }
        } else {
          final double rad = v.ribAngle * math.pi / 180.0;
          final double dx = math.cos(rad) * span * 0.5;
          final double dy = math.sin(rad) * span * 0.5;
          _smoothStroke(
            canvas,
            <EmblemPoint>[
              EmblemPoint(mx - dx, my - dy),
              EmblemPoint(mx + dx, my + dy),
            ],
            c,
            r,
            v.ribRadius * r,
            emissiveDim,
          );
        }
      }
    }

    // antennae (flattened, NaN separates runs)
    final List<EmblemPoint> run = <EmblemPoint>[];
    void flush() {
      if (run.length >= 2) {
        _smoothStroke(canvas, List<EmblemPoint>.of(run), c, r,
            math.max(v.ribRadius, 0.005) * r, emissive);
      }
      run.clear();
    }

    for (final EmblemPoint p in v.antennae) {
      if (p.x.isNaN) {
        flush();
      } else {
        run.add(p);
      }
    }
    flush();
  }

  static void _shellOval(Canvas canvas, Offset c, double r, EmblemVolume v,
      double sign, Color fill, Color edge) {
    final bool bivalve = v.shellType == 'bivalve';
    final double w = bivalve ? v.width * 0.94 : v.width;
    canvas.save();
    canvas.translate(c.dx + (v.offsetX + sign * v.gap) * r, c.dy - v.offsetY * r);
    canvas.rotate(sign * v.tilt * math.pi / 180.0);
    final Rect rect = Rect.fromCenter(
        center: Offset.zero, width: w * r, height: v.height * r);
    canvas.drawOval(
      rect,
      Paint()..color = fill.withValues(alpha: 0.92),
    );
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.004 * r
        ..color = edge.withValues(alpha: 0.35),
    );
    canvas.restore();
  }

  static void _smoothStroke(Canvas canvas, List<EmblemPoint> pts, Offset c,
      double r, double width, Color color) {
    final Path path = _pathFrom(pts, c, r, true, false);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.30)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 1.6),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  // ------------------------------------------------------------------ paths

  /// Polyline -> Path. With [smooth], applies one Catmull-Rom pass so ported
  /// quadratic/cubic segments from the legacy painters stay curved.
  static Path _pathFrom(List<EmblemPoint> pts, Offset c, double r,
      bool smooth, bool closed) {
    final List<Offset> o = <Offset>[for (final EmblemPoint p in pts) _pt(p, c, r)];
    final Path path = Path();
    if (o.isEmpty) return path;
    if (o.length == 1) {
      path.moveTo(o.first.dx, o.first.dy);
      return path;
    }
    if (!smooth || o.length < 3) {
      path.moveTo(o.first.dx, o.first.dy);
      for (int i = 1; i < o.length; i++) {
        path.lineTo(o[i].dx, o[i].dy);
      }
      if (closed) path.close();
      return path;
    }
    path.moveTo(o.first.dx, o.first.dy);
    for (int i = 0; i < o.length - 1; i++) {
      final Offset p0 = i == 0 ? o[0] : o[i - 1];
      final Offset p1 = o[i];
      final Offset p2 = o[i + 1];
      final Offset p3 = i + 2 < o.length ? o[i + 2] : o.last;
      final Offset c1 =
          Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
      final Offset c2 =
          Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    if (closed) path.close();
    return path;
  }

  /// Blurred core used by the default emblem's lens glow.
  static void paintLensGlow(
      Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius * 0.2,
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }
}

/// Convenience CustomPainter for screens that only need the organism region.
class EmblemPainter extends CustomPainter {
  final EmblemSpec spec;
  final bool isHovered;

  const EmblemPainter({required this.spec, this.isHovered = false});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    EmblemRenderer.paint(
      canvas,
      Offset(size.width / 2, size.height / 2),
      radius,
      spec,
    );
  }

  @override
  bool shouldRepaint(covariant EmblemPainter old) =>
      old.spec.name != spec.name || old.isHovered != isHovered;
}

/// Kept so `dart:ui` stays referenced if [EmblemRenderer] is trimmed.
typedef EmblemImageFilter = ui.ImageFilter;
