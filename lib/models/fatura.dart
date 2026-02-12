class Fatura {
  final int? id;
  final String faturaNo;
  final FaturaTipi tipi; // Satış veya Alış
  final int? cariHesapId;
  final String? cariHesapUnvan;
  final DateTime tarih;
  final DateTime? vadeTarihi;
  final double toplamTutar;
  final double kdvTutari;
  final double genelToplam;
  final String? aciklama;
  final List<FaturaKalemi> kalemler;
  final DateTime olusturmaTarihi;

  Fatura({
    this.id,
    required this.faturaNo,
    required this.tipi,
    this.cariHesapId,
    this.cariHesapUnvan,
    required this.tarih,
    this.vadeTarihi,
    this.toplamTutar = 0.0,
    this.kdvTutari = 0.0,
    this.genelToplam = 0.0,
    this.aciklama,
    this.kalemler = const [],
    DateTime? olusturmaTarihi,
  }) : olusturmaTarihi = olusturmaTarihi ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fatura_no': faturaNo,
      'tipi': tipi.name,
      'cari_hesap_id': cariHesapId,
      'cari_hesap_unvan': cariHesapUnvan ?? '',
      'tarih': tarih.toIso8601String(),
      'vade_tarihi': vadeTarihi?.toIso8601String(),
      'toplam_tutar': toplamTutar,
      'kdv_tutari': kdvTutari,
      'genel_toplam': genelToplam,
      'aciklama': aciklama ?? '',
      'kalemler': kalemler.map((k) => k.toMap()).toList(),
      'olusturma_tarihi': olusturmaTarihi.toIso8601String(),
    };
  }

  factory Fatura.fromMap(Map<String, dynamic> map) {
    return Fatura(
      id: map['id'] as int?,
      faturaNo: map['fatura_no'] as String,
      tipi: FaturaTipi.values.firstWhere(
        (e) => e.name == map['tipi'],
        orElse: () => FaturaTipi.satis,
      ),
      cariHesapId: map['cari_hesap_id'] as int?,
      cariHesapUnvan: map['cari_hesap_unvan'] as String?,
      tarih: DateTime.parse(map['tarih'] as String),
      vadeTarihi: map['vade_tarihi'] != null
          ? DateTime.parse(map['vade_tarihi'] as String)
          : null,
      toplamTutar: (map['toplam_tutar'] as num?)?.toDouble() ?? 0.0,
      kdvTutari: (map['kdv_tutari'] as num?)?.toDouble() ?? 0.0,
      genelToplam: (map['genel_toplam'] as num?)?.toDouble() ?? 0.0,
      aciklama: map['aciklama'] as String?,
      kalemler: (map['kalemler'] as List<dynamic>?)
              ?.map((k) => FaturaKalemi.fromMap(k as Map<String, dynamic>))
              .toList() ??
          [],
      olusturmaTarihi: map['olusturma_tarihi'] != null
          ? DateTime.parse(map['olusturma_tarihi'] as String)
          : DateTime.now(),
    );
  }
}

enum FaturaTipi { satis, alis }

class FaturaKalemi {
  final int? id;
  final String? stokAdi;
  final int? stokId;
  final double miktar;
  final String birim;
  final double birimFiyat;
  final double kdvOrani;
  final double tutar;
  final double kdvTutari;
  final double genelTutar;
  final String? aciklama;

  FaturaKalemi({
    this.id,
    this.stokAdi,
    this.stokId,
    required this.miktar,
    this.birim = 'Adet',
    required this.birimFiyat,
    this.kdvOrani = 20.0,
    required this.tutar,
    required this.kdvTutari,
    required this.genelTutar,
    this.aciklama,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stok_adi': stokAdi ?? '',
      'stok_id': stokId,
      'miktar': miktar,
      'birim': birim,
      'birim_fiyat': birimFiyat,
      'kdv_orani': kdvOrani,
      'tutar': tutar,
      'kdv_tutari': kdvTutari,
      'genel_tutar': genelTutar,
      'aciklama': aciklama ?? '',
    };
  }

  factory FaturaKalemi.fromMap(Map<String, dynamic> map) {
    return FaturaKalemi(
      id: map['id'] as int?,
      stokAdi: map['stok_adi'] as String?,
      stokId: map['stok_id'] as int?,
      miktar: (map['miktar'] as num?)?.toDouble() ?? 0.0,
      birim: map['birim'] as String? ?? 'Adet',
      birimFiyat: (map['birim_fiyat'] as num?)?.toDouble() ?? 0.0,
      kdvOrani: (map['kdv_orani'] as num?)?.toDouble() ?? 20.0,
      tutar: (map['tutar'] as num?)?.toDouble() ?? 0.0,
      kdvTutari: (map['kdv_tutari'] as num?)?.toDouble() ?? 0.0,
      genelTutar: (map['genel_tutar'] as num?)?.toDouble() ?? 0.0,
      aciklama: map['aciklama'] as String?,
    );
  }
}


