class CariIslem {
  final int? id;
  final int cariHesapId;
  final String? cariHesapUnvan;
  final DateTime tarih;
  final String aciklama;
  final String hesapTipi; // Nakit, Banka Havale, Çek, Kredi Kartı
  final String? evrakNo;
  final DateTime? vade;
  final DateTime? vadeBitis;
  final double borc; // Gelecek (G)
  final double alacak; // Çıkacak (Ç)
  final double bakiye; // Borç - Alacak
  final int? projectId; // Project association
  final DateTime olusturmaTarihi;

  CariIslem({
    this.id,
    required this.cariHesapId,
    this.cariHesapUnvan,
    required this.tarih,
    required this.aciklama,
    required this.hesapTipi,
    this.evrakNo,
    this.vade,
    this.vadeBitis,
    required this.borc,
    required this.alacak,
    required this.bakiye,
    this.projectId,
    DateTime? olusturmaTarihi,
  }) : olusturmaTarihi = olusturmaTarihi ?? DateTime.now();

  String get displayAciklama {
    if (aciklama.contains('#H:[')) {
      return aciklama.split('#H:[')[0].trim();
    }
    return aciklama;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cari_hesap_id': cariHesapId,
      'cari_hesap_unvan': cariHesapUnvan ?? '',
      'tarih': tarih.toIso8601String(),
      'aciklama': aciklama,
      'hesap_tipi': hesapTipi,
      'evrak_no': evrakNo ?? '',
      'vade': vade?.toIso8601String(),
      'vade_bitis': vadeBitis?.toIso8601String(),
      'borc': borc,
      'alacak': alacak,
      'bakiye': bakiye,
      'project_id': projectId,
      'olusturma_tarihi': olusturmaTarihi.toIso8601String(),
    };
  }

  factory CariIslem.fromMap(Map<String, dynamic> map) {
    return CariIslem(
      id: map['id'] as int?,
      cariHesapId: map['cari_hesap_id'] as int,
      cariHesapUnvan: map['cari_hesap_unvan'] as String?,
      tarih: DateTime.parse(map['tarih'] as String),
      aciklama: map['aciklama'] as String,
      hesapTipi: map['hesap_tipi'] as String,
      evrakNo: map['evrak_no'] as String?,
      vade: map['vade'] != null ? DateTime.parse(map['vade'] as String) : null,
      vadeBitis: map['vade_bitis'] != null ? DateTime.parse(map['vade_bitis'] as String) : null,
      borc: (map['borc'] as num?)?.toDouble() ?? 0.0,
      alacak: (map['alacak'] as num?)?.toDouble() ?? 0.0,
      bakiye: (map['bakiye'] as num?)?.toDouble() ?? 0.0,
      projectId: map['project_id'] as int?,
      olusturmaTarihi: map['olusturma_tarihi'] != null
          ? DateTime.parse(map['olusturma_tarihi'] as String)
          : DateTime.now(),
    );
  }

  CariIslem copyWith({
    int? id,
    int? cariHesapId,
    String? cariHesapUnvan,
    DateTime? tarih,
    String? aciklama,
    String? hesapTipi,
    String? evrakNo,
    DateTime? vade,
    DateTime? vadeBitis,
    double? borc,
    double? alacak,
    double? bakiye,
    int? projectId,
    DateTime? olusturmaTarihi,
  }) {
    return CariIslem(
      id: id ?? this.id,
      cariHesapId: cariHesapId ?? this.cariHesapId,
      cariHesapUnvan: cariHesapUnvan ?? this.cariHesapUnvan,
      tarih: tarih ?? this.tarih,
      aciklama: aciklama ?? this.aciklama,
      hesapTipi: hesapTipi ?? this.hesapTipi,
      evrakNo: evrakNo ?? this.evrakNo,
      vade: vade ?? this.vade,
      vadeBitis: vadeBitis ?? this.vadeBitis,
      borc: borc ?? this.borc,
      alacak: alacak ?? this.alacak,
      bakiye: bakiye ?? this.bakiye,
      projectId: projectId ?? this.projectId,
      olusturmaTarihi: olusturmaTarihi ?? this.olusturmaTarihi,
    );
  }
}


