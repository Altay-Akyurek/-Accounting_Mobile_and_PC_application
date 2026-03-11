import 'package:flutter/material.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanım Şartları'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             _buildSectionTitle('1. Taraflar ve Konu'),
             _buildParagraph('İşbu Kullanım Şartları Sözleşmesi ("Sözleşme"), Muhasebe Pro mobil uygulamasını ("Uygulama") cihazına indiren veya kullanan tüm kullanıcılar ("Kullanıcı") ile Uygulama Geliştiricisi arasında akdedilmiştir. Uygulamayı kullanarak veya erişim sağlayarak bu sözleşmenin tamamını okuduğunuzu, anladığınızı ve onayladığınızı kabul etmiş sayılırsınız.'),
             
             _buildSectionTitle('2. Hizmetin Kapsamı'),
             _buildParagraph('Muhasebe Pro, Kullanıcılarına gelir-gider takibi, cari hesap yönetimi, personel puantaj kaydı, hakediş düzenleme ve ön muhasebe işlemleri yapabilmeleri için dijital bir altyapı sunar. Uygulama, resmi bir mali müşavirlik/muhasebeci hizmeti vermez; yalnızca Kullanıcının girdiği verileri organize etmesine yardımcı olan bir yazılım aracıdır.'),
             
             _buildSectionTitle('3. Kullanım Koşulları ve Yükümlülükler'),
             _buildParagraph('a) Kullanıcı, Uygulamaya kaydettiği tüm kişi, kurum, tutar, unvan ve benzeri verilerin doğruluğundan, yasallığından ve güncelliğinden bizzat sorumludur. Yanlış, yanıltıcı veya hukuka aykırı verilerden kaynaklanabilecek her türlü hukuki ve cezai sorumluluk Kullanıcı\'ya aittir.\n\n'
                 'b) Kullanıcı hesabının güvenliği Kullanıcının sorumluluğundadır. E-posta ve şifre bilgilerinin üçüncü kişilerle paylaşılması sonucu doğacak zararlardan Uygulama sorumlu tutulamaz.\n\n'
                 'c) Uygulama, tersine mühendislik (reverse engineering) yöntemleriyle incelenemez, kaynak kodları kopyalanamaz veya Uygulamanın çalışmasını engelleyecek siber saldırılarda bulunulamaz.'),
             
             _buildSectionTitle('4. Premium Hizmetler (In-App Purchases)'),
             _buildParagraph('Uygulama, temel özellikleri ücretsiz olarak (reklam destekli) sunmakta olup, bazı gelişmiş özellikler (bulut yedekleme, sınırsız PDF dışa aktarma, reklamsız deneyim vb.) uygulama içi satın alma (Premium) yöntemiyle sunulmaktadır. Abonelik veya satın alma iptalleri/iadesi Google Play Store politikalarına tabidir.'),
             
             _buildSectionTitle('5. Reklamlar ve Üçüncü Taraf Bağlantıları'),
             _buildParagraph('Uygulamanın ücretsiz sürümünde Google AdMob servisleri aracılığıyla reklamlar gösterilmektedir. Bu reklamlara tıklanması sonucunda yönlendirilen internet sitelerinin veya uygulamaların içerik, güvenlik ve gizlilik koşulları tamamen ilgili web sitelerine ait olup, Muhasebe Pro bu içeriklerden ötürü hiçbir garanti vermez ve sorumluluk kabul etmez.'),
             
             _buildSectionTitle('6. Sorumluluğun Sınırlandırılması'),
             _buildParagraph('Uygulama Geliştiricisi, Uygulamanın kesintisiz, hatasız veya siber saldırılara karşı tamamen bağışık olduğunu garanti etmez. Cihaz arızaları, işletim sistemi güncellemeleri, internet kesintileri veya yazılım hataları nedeniyle oluşabilecek veri kaybı, iş kaybı, kar kaybı veya herhangi bir nevi dolaylı veya dolaysız zarardan Uygulama Geliştiricisi sorumlu tutulamaz. Kullanıcının Kritik verilerini düzenli aralıklarla cihaz dışına veya güvendiği bir bulut platformuna yedeklemesi şiddetle tavsiye edilir.'),
             
             _buildSectionTitle('7. Fikri Mülkiyet Hakları'),
             _buildParagraph('Muhasebe Pro uygulamasının tasarımı, kaynak kodları, arayüzü, logoları, grafikleri ve tüm telif/marka hakları Muhasebe Pro geliştiricilerine aittir. Kullanıcı, uygulamayı yalnızca bireysel kullanım lisansı kapsamında kullanabilir, kopyalayamaz, satamaz ve çoğaltamaz.'),
             
             _buildSectionTitle('8. Değişiklikler ve Bildirimler'),
             _buildParagraph('Uygulama Geliştiricisi, yasal güncellemeler, yeni özellikler veya güvenlik gereksinimleri doğrultusunda işbu Kullanım Şartları\'nı dilediği zaman tek taraflı olarak değiştirme hakkını saklı tutar. Yapılan değişiklikler Uygulama içerisinde güncellendiği andan itibaren geçerlilik kazanır.'),
             
             _buildSectionTitle('9. Sözleşmenin Feshi'),
             _buildParagraph('Kullanıcı, dilediği zaman Uygulamayı cihazından kaldırarak veya hesabını silerek hizmeti kullanmayı bırakabilir. Uygulama Geliştiricisi, Kullanıcının işbu Kullanım Şartlarına aykırı davranması halinde bildirimde bulunmaksızın kullanıcının hesabını askıya alabilir veya silebilir.'),
             
             _buildSectionTitle('10. İletişim'),
             _buildParagraph('Bu sözleşmeyle ilgili her türlü soru ve teknik desteğiniz için "Bize Ulaşın / Destek" menüsü üzerinden veya destek_muhasebePro@hotmail.com adresinden bizimle iletişime geçebilirsiniz.'),
             
             const SizedBox(height: 32),
             const Text('Yürürlük Tarihi: 10 Mart 2026', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF011627)),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
      textAlign: TextAlign.justify,
    );
  }
}
