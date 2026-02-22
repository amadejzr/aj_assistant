import 'dart:math' as math;

import 'package:flutter/material.dart';

class SealLogo extends StatelessWidget {
  final Color color;
  final Color textColor;
  final double size;

  const SealLogo({
    super.key,
    required this.color,
    required this.textColor,
    this.size = 58,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SealPainter(color: color),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _BowerbirdPainter(color: textColor),
        ),
      ),
    );
  }
}

/// Vermillion seal — slightly irregular circle like a hanko stamp
class _SealPainter extends CustomPainter {
  final Color color;

  _SealPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Slightly irregular circle with subtle wobble
    final path = Path();
    const segments = 36;
    for (var i = 0; i <= segments; i++) {
      final angle = (i / segments) * 2 * math.pi;
      final wobble = 1.0 +
          math.sin(angle * 5) * 0.015 +
          math.cos(angle * 3) * 0.01;
      final r = radius * wobble;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);

    // Inner ring for stamp authenticity
    final innerRing = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius * 0.78, innerRing);
  }

  @override
  bool shouldRepaint(covariant _SealPainter oldDelegate) =>
      color != oldDelegate.color;
}

/// Bowerbird silhouette from SVG path data, scaled to fit within seal
class _BowerbirdPainter extends CustomPainter {
  final Color color;

  _BowerbirdPainter({required this.color});

  static const _svgPaths = [
    // Main bird body
    'M135.31201,93.07075c6.86118,-0.49819 11.70703,3.03677 14.70703,9.03354'
        'c1.22607,2.45054 2.35547,5.30889 4.27588,7.29316'
        'c2.04492,2.11582 4.59668,3.77856 6.94336,5.55571'
        'c1.89258,1.45825 3.68115,3.046 5.354,4.75195'
        'c4.51025,4.56152 8.23096,10.50703 12.19336,15.60029'
        'c2.53857,3.26323 5.45801,5.8979 7.92334,8.92603'
        'c-4.1499,0.85518 -8.73779,0.69741 -12.91992,0.16699'
        'c1.47803,1.91646 3.86719,4.229 5.56348,6.31201'
        'c7.46631,9.17285 11.41113,16.58936 14.68652,27.82324'
        'c0.84521,0.68848 2.80664,1.86328 3.79395,2.49463'
        'c-0.85254,-9.67822 -7.6084,-21.18896 -13.80469,-28.42236'
        'c-1.6626,-1.93945 -3.49512,-3.63574 -5.04639,-5.47705'
        'l-0.11719,-0.14209'
        'c1.19531,0.03369 2.16504,0.06885 3.3501,0.19629'
        'c1.55273,1.0459 3.79102,4.03125 5.06982,5.58105'
        'c8.0376,9.74707 13.32568,20.92822 13.27881,33.76904'
        'c-3.0293,-2.81982 -5.23096,-4.1792 -8.71875,-6.25049'
        'c-3.30908,-12.65332 -8.79785,-21.95508 -17.6748,-31.59229'
        'c-5.30127,-5.75391 -4.49268,-4.60737 -11.67334,-6.73843'
        'c-9.47754,-2.81294 -23.73765,-10.88218 -23.14292,-22.36772'
        'c0.39624,-3.71895 2.55234,-6.0126 6.15542,-6.83394'
        'c-6.1144,5.3064 -3.82017,12.95332 1.50557,17.80269'
        'c8.99414,8.18877 22.54541,11.94272 34.49121,11.71714'
        'c-6.00732,-6.22427 -9.76611,-12.89326 -15.26807,-19.20073'
        'c-1.96289,-2.24238 -4.13818,-4.28818 -6.49658,-6.10854'
        'c-2.99854,-2.31123 -6.27979,-4.18462 -8.58545,-7.24922'
        'c-1.62451,-2.20737 -2.50781,-4.60986 -3.75293,-7.07974'
        'c-2.96997,-5.89336 -9.58096,-9.06387 -15.71001,-5.84531'
        'c-1.44785,0.76025 -2.96982,2.152 -3.42539,3.80566'
        'c-2.89482,-1.15181 -5.32441,-0.20874 -8.12007,0.71865'
        'c2.39766,0.06196 7.77407,0.6271 9.55693,2.279'
        'l-0.13228,0.12891'
        'c0.06519,0.38364 1.2356,1.86621 1.5769,2.45654'
        'c0.64907,1.13159 1.08442,2.3729 1.28437,3.66211'
        'c0.58359,3.64746 -0.70342,7.76982 -0.14487,12.17798'
        'c0.13213,1.05952 0.34893,2.10674 0.64819,3.13154'
        'c3.03662,10.373 12.9813,16.75049 23.23916,18.45513'
        'c4.48828,0.74575 7.68604,-0.1062 11.90771,2.24092'
        'l0.18018,0.10181'
        'c-4.25098,0.57173 -7.71826,0.87349 -12.04541,0.22822'
        'c-12.24902,-1.82446 -24.51035,-10.35176 -26.3647,-23.27915'
        'c-0.23599,-1.73628 -0.30952,-3.49058 -0.21987,-5.24048'
        'c0.17812,-3.58594 1.12632,-8.08271 -1.25654,-11.1416'
        'c-2.36631,-3.03765 -9.23291,-3.28594 -12.95171,-3.68701'
        'c0.16875,-0.24375 0.35347,-0.47622 0.55283,-0.69565'
        'c2.81689,-3.14004 6.50742,-4.18242 10.54058,-4.45166'
        'c2.98389,-2.76313 4.61616,-4.09658 8.79316,-4.60679z',
    // Nest / bower swoosh
    'M123.46699,113.40132l0.03003,0.01743'
        'c-0.02358,0.21973 -2.3896,3.03237 -2.79404,3.59824'
        'c-3.48003,4.8687 -7.60781,12.63384 -7.90239,18.78457'
        'c-0.90835,18.96357 11.9376,30.90205 27.44941,37.87471'
        'c-8.88472,-0.46289 -18.29473,-7.41943 -23.06484,-14.57666'
        'c-1.26914,-1.9043 -2.30713,-3.83936 -3.49834,-5.78174'
        'c0.76772,3.98145 3.00469,7.77979 5.34536,11.02588'
        'c5.9373,8.18994 14.89438,13.67578 24.88828,15.24316'
        'c8.99604,1.41357 19.41401,-0.64893 26.80854,-6.05859'
        'c-1.28613,0.40723 -2.58398,0.77637 -3.89209,1.10303'
        'c-10.56738,2.56934 -21.34819,1.17041 -30.65361,-4.53516'
        'c-11.12344,-6.82178 -17.20752,-16.58496 -20.21646,-28.98149'
        'c5.06499,8.88237 11.03613,15.27788 20.96074,18.76421'
        'c1.36553,0.49512 2.76284,0.89502 4.18257,1.20117'
        'c7.76484,1.61279 16.17598,-0.0791 23.07686,-3.79102'
        'c1.96729,-1.05762 3.76318,-2.33936 5.63232,-3.55664'
        'c-3.01904,4.5498 -9.68701,8.31738 -14.90771,9.56396'
        'c-7.72412,1.84277 -16.02202,0.76172 -23.10146,-2.81543'
        'c-2.29951,-1.16162 -4.07871,-2.4126 -6.25137,-3.73242'
        'c0.20522,0.34863 0.42524,0.68848 0.65947,1.01953'
        'c5.19082,7.4458 15.11938,13.70068 23.98535,15.06738'
        'c13.71973,2.1167 22.60547,-1.91309 33.34277,-9.34424'
        'c-2.26758,4.29932 -6.10107,8.28809 -9.9624,11.16797'
        'c-8.49316,6.31201 -19.14111,9 -29.61284,7.47656'
        'c-10.86665,-1.57617 -20.63306,-7.48242 -27.07646,-16.37402'
        'c-7.20146,-9.88623 -9.44355,-23.73589 -5.52422,-35.3644'
        'c2.12593,-6.30762 6.66724,-13.12764 12.09653,-16.996z',
    // Eye / head detail
    'M175.65381,153.76758c0.35303,0.33545 0.65332,0.71924 0.89648,1.14111'
        'c0.1377,0.24463 0.47607,1.02832 0.2959,1.28174'
        'c-7.98926,11.25879 -22.66553,17.13135 -35.82056,11.7876'
        'c-1.19561,-0.45703 -2.077,-0.9375 -3.16143,-1.59961'
        'c4.87676,1.14258 9.06401,1.64795 14.0855,1.26123'
        'c7.38721,-0.54932 14.32617,-3.74707 19.54395,-9.00439'
        'c1.58643,-1.59814 2.71143,-3.18457 4.16016,-4.86768z',
  ];

  static Path? _cachedPath;
  static Rect? _cachedBounds;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    if (_cachedPath == null) {
      _cachedPath = Path();
      for (final d in _svgPaths) {
        _cachedPath!.addPath(_parseSvgPath(d), Offset.zero);
      }
      _cachedBounds = _cachedPath!.getBounds();
    }

    final bounds = _cachedBounds!;
    final maxDim = math.max(bounds.width, bounds.height);
    final scale = size.width * 0.60 / maxDim;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale, scale);
    canvas.translate(-bounds.center.dx, -bounds.center.dy);
    canvas.drawPath(_cachedPath!, paint);
    canvas.restore();
  }

  static Path _parseSvgPath(String d) {
    final path = Path();
    final tokens = RegExp(
      r'[MmCcLlZz]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?',
    ).allMatches(d).map((m) => m.group(0)!).toList();

    var i = 0;
    double next() => double.parse(tokens[i++]);

    while (i < tokens.length) {
      switch (tokens[i++]) {
        case 'M':
          path.moveTo(next(), next());
        case 'c':
          while (i < tokens.length && _isNum(tokens[i])) {
            path.relativeCubicTo(
              next(), next(), next(), next(), next(), next(),
            );
          }
        case 'l':
          while (i < tokens.length && _isNum(tokens[i])) {
            path.relativeLineTo(next(), next());
          }
        case 'z':
        case 'Z':
          path.close();
      }
    }
    return path;
  }

  static bool _isNum(String s) => RegExp(r'^[-+.\d]').hasMatch(s);

  @override
  bool shouldRepaint(covariant _BowerbirdPainter oldDelegate) =>
      color != oldDelegate.color;
}