import 'package:flutter/foundation.dart';
import '../models/worker.dart';
import '../services/database_helper.dart';
import '../services/sync_manager.dart';
import 'dart:async';

class WorkerProvider with ChangeNotifier {
  List<Worker> _workers = [];
  bool _isLoading = false;
  StreamSubscription? _syncSubscription;

  List<Worker> get workers => _workers;
  bool get isLoading => _isLoading;

  WorkerProvider() {
    // Sync tamamlandığında (Örn: geçici ID'ler gerçek ID'lerle değiştiğinde) listeyi yenile
    _syncSubscription = SyncManager.instance.onSyncCompleted.listen((_) {
      loadWorkers();
    });
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadWorkers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _workers = await DatabaseHelper.instance.getAllWorkers();
    } catch (e) {
      debugPrint("WorkerProvider error loading workers: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addWorker(Worker worker) async {
    try {
      final id = await DatabaseHelper.instance.insertWorker(worker);
      final newWorker = worker.copyWith(id: id);
      _workers.add(newWorker);
      notifyListeners();
      // Reload fully to ensure correct sorting or state if needed
      await loadWorkers();
    } catch (e) {
      debugPrint("WorkerProvider error adding worker: $e");
    }
  }

  Future<void> updateWorker(Worker worker) async {
    try {
      await DatabaseHelper.instance.updateWorker(worker);
      await loadWorkers(); // Yeniden yükleyerek Hive'dan güncel hali çekiyoruz
    } catch (e) {
      debugPrint("WorkerProvider error updating worker: $e");
    }
  }

  Future<void> deleteWorker(int id) async {
    try {
      await DatabaseHelper.instance.deleteWorker(id);
      await loadWorkers(); // Yeniden yükleyerek Hive'dan güncel hali çekiyoruz
    } catch (e) {
      debugPrint("WorkerProvider error deleting worker: $e");
    }
  }
  
  Future<void> dismissWorker(int id, DateTime dismissalDate) async {
    try {
       await DatabaseHelper.instance.dismissWorker(id, dismissalDate);
       await loadWorkers(); // Reload to get updated status and potentially removed cari.
    } catch (e) {
      debugPrint("WorkerProvider error dismissing worker: $e");
    }
  }
}
