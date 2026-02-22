import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final String stressPrefix = 'STRESS_TEST_';
  final client = SupabaseClient(
    'https://dwyeynurzyhjxncafqnz.supabase.co',
    'sb_publishable_v6VWwf7RZtHT7521pcpohQ_-ayN2OdC',
  );

  print('--- Standalone Stress Test Started ---');

  try {
    // 1. Find an existing Cari Hesap
    print('Searching for an existing Cari Hesap...');
    final List<dynamic> caris = await client.from('cari_hesaplar').select('id, unvan').limit(1);
    
    if (caris.isEmpty) {
      print('No existing Cari Hesap found. RLS prevents creating new ones. Test aborted.');
      exit(1);
    }
    
    final int cariId = caris[0]['id'] as int;
    final String unvan = caris[0]['unvan'] as String;
    print('Using existing Cari Hesap: $unvan (ID: $cariId)');

    // 2. Sequential Insertions (50 items)
    final int count = 50;
    final stopwatch = Stopwatch()..start();

    print('Inserting $count records to cari_islemler...');
    for (int i = 0; i < count; i++) {
        final islemMap = {
            'cari_hesap_id': cariId,
            'tarih': DateTime.now().toIso8601String(),
            'aciklama': '${stressPrefix}Islem $i',
            'hesap_tipi': 'Nakit',
            'borc': 100.0,
            'alacak': 0.0,
            'bakiye': 100.0,
            'olusturma_tarihi': DateTime.now().toIso8601String(),
        };
        await client.from('cari_islemler').insert(islemMap);
    }
    stopwatch.stop();
    print('Sequential Insertion of $count records took: ${stopwatch.elapsedMilliseconds} ms');
    print('Average time per insertion: ${stopwatch.elapsedMilliseconds / count} ms');

    // 3. Bulk Read Performance
    stopwatch.reset();
    stopwatch.start();
    final List<dynamic> allRows = await client.from('cari_islemler').select();
    stopwatch.stop();
    final stressRows = allRows.where((e) => (e['aciklama'] as String).contains(stressPrefix)).toList();
    print('Reading all records (Total: ${allRows.length}, Stress: ${stressRows.length}) took: ${stopwatch.elapsedMilliseconds} ms');

    // 4. Cleanup
    print('Cleaning up stress test records...');
    await client.from('cari_islemler').delete().like('aciklama', '%$stressPrefix%');
    print('Cleanup completed.');
    print('--- Stress Test Finished Successfully ---');
    exit(0);
  } catch (e) {
    print('Stress Test Failed: $e');
    exit(1);
  }
}
