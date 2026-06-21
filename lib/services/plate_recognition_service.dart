import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class PlateRecognitionService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String?> scanPlate() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) return null;

    final inputImage = InputImage.fromFilePath(image.path);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

    return _extractPlate(recognizedText.text);
  }

  String? _extractPlate(String text) {
    // Türkiye plakaları için regex: 
    // 01-81 ile başlayan, 
    // Ortada 1-3 harf, 
    // Sonda 2-4 rakam olan formatlar
    // Örn: 34 ABC 123, 06 A 1234, 35 AB 123
    
    // Boşlukları ve gereksiz karakterleri temizle, büyük harfe çevir
    String cleanedText = text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), ' ');
    
    // Genel Türkiye plaka deseni
    // 1. Grup: İl kodu (01-81)
    // 2. Grup: Harfler (A-ZZZ)
    // 3. Grup: Rakamlar (01-9999)
    RegExp plateRegex = RegExp(r'([0-8][0-9])\s*([A-Z]{1,3})\s*(\d{2,4})');
    
    Iterable<RegExpMatch> matches = plateRegex.allMatches(cleanedText);
    
    if (matches.isNotEmpty) {
      RegExpMatch match = matches.first;
      return "${match.group(1)} ${match.group(2)} ${match.group(3)}";
    }
    
    return null;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
