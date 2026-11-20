import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:planish/src/l10n/l10n.dart';
import 'package:planish/src/log/log.dart';

enum _Tool { pen, rectangle }

class _Stroke {
  _Stroke(this.tool, this.color, this.points);

  final _Tool tool;
  final Color color;
  final List<Offset> points; // image coordinates
}

/// Lets the user draw on a screenshot. Pops with the PNG bytes of the
/// annotated image, or null when dismissed.
class AnnotatePage extends StatefulWidget {
  const AnnotatePage({super.key, required this.image});

  final Uint8List image;

  @override
  State<AnnotatePage> createState() => _AnnotatePageState();
}

class _AnnotatePageState extends State<AnnotatePage> {
  // The web widget's annotation colours, so both kinds of report look alike.
  static const List<Color> _palette = <Color>[
    Color(0xFFE5484D),
    Color(0xFFFFB300),
    Color(0xFF245BEE),
    Color(0xFF12A15F),
  ];

  ui.Image? _image;
  final List<_Stroke> _strokes = <_Stroke>[];
  _Tool _tool = _Tool.pen;
  Color _color = _palette.first;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    unawaited(_decode());
  }

  Future<void> _decode() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.image);
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (mounted) {
        setState(() => _image = frame.image);
      } else {
        frame.image.dispose();
      }
    } on Object catch (e, s) {
      Log.warning(
        'Screenshot could not be decoded',
        error: e,
        stackTrace: s,
        tag: 'feedback',
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  // The canvas is letterboxed inside the available box; map taps back to
  // image pixels so strokes survive rotation and export at full size.
  Rect _fit(Size box) {
    final img = _image!;
    final scale = (box.width / img.width).clamp(0.0, box.height / img.height);
    final size = Size(img.width * scale, img.height * scale);
    return Alignment.center.inscribe(size, Offset.zero & box);
  }

  Offset _toImage(Offset local, Rect fit) => Offset(
    ((local.dx - fit.left) / fit.width * _image!.width).clamp(
      0,
      _image!.width.toDouble(),
    ),
    ((local.dy - fit.top) / fit.height * _image!.height).clamp(
      0,
      _image!.height.toDouble(),
    ),
  );

  Future<void> _done() async {
    setState(() => _exporting = true);
    Uint8List? result;
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final img = _image!;
      canvas.drawImage(img, Offset.zero, Paint());
      _paintStrokes(canvas, _strokes, 1, strokeScale: img.width / 400);
      final out = await recorder.endRecording().toImage(img.width, img.height);
      final bytes = await out.toByteData(format: ui.ImageByteFormat.png);
      out.dispose();
      result = bytes?.buffer.asUint8List();
    } on Object catch (e, s) {
      Log.warning(
        'Annotation export failed',
        error: e,
        stackTrace: s,
        tag: 'feedback',
      );
    }
    if (mounted) {
      // null: the form keeps the original screenshot.
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.planishStrings;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.annotate),
        actions: [
          IconButton(
            tooltip: s.undo,
            icon: const Icon(Icons.undo),
            onPressed: _strokes.isEmpty
                ? null
                : () => setState(_strokes.removeLast),
          ),
          IconButton(
            tooltip: s.clear,
            icon: const Icon(Icons.delete_outline),
            onPressed: _strokes.isEmpty ? null : () => setState(_strokes.clear),
          ),
          TextButton(
            onPressed: _image == null || _exporting ? null : _done,
            child: Text(s.done),
          ),
        ],
      ),
      body: _image == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ColoredBox(
                    color: colors.surfaceContainerHighest,
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints c) {
                        final fit = _fit(c.biggest);
                        return GestureDetector(
                          onPanStart: (DragStartDetails d) => setState(() {
                            _strokes.add(
                              _Stroke(_tool, _color, <Offset>[
                                _toImage(d.localPosition, fit),
                              ]),
                            );
                          }),
                          onPanUpdate: (DragUpdateDetails d) => setState(() {
                            final p = _toImage(d.localPosition, fit);
                            if (_tool == _Tool.rectangle &&
                                _strokes.last.points.length > 1) {
                              _strokes.last.points[1] = p;
                            } else {
                              _strokes.last.points.add(p);
                            }
                          }),
                          child: CustomPaint(
                            size: c.biggest,
                            painter: _AnnotationPainter(_image!, _strokes, fit),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        SegmentedButton<_Tool>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment<_Tool>(
                              value: _Tool.pen,
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: s.pen,
                            ),
                            ButtonSegment<_Tool>(
                              value: _Tool.rectangle,
                              icon: const Icon(Icons.crop_square),
                              tooltip: s.rectangle,
                            ),
                          ],
                          selected: <_Tool>{_tool},
                          onSelectionChanged: (Set<_Tool> v) =>
                              setState(() => _tool = v.first),
                        ),
                        const Spacer(),
                        for (final Color c in _palette)
                          Semantics(
                            button: true,
                            selected: c == _color,
                            label: s.color,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => setState(() => _color = c),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: c == _color
                                          ? colors.onSurface
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

void _paintStrokes(
  Canvas canvas,
  List<_Stroke> strokes,
  double scale, {
  double strokeScale = 1,
}) {
  for (final stroke in strokes) {
    final paint = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * strokeScale * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pts = stroke.points.map((Offset p) => p * scale).toList();
    if (stroke.tool == _Tool.rectangle && pts.length >= 2) {
      canvas.drawRect(Rect.fromPoints(pts.first, pts.last), paint);
    } else if (pts.length == 1) {
      canvas.drawCircle(
        pts.first,
        paint.strokeWidth / 2,
        paint..style = PaintingStyle.fill,
      );
    } else {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }
}

class _AnnotationPainter extends CustomPainter {
  _AnnotationPainter(this.image, this.strokes, this.fit);

  final ui.Image image;
  final List<_Stroke> strokes;
  final Rect fit;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      fit,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas
      ..save()
      ..translate(fit.left, fit.top);
    _paintStrokes(
      canvas,
      strokes,
      fit.width / image.width,
      strokeScale: image.width / 400,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AnnotationPainter old) => true;
}
