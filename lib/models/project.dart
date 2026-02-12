enum ProjectStatus { aktif, tamamlandi, askida }

class Project {
  final int? id;
  final String ad;
  final int? cariHesapId;
  final String? cariHesapUnvan;
  final ProjectStatus durum;
  final DateTime baslangicTarihi;
  final DateTime? bitisTarihi;
  final double toplamButce;
  final String? aciklama;
  final DateTime olusturmaTarihi;

  Project({
    this.id,
    required this.ad,
    this.cariHesapId,
    this.cariHesapUnvan,
    this.durum = ProjectStatus.aktif,
    required this.baslangicTarihi,
    this.bitisTarihi,
    this.toplamButce = 0.0,
    this.aciklama,
    DateTime? olusturmaTarihi,
  }) : olusturmaTarihi = olusturmaTarihi ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ad': ad,
      'cari_hesap_id': cariHesapId,
      'cari_hesap_unvan': cariHesapUnvan ?? '',
      'durum': durum.name,
      'baslangic_tarihi': baslangicTarihi.toIso8601String(),
      'bitis_tarihi': bitisTarihi?.toIso8601String(),
      'toplam_butce': toplamButce,
      'aciklama': aciklama ?? '',
      'olusturma_tarihi': olusturmaTarihi.toIso8601String(),
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as int?,
      ad: map['ad'] as String,
      cariHesapId: map['cari_hesap_id'] as int?,
      cariHesapUnvan: map['cari_hesap_unvan'] as String?,
      durum: ProjectStatus.values.firstWhere(
        (e) => e.name == map['durum'],
        orElse: () => ProjectStatus.aktif,
      ),
      baslangicTarihi: map['baslangic_tarihi'] != null 
          ? DateTime.parse(map['baslangic_tarihi'] as String)
          : DateTime.now(),
      bitisTarihi: map['bitis_tarihi'] != null
          ? DateTime.parse(map['bitis_tarihi'] as String)
          : null,
      toplamButce: (map['toplam_butce'] as num?)?.toDouble() ?? 0.0,
      aciklama: map['aciklama'] as String?,
      olusturmaTarihi: map['olusturma_tarihi'] != null 
          ? DateTime.parse(map['olusturma_tarihi'] as String)
          : DateTime.now(),
    );
  }

  Project copyWith({
    int? id,
    String? ad,
    int? cariHesapId,
    String? cariHesapUnvan,
    ProjectStatus? durum,
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
    double? toplamButce,
    String? aciklama,
    DateTime? olusturmaTarihi,
  }) {
    return Project(
      id: id ?? this.id,
      ad: ad ?? this.ad,
      cariHesapId: cariHesapId ?? this.cariHesapId,
      cariHesapUnvan: cariHesapUnvan ?? this.cariHesapUnvan,
      durum: durum ?? this.durum,
      baslangicTarihi: baslangicTarihi ?? this.baslangicTarihi,
      bitisTarihi: bitisTarihi ?? this.bitisTarihi,
      toplamButce: toplamButce ?? this.toplamButce,
      aciklama: aciklama ?? this.aciklama,
      olusturmaTarihi: olusturmaTarihi ?? this.olusturmaTarihi,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
