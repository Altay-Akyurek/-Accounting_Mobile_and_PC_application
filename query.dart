import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  DateTime vade = DateTime(2025, 2, 28);
  DateTime start = DateTime(2025, 2, 1);
  DateTime end = DateTime(2025, 2, 28);
  
  bool isBeforeEnd = vade.isBefore(end.add(Duration(seconds: 1)));
  bool isAfterStart = vade.isAfter(start.subtract(Duration(seconds: 1)));
  
  print('vade.isBefore(end.add(1s)): ' + isBeforeEnd.toString());
  print('vade.isAfter(start.subtract(1s)): ' + isAfterStart.toString());
  
  // Dashboard default report ranges:
  DateTime bitisTarihi = DateTime.now(); // 2026-03-02
  DateTime baslangicTarihi = DateTime(bitisTarihi.year, bitisTarihi.month, 1); // 2026-03-01
  
  bool dashBeforeEnd = vade.isBefore(bitisTarihi.add(Duration(seconds: 1)));
  bool dashAfterStart = vade.isAfter(baslangicTarihi.subtract(Duration(seconds: 1)));
  
  print('Dashboard vade.isBefore(end.add(1s)): ' + dashBeforeEnd.toString());
  print('Dashboard vade.isAfter(start.subtract(1s)): ' + dashAfterStart.toString());
  
  exit(0);
}
