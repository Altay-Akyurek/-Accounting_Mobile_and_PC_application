enum WorkerSalaryType { gunluk, aylik, saatlik }

class Worker {
  final int? id;
  final String adSoyad;
  final String? tcNo;
  final String? telefon;
  final String? pozisyon;
  final WorkerSalaryType maasTuru;
  final double maasTutari;
  final DateTime baslangicTarihi;
  final bool aktif;
  final int? cariHesapId;
  final DateTime? istenCikisTarihi;
  final DateTime olusturmaTarihi;

  Worker({
    this.id,
    required this.adSoyad,
    this.tcNo,
    this.telefon,
    this.pozisyon,
    this.maasTuru = WorkerSalaryType.gunluk,
    this.maasTutari = 0.0,
    required this.baslangicTarihi,
    this.aktif = true,
    this.cariHesapId,
    this.istenCikisTarihi,
    DateTime? olusturmaTarihi,
  }) : olusturmaTarihi = olusturmaTarihi ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ad_soyad': adSoyad,
      'tc_no': tcNo ?? '',
      'telefon': telefon ?? '',
      'pozisyon': pozisyon ?? '',
      'maas_turu': maasTuru.name,
      'maas_tutari': maasTutari,
      'baslangic_tarihi': baslangicTarihi.toIso8601String(),
      'aktif': aktif,
      'cari_hesap_id': cariHesapId,
      'isten_cikis_tarihi': istenCikisTarihi?.toIso8601String(),
      'olusturma_tarihi': olusturmaTarihi.toIso8601String(),
    };
  }

  factory Worker.fromMap(Map<String, dynamic> map) {
    return Worker(
      id: map['id'] as int?,
      adSoyad: map['ad_soyad'] as String,
      tcNo: map['tc_no'] as String?,
      telefon: map['telefon'] as String?,
      pozisyon: map['pozisyon'] as String?,
      maasTuru: WorkerSalaryType.values.firstWhere(
        (e) => e.name == map['maas_turu'],
        orElse: () => WorkerSalaryType.gunluk,
      ),
      maasTutari: (map['maas_tutari'] as num?)?.toDouble() ?? 0.0,
      baslangicTarihi: map['baslangic_tarihi'] != null 
          ? DateTime.parse(map['baslangic_tarihi'] as String)
          : DateTime.now(),
      aktif: map['aktif'] as bool? ?? true,
      cariHesapId: map['cari_hesap_id'] as int?,
      istenCikisTarihi: map['isten_cikis_tarihi'] != null 
          ? DateTime.parse(map['isten_cikis_tarihi'] as String) 
          : null,
      olusturmaTarihi: map['olusturma_tarihi'] != null 
          ? DateTime.parse(map['olusturma_tarihi'] as String)
          : DateTime.now(),
    );
  }

  Worker copyWith({
    int? id,
    String? adSoyad,
    String? tcNo,
    String? telefon,
    String? pozisyon,
    WorkerSalaryType? maasTuru,
    double? maasTutari,
    DateTime? baslangicTarihi,
    bool? aktif,
    int? cariHesapId,
    DateTime? istenCikisTarihi,
    DateTime? olusturmaTarihi,
  }) {
    return Worker(
      id: id ?? this.id,
      adSoyad: adSoyad ?? this.adSoyad,
      tcNo: tcNo ?? this.tcNo,
      telefon: telefon ?? this.telefon,
      pozisyon: pozisyon ?? this.pozisyon,
      maasTuru: maasTuru ?? this.maasTuru,
      maasTutari: maasTutari ?? this.maasTutari,
      baslangicTarihi: baslangicTarihi ?? this.baslangicTarihi,
      aktif: aktif ?? this.aktif,
      cariHesapId: cariHesapId ?? this.cariHesapId,
      istenCikisTarihi: istenCikisTarihi ?? this.istenCikisTarihi,
      olusturmaTarihi: olusturmaTarihi ?? this.olusturmaTarihi,
    );
  }
}

class Puantaj {
  final int? id;
  final int workerId;
  final DateTime tarih;
  final double saat; // Çalışılan saat (örnek: 8.5)
  final double mesai; // Fazla mesai saati
  final String? aciklama;
  final int? projectId; // Hangi projede çalıştı

  Puantaj({
    this.id,
    required this.workerId,
    required this.tarih,
    this.saat = 8.0,
    this.mesai = 0.0,
    this.aciklama,
    this.projectId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'worker_id': workerId,
      'tarih': tarih.toIso8601String(),
      'saat': saat,
      'mesai': mesai,
      'aciklama': aciklama ?? '',
      'project_id': projectId,
    };
  }

  factory Puantaj.fromMap(Map<String, dynamic> map) {
    return Puantaj(
      id: map['id'] as int?,
      workerId: map['worker_id'] as int,
      tarih: DateTime.parse(map['tarih'] as String),
      saat: (map['saat'] as num?)?.toDouble() ?? 8.0,
      mesai: (map['mesai'] as num?)?.toDouble() ?? 0.0,
      aciklama: map['aciklama'] as String?,
      projectId: map['project_id'] as int?,
    );
  }
}
