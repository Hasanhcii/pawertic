import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_locale.dart';
import '../core/theme_notifier.dart';
import '../services/job_store.dart';
import '../data/vehicle_data.dart';
import '../widgets/app_drawer.dart';
import 'job_form_page.dart';
import 'step_installation_form.dart';

class BWPanelPage extends StatefulWidget {
  final String username;
  const BWPanelPage({required this.username, super.key});
  @override
  State<BWPanelPage> createState() => _BWPanelPageState();
}

class _BWPanelPageState extends State<BWPanelPage> {
  String selectedType = jobTypes.first;
  final companyCtrl = TextEditingController();
  bool _showAnnouncement = true;
  String? _lastReadAnnouncementId;

  @override
  void initState() { 
    super.initState(); 
    JobStore.instance.addListener(_refreshUI); 
    _loadAnnouncementStatus();
  }

  @override
  void dispose() { 
    JobStore.instance.removeListener(_refreshUI); 
    super.dispose(); 
  }

  void _refreshUI() { if(mounted) setState(() {}); }

  Future<void> _loadAnnouncementStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastReadAnnouncementId = prefs.getString('last_read_announcement_id');
    });
  }

  Future<void> _markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_read_announcement_id', id);
    setState(() {
      _showAnnouncement = false;
      _lastReadAnnouncementId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = ThemeNotifier.isDarkMode;
    final myJobs = JobStore.jobs.where((j) => j.technician == widget.username).toList();
    int todayCount = myJobs.where((j) => j.date.day == DateTime.now().day && j.date.month == DateTime.now().month && j.date.year == DateTime.now().year).length;
    int monthCount = myJobs.where((j) => j.date.month == DateTime.now().month && j.date.year == DateTime.now().year).length;
    
    return Scaffold(
      drawer: AppDrawer(username: widget.username),
      appBar: AppBar(
        title: const Text("PAWERTIC", style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Container(
        height: double.infinity, 
        decoration: isDark 
          ? const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black, Color(0xFF100020)])) 
          : const BoxDecoration(color: Color(0xFFF8F9FA)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), 
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            
            // --- DUYURU SİSTEMİ (AKILLI KONTROL) ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('announcements').orderBy('date', descending: true).limit(1).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final doc = snapshot.data!.docs.first;
                  final announcement = doc.data() as Map<String, dynamic>;
                  final announcementId = doc.id;

                  // Eğer duyuru kapatılmamışsa VE en son okunan duyurudan farklıysa göster
                  if (_showAnnouncement && announcementId != _lastReadAnnouncementId) {
                    return _buildAnnouncementCard(announcement['text'], announcementId, isDark);
                  }
                }
                return const SizedBox.shrink();
              },
            ),

            // Karşılama Bölümü
            Text("${AppLocale.t('welcome')},", style: const TextStyle(fontSize: 14, color: Colors.grey)),
            Text(widget.username, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),

            // İstatistik Kartları
            Row(children: [
              _modernStatCard(AppLocale.t('today'), todayCount.toString(), Icons.today, Colors.blue, isDark),
              const SizedBox(width: 15),
              _modernStatCard(AppLocale.t('month'), monthCount.toString(), Icons.calendar_month, Colors.orange, isDark),
            ]),

            const SizedBox(height: 30),
            const Text("YENİ İŞ KAYDI", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 15),

            // İş Başlatma Formu
            Container(
              padding: const EdgeInsets.all(25), 
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151515) : Colors.white, 
                borderRadius: BorderRadius.circular(30), 
                boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]
              ), 
              child: Column(children: [
                _dropdown(null, jobTypes, selectedType, (v) => setState(() => selectedType = v!)),
                const SizedBox(height: 20),
                TextField(
                  controller: companyCtrl, 
                  style: TextStyle(color: isDark ? Colors.white : Colors.black), 
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.business_rounded, color: Color(0xFF6200EE)),
                    hintText: AppLocale.t('company'), 
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14), 
                    filled: true, 
                    fillColor: isDark ? const Color(0xFF151515) : const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none)
                  )
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity, 
                  height: 65, 
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 5,
                      shadowColor: const Color(0xFF6200EE).withOpacity(0.3)
                    ), 
                    onPressed: () { 
                      if(companyCtrl.text.isNotEmpty) {
                        Navigator.push(context, MaterialPageRoute(builder: (c) => StepInstallationForm(type: selectedType, company: companyCtrl.text, technician: widget.username)));
                      }
                    }, 
                    child: Text(AppLocale.t('start_job'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1))
                  )
                )
              ])
            ),
            
            const SizedBox(height: 40),
            Center(child: Text("PAWERTIC v1.0.0", style: TextStyle(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.1), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 3))),
            const SizedBox(height: 20),
          ])
        ),
      ),
    );
  }

  Widget _modernStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151515) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: isDark ? null : [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 15),
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildAnnouncementCard(String text, String id, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: isDark ? [const Color(0xFF330066), const Color(0xFF1A0033)] : [const Color(0xFF6200EE), const Color(0xFF4A00E0)]),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: const Color(0xFF6200EE).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.campaign_rounded, color: Colors.white)),
        title: const Text("ÖNEMLİ DUYURU", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.white60),
          onPressed: () => _markAsRead(id),
        ),
      ),
    );
  }

  Widget _statBox(String l, String v) => Column(children: [Text(l, style: const TextStyle(color: Colors.grey, fontSize: 11)), Text(v, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: ThemeNotifier.isDarkMode ? Colors.white : Colors.black))]);

  Widget _dropdown(String? l, List<String> i, String v, Function(String?) o) {
    bool isDark = ThemeNotifier.isDarkMode;
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(context: context, backgroundColor: isDark ? const Color(0xFF151515) : Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))), builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [const SizedBox(height: 10), Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))), const SizedBox(height: 20), Text("İşlemi Seçin", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black)), const SizedBox(height: 15), ...i.map((item) => ListTile(leading: Icon(Icons.check_circle_outline, color: item == v ? const Color(0xFF6200EE) : Colors.transparent), title: Text(item, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: item == v ? FontWeight.bold : FontWeight.normal)), onTap: () { o(item); Navigator.pop(context); }, tileColor: item == v ? (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)) : null)).toList(), const SizedBox(height: 20)])));
      },
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), decoration: BoxDecoration(color: isDark ? Colors.black : const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(18), border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05))), child: Row(children: [Icon(Icons.assignment_rounded, color: isDark ? const Color(0xFFBB86FC) : const Color(0xFF6200EE), size: 24), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("İşlem Tipi", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)), Text(v, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis)])), const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey)])),
    );
  }
}
