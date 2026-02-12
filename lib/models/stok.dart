class Stok {
  final int? id;
  final String kod;
  final String ad;
  final String? birim;
  final double? stokMiktari;
  final double? kritikStokSeviyesi;
  final double? alisFiyati;
  final double? satisFiyati;
  final double? kdvOrani;
  final String? kategori;
  final String? aciklama;
  final DateTime olusturmaTarihi;

  Stok({
    this.id,
    required this.kod,
    required this.ad,
    this.birim = 'Adet',
    this.stokMiktari = 0.0,
    this.kritikStokSeviyesi,
    this.alisFiyati,
    this.satisFiyati,
    this.kdvOrani = 20.0,
    this.kategori,
    this.aciklama,
    DateTime? olusturmaTarihi,
  }) : olusturmaTarihi = olusturmaTarihi ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kod': kod,
      'ad': ad,
      'birim': birim ?? 'Adet',
      'stok_miktari': stokMiktari ?? 0.0,
      'kritik_stok_seviyesi': kritikStokSeviyesi,
      'alis_fiyati': alisFiyati,
      'satis_fiyati': satisFiyati,
      'kdv_orani': kdvOrani ?? 20.0,
      'kategori': kategori ?? '',
      'aciklama': aciklama ?? '',
      'olusturma_tarihi': olusturmaTarihi.toIso8601String(),
    };
  }

  factory Stok.fromMap(Map<String, dynamic> map) {
    return Stok(
      id: map['id'] as int?,
      kod: map['kod'] as String,
      ad: map['ad'] as String,
      birim: map['birim'] as String? ?? 'Adet',
      stokMiktari: (map['stok_miktari'] as num?)?.toDouble() ?? 0.0,
      kritikStokSeviyesi: (map['kritik_stok_seviyesi'] as num?)?.toDouble(),
      alisFiyati: (map['alis_fiyati'] as num?)?.toDouble(),
      satisFiyati: (map['satis_fiyati'] as num?)?.toDouble(),
      kdvOrani: (map['kdv_orani'] as num?)?.toDouble() ?? 20.0,
      kategori: map['kategori'] as String?,
      aciklama: map['aciklama'] as String?,
      olusturmaTarihi: map['olusturma_tarihi'] != null
          ? DateTime.parse(map['olusturma_tarihi'] as String)
          : DateTime.now(),
    );
  }

  Stok copyWith({
    int? id,
    String? kod,
    String? ad,
    String? birim,
    double? stokMiktari,
    double? kritikStokSeviyesi,
    double? alisFiyati,
    double? satisFiyati,
    double? kdvOrani,
    String? kategori,
    String? aciklama,
    DateTime? olusturmaTarihi,
  }) {
    return Stok(
      id: id ?? this.id,
      kod: kod ?? this.kod,
      ad: ad ?? this.ad,
      birim: birim ?? this.birim,
      stokMiktari: stokMiktari ?? this.stokMiktari,
      kritikStokSeviyesi: kritikStokSeviyesi ?? this.kritikStokSeviyesi,
      alisFiyati: alisFiyati ?? this.alisFiyati,
      satisFiyati: satisFiyati ?? this.satisFiyati,
      kdvOrani: kdvOrani ?? this.kdvOrani,
      kategori: kategori ?? this.kategori,
      aciklama: aciklama ?? this.aciklama,
      olusturmaTarihi: olusturmaTarihi ?? this.olusturmaTarihi,
    );
  }
}


