import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_locale.dart';
import '../core/theme_notifier.dart';
import '../services/job_store.dart';
import '../models/job_model.dart';
import 'job_form_page.dart';

class JobDetailsPage extends StatefulWidget {
  final JobModel job;
  const JobDetailsPage({required this.job, super.key});
  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  @override
  void initState() { 
    super.initState(); 
    JobStore.instance.addListener(_refreshUI); 
  }

  @override
  void dispose() { 
    JobStore.instance.removeListener(_refreshUI); 
    super.dispose(); 
  }

  void _refreshUI() { if(mounted) setState(() {}); }

  @override
  Widget build(BuildContext context) {
    bool isDark = ThemeNotifier.isDarkMode;
    Color statusColor = widget.job.isCompleted ? Colors.green : Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.t('details')),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 15, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.5))
            ),
            child: Center(
              child: Text(
                widget.job.isCompleted ? AppLocale.t('completed') : AppLocale.t('waiting'),
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHeroCard(isDark),
          const SizedBox(height: 25),
          
          _sectionHeader("Müşteri & İş Bilgisi", Icons.business_center_rounded),
          _buildInfoGroup(isDark, [
            _detailRow(Icons.work_outline, "İş Tipi", widget.job.jobType),
            _detailRow(Icons.calendar_today_outlined, "Tarih", DateFormat('dd.MM.yyyy HH:mm').format(widget.job.date)),
            _detailRow(Icons.person_outline, AppLocale.t('technician'), widget.job.technician, isBold: true),
          ]),
          
          const SizedBox(height: 25),
          _sectionHeader("Araç Detayları", Icons.directions_car_filled_rounded),
          _buildInfoGroup(isDark, [
            _detailRow(Icons.numbers_rounded, AppLocale.t('plate'), widget.job.plate, isBold: true),
            _detailRow(Icons.category_outlined, AppLocale.t('category'), widget.job.category),
            _detailRow(Icons.branding_watermark_outlined, AppLocale.t('brand'), "${widget.job.brand} ${widget.job.model}"),
            if (widget.job.modelYear.isNotEmpty)
              _detailRow(Icons.calendar_month_outlined, "Model Yılı", widget.job.modelYear),
          ]),
          
          if (widget.job.jobType != 'Servis' && widget.job.accessories.isNotEmpty) ...[
            const SizedBox(height: 25),
            _sectionHeader(AppLocale.t('accessories'), Icons.extension_outlined),
            _buildInfoGroup(isDark, [
              _detailRow(Icons.add_circle_outline, AppLocale.t('accessories'), widget.job.accessories.replaceAll(',', ', ')),
            ]),
          ],

          if (widget.job.jobType == 'Demontaj' && widget.job.deliveredTo.isNotEmpty) ...[
            const SizedBox(height: 25),
            _sectionHeader("Teslimat Bilgisi", Icons.local_shipping_outlined),
            _buildInfoGroup(isDark, [
              _detailRow(Icons.person_pin_outlined, "Teslim Edilen", widget.job.deliveredTo),
              _detailRow(Icons.person_outline, "Teslim Alan", widget.job.receiverName),
            ]),
          ],
          
          const SizedBox(height: 25),
          _sectionHeader("Cihaz Verileri", Icons.settings_input_component_rounded),
          _buildInfoGroup(isDark, [
            if (widget.job.deviceModel.isNotEmpty)
              _detailRow(Icons.device_hub, "Cihaz Modeli", widget.job.deviceModel),
            _detailRow(Icons.qr_code_2_rounded, "Cihaz IMEI", widget.job.imei),
            _detailRow(Icons.sim_card_rounded, "SIM Kart", widget.job.simNo),
            if(widget.job.cameraImei.isNotEmpty) 
              _detailRow(Icons.videocam_outlined, "Kamera IMEI", widget.job.cameraImei),
          ]),

          if (widget.job.notes.isNotEmpty) ...[
            const SizedBox(height: 25),
            _sectionHeader(AppLocale.t('notes'), Icons.note_outlined),
            _buildInfoGroup(isDark, [
              _detailRow(Icons.description_outlined, AppLocale.t('notes'), widget.job.notes),
            ]),
          ],

          if (widget.job.signature.isNotEmpty) ...[
            const SizedBox(height: 25),
            _sectionHeader(AppLocale.t('signature'), Icons.gesture_rounded),
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.memory(
                    base64Decode(widget.job.signature), 
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 40),
          if (!widget.job.isCompleted) 
            SizedBox(
              width: double.infinity, 
              height: 60, 
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 8,
                  shadowColor: const Color(0xFF6200EE).withOpacity(0.4)
                ), 
                icon: const Icon(Icons.edit_note_rounded),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => JobFormPage(type: widget.job.jobType, company: widget.job.companyName, technician: widget.job.technician, editJob: widget.job))), 
                label: Text(AppLocale.t('save'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
              )
            ),
        ]),
      ),
    );
  }

  Widget _buildHeroCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [const Color(0xFF1E1E1E), const Color(0xFF121212)] : [const Color(0xFF6200EE), const Color(0xFF7C4DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))]
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("FİRMA / MÜŞTERİ", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Text(widget.job.companyName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Row(children: [
          _heroStat(Icons.tag, widget.job.plate),
          const SizedBox(width: 20),
          _heroStat(Icons.build_circle_outlined, widget.job.jobType),
        ])
      ]),
    );
  }

  Widget _heroStat(IconData icon, String label) {
    return Row(children: [
      Icon(icon, color: Colors.white60, size: 16),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _sectionHeader(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(left: 5, bottom: 12), 
    child: Row(children: [
      Icon(icon, size: 20, color: const Color(0xFF6200EE)), 
      const SizedBox(width: 10), 
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5))
    ])
  );

  Widget _buildInfoGroup(bool isDark, List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151515) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(children: rows),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF6200EE).withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: const Color(0xFF6200EE)),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
          ]),
        )
      ]),
    );
  }
}
