import 'package:flutter/material.dart';
import '../core/app_locale.dart';
import '../core/theme_notifier.dart';
import '../services/user_store.dart';
import '../models/user_model.dart';
import '../widgets/notify.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});
  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  @override
  void initState() { super.initState(); UserStore.instance.addListener(_refreshUI); }
  @override
  void dispose() { UserStore.instance.removeListener(_refreshUI); super.dispose(); }
  void _refreshUI() { if(mounted) setState(() {}); }

  void _showAddUser() {
    final userCtrl = TextEditingController(), passCtrl = TextEditingController();
    String role = 'technician';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeNotifier.isDarkMode ? const Color(0xFF151515) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocalState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(AppLocale.t('create_user'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 20),
          TextField(controller: userCtrl, decoration: InputDecoration(hintText: AppLocale.t('user'), filled: true, fillColor: ThemeNotifier.isDarkMode ? Colors.black : const Color(0xFFF5F5F5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
          const SizedBox(height: 15),
          TextField(controller: passCtrl, decoration: InputDecoration(hintText: AppLocale.t('pass'), filled: true, fillColor: ThemeNotifier.isDarkMode ? Colors.black : const Color(0xFFF5F5F5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: role,
            items: [
              DropdownMenuItem(value: 'technician', child: Text(AppLocale.t('technician'))),
              DropdownMenuItem(value: 'admin', child: Text(AppLocale.t('admin'))),
            ],
            onChanged: (v) => setLocalState(() => role = v!),
            decoration: InputDecoration(labelText: AppLocale.t('role'), filled: true, fillColor: ThemeNotifier.isDarkMode ? Colors.black : const Color(0xFFF5F5F5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: () async {
            if (userCtrl.text.isEmpty) { Notify.show(context, AppLocale.t('username_req'), isError: true); return; }
            if (passCtrl.text.isEmpty) { Notify.show(context, AppLocale.t('password_req'), isError: true); return; }
            await UserStore.addUser(UserModel(username: userCtrl.text.trim(), password: passCtrl.text.trim(), role: role));
            if (!mounted) return;
            Navigator.pop(ctx);
            Notify.show(context, AppLocale.t('user_added'));
          }, child: Text(AppLocale.t('save')))),
          const SizedBox(height: 20),
        ]),
      ))
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = ThemeNotifier.isDarkMode;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocale.t('manage_users'))),
      floatingActionButton: FloatingActionButton(onPressed: _showAddUser, backgroundColor: const Color(0xFF6200EE), child: const Icon(Icons.add, color: Colors.white)),
      body: UserStore.users.isEmpty ? const Center(child: Text("Kullanıcı bulunamadı")) : ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: UserStore.users.length,
        itemBuilder: (c, i) {
          final user = UserStore.users[i];
          return Card(
            color: isDark ? const Color(0xFF151515) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: user.role == 'admin' ? Colors.orange : Colors.blue, child: Icon(user.role == 'admin' ? Icons.security : Icons.person, color: Colors.white)),
              title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(user.role == 'admin' ? AppLocale.t('admin') : AppLocale.t('technician')),
              trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => UserStore.deleteUser(user.username)),
            ),
          );
        },
      ),
    );
  }
}
