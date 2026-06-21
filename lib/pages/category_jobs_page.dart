import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme_notifier.dart';
import '../services/job_store.dart';
import '../models/job_model.dart';
import 'job_details_page.dart';

class CategoryJobsPage extends StatefulWidget {
  final String category;
  const CategoryJobsPage({required this.category, super.key});
  @override
  State<CategoryJobsPage> createState() => _CategoryJobsPageState();
}

class _CategoryJobsPageState extends State<CategoryJobsPage> {
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
    final filteredJobs = JobStore.jobs.where((j) => j.jobType == widget.category).toList();
    Map<String, List<JobModel>> grouped = {};
    for (var job in filteredJobs) { 
      String dateStr = DateFormat('dd.MM.yyyy').format(job.date); 
      if (!grouped.containsKey(dateStr)) grouped[dateStr] = []; 
      grouped[dateStr]!.add(job); 
    }
    final dates = grouped.keys.toList();
    
    return Scaffold(
      appBar: AppBar(title: Text(widget.category)),
      body: filteredJobs.isEmpty 
        ? const Center(child: Text("Kayıt bulunamadı")) 
        : ListView.builder(
            padding: const EdgeInsets.all(15), 
            itemCount: dates.length, 
            itemBuilder: (c, i) {
              String date = dates[i]; 
              List<JobModel> dayJobs = grouped[date]!;
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5), child: Text(date, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))), 
                ...dayJobs.map((job) => Card(color: isDark ? const Color(0xFF151515) : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: ListTile(title: Text(job.companyName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black)), subtitle: Text(job.plate, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)), trailing: Icon(job.isCompleted ? Icons.check_circle : Icons.pending, color: job.isCompleted ? Colors.green : Colors.orange, size: 20), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => JobDetailsPage(job: job))))))
              ]);
            }
          ),
    );
  }
}
