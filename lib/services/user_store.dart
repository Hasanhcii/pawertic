import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserStore extends ChangeNotifier {
  static List<UserModel> users = [];
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _usersRef = _firestore.collection('users');
  static final UserStore instance = UserStore();

  static void startListening() {
    _usersRef.snapshots().listen((snapshot) {
      users = snapshot.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
      instance.notifyListeners();
    });
  }

  static Future<void> addUser(UserModel user) async {
    await _usersRef.doc(user.username).set(user.toMap());
  }

  static Future<void> deleteUser(String username) async {
    await _usersRef.doc(username).delete();
  }
}
