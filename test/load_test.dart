import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final String email = 'altayfbak@gmail.com';
  final String password = 'altay1700';
  final String stressPrefix = 'LOAD_TEST_';
  
  final client = SupabaseClient(
    'https://dwyeynurzyhjxncafqnz.supabase.co',
    'sb_publishable_v6VWwf7RZtHT7521pcpohQ_-ayN2OdC',
  );

  print('--- Authorized Load Test Started ---');
  print('Logging in as $email...');

  try {
    final authResponse = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (authResponse.session == null) {
      print('Login failed: Session is null');
      exit(1);
    }
    print('Login successful. Session acquired.');

    // 1. Create a test Cari Hesap
    print('Creating test Cari Hesap...');
    final testCari = {
      'unvan': '${stressPrefix}Musteri_${DateTime.now().millisecondsSinceEpoch}',
      'vergi_dairesi': 'Load Test',
      'vergi_no': '999888777',
      'telefon': '05000000000',
      'adres': 'Authorized Load Test Adres',
      'bakiye': 0.0,
      'is_kasa': false,
      'olusturma_tarihi': DateTime.now().toIso8601String(),
    };

    final cariResponse = await client.from('cari_hesaplar').insert(testCari).select().single();
    final int cariId = cariResponse['id'];
    print('Test Cari created with ID: $cariId');

    // 2. High Volume Parallel Insertions (100 items)
    final int count = 100;
    print('Preparing to insert $count records in batches...');
    
    final stopwatch = Stopwatch()..start();
    
    final List<Map<String, dynamic>> batchData = List.generate(count, (i) => {
      'cari_hesap_id': cariId,
      'tarih': DateTime.now().toIso8601String(),
      'aciklama': '${stressPrefix}Batch_Islem_$i',
      'hesap_tipi': 'Nakit',
      'borc': 150.0,
      'alacak': 0.0,
      'bakiye': 150.0,
      'olusturma_tarihi': DateTime.now().toIso8601String(),
    });

    // We do one large bulk insert to test throughput
    print('Executing bulk insert for $count records...');
    await client.from('cari_islemler').insert(batchData);
    
    stopwatch.stop();
    print('Bulk insertion of $count records took: ${stopwatch.elapsedMilliseconds} ms');

    // 3. Measuring Read Performance of Large Volume
    stopwatch.reset();
    stopwatch.start();
    print('Querying all records for stress markers...');
    final List<dynamic> results = await client
        .from('cari_islemler')
        .select()
        .filter('aciklama', 'ilike', '%$stressPrefix%');
    stopwatch.stop();
    
    print('Querying ${results.length} records took: ${stopwatch.elapsedMilliseconds} ms');

    // 4. Sequential stress (testing latency per request under load)
    print('Testing sequential latency (10 requests)...');
    stopwatch.reset();
    stopwatch.start();
    for (int i = 0; i < 10; i++) {
        await client.from('cari_islemler').insert({
            'cari_hesap_id': cariId,
            'tarih': DateTime.now().toIso8601String(),
            'aciklama': '${stressPrefix}Seq_Islem_$i',
            'hesap_tipi': 'Nakit',
            'borc': 1.0,
            'alacak': 0.0,
            'bakiye': 1.0,
        });
    }
    stopwatch.stop();
    print('10 sequential requests took: ${stopwatch.elapsedMilliseconds} ms (Avg: ${stopwatch.elapsedMilliseconds / 10} ms/req)');

    // 5. Cleanup
    print('Starting cleanup...');
    await client.from('cari_islemler').delete().filter('aciklama', 'ilike', '%$stressPrefix%');
    await client.from('cari_hesaplar').delete().eq('id', cariId);
    print('Cleanup completed.');

    print('--- Authorized Load Test Finished Successfully ---');
    exit(0);
  } catch (e) {
    print('Load Test Failed: $e');
    exit(1);
  }
}
