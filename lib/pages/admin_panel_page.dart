import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_locale.dart';
import '../core/theme_notifier.dart';
import '../services/job_store.dart';
import '../models/job_model.dart';
import '../helpers/excel_helper.dart';
import '../widgets/app_drawer.dart';
import '../widgets/notify.dart';
import 'job_details_page.dart';

class AdminPanelPage extends StatefulWidget {
  final String username;
  const AdminPanelPage({required this.username, super.key});
  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  String _searchQuery = "";
  final _announcementCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    JobStore.instance.addListener(_refreshUI);
  }

  @override
  void dispose() {
    JobStore.instance.removeListener(_refreshUI);
    _announcementCtrl.dispose();
    super.dispose();
  }

  void _refreshUI() {
    if (mounted) setState(() {});
  }

  Future<void> _sendAnnouncement() async {
    if (_announcementCtrl.text.trim().isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'text': _announcementCtrl.text.trim(),
        'date': FieldValue.serverTimestamp(),
        'sender': widget.username,
      });
      _announcementCtrl.clear();
      if (!mounted) return;
      Notify.show(context, AppLocale.t('announcement_sent'));
    } catch (e) {
      Notify.show(context, "Hata: $e", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = ThemeNotifier.isDarkMode;
    final allJobs = JobStore.jobs;
    
    Map<String, int> performance = {};
    for (var j in allJobs) {
      performance[j.technician] = (performance[j.technician] ?? 0) + 1;
    }
    final sortedTechs = performance.keys.toList()..sort((a, b) => performance[b]!.compareTo(performance[a]!));

    final filteredJobs = allJobs.where((j) {
      final matchesSearch = j.companyName.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                           j.plate.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    return Scaffold(
      drawer: AppDrawer(username: widget.username),
      appBar: AppBar(title: Text(AppLocale.t('admin_panel')), centerTitle: true),
      body: Container(
        height: double.infinity,
        decoration: isDark 
          ? const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black, Color(0xFF100020)])) 
          : const BoxDecoration(color: Color(0xFFF5F5F5)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Hızlı İşlemler
            _sectionHeader("Hızlı İşlemler", Icons.bolt),
            Row(children: [
              _actionCard(Icons.person_add, "Personel Ekle", () {}, Colors.blue),
            ]),
            const SizedBox(height: 30),

            // Duyuru Yayınla
            _sectionHeader(AppLocale.t('publish_announcement'), Icons.campaign_outlined),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: isDark ? const Color(0xFF151515) : Colors.white, borderRadius: BorderRadius.circular(15)),
              child: Row(children: [
                Expanded(child: TextField(controller: _announcementCtrl, decoration: InputDecoration(hintText: AppLocale.t('announcement_hint'), border: InputBorder.none))),
                IconButton(onPressed: _sendAnnouncement, icon: const Icon(Icons.send, color: Color(0xFF6200EE))),
              ]),
            ),
            const SizedBox(height: 30),

            // Personel Performansı
            _sectionHeader(AppLocale.t('personnel_perf'), Icons.bar_chart),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: sortedTechs.length,
                itemBuilder: (c, i) {
                  final tech = sortedTechs[i];
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 15),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF151515) : Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.withOpacity(0.3))),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(performance[tech].toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 5),
                      Text(tech, style: const TextStyle(fontSize: 10, overflow: TextOverflow.ellipsis)),
                    ]),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),

            // Genel İstatistikler
            _sectionHeader(AppLocale.t('stats'), Icons.pie_chart_outline),
            Row(children: [
              _statBox(AppLocale.t('total_jobs'), allJobs.length.toString(), Colors.blue, isDark),
              const SizedBox(width: 10),
              _statBox(AppLocale.t('total_completed'), allJobs.where((j) => j.isCompleted).length.toString(), Colors.green, isDark),
              const SizedBox(width: 10),
              _statBox(AppLocale.t('total_pending'), allJobs.where((j) => !j.isCompleted).length.toString(), Colors.orange, isDark),
            ]),
            const SizedBox(height: 30),

            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _sectionHeader(AppLocale.t('all_jobs'), Icons.list_alt),
              IconButton(icon: const Icon(Icons.download, color: Colors.blue), onPressed: () => ExcelHelper.exportJobs(filteredJobs, context))
            ]),
            TextField(
              decoration: InputDecoration(hintText: "Firma veya Plaka Ara...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: isDark ? const Color(0xFF151515) : Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 10),
            ...filteredJobs.take(10).map((job) => _adminJobCard(job, isDark)),
          ]),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Icon(icon, size: 20, color: const Color(0xFF6200EE)), const SizedBox(width: 10), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]));

  Widget _actionCard(IconData icon, String label, VoidCallback onTap, Color color) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        ]),
      ),
    ),
  );

  Widget _statBox(String label, String value, Color color, bool isDark) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF151515) : Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 5),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
      ]),
    ),
  );

  Widget _adminJobCard(JobModel job, bool isDark) => Card(
    color: isDark ? const Color(0xFF151515) : Colors.white,
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: ListTile(
      title: Text(job.companyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text("${job.technician} - ${job.plate}", style: const TextStyle(fontSize: 12)),
      trailing: Icon(job.isCompleted ? Icons.check_circle : Icons.pending, color: job.isCompleted ? Colors.green : Colors.orange, size: 20),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => JobDetailsPage(job: job))),
    ),
  );
}
