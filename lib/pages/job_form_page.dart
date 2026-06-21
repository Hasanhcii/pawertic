import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../core/app_locale.dart';
import '../core/theme_notifier.dart';
import '../services/job_store.dart';
import '../models/job_model.dart';
import '../data/vehicle_data.dart';
import '../widgets/notify.dart';
import '../services/plate_recognition_service.dart';
import '../widgets/signature_pad.dart';

class VehicleEntry {
  String selCat = vehicleData.keys.first; late String selBrand; late String selModel;
  final p1 = TextEditingController(), p2 = TextEditingController(), p3 = TextEditingController(), imeiCtrl = TextEditingController(), simCtrl = TextEditingController(), camImei = TextEditingController(), notesCtrl = TextEditingController(), yearCtrl = TextEditingController();
  String signature = '';
  List<String> selectedAccessories = [];
  VehicleEntry() { 
    selBrand = vehicleData[selCat]!.keys.first; 
    selModel = vehicleData[selCat]![selBrand]!.first; 
  }
}

class JobFormPage extends StatefulWidget {
  final String type, company, technician; final JobModel? editJob;
  const JobFormPage({required this.type, required this.company, required this.technician, this.editJob, super.key});
  @override
  State<JobFormPage> createState() => _JobFormPageState();
}

class _JobFormPageState extends State<JobFormPage> {
  final List<VehicleEntry> _entries = [VehicleEntry()]; 
  final picker = ImagePicker();
  final _plateService = PlateRecognitionService();

  @override
  void initState() { 
    super.initState(); 
    if (widget.editJob != null) { 
      final e = _entries[0], j = widget.editJob!; 
      e.selCat = j.category; 
      e.selBrand = j.brand; 
      e.selModel = j.model; 
      e.yearCtrl.text = j.modelYear;
      e.imeiCtrl.text = j.imei; 
      e.simCtrl.text = j.simNo; 
      e.camImei.text = j.cameraImei; 
      e.notesCtrl.text = j.notes;
      e.signature = j.signature;
      e.selectedAccessories = j.accessories.split(',').where((s) => s.isNotEmpty).toList();
      var p = j.plate.split(' '); 
      if (p.length == 3) { e.p1.text = p[0]; e.p2.text = p[1]; e.p3.text = p[2]; } 
    } 
  }

  @override
  void dispose() {
    _plateService.dispose();
    super.dispose();
  }

  Future<void> _save(bool isCompleted) async {
    for (var e in _entries) {
      if (isCompleted && (e.p1.text.isEmpty || e.p2.text.isEmpty || e.p3.text.isEmpty || e.imeiCtrl.text.isEmpty || e.simCtrl.text.isEmpty)) {
        Notify.show(context, AppLocale.t('required_fields'), isError: true);
        return;
      }
    }
    
    Notify.showLoading(context, AppLocale.t('saving'));
    
    try {
      List<JobModel> toSave = [];
      for (var e in _entries) {
        String id = widget.editJob?.id ?? "${DateTime.now().millisecondsSinceEpoch}${_entries.indexOf(e)}";
        toSave.add(JobModel(
          id: id, 
          jobType: widget.type, 
          companyName: widget.company, 
          plate: "${e.p1.text} ${e.p2.text} ${e.p3.text}".trim().toUpperCase(), 
          category: e.selCat, 
          brand: e.selBrand, 
          model: e.selModel, 
          modelYear: e.yearCtrl.text,
          imei: e.imeiCtrl.text, 
          simNo: e.simCtrl.text, 
          cameraImei: e.camImei.text, 
          notes: e.notesCtrl.text,
          signature: e.signature,
          accessories: e.selectedAccessories.join(','),
          technician: widget.technician, 
          isCompleted: isCompleted, 
          date: widget.editJob?.date ?? DateTime.now()
        ));
      }
      
      await JobStore.batchAddOrUpdate(toSave);
      
      if (!mounted) return;
      Navigator.pop(context);
      Notify.show(context, AppLocale.t('save_success'));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) Navigator.pop(context); 
      Notify.show(context, "Hata: $e", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = ThemeNotifier.isDarkMode;
    return Scaffold(
      appBar: AppBar(title: Text(widget.type)),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.apartment, color: Color(0xFF6200EE)), const SizedBox(width: 10), Expanded(child: Text(widget.company, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)))]),
        const SizedBox(height: 25), ..._entries.map((e) => _buildCard(e, _entries.indexOf(e))),
        if (widget.editJob == null) Padding(padding: const EdgeInsets.only(top: 10), child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: isDark ? const Color(0xFF151515) : Colors.white, foregroundColor: isDark ? Colors.white : Colors.black, minimumSize: const Size.fromHeight(60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 2), icon: const Icon(Icons.add_circle_outline), label: Text(AppLocale.t('add_vehicle'), style: const TextStyle(fontWeight: FontWeight.bold)), onPressed: () => setState(() => _entries.add(VehicleEntry())))),
        const SizedBox(height: 40), SizedBox(width: double.infinity, height: 65, child: ElevatedButton(style: ElevatedButton.styleFrom(shape: const StadiumBorder(), elevation: 5), onPressed: () => _save(true), child: Text(AppLocale.t('save'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
        const SizedBox(height: 15), SizedBox(width: double.infinity, height: 65, child: OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: isDark ? Colors.white70 : Colors.black54, side: BorderSide(color: isDark ? Colors.white24 : Colors.black12), shape: const StadiumBorder()), onPressed: () => _save(false), child: Text(AppLocale.t('draft'), style: const TextStyle(fontWeight: FontWeight.bold))))
      ])),
    );
  }

  Widget _buildCard(VehicleEntry e, int idx) {
    bool isDark = ThemeNotifier.isDarkMode;
    return Container(margin: const EdgeInsets.only(bottom: 25), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: isDark ? const Color(0xFF151515) : Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: isDark ? null : [const BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF6200EE).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text("${idx + 1}. ARAÇ", style: const TextStyle(color: Color(0xFF6200EE), fontSize: 12, fontWeight: FontWeight.bold))),
        if(_entries.length > 1 && widget.editJob == null) IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent), onPressed: () => setState(() => _entries.removeAt(idx)))
      ]),
      const SizedBox(height: 20),
      _searchDrop(AppLocale.t('category'), e.selCat, vehicleData.keys.toList(), (v) => setState(() { e.selCat = v; e.selBrand = vehicleData[v]!.keys.first; e.selModel = vehicleData[v]![e.selBrand]!.first; }), Icons.category_outlined), 
      _searchDrop(AppLocale.t('brand'), e.selBrand, vehicleData[e.selCat]!.keys.toList(), (v) => setState(() { e.selBrand = v; e.selModel = vehicleData[e.selCat]![v]!.first; }), Icons.branding_watermark_outlined), 
      _searchDrop(AppLocale.t('model'), e.selModel, vehicleData[e.selCat]![e.selBrand]!, (v) => setState(() => e.selModel = v), Icons.model_training_outlined),
      const SizedBox(height: 15),
      _field("Model Yılı", e.yearCtrl, null, Icons.calendar_today, k: TextInputType.number),
      
      const SizedBox(height: 25),
      Row(
        children: [
          const Text("PLAKA", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            onPressed: () => _scanPlate(e),
            icon: const Icon(Icons.camera_alt_rounded, size: 20, color: Color(0xFF6200EE)),
            tooltip: AppLocale.t('scan_plate'),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(children: [_pBox(e.p1, 2, "34", true), const SizedBox(width: 8), _pBox(e.p2, 3, "ABC", false), const SizedBox(width: 8), _pBox(e.p3, 4, "1234", true)]), 
      
      const Divider(height: 50), 
      _field("Cihaz IMEI", e.imeiCtrl, null, Icons.qr_code_scanner, k: TextInputType.number), 
      const SizedBox(height: 15), 
      _field("SIM Kart No", e.simCtrl, SimNumberFormatter(), Icons.sim_card_outlined, k: TextInputType.number), 
      const SizedBox(height: 15), 
      _field("Kamera IMEI", e.camImei, null, Icons.camera_outlined, k: TextInputType.number), 
      
      const SizedBox(height: 25),
      Text(AppLocale.t('accessories'), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 0,
        children: accessoriesList.map((acc) {
          final isSelected = e.selectedAccessories.contains(acc);
          return FilterChip(
            label: Text(acc, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87))),
            selected: isSelected,
            onSelected: (val) {
              setState(() {
                if (val) e.selectedAccessories.add(acc);
                else e.selectedAccessories.remove(acc);
              });
            },
            selectedColor: const Color(0xFF6200EE),
            checkmarkColor: Colors.white,
            backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.03),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          );
        }).toList(),
      ),

      const SizedBox(height: 25),
      _field(AppLocale.t('notes'), e.notesCtrl, null, Icons.note_add_outlined),
      
      const SizedBox(height: 25),
      const Text("İMZA", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: () => _showSignaturePad(e),
        child: Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
          ),
          child: e.signature.isEmpty 
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.edit_outlined, color: Colors.grey.withOpacity(0.5)),
                const SizedBox(height: 5),
                Text(AppLocale.t('add_signature'), style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 12)),
              ])
            : Padding(
                padding: const EdgeInsets.all(10),
                child: Image.memory(base64Decode(e.signature), fit: BoxFit.contain),
              ),
        ),
      ),

      const SizedBox(height: 25),
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6200EE).withOpacity(0.1), 
          foregroundColor: const Color(0xFF6200EE), 
          minimumSize: const Size.fromHeight(55), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), 
          elevation: 0
        ), 
        icon: const Icon(Icons.qr_code_scanner), 
        label: Text(AppLocale.t('scan'), style: const TextStyle(fontWeight: FontWeight.bold)), 
        onPressed: () => _robustScan(e)
      )
    ]));
  }

  void _showSignaturePad(VehicleEntry e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SignaturePad(onSave: (val) => setState(() => e.signature = val)),
      ),
    );
  }

  Widget _searchDrop(String l, String v, List<String> i, Function(String) o, IconData icon) {
    bool isDark = ThemeNotifier.isDarkMode;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)), GestureDetector(onTap: () => _showSearchableDialog(l, i, o), child: Container(width: double.infinity, padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(top: 6, bottom: 12), decoration: BoxDecoration(color: isDark ? Colors.black : const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(15), border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Icon(icon, size: 18, color: const Color(0xFF6200EE)), const SizedBox(width: 12), Text(v, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w500))]), const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20)])))]);
  }

  Widget _pBox(TextEditingController c, int l, String h, bool n) => Expanded(child: TextField(controller: c, maxLength: l, textAlign: TextAlign.center, style: TextStyle(color: ThemeNotifier.isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16), keyboardType: n ? TextInputType.number : TextInputType.text, inputFormatters: [UpperCaseTextFormatter()], decoration: InputDecoration(hintText: h, counterText: "", filled: true, fillColor: ThemeNotifier.isDarkMode ? Colors.black : const Color(0xFFF8F9FA), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))));
  
  Widget _field(String l, TextEditingController c, TextInputFormatter? f, IconData icon, {TextInputType? k}) => TextField(controller: c, keyboardType: k, style: TextStyle(color: ThemeNotifier.isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.w500), inputFormatters: f != null ? [f] : null, decoration: InputDecoration(labelText: l, labelStyle: const TextStyle(fontSize: 13), prefixIcon: Icon(icon, size: 20, color: const Color(0xFF6200EE)), filled: true, fillColor: ThemeNotifier.isDarkMode ? Colors.black : const Color(0xFFF8F9FA), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 16)));

  Future<void> _scanPlate(VehicleEntry entry) async {
    final plate = await _plateService.scanPlate();
    if (plate != null) {
      var parts = plate.split(' ');
      if (parts.length == 3) {
        setState(() {
          entry.p1.text = parts[0];
          entry.p2.text = parts[1];
          entry.p3.text = parts[2];
        });
      }
    } else {
      if(mounted) Notify.show(context, AppLocale.t('plate_not_found'), isError: true);
    }
  }

  Future<void> _robustScan(VehicleEntry entry) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: ThemeNotifier.isDarkMode ? const Color(0xFF151515) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 15),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text("Görüntü Kaynağı", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: ThemeNotifier.isDarkMode ? Colors.white : Colors.black)),
            const SizedBox(height: 15),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF6200EE)),
              title: Text("Kamera", style: TextStyle(color: ThemeNotifier.isDarkMode ? Colors.white : Colors.black)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF6200EE)),
              title: Text("Galeri", style: TextStyle(color: ThemeNotifier.isDarkMode ? Colors.white : Colors.black)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );

    if (source == null) return;
    final img = await picker.pickImage(source: source);
    if (img == null) return;
    final input = InputImage.fromFilePath(img.path);
    final recognizer = TextRecognizer();
    final res = await recognizer.processImage(input);
    for (TextBlock block in res.blocks) {
      for (TextLine line in block.lines) {
        String digits = line.text.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length == 15) entry.imeiCtrl.text = digits;
        if (digits.length == 10 && digits.startsWith('5')) {
          entry.simCtrl.text = "${digits.substring(0,3)} ${digits.substring(3,6)} ${digits.substring(6,8)} ${digits.substring(8,10)}";
        }
      }
    }
    recognizer.close();
    if(mounted) setState(() {});
  }

  void _showSearchableDialog(String title, List<String> items, Function(String) onSelect) { 
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: ThemeNotifier.isDarkMode ? const Color(0xFF151515) : Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))), builder: (ctx) { 
      String query = ""; 
      return StatefulBuilder(builder: (ctx, setLocalState) { 
        final filtered = items.where((i) => i.toLowerCase().contains(query.toLowerCase())).toList(); 
        return Container(padding: const EdgeInsets.all(20), height: MediaQuery.of(context).size.height * 0.8, child: Column(children: [Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 15), TextField(decoration: const InputDecoration(hintText: "Ara...", prefixIcon: Icon(Icons.search)), onChanged: (v) => setLocalState(() => query = v)), const SizedBox(height: 15), Expanded(child: ListView.separated(itemCount: filtered.length, separatorBuilder: (c, i) => const Divider(), itemBuilder: (c, i) => ListTile(title: Text(filtered[i]), onTap: () { onSelect(filtered[i]); Navigator.pop(ctx); }))) ])); 
      }); 
    }); 
  }
}

class UpperCaseTextFormatter extends TextInputFormatter { @override TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) => n.copyWith(text: n.text.toUpperCase()); }
class SimNumberFormatter extends TextInputFormatter { @override TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) { String t = n.text.replaceAll(' ', ''); if (t.length > 10) t = t.substring(0, 10); String r = ''; for (int i = 0; i < t.length; i++) { r += t[i]; if ((i == 2 || i == 5 || i == 7) && i != t.length - 1) r += ' '; } return TextEditingValue(text: r, selection: TextSelection.collapsed(offset: r.length)); } }
