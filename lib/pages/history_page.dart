import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_locale.dart';
import '../core/theme_notifier.dart';
import '../services/job_store.dart';
import '../widgets/notify.dart';
import 'job_details_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _searchQuery = "";
  final _searchCtrl = TextEditingController();

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
    final filteredJobs = JobStore.jobs.where((j) => 
      j.companyName.toLowerCase().contains(_searchQuery.toLowerCase()) || 
      j.plate.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.t('history')), 
        actions: [IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.redAccent), onPressed: () => _confirmClear())]
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(15), 
          child: TextField(
            controller: _searchCtrl, 
            style: TextStyle(color: isDark ? Colors.white : Colors.black), 
            decoration: InputDecoration(
              hintText: "Müşteri veya Plaka Ara...", 
              prefixIcon: const Icon(Icons.search), 
              filled: true, 
              fillColor: isDark ? const Color(0xFF151515) : Colors.white, 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
            ), 
            onChanged: (v) => setState(() => _searchQuery = v)
          )
        ), 
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 15), 
            itemCount: filteredJobs.length, 
            itemBuilder: (c, i) { 
              final job = filteredJobs[i]; 
              return Card(
                color: isDark ? const Color(0xFF151515) : Colors.white, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), 
                margin: const EdgeInsets.only(bottom: 10), 
                child: ListTile(
                  title: Text("${job.companyName} (${job.jobType})", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)), 
                  subtitle: Text("${AppLocale.t('plate')}: ${job.plate}\n${DateFormat('dd.MM.yyyy HH:mm').format(job.date)}", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)), 
                  trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _confirmDelete(job.id)), 
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => JobDetailsPage(job: job)))
                )
              ); 
            }
          )
        )
      ]),
    );
  }

  void _confirmDelete(String id) {
    showDialog(context: context, builder: (c) => AlertDialog(title: Text(AppLocale.t('delete_confirm')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("İPTAL")), TextButton(onPressed: () async {
      Navigator.pop(context);
      Notify.showLoading(context, AppLocale.t('deleting'));
      try {
        await JobStore.deleteJob(id);
        if(!mounted) return;
        Navigator.pop(context);
        Notify.show(context, AppLocale.t('delete_success'));
      } catch (e) {
        if(mounted) Navigator.pop(context);
        Notify.show(context, "Hata: $e", isError: true);
      }
    }, child: const Text("SİL", style: TextStyle(color: Colors.red)))]));
  }

  void _confirmClear() {
    showDialog(context: context, builder: (c) => AlertDialog(title: Text(AppLocale.t('clear_confirm')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("İPTAL")), TextButton(onPressed: () async {
      Navigator.pop(context);
      Notify.showLoading(context, AppLocale.t('deleting'));
      try {
        await JobStore.clearAllJobs();
        if(!mounted) return;
        Navigator.pop(context);
        Notify.show(context, AppLocale.t('clear_success'));
      } catch (e) {
        if(mounted) Navigator.pop(context);
        Notify.show(context, "Hata: $e", isError: true);
      }
    }, child: const Text("TEMİZLE", style: TextStyle(color: Colors.red)))]));
  }
}
