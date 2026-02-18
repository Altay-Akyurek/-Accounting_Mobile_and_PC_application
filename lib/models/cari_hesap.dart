class CariHesap {
  final int? id;
  final String unvan;
  final String? vergiNo;
  final String? vergiDairesi;
  final String? telefon;
  final String? email;
  final String? adres;
  final double bakiye;
  final bool isKasa;
  final DateTime olusturmaTarihi;

  CariHesap({
    this.id,
    required this.unvan,
    this.vergiNo,
    this.vergiDairesi,
    this.telefon,
    this.email,
    this.adres,
    this.bakiye = 0.0,
    this.isKasa = false,
    DateTime? olusturmaTarihi,
  }) : olusturmaTarihi = olusturmaTarihi ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unvan': unvan,
      'vergi_no': vergiNo ?? '',
      'vergi_dairesi': vergiDairesi ?? '',
      'telefon': telefon ?? '',
      'email': email ?? '',
      'adres': adres ?? '',
      'bakiye': bakiye,
      'is_kasa': isKasa ? 1 : 0,
      'olusturma_tarihi': olusturmaTarihi.toIso8601String(),
    };
  }

  factory CariHesap.fromMap(Map<String, dynamic> map) {
    return CariHesap(
      id: map['id'] as int?,
      unvan: map['unvan'] as String,
      vergiNo: map['vergi_no'] as String?,
      vergiDairesi: map['vergi_dairesi'] as String?,
      telefon: map['telefon'] as String?,
      email: map['email'] as String?,
      adres: map['adres'] as String?,
      bakiye: (map['bakiye'] as num?)?.toDouble() ?? 0.0,
      isKasa: map['is_kasa'] == 1 || map['is_kasa'] == true,
      olusturmaTarihi: map['olusturma_tarihi'] != null 
          ? DateTime.parse(map['olusturma_tarihi'] as String) 
          : DateTime.now(),
    );
  }

  CariHesap copyWith({
    int? id,
    String? unvan,
    String? vergiNo,
    String? vergiDairesi,
    String? telefon,
    String? email,
    String? adres,
    double? bakiye,
    bool? isKasa,
    DateTime? olusturmaTarihi,
  }) {
    return CariHesap(
      id: id ?? this.id,
      unvan: unvan ?? this.unvan,
      vergiNo: vergiNo ?? this.vergiNo,
      vergiDairesi: vergiDairesi ?? this.vergiDairesi,
      telefon: telefon ?? this.telefon,
      email: email ?? this.email,
      adres: adres ?? this.adres,
      bakiye: bakiye ?? this.bakiye,
      isKasa: isKasa ?? this.isKasa,
      olusturmaTarihi: olusturmaTarihi ?? this.olusturmaTarihi,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CariHesap &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
