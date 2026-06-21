import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_locale.dart';
import '../core/theme_notifier.dart';
import '../widgets/notify.dart';
import '../data/vehicle_data.dart';

class AdminWiringPage extends StatefulWidget {
  const AdminWiringPage({super.key});

  @override
  State<AdminWiringPage> createState() => _AdminWiringPageState();
}

class _AdminWiringPageState extends State<AdminWiringPage> {
  final _detailsCtrl = TextEditingController();
  
  String _selCat = vehicleData.keys.first;
  late String _selBrand;
  late String _selModel;
  
  List<XFile> _images = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _selBrand = vehicleData[_selCat]!.keys.first;
    _selModel = vehicleData[_selCat]![_selBrand]!.first;
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) setState(() => _images.addAll(picked));
  }

  Future<void> _save() async {
    if (_images.isEmpty) {
      Notify.show(context, "Lütfen en az bir fotoğraf ekleyin", isError: true);
      return;
    }

    setState(() => _isUploading = true);
    Notify.showLoading(context, "Yükleniyor...");

    try {
      List<String> imageUrls = [];
      for (int i = 0; i < _images.length; i++) {
        final img = _images[i];
        // En basit isimlendirme formatı (özel karakter ihtimalini sıfırlar)
        String ext = img.path.split('.').last.toLowerCase();
        if (ext != 'jpg' && ext != 'jpeg' && ext != 'png') ext = 'jpg';
        String fileName = "diagram_${DateTime.now().millisecondsSinceEpoch}_$i.$ext";
        
        final storageRef = FirebaseStorage.instance.ref().child('wiring_diagrams').child(fileName);
        
        // Dosyayı yükle ve tamamlanmasını bekle
        await storageRef.putFile(
          File(img.path), 
          SettableMetadata(contentType: 'image/$ext')
        );
        
        // Yükleme bittikten sonra URL'yi ref üzerinden alalım
        // (Snapshot yerine doğrudan ref üzerinden almak daha kararlıdır)
        String downloadUrl = await storageRef.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      await FirebaseFirestore.instance.collection('wiring_diagrams').add({
        'model': _selModel,
        'category': _selCat,
        'brand': _selBrand,
        'details': _detailsCtrl.text,
        'images': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context); // Close loading
      Navigator.pop(context); // Close page
      Notify.show(context, "Şema başarıyla eklendi");
    } catch (e) {
      if (mounted) Navigator.pop(context); 
      Notify.show(context, "Hata: ${e.toString()}", isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = ThemeNotifier.isDarkMode;
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Şema Ekle")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle("ARAÇ SEÇİMİ", Icons.directions_car),
          const SizedBox(height: 20),
          _searchDrop(AppLocale.t('category'), _selCat, vehicleData.keys.toList(), (v) {
            setState(() {
              _selCat = v;
              _selBrand = vehicleData[v]!.keys.first;
              _selModel = vehicleData[v]![_selBrand]!.first;
            });
          }, Icons.category_outlined),
          _searchDrop(AppLocale.t('brand'), _selBrand, vehicleData[_selCat]!.keys.toList(), (v) {
            setState(() {
              _selBrand = v;
              _selModel = vehicleData[_selCat]![v]!.first;
            });
          }, Icons.branding_watermark_outlined),
          _searchDrop(AppLocale.t('model'), _selModel, vehicleData[_selCat]![_selBrand]!, (v) {
            setState(() => _selModel = v);
          }, Icons.model_training_outlined),
          
          const SizedBox(height: 25),
          _sectionTitle("ŞEMA DETAYLARI", Icons.description_outlined),
          const SizedBox(height: 15),
          TextField(
            controller: _detailsCtrl, 
            maxLines: 3, 
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: "Bağlantı noktaları, kablo renkleri vb. detaylar...",
              filled: true,
              fillColor: isDark ? Colors.black : const Color(0xFFF8F9FA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
            )
          ),
          
          const SizedBox(height: 25),
          _sectionTitle("FOTOĞRAFLAR", Icons.collections_outlined),
          const SizedBox(height: 15),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ..._images.map((img) => Stack(children: [
                ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(File(img.path), width: 100, height: 100, fit: BoxFit.cover)),
                Positioned(top: 5, right: 5, child: GestureDetector(onTap: () => setState(() => _images.remove(img)), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16))))
              ])),
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: 100, 
                  height: 100, 
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), 
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFF6200EE).withOpacity(0.2))
                  ), 
                  child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, color: Color(0xFF6200EE)), SizedBox(height: 4), Text("Ekle", style: TextStyle(fontSize: 12, color: Color(0xFF6200EE), fontWeight: FontWeight.bold))]),
                ),
              )
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity, 
            height: 60, 
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), backgroundColor: const Color(0xFF6200EE), foregroundColor: Colors.white),
              onPressed: _isUploading ? null : _save, 
              child: const Text("ŞEMAYI KAYDET", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
            )
          )
        ]),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(children: [Icon(icon, color: const Color(0xFF6200EE), size: 18), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1))]);
  }

  Widget _searchDrop(String l, String v, List<String> i, Function(String) o, IconData icon) {
    bool isDark = ThemeNotifier.isDarkMode;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
      GestureDetector(
          onTap: () => _showSearchableDialog(l, i, o),
          child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(top: 6, bottom: 12),
              decoration: BoxDecoration(
                  color: isDark ? Colors.black : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05))),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Icon(icon, size: 18, color: const Color(0xFF6200EE)),
                  const SizedBox(width: 12),
                  Text(v, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w500))
                ]),
                const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20)
              ])))
    ]);
  }

  void _showSearchableDialog(String title, List<String> items, Function(String) onSelect) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: ThemeNotifier.isDarkMode ? const Color(0xFF151515) : Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        builder: (ctx) {
          String query = "";
          return StatefulBuilder(builder: (ctx, setLocalState) {
            final filtered = items.where((i) => i.toLowerCase().contains(query.toLowerCase())).toList();
            return Container(
                padding: const EdgeInsets.all(20),
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  TextField(decoration: const InputDecoration(hintText: "Ara...", prefixIcon: Icon(Icons.search)), onChanged: (v) => setLocalState(() => query = v)),
                  const SizedBox(height: 15),
                  Expanded(child: ListView.separated(itemCount: filtered.length, separatorBuilder: (c, i) => const Divider(), itemBuilder: (c, i) => ListTile(title: Text(filtered[i]), onTap: () { onSelect(filtered[i]); Navigator.pop(ctx); })))
                ]));
          });
        });
  }
}
