import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_model.dart';

class JobStore extends ChangeNotifier {
  static List<JobModel> jobs = [];
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _jobsRef = _firestore.collection('jobs');
  static final JobStore instance = JobStore();

  static void startListening() {
    _jobsRef.orderBy('date', descending: true).snapshots().listen((snapshot) {
      jobs = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return JobModel.fromMap(data);
      }).toList();
      instance.notifyListeners();
    });
  }

  static Future<void> batchAddOrUpdate(List<JobModel> jobList) async {
    final batch = _firestore.batch();
    for (var job in jobList) {
      batch.set(_jobsRef.doc(job.id), job.toMap());
    }
    await batch.commit();
  }

  static Future<void> deleteJob(String id) async {
    await _jobsRef.doc(id).delete();
  }

  static Future<void> clearAllJobs() async {
    final snapshot = await _jobsRef.get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
