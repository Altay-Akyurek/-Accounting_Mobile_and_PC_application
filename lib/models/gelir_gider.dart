class GelirGider {
  final int? id;
  final GelirGiderTipi tipi; // Gelir veya Gider
  final String baslik;
  final double tutar;
  final DateTime tarih;
  final String? kategori;
  final int? cariHesapId;
  final String? cariHesapUnvan;
  final String? aciklama;
  final String? faturaNo;
  final int? projectId; // Project association
  final DateTime olusturmaTarihi;

  GelirGider({
    this.id,
    required this.tipi,
    required this.baslik,
    required this.tutar,
    required this.tarih,
    this.kategori,
    this.cariHesapId,
    this.cariHesapUnvan,
    this.aciklama,
    this.faturaNo,
    this.projectId,
    DateTime? olusturmaTarihi,
  }) : olusturmaTarihi = olusturmaTarihi ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipi': tipi.name,
      'baslik': baslik,
      'tutar': tutar,
      'tarih': tarih.toIso8601String(),
      'kategori': kategori ?? '',
      'cari_hesap_id': cariHesapId,
      'cari_hesap_unvan': cariHesapUnvan ?? '',
      'aciklama': aciklama ?? '',
      'fatura_no': faturaNo ?? '',
      'project_id': projectId,
      'olusturma_tarihi': olusturmaTarihi.toIso8601String(),
    };
  }

  factory GelirGider.fromMap(Map<String, dynamic> map) {
    return GelirGider(
      id: map['id'] as int?,
      tipi: GelirGiderTipi.values.firstWhere(
        (e) => e.name == map['tipi'],
        orElse: () => GelirGiderTipi.gelir,
      ),
      baslik: map['baslik'] as String,
      tutar: (map['tutar'] as num?)?.toDouble() ?? 0.0,
      tarih: map['tarih'] != null
          ? DateTime.parse(map['tarih'] as String)
          : DateTime.now(),
      kategori: map['kategori'] as String?,
      cariHesapId: map['cari_hesap_id'] as int?,
      cariHesapUnvan: map['cari_hesap_unvan'] as String?,
      aciklama: map['aciklama'] as String?,
      faturaNo: map['fatura_no'] as String?,
      projectId: map['project_id'] as int?,
      olusturmaTarihi: map['olusturma_tarihi'] != null
          ? DateTime.parse(map['olusturma_tarihi'] as String)
          : DateTime.now(),
    );
  }
}

enum GelirGiderTipi { gelir, gider }


