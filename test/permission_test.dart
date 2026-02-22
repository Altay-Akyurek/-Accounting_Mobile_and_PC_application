import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://dwyeynurzyhjxncafqnz.supabase.co',
    'sb_publishable_v6VWwf7RZtHT7521pcpohQ_-ayN2OdC',
  );

  print('--- Permission Test Started ---');

  try {
    final testCari = {
      'unvan': 'PERMISSION_TEST_' + DateTime.now().millisecondsSinceEpoch.toString(),
      'vergi_dairesi': 'Test',
      'vergi_no': '111222333',
      'bakiye': 0.0,
      'is_kasa': false,
      'olusturma_tarihi': DateTime.now().toIso8601String(),
    };

    final response = await client.from('cari_hesaplar').insert(testCari).select().single();
    print('Insert Successful! ID: ${response['id']}');
    
    // Cleanup
    await client.from('cari_hesaplar').delete().eq('id', response['id']);
    print('Cleanup Successful.');
    print('--- PERMISSIONS ARE GRANTED (RLS is OFF or Permissive) ---');
    exit(0);
  } catch (e) {
    print('Insert Failed: $e');
    print('--- PERMISSIONS ARE STILL RESTRICTED ---');
    exit(1);
  }
}
