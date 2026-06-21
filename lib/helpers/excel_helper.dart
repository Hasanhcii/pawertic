import 'dart:io';
import 'package:excel/excel.dart' as excel_lib;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import '../models/job_model.dart';

class ExcelHelper {
  static Future<void> exportJobs(List<JobModel> jobs, BuildContext context) async {
    var excel = excel_lib.Excel.createExcel();
    excel_lib.Sheet sheet = excel['Rapor'];
    excel.delete('Sheet1');
    
    // Başlık satırı
    sheet.appendRow([
      "Tarih", "Teknisyen", "İş Tipi", "Firma", "Plaka", "Kategori", "Marka", "Model", "IMEI", "SIM", "Notlar", "Durum"
    ].map((e) => excel_lib.TextCellValue(e)).toList());
    
    // Veri satırları
    for (var j in jobs) {
      sheet.appendRow([
        DateFormat('dd.MM.yyyy HH:mm').format(j.date),
        j.technician,
        j.jobType,
        j.companyName,
        j.plate,
        j.category,
        j.brand,
        j.model,
        j.imei,
        j.simNo,
        j.notes, // Yeni eklediğimiz notlar alanı
        j.isCompleted ? "Tamamlandı" : "Bekliyor"
      ].map((e) => excel_lib.TextCellValue(e)).toList());
    }
    
    var bytes = excel.save();
    if (bytes != null) {
      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/Pawertic_Rapor_${DateTime.now().millisecondsSinceEpoch}.xlsx");
      await file.writeAsBytes(bytes);
      
      // Dosyayı paylaşma ekranını aç
      await Share.shareXFiles([XFile(file.path)], text: 'Pawertic İş Kayıt Raporu');
    }
  }
}
