import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final String email = 'altayfbak@gmail.com';
  final String password = 'altay1700';
  final String testPrefix = 'VOLUME_TEST_';
  
  final client = SupabaseClient(
    'https://dwyeynurzyhjxncafqnz.supabase.co',
    'sb_publishable_v6VWwf7RZtHT7521pcpohQ_-ayN2OdC',
  );

  print('--- Volume Test Started ---');
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
    print('Login successful.');

    // 1. Create a test Cari Hesap
    print('Creating test Cari Hesap for volume data...');
    final testCari = {
      'unvan': '${testPrefix}Scale_Account_${DateTime.now().millisecondsSinceEpoch}',
      'vergi_dairesi': 'Volume Test',
      'vergi_no': '777666555',
      'bakiye': 0.0,
      'is_kasa': false,
      'olusturma_tarihi': DateTime.now().toIso8601String(),
    };

    final cariResponse = await client.from('cari_hesaplar').insert(testCari).select().single();
    final int cariId = cariResponse['id'];
    print('Scale Account created with ID: $cariId');

    // 2. Volume Insertion (1000 items in 5 batches of 200)
    final int totalCount = 1000;
    final int batchSize = 200;
    final totalStopwatch = Stopwatch()..start();

    print('Inserting $totalCount records in $batchSize size batches...');
    
    for (int b = 0; b < totalCount / batchSize; b++) {
      final List<Map<String, dynamic>> batchData = List.generate(batchSize, (i) => {
        'cari_hesap_id': cariId,
        'tarih': DateTime.now().toIso8601String(),
        'aciklama': '${testPrefix}Record_${b * batchSize + i}',
        'hesap_tipi': 'Nakit',
        'borc': 10.0 * (i + 1),
        'alacak': 5.0,
        'bakiye': 5.0 * (i + 1),
        'olusturma_tarihi': DateTime.now().toIso8601String(),
      });
      
      final batchStopwatch = Stopwatch()..start();
      await client.from('cari_islemler').insert(batchData);
      batchStopwatch.stop();
      print('Batch ${b + 1} (${batchSize} records) took: ${batchStopwatch.elapsedMilliseconds} ms');
    }
    
    totalStopwatch.stop();
    print('Total Volume Insertion ($totalCount records) took: ${totalStopwatch.elapsedMilliseconds} ms');

    // 3. Performance Querying on High Volume
    print('Executing analytical queries on high volume data...');

    // A. Querying specific range
    final qStopwatch = Stopwatch()..start();
    final List<dynamic> filteredResults = await client
        .from('cari_islemler')
        .select()
        .eq('cari_hesap_id', cariId)
        .gt('borc', 500.0);
    qStopwatch.stop();
    print('Querying for specific range (found ${filteredResults.length} records) took: ${qStopwatch.elapsedMilliseconds} ms');

    // B. Aggregation test (limit + count simulation)
    qStopwatch.reset();
    qStopwatch.start();
    final List<dynamic> allRecordsInAccount = await client
        .from('cari_islemler')
        .select('id')
        .eq('cari_hesap_id', cariId);
    qStopwatch.stop();
    print('Fetching IDs for $totalCount records in account took: ${qStopwatch.elapsedMilliseconds} ms (Count: ${allRecordsInAccount.length})');

    // 4. Cleanup
    print('Cleaning up volume test data...');
    final cStopwatch = Stopwatch()..start();
    await client.from('cari_islemler').delete().eq('cari_hesap_id', cariId);
    await client.from('cari_hesaplar').delete().eq('id', cariId);
    cStopwatch.stop();
    print('Cleanup took: ${cStopwatch.elapsedMilliseconds} ms');

    print('--- Volume Test Finished Successfully ---');
    exit(0);
  } catch (e) {
    print('Volume Test Failed: $e');
    exit(1);
  }
}
