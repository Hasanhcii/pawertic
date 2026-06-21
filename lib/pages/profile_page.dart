import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_locale.dart';
import '../core/theme_notifier.dart';
import '../services/job_store.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  const ProfilePage({required this.username, super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _name, _title, _email, _phone;

  @override
  void initState() { super.initState(); _loadData(); }

  void _loadData() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.username).get();
    
    if (userDoc.exists) {
      final data = userDoc.data()!;
      setState(() {
        _name = data['name_surname'] ?? widget.username;
        _title = data['job_title'] ?? "Teknisyen";
        _email = data['email'] ?? "destek@pawertic.com";
        _phone = data['phone'] ?? "05XX XXX XX XX";
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _name = prefs.getString('profile_name') ?? widget.username;
        _title = prefs.getString('profile_title') ?? "Teknisyen";
        _email = prefs.getString('profile_email') ?? "destek@pawertic.com";
        _phone = prefs.getString('profile_phone') ?? "05XX XXX XX XX";
      });
    }
  }

  Future<void> _updateFirestore(String key, String value) async {
    await FirebaseFirestore.instance.collection('users').doc(widget.username).set({
      key: value
    }, SetOptions(merge: true));
    _loadData();
  }

  Future<void> _updateInfo(String firestoreKey, String title, String current, {TextInputType type = TextInputType.text}) async {
    final ctrl = TextEditingController(text: current);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeNotifier.isDarkMode ? const Color(0xFF151515) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 20),
          TextField(controller: ctrl, keyboardType: type, autofocus: true, decoration: InputDecoration(filled: true, fillColor: ThemeNotifier.isDarkMode ? Colors.black : const Color(0xFFF5F5F5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: () async {
            await _updateFirestore(firestoreKey, ctrl.text);
            Navigator.pop(ctx);
          }, child: const Text("GÜNCELLE"))),
          const SizedBox(height: 20),
        ]),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = ThemeNotifier.isDarkMode;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocale.t('profile')), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(children: [
          const SizedBox(height: 10),
          // Fotoğraf yerine şık bir isim baş harfi (Avatar)
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFF6200EE),
              child: Text(
                (_name ?? widget.username).substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(_name ?? widget.username, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          Text(_title ?? "", style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 30),
          
          // İstatistik Kartı
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151515) : Colors.white, 
              borderRadius: BorderRadius.circular(20),
              boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _statItem(JobStore.jobs.where((j) => j.technician == widget.username).length.toString(), "Toplam İş"),
              Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.2)),
              _statItem(JobStore.jobs.where((j) => j.isCompleted && j.technician == widget.username).length.toString(), "Biten"),
            ]),
          ),
          const SizedBox(height: 30),

          // Bilgi Listesi
          _infoTile(Icons.person_outline, AppLocale.t('name_surname'), _name ?? "", () => _updateInfo('name_surname', AppLocale.t('name_surname'), _name ?? "")),
          _infoTile(Icons.work_outline, AppLocale.t('job_title'), _title ?? "", () => _updateInfo('job_title', AppLocale.t('job_title'), _title ?? "")),
          _infoTile(Icons.email_outlined, AppLocale.t('email'), _email ?? "", () => _updateInfo('email', AppLocale.t('email'), _email ?? "", type: TextInputType.emailAddress)),
          _infoTile(Icons.phone_android_outlined, AppLocale.t('phone'), _phone ?? "", () => _updateInfo('phone', AppLocale.t('phone'), _phone ?? "", type: TextInputType.phone)),
        ]),
      ),
    );
  }
  Widget _statItem(String v, String l) => Column(children: [Text(v, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text(l, style: const TextStyle(color: Colors.grey, fontSize: 12))]);
  Widget _infoTile(IconData i, String l, String v, VoidCallback onTap) => Container(margin: const EdgeInsets.only(bottom: 15), decoration: BoxDecoration(color: ThemeNotifier.isDarkMode ? const Color(0xFF151515) : Colors.white, borderRadius: BorderRadius.circular(15)), child: ListTile(leading: Icon(i, color: const Color(0xFF6200EE)), title: Text(l, style: const TextStyle(color: Colors.grey, fontSize: 11)), subtitle: Text(v, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: ThemeNotifier.isDarkMode ? Colors.white : Colors.black)), trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey), onTap: onTap, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))));
}
