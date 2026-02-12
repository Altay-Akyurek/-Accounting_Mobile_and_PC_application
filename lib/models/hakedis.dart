enum HakedisDurum { bekliyor, tahsilEdildi, iptal }

class Hakedis {
  final int? id;
  final int projectId;
  final String? projectAd;
  final String baslik; // 1. Hakediş, 2. Hakediş vb.
  final double tutar; // Saf hakediş tutarı
  final double kdvOrani; // %20 vb.
  final double stopajOrani; // %5 vb.
  final double teminatOrani; // %5 vb.
  final HakedisDurum durum;
  final DateTime tarih;
  final String? aciklama;
  final DateTime olusturmaTarihi;

  Hakedis({
    this.id,
    required this.projectId,
    this.projectAd,
    required this.baslik,
    required this.tutar,
    this.kdvOrani = 20.0,
    this.stopajOrani = 0.0,
    this.teminatOrani = 0.0,
    this.durum = HakedisDurum.bekliyor,
    required this.tarih,
    this.aciklama,
    DateTime? olusturmaTarihi,
  }) : olusturmaTarihi = olusturmaTarihi ?? DateTime.now();

  double get kdvTutari => tutar * (kdvOrani / 100);
  double get stopajTutari => tutar * (stopajOrani / 100);
  double get teminatTutari => tutar * (teminatOrani / 100);
  double get netTutar => tutar + kdvTutari - stopajTutari - teminatTutari;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'project_ad': projectAd ?? '',
      'baslik': baslik,
      'tutar': tutar,
      'kdv_orani': kdvOrani,
      'stopaj_orani': stopajOrani,
      'teminat_orani': teminatOrani,
      'durum': durum.name,
      'tarih': tarih.toIso8601String(),
      'aciklama': aciklama ?? '',
      'olusturma_tarihi': olusturmaTarihi.toIso8601String(),
    };
  }

  factory Hakedis.fromMap(Map<String, dynamic> map) {
    return Hakedis(
      id: map['id'] as int?,
      projectId: map['project_id'] as int,
      projectAd: map['project_ad'] as String?,
      baslik: map['baslik'] as String,
      tutar: (map['tutar'] as num?)?.toDouble() ?? 0.0,
      kdvOrani: (map['kdv_orani'] as num?)?.toDouble() ?? 20.0,
      stopajOrani: (map['stopaj_orani'] as num?)?.toDouble() ?? 0.0,
      teminatOrani: (map['teminat_orani'] as num?)?.toDouble() ?? 0.0,
      durum: HakedisDurum.values.firstWhere(
        (e) => e.name == map['durum'],
        orElse: () => HakedisDurum.bekliyor,
      ),
      tarih: DateTime.parse(map['tarih'] as String),
      aciklama: map['aciklama'] as String?,
      olusturmaTarihi: map['olusturma_tarihi'] != null 
          ? DateTime.parse(map['olusturma_tarihi'] as String)
          : DateTime.parse(map['tarih'] as String),
    );
  }
}
