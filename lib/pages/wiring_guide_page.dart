import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_locale.dart';
import '../core/theme_notifier.dart';
import '../models/wiring_diagram_model.dart';

class WiringGuidePage extends StatefulWidget {
  const WiringGuidePage({super.key});

  @override
  State<WiringGuidePage> createState() => _WiringGuidePageState();
}

class _WiringGuidePageState extends State<WiringGuidePage> {
  String _query = "";

  @override
  Widget build(BuildContext context) {
    bool isDark = ThemeNotifier.isDarkMode;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocale.t('wiring_guide'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              decoration: InputDecoration(
                hintText: AppLocale.t('search_vehicle'),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('wiring_diagrams').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final docs = snapshot.data!.docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return data['model'].toString().toLowerCase().contains(_query.toLowerCase());
                }).toList();

                if (docs.isEmpty) return Center(child: Text(AppLocale.t('no_diagram_found')));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final diagram = WiringDiagramModel.fromMap(docs[index].data() as Map<String, dynamic>, docs[index].id);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: ExpansionTile(
                        leading: const Icon(Icons.directions_car, color: Color(0xFF6200EE)),
                        title: Text(diagram.model, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(diagram.category),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 200,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: diagram.images.length,
                                    itemBuilder: (context, i) {
                                      return GestureDetector(
                                        onTap: () => _showFullImage(diagram.images[i]),
                                        child: Container(
                                          width: 250,
                                          margin: const EdgeInsets.only(right: 10),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(15),
                                            image: DecorationImage(image: NetworkImage(diagram.images[i]), fit: BoxFit.cover),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Text(AppLocale.t('wiring_details'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6200EE))),
                                const SizedBox(height: 5),
                                Text(diagram.details),
                                const SizedBox(height: 10),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(child: Image.network(url)),
            Positioned(right: 0, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context))),
          ],
        ),
      ),
    );
  }
}
