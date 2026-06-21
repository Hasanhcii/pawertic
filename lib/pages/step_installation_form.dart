import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../core/app_locale.dart';
import '../core/theme_notifier.dart';
import '../data/vehicle_data.dart';
import '../models/job_model.dart';
import '../services/job_store.dart';
import '../widgets/notify.dart';
import '../widgets/signature_pad.dart';

class StepInstallationForm extends StatefulWidget {
  final String type, company, technician;
  const StepInstallationForm({
    required this.type,
    required this.company,
    required this.technician,
    super.key,
  });

  @override
  State<StepInstallationForm> createState() => _StepInstallationFormState();
}

class _StepInstallationFormState extends State<StepInstallationForm> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final ImagePicker _picker = ImagePicker();

  // Step 1 Data
  String _selCat = vehicleData.keys.first;
  late String _selBrand;
  late String _selModel;
  final TextEditingController _yearCtrl = TextEditingController();

  // Step 2 Data
  String _selDeviceModel = deviceModels.first;
  final TextEditingController _p1 = TextEditingController();
  final TextEditingController _p2 = TextEditingController();
  final TextEditingController _p3 = TextEditingController();
  final TextEditingController _imeiCtrl = TextEditingController();
  final TextEditingController _simCtrl = TextEditingController();
  final TextEditingController _receiverCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  String _signature = '';
  List<String> _selectedAccessories = [];
  String _deliveredTo = 'Müşteri'; // Müşteri veya Tekniker
  String _serviceResult = 'Cihaz bakıma alındı'; // Servis için

  @override
  void initState() {
    super.initState();
    _selBrand = vehicleData[_selCat]!.keys.first;
    _selModel = vehicleData[_selCat]![_selBrand]!.first;
  }

  void _nextPage() {
    if (_currentStep < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _save() async {
    if (_p1.text.isEmpty || _p2.text.isEmpty || _p3.text.isEmpty || _imeiCtrl.text.isEmpty) {
      Notify.show(context, AppLocale.t('required_fields'), isError: true);
      return;
    }

    if (widget.type == 'Servis' && _notesCtrl.text.trim().isEmpty) {
      Notify.show(context, "Servis nedeni girmek zorunludur!", isError: true);
      return;
    }

    Notify.showLoading(context, AppLocale.t('saving'));

    try {
      final job = JobModel(
        id: "${DateTime.now().millisecondsSinceEpoch}",
        jobType: widget.type,
        companyName: widget.company,
        plate: "${_p1.text} ${_p2.text} ${_p3.text}".trim().toUpperCase(),
        category: _selCat,
        brand: _selBrand,
        model: _selModel,
        modelYear: _yearCtrl.text,
        deviceModel: _selDeviceModel,
        imei: _imeiCtrl.text,
        simNo: _simCtrl.text,
        deliveredTo: widget.type == 'Demontaj' ? _deliveredTo : '',
        receiverName: widget.type == 'Demontaj' ? _receiverCtrl.text : '',
        notes: widget.type == 'Servis' ? "[$_serviceResult] ${_notesCtrl.text}" : _notesCtrl.text,
        signature: _signature,
        accessories: _selectedAccessories.join(','),
        technician: widget.technician,
        isCompleted: true,
        date: DateTime.now(),
      );

      await JobStore.batchAddOrUpdate([job]);

      if (!mounted) return;
      Navigator.pop(context); // Close loading
      Notify.show(context, AppLocale.t('save_success'));
      Navigator.pop(context); // Go back to panel
    } catch (e) {
      if (mounted) Navigator.pop(context);
      Notify.show(context, "Hata: $e", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = ThemeNotifier.isDarkMode;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 2,
            backgroundColor: isDark ? Colors.white10 : Colors.black12,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6200EE)),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (idx) => setState(() => _currentStep = idx),
        children: [
          _buildStep1(),
          _buildStep2(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("ARAÇ BİLGİLERİ", Icons.directions_car),
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
          const SizedBox(height: 10),
          _field("Model Yılı", _yearCtrl, null, Icons.calendar_today, k: TextInputType.number),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    bool isDark = ThemeNotifier.isDarkMode;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("KURULUM DETAYLARI", Icons.settings),
          const SizedBox(height: 20),
          _searchDrop("Cihaz Modeli", _selDeviceModel, deviceModels, (v) => setState(() => _selDeviceModel = v), Icons.device_hub),
          const SizedBox(height: 20),
          const Text("PLAKA", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            _pBox(_p1, 2, "34", true),
            const SizedBox(width: 8),
            _pBox(_p2, 3, "ABC", false),
            const SizedBox(width: 8),
            _pBox(_p3, 4, "1234", true)
          ]),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _field("Cihaz IMEI", _imeiCtrl, null, Icons.qr_code_scanner, k: TextInputType.number)),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: () => _robustScan(isImei: true),
                icon: const Icon(Icons.camera_alt),
                style: IconButton.styleFrom(minimumSize: const Size(55, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _field("SIM Kart No / Tel", _simCtrl, null, Icons.sim_card_outlined, k: TextInputType.phone)),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: () => _robustScan(isImei: false),
                icon: const Icon(Icons.camera_alt),
                style: IconButton.styleFrom(minimumSize: const Size(55, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              ),
            ],
          ),
          if (widget.type == 'Demontaj') ...[
            const SizedBox(height: 25),
            _sectionTitle("CİHAZ TESLİMATI", Icons.local_shipping_outlined),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text("Müşteriye Teslim"),
                    selected: _deliveredTo == 'Müşteri',
                    onSelected: (v) => setState(() => _deliveredTo = 'Müşteri'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Text("Teknik Servis"),
                    selected: _deliveredTo == 'Tekniker',
                    onSelected: (v) => setState(() => _deliveredTo = 'Tekniker'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _field(
              _deliveredTo == 'Müşteri' ? "Teslim Alan Müşteri Ad Soyad" : "Teslim Alan Tekniker Ad Soyad",
              _receiverCtrl,
              null,
              Icons.person_outline,
            ),
          ],
          if (widget.type == 'Servis') ...[
            const SizedBox(height: 25),
            _sectionTitle("SERVİS DURUMU", Icons.build_circle_outlined),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text("Cihaz Bakıma Alındı"),
                    selected: _serviceResult == 'Cihaz bakıma alındı',
                    onSelected: (v) => setState(() => _serviceResult = 'Cihaz bakıma alındı'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Text("Sorun Giderildi"),
                    selected: _serviceResult == 'Cihaz sorunu giderildi',
                    onSelected: (v) => setState(() => _serviceResult = 'Cihaz sorunu giderildi'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 25),
          if (widget.type != 'Servis') ...[
            _multiSelectDrop(AppLocale.t('accessories'), _selectedAccessories, accessoriesList, Icons.extension_outlined),
            const SizedBox(height: 20),
          ],
          _field(widget.type == 'Servis' ? "Servis Nedeni (Zorunlu)" : AppLocale.t('notes'), _notesCtrl, null, Icons.note_add_outlined),
          const SizedBox(height: 25),
          const Text("İMZA", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _showSignaturePad(),
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: _signature.isEmpty
                  ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.edit_outlined, color: Colors.grey.withOpacity(0.5)),
                      const SizedBox(height: 5),
                      Text(AppLocale.t('add_signature'), style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 12)),
                    ])
                  : Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.memory(base64Decode(_signature), fit: BoxFit.contain),
                    ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeNotifier.isDarkMode ? const Color(0xFF151515) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _prevPage,
                child: const Text("GERİ"),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(55),
                backgroundColor: const Color(0xFF6200EE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: _currentStep == 1 ? _save : _nextPage,
              child: Text(_currentStep == 1 ? "TAMAMLA" : "İLERİ"),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignaturePad() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SignaturePad(onSave: (val) => setState(() => _signature = val)),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6200EE), size: 20),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
      ],
    );
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

  Widget _multiSelectDrop(String l, List<String> selected, List<String> items, IconData icon) {
    bool isDark = ThemeNotifier.isDarkMode;
    String display = selected.isEmpty ? "Seçim Yapın" : selected.join(', ');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
      GestureDetector(
          onTap: () => _showMultiSelectDialog(l, items, selected),
          child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(top: 6, bottom: 12),
              decoration: BoxDecoration(
                  color: isDark ? Colors.black : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05))),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                  child: Row(children: [
                    Icon(icon, size: 18, color: const Color(0xFF6200EE)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(display, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis))
                  ]),
                ),
                const Icon(Icons.add_circle_outline, color: Color(0xFF6200EE), size: 20)
              ])))
    ]);
  }

  void _showMultiSelectDialog(String title, List<String> items, List<String> selected) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: ThemeNotifier.isDarkMode ? const Color(0xFF151515) : Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        builder: (ctx) {
          return StatefulBuilder(builder: (ctx, setLocalState) {
            return Container(
                padding: const EdgeInsets.all(20),
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("TAMAM", style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                      child: ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (c, i) => const Divider(height: 1),
                          itemBuilder: (c, i) {
                            final item = items[i];
                            final isSelected = selected.contains(item);
                            return CheckboxListTile(
                                title: Text(item),
                                value: isSelected,
                                activeColor: const Color(0xFF6200EE),
                                checkColor: Colors.white,
                                controlAffinity: ListTileControlAffinity.trailing,
                                onChanged: (v) {
                                  setLocalState(() {
                                    if (v == true) selected.add(item);
                                    else selected.remove(item);
                                  });
                                  setState(() {});
                                });
                          }))
                ]));
          });
        });
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

  Widget _pBox(TextEditingController c, int l, String h, bool n) => Expanded(
      child: TextField(
          controller: c,
          maxLength: l,
          textAlign: TextAlign.center,
          style: TextStyle(color: ThemeNotifier.isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
          keyboardType: n ? TextInputType.number : TextInputType.text,
          inputFormatters: [UpperCaseTextFormatter()],
          decoration: InputDecoration(hintText: h, counterText: "", filled: true, fillColor: ThemeNotifier.isDarkMode ? Colors.black : const Color(0xFFF8F9FA), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))));

  Widget _field(String l, TextEditingController c, TextInputFormatter? f, IconData icon, {TextInputType? k}) => TextField(
      controller: c,
      keyboardType: k,
      style: TextStyle(color: ThemeNotifier.isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.w500),
      inputFormatters: f != null ? [f] : null,
      decoration: InputDecoration(
          labelText: l,
          labelStyle: const TextStyle(fontSize: 13),
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF6200EE)),
          filled: true,
          fillColor: ThemeNotifier.isDarkMode ? Colors.black : const Color(0xFFF8F9FA),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 16)));

  Future<void> _robustScan({required bool isImei}) async {
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
    final img = await _picker.pickImage(source: source);
    if (img == null) return;

    Notify.showLoading(context, "Metin taranıyor...");
    final input = InputImage.fromFilePath(img.path);
    final recognizer = TextRecognizer();
    final res = await recognizer.processImage(input);
    Navigator.pop(context); // Close loading

    String foundText = "";
    for (TextBlock block in res.blocks) {
      for (TextLine line in block.lines) {
        String digits = line.text.replaceAll(RegExp(r'[^0-9]'), '');
        if (isImei && digits.length >= 14) {
          foundText = digits;
          break;
        } else if (!isImei && digits.length >= 10) {
          foundText = digits;
          break;
        }
      }
      if (foundText.isNotEmpty) break;
    }
    recognizer.close();

    if (foundText.isNotEmpty) {
      setState(() {
        if (isImei) _imeiCtrl.text = foundText;
        else _simCtrl.text = foundText;
      });
      Notify.show(context, "Numara başarıyla okundu.");
    } else {
      Notify.show(context, "Numara tespit edilemedi. Lütfen manuel giriniz.", isError: true);
    }
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) => n.copyWith(text: n.text.toUpperCase());
}
