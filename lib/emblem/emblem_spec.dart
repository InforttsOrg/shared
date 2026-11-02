import 'dart:convert';

import 'emblem_registry.g.dart';

/// Declarative model for an Infortts emblem.
///
/// Every organism — volumetric carapace or glyph-style relief — is described by
/// `brand/organisms.json` in `logos/3d` and shipped here as data via
/// [kEmblemSpecs]. Nothing in this file knows about a specific organism.
///
/// Coordinates: 1.0 == the painter's `radius`, origin at the medal centre,
/// **+Y is up** (the opposite of Flutter's canvas, which the renderer flips).
/// Layer `width` values are logical pixels at the default 180 px logo.
class EmblemSpec {
  final String name;
  final String label;
  final String renderMode; // 'volume' | 'relief'
  final List<EmblemLayer> layers;
  final EmblemVolume? volume;

  /// Standalone marks (the corporate logo) carry their own full-bleed disc and
  /// must not sit on the dark medallion chrome.
  final bool showMedal;

  const EmblemSpec({
    required this.name,
    required this.label,
    required this.renderMode,
    required this.layers,
    required this.volume,
    this.showMedal = true,
  });

  bool get isRelief => renderMode == 'relief';

  // ---------------------------------------------------------------- lookup

  /// App names that historically mapped to a specific organism but do not
  /// contain its registry key. Kept from the old `if/else` dispatch in
  /// `shell.dart` so existing apps keep their emblem.
  static const Map<String, String> _aliases = <String, String>{
    'forensic': 'mitochondria',
  };

  static final Map<String, EmblemSpec> _cache = <String, EmblemSpec>{};

  /// Exact-name lookup, then longest-substring match (organism names arrive as
  /// free-form app names like "Glycocalyx Auth" or "mitochondria-forensic"),
  /// then the legacy aliases, then the `_default` emblem. Never returns null.
  static EmblemSpec resolve(String rawName) {
    final String needle = rawName.toLowerCase();
    final List<String> keys = kEmblemSpecs.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final String key in keys) {
      if (key.startsWith('_')) continue;
      if (needle == key || needle.contains(key)) return of(key);
    }
    for (final MapEntry<String, String> alias in _aliases.entries) {
      if (needle.contains(alias.key)) return of(alias.value);
    }
    return of('_default');
  }

  static EmblemSpec of(String key) {
    final EmblemSpec? cached = _cache[key];
    if (cached != null) return cached;
    final String? raw = kEmblemSpecs[key] ?? kEmblemSpecs['_default'];
    if (raw == null) {
      throw StateError('emblem registry is empty');
    }
    final EmblemSpec spec = EmblemSpec.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
      fallbackName: key,
    );
    _cache[key] = spec;
    return spec;
  }

  static bool has(String key) => kEmblemSpecs.containsKey(key);

  // ---------------------------------------------------------------- parsing

  factory EmblemSpec.fromJson(Map<String, dynamic> json,
      {String? fallbackName}) {
    final String mode = (json['render'] as String?) ?? 'volume';
    final List<EmblemLayer> layers = <EmblemLayer>[
      for (final dynamic l in (json['layers'] as List<dynamic>? ?? const []))
        EmblemLayer.fromJson(l as Map<String, dynamic>),
    ];
    return EmblemSpec(
      name: (json['name'] as String?) ?? fallbackName ?? '',
      label: (json['label'] as String?) ?? (fallbackName ?? ''),
      renderMode: mode,
      layers: layers,
      volume: mode == 'volume' ? EmblemVolume.fromJson(json) : null,
      showMedal: (json['medal'] as bool?) ?? true,
    );
  }
}

/// Theme lookup with a safe fallback, so a typo'd or stale theme key renders the
/// brand gradient instead of crashing an app icon.
EmblemTheme emblemThemeOf(String? key) =>
    kEmblemThemes[key] ??
    kEmblemThemes[kDefaultEmblemTheme] ??
    kEmblemThemes.values.first;

/// One drawing primitive. [kind] is one of: disc, poly, arc, line, ring, dot.
class EmblemLayer {
  final String kind;
  final List<EmblemPoint> points;
  final double cx;
  final double cy;
  final double rx;
  final double ry;
  final double r;
  final double width;
  final double opacity;
  final double z;
  final String? fill;

  /// Name of a [EmblemTheme] in `kEmblemThemes`. When set, the layer fills with
  /// that gradient instead of [fill]; the renderer can override it per call.
  final String? gradient;

  final String? color;
  final String? edge;
  final double edgeWidth;
  final double edgeOpacity;
  final double blur;
  final double startDeg;
  final double sweepDeg;
  final bool closed;
  final bool smooth;
  final bool glow;

  /// The raw JSON for this layer. Primitives with their own parameter set
  /// (`phyllotaxis`) read from here instead of growing a field per knob; the
  /// common ones above stay typed because every interpreter uses them.
  final Map<String, dynamic> raw;

  const EmblemLayer({
    required this.kind,
    required this.points,
    required this.cx,
    required this.cy,
    required this.rx,
    required this.ry,
    required this.r,
    required this.width,
    required this.opacity,
    required this.z,
    required this.fill,
    required this.gradient,
    required this.color,
    required this.edge,
    required this.edgeWidth,
    required this.edgeOpacity,
    required this.blur,
    required this.startDeg,
    required this.sweepDeg,
    required this.closed,
    required this.smooth,
    required this.glow,
    required this.raw,
  });

  factory EmblemLayer.fromJson(Map<String, dynamic> j) {
    return EmblemLayer(
      kind: (j['kind'] as String?) ?? 'line',
      points: <EmblemPoint>[
        for (final dynamic p in (j['points'] as List<dynamic>? ?? const []))
          EmblemPoint(
            ((p as List<dynamic>)[0] as num).toDouble(),
            (p[1] as num).toDouble(),
          ),
      ],
      cx: _d(j['cx']),
      cy: _d(j['cy']),
      rx: _d(j['rx']),
      ry: _d(j['ry']),
      r: _d(j['r']),
      width: _d(j['width'], 1.0),
      opacity: _d(j['opacity'], 1.0),
      z: _d(j['z']),
      fill: j['fill'] as String?,
      gradient: j['gradient'] as String?,
      color: j['color'] as String?,
      edge: j['edge'] as String?,
      edgeWidth: _d(j['edgeWidth'], 1.0),
      edgeOpacity: _d(j['edgeOpacity'], 1.0),
      blur: _d(j['blur']),
      startDeg: _d(j['startDeg']),
      sweepDeg: _d(j['sweepDeg'], 360.0),
      closed: (j['closed'] as bool?) ?? false,
      smooth: (j['smooth'] as bool?) ?? false,
      glow: (j['glow'] as bool?) ?? false,
      raw: j,
    );
  }

  static double _d(Object? v, [double fallback = 0.0]) =>
      v is num ? v.toDouble() : fallback;
}

class EmblemPoint {
  final double x;
  final double y;
  const EmblemPoint(this.x, this.y);
}

/// The volumetric (shell + spine + ribs) organism shape, used by organisms that
/// are modelled as real 3D domes rather than flat glyphs.
class EmblemVolume {
  final String shellType; // bivalve | ellipsoid | none
  final double width;
  final double height;
  final double thickness;
  final double gap;
  final double tilt;
  final double offsetX;
  final double offsetY;
  final List<EmblemPoint> spine;
  final double spineRadius;
  final List<EmblemPoint> antennae; // flattened pairs per antenna, see renderer
  final int ribCount;
  final EmblemPoint ribFrom;
  final EmblemPoint ribTo;
  final double ribLength;
  final double ribFalloff;
  final double ribRadius;
  final double ribAngle;
  final bool ribMirror;

  const EmblemVolume({
    required this.shellType,
    required this.width,
    required this.height,
    required this.thickness,
    required this.gap,
    required this.tilt,
    required this.offsetX,
    required this.offsetY,
    required this.spine,
    required this.spineRadius,
    required this.antennae,
    required this.ribCount,
    required this.ribFrom,
    required this.ribTo,
    required this.ribLength,
    required this.ribFalloff,
    required this.ribRadius,
    required this.ribAngle,
    required this.ribMirror,
  });

  factory EmblemVolume.fromJson(Map<String, dynamic> j) {
    final Map<String, dynamic>? shell =
        j['shell'] as Map<String, dynamic>?;
    final Map<String, dynamic>? ribs = j['ribs'] as Map<String, dynamic>?;
    final List<dynamic> offset =
        (shell?['offset'] as List<dynamic>?) ?? const <dynamic>[0, 0];
    final List<EmblemPoint> antennaPts = <EmblemPoint>[];
    for (final dynamic line in (j['antennae'] as List<dynamic>? ?? const [])) {
      for (final dynamic p in (line as List<dynamic>)) {
        antennaPts.add(EmblemPoint(
            ((p as List<dynamic>)[0] as num).toDouble(),
            (p[1] as num).toDouble()));
      }
      antennaPts.add(const EmblemPoint(double.nan, double.nan)); // separator
    }
    return EmblemVolume(
      shellType: (shell?['type'] as String?) ?? 'none',
      width: EmblemLayer._d(shell?['width']),
      height: EmblemLayer._d(shell?['height']),
      thickness: EmblemLayer._d(shell?['thickness']),
      gap: EmblemLayer._d(shell?['gap']),
      tilt: EmblemLayer._d(shell?['tilt']),
      offsetX: EmblemLayer._d(offset.isNotEmpty ? offset[0] : null),
      offsetY: EmblemLayer._d(offset.length > 1 ? offset[1] : null),
      spine: <EmblemPoint>[
        for (final dynamic p in (j['spineline'] as List<dynamic>? ?? const []))
          EmblemPoint(
              ((p as List<dynamic>)[0] as num).toDouble(),
              (p[1] as num).toDouble()),
      ],
      spineRadius: EmblemLayer._d(j['spineRadius']),
      antennae: antennaPts,
      ribCount: ((ribs?['count'] as num?) ?? 0).toInt(),
      ribFrom: _pair(ribs?['from']),
      ribTo: _pair(ribs?['to']),
      ribLength: EmblemLayer._d(ribs?['length']),
      ribFalloff: EmblemLayer._d(ribs?['falloff']),
      ribRadius: EmblemLayer._d(ribs?['radius']),
      ribAngle: EmblemLayer._d(ribs?['angle'], 90.0),
      ribMirror: (ribs?['mirror'] as bool?) ?? true,
    );
  }

  static EmblemPoint _pair(Object? v) {
    if (v is List<dynamic> && v.length >= 2) {
      return EmblemPoint((v[0] as num).toDouble(), (v[1] as num).toDouble());
    }
    return const EmblemPoint(0, 0);
  }
}
