import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gizlilik Politikası'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             _buildSectionTitle('Giriş'),
             _buildParagraph('Muhasebe Pro ("Uygulama") olarak kişisel verilerinizin güvenliğine ve gizliliğine büyük önem veriyoruz. İşbu Gizlilik Politikası, uygulamamızı kullandığınızda veya hizmetlerimize eriştiğinizde kişisel verilerinizin nasıl toplandığını, kullanıldığını, paylaşıldığını ve korunduğunu açıklamak amacıyla hazırlanmıştır. Uygulamamızı kullanarak bu politikada belirtilen uygulamaları kabul etmiş sayılırsınız.'),
             
             _buildSectionTitle('1. Toplanan Veriler'),
             _buildParagraph('Uygulamamızı kullanırken aşağıdaki veri türleri toplanabilir veya işlenebilir:\n\n'
                 'a) Kayıt ve Profil Bilgileri: Uygulama içerisinde hesap oluşturduğunuzda ad, soyad ve e-posta adresi gibi temel iletişim bilgileriniz.\n'
                 'b) Finansal ve Operasyonel Veriler: Uygulama içerisinde kendi isteğinizle girdiğiniz müşteri/cari bilgileri, gelir/gider kayıtları, projeler ve personel puantaj verileri.\n'
                 'c) Cihaz ve Kullanım Verileri: IP adresi, cihaz modeli, işletim sistemi sürümü, uygulama içi gezinme bilgileri ve hata (crash) raporları.\n'
                 'd) Reklam ve Çerez Verileri: Google AdMob ve benzeri entegre servisler aracılığıyla toplanan mobil reklam kimliği (Mobile Ad ID) ve kullanım alışkanlıkları.'),
             
             _buildSectionTitle('2. Verilerin Kullanım Amaçları'),
             _buildParagraph('Toplanan veriler aşağıdaki amaçlarla kullanılmaktadır:\n'
                 '- Uygulamanın temel işlevlerinin (muhasebe, personel yönetimi vb.) sağlanması ve bulut senkronizasyonu,\n'
                 '- Kullanıcı hesabınızın yönetilmesi ve müşteri desteği sağlanması,\n'
                 '- Uygulama performansının izlenmesi, hataların giderilmesi ve hizmet kalitesinin artırılması,\n'
                 '- Yasal yükümlülüklerimizin yerine getirilmesi,\n'
                 '- İlgi alanınıza uygun ve kişiselleştirilmiş reklamların (Google AdMob aracılığıyla) sunulabilmesi.'),
             
             _buildSectionTitle('3. Verilerin Üçüncü Taraflarla Paylaşımı'),
             _buildParagraph('Kişisel verileriniz kural olarak izniniz olmadan üçüncü kişilerle paylaşılmaz. Ancak şu durumlarda paylaşım yapılabilir:\n\n'
                 'a) Hizmet Sağlayıcılar: Uygulamanın çalışması için gerekli olan sunucu barındırma (örn. Supabase) ve analitik altyapı hizmeti sunan güvenilir iş ortakları.\n'
                 'b) Reklam Ağları: Uygulamamız ücretsiz hizmet verebilmek adına Google AdMob entegrasyonu kullanmaktadır. AdMob, kişiselleştirilmiş reklamlar göstermek için cihaz reklam tanımlayıcınızı kullanabilir. Bu veri paylaşımı tamamen Google Gizlilik Politikası çerçevesinde yürütülür.\n'
                 'c) Yasal Zorunluluklar: Kanunların gerektirdiği hallerde, yetkili resmi kurumların usulüne uygun taleplerini karşılamak amacıyla.'),
             
             _buildSectionTitle('4. Veri Güvenliği'),
             _buildParagraph('Verilerinizin yetkisiz erişime, değiştirilmeye, ifşa edilmeye veya yok edilmeye karşı korunması için gelişmiş şifreleme ve güvenli sunucu (SSL/TLS) protokolleri gibi endüstri standardı güvenlik önlemleri almaktayız. Ancak, internet üzerinden yapılan hiçbir iletimin veya elektronik depolama yönteminin %100 güvenli olduğu garanti edilemez.'),
             
             _buildSectionTitle('5. Veri Saklama ve Silme Politikası'),
             _buildParagraph('Kişisel verileriniz, işlenme amaçları ortadan kalkana veya tarafınızca silinmesi talep edilene kadar saklanır. Uygulama içerisindeki "Hesabı Sil" özelliğini kullanarak veya destek e-posta adresimiz üzerinden bizimle iletişime geçerek hesabınızın ve bağlı tüm finansal verilerinizin (bulut ve yerel veritabanı dahil) kalıcı olarak silinmesini talep edebilirsiniz.'),
             
             _buildSectionTitle('6. Çocukların Gizliliği'),
             _buildParagraph('Uygulamamız 13 yaşın altındaki çocuklara yönelik değildir. 13 yaşından küçük olduğunu bildiğimiz kişilerden bilerek kişisel veri toplamıyoruz. Eğer çocuğunuzun bize veri sağladığını fark ederseniz lütfen bizimle iletişime geçin, bu veriler derhal silinecektir.'),
             
             _buildSectionTitle('7. Kullanıcı Hakları (KVKK / GDPR Kapsamında)'),
             _buildParagraph('Kişisel verilerinizin işlenip işlenmediğini öğrenme, işlenmişse buna ilişkin bilgi talep etme, işlenme amacını ve amacına uygun kullanılıp kullanılmadığını öğrenme, eksik/yanlış verilerin düzeltilmesini isteme ve verilerin silinmesini veya yok edilmesini talep etme haklarına sahipsiniz.'),
             
             _buildSectionTitle('8. İletişim'),
             _buildParagraph('Bu Gizlilik Politikası, uygulama içi veri işleme veya haklarınızla ilgili her türlü soru, görüş ve sildirme talepleriniz için uygulama içerisindeki "Bize Ulaşın / Destek" menüsünü kullanabilir veya destek_muhasebePro@hotmail.com adresine e-posta gönderebilirsiniz.'),
             
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
