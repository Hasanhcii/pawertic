import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../core/app_locale.dart';
import '../core/theme_notifier.dart';

class SignaturePad extends StatefulWidget {
  final Function(String) onSave;
  const SignaturePad({required this.onSave, super.key});

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  List<Offset?> _points = <Offset?>[];
  final GlobalKey _containerKey = GlobalKey();

  Future<void> _saveSignature() async {
    if (_points.isEmpty) return;

    final RenderBox? renderBox = _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));
    
    // ARKA PLANI ÇİZMİYORUZ (Şeffaf kalması için)
    
    final paint = Paint()
      ..color = Colors.black // Kaydederken siyah kaydediyoruz (daha sonra filtre ile renk değiştirebiliriz)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    for (int i = 0; i < _points.length - 1; i++) {
      if (_points[i] != null && _points[i + 1] != null) {
        canvas.drawLine(_points[i]!, _points[i + 1]!, paint);
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();
    
    widget.onSave(base64Encode(buffer));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = ThemeNotifier.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.7, // Daha da büyük yaptık
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151515) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocale.t('signature'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              TextButton(
                onPressed: () => setState(() => _points.clear()),
                child: Text(AppLocale.t('clear'), style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Expanded(
            child: Container(
              key: _containerKey,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white, // Çizim alanı beyaz
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF6200EE).withOpacity(0.3), width: 2),
              ),
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    RenderBox renderBox = _containerKey.currentContext!.findRenderObject() as RenderBox;
                    _points.add(renderBox.globalToLocal(details.globalPosition));
                  });
                },
                onPanEnd: (details) => _points.add(null),
                child: CustomPaint(
                  painter: SignaturePainter(points: _points),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
                backgroundColor: const Color(0xFF6200EE),
              ),
              onPressed: _saveSignature,
              child: Text(AppLocale.t('save'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black // Çizim yaparken siyah görünsün
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => oldDelegate.points != points;
}
