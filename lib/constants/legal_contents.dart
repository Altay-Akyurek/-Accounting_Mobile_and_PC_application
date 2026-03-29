import 'package:flutter/material.dart';

class LegalContent {
  static String getTermsTitle(BuildContext context, String locale) {
    return locale == 'tr' ? 'Kullanım Şartları' : 'Terms of Use';
  }

  static List<Map<String, String>> getTermsSections(String locale) {
    if (locale == 'tr') {
      return [
        {
          'title': '1. Taraflar ve Konu',
          'body': 'İşbu Kullanım Şartları Sözleşmesi ("Sözleşme"), Muhasebe Pro mobil uygulamasını ("Uygulama") cihazına indiren veya kullanan tüm kullanıcılar ("Kullanıcı") ile Uygulama Geliştiricisi arasında akdedilmiştir. Uygulamayı kullanarak veya erişim sağlayarak bu sözleşmenin tamamını okuduğunuzu, anladığınızı ve onayladığınızı kabul etmiş sayılırsınız.'
        },
        {
          'title': '2. Hizmetin Kapsamı',
          'body': 'Muhasebe Pro, Kullanıcılarına gelir-gider takibi, cari hesap yönetimi, personel puantaj kaydı, hakediş düzenleme ve ön muhasebe işlemleri yapabilmeleri için dijital bir altyapı sunar. Uygulama, resmi bir mali müşavirlik/muhasebeci hizmeti vermez; yalnızca Kullanıcının girdiği verileri organize etmesine yardımcı olan bir yazılım aracıdır.'
        },
        {
          'title': '3. Kullanım Koşulları ve Yükümlülükler',
          'body': 'a) Kullanıcı, Uygulamaya kaydettiği tüm kişi, kurum, tutar, unvan ve benzeri verilerin doğruluğundan, yasallığından ve güncelliğinden bizzat sorumludur. Yanlış, yanıltıcı veya hukuka aykırı verilerden kaynaklanabilecek her türlü hukuki ve cezai sorumluluk Kullanıcı\'ya aittir.\n\nb) Kullanıcı hesabının güvenliği Kullanıcının sorumluluğundadır. E-posta ve şifre bilgilerinin üçüncü kişilerle paylaşılması sonucu doğacak zararlardan Uygulama sorumlu tutulamaz.\n\nc) Uygulama, tersine mühendislik (reverse engineering) yöntemleriyle incelenemez, kaynak kodları kopyalanamaz veya Uygulamanın çalışmasını engelleyecek siber saldırılarda bulunulamaz.'
        },
        // ... more sections
      ];
    } else {
      return [
        {
          'title': '1. Parties and Subject',
          'body': 'This Terms of Use Agreement ("Agreement") is concluded between all users ("User") who download or use the Muhasebe Pro mobile application ("Application") and the Application Developer. By using or accessing the Application, you are deemed to have read, understood, and approved the entire agreement.'
        },
        {
          'title': '2. Scope of Service',
          'body': 'Muhasebe Pro provides a digital infrastructure for its Users to perform income-expense tracking, current account management, personnel attendance recording, progress payment arrangement, and preliminary accounting operations. The Application does not provide official financial consultancy/accounting services; it is only a software tool that helps the User organize the data they enter.'
        },
        {
          'title': '3. Conditions of Use and Obligations',
          'body': 'a) The User is personally responsible for the accuracy, legality, and up-to-dateness of all persons, institutions, amounts, titles, and similar data they record in the Application. Any legal and criminal responsibility that may arise from incorrect, misleading, or unlawful data belongs to the User.\n\nb) The security of the User account is the responsibility of the User. The Application cannot be held responsible for damages resulting from sharing e-mail and password information with third parties.\n\nc) The Application cannot be examined by reverse engineering methods, source codes cannot be copied, or cyber attacks that prevent the operation of the Application cannot be carried out.'
        },
      ];
    }
  }

  static String getTermsEffectiveDate(String locale) {
    return locale == 'tr' ? 'Yürürlük Tarihi: 10 Mart 2026' : 'Effective Date: March 10, 2026';
  }

  static String getPrivacyTitle(BuildContext context, String locale) {
    return locale == 'tr' ? 'Gizlilik Politikası' : 'Privacy Policy';
  }

  static List<Map<String, String>> getPrivacySections(String locale) {
    if (locale == 'tr') {
      return [
        {
          'title': 'Giriş',
          'body': 'Muhasebe Pro ("Uygulama") olarak kişisel verilerinizin güvenliğine ve gizliliğine büyük önem veriyoruz. İşbu Gizlilik Politikası, uygulamamızı kullandığınızda veya hizmetlerimize eriştiğinizde kişisel verilerinizin nasıl toplandığını, kullanıldığını, paylaşıldığını ve korunduğunu açıklamak amacıyla hazırlanmıştır.'
        },
        {
          'title': '1. Toplanan Veriler',
          'body': 'a) Kayıt ve Profil Bilgileri: Ad, soyad ve e-posta adresi.\nb) Finansal Veriler: Müşteri/cari bilgileri, gelir/gider kayıtları, projeler ve personel puantaj verileri.\nc) Cihaz Verileri: IP adresi, cihaz modeli ve hata raporları.'
        },
        // ... abbreviated for focus
      ];
    } else {
      return [
        {
          'title': 'Introduction',
          'body': 'As Muhasebe Pro ("Application"), we attach great importance to the security and privacy of your personal data. This Privacy Policy has been prepared to explain how your personal data is collected, used, shared, and protected when you use our application or access our services.'
        },
        {
          'title': '1. Data Collected',
          'body': 'a) Registration and Profile Information: Basic contact information such as name, surname, and e-mail address.\nb) Financial and Operational Data: Customer/current account information, income/expense records, projects, and personnel attendance data that you voluntarily enter.\nc) Device and Usage Data: IP address, device model, operating system version, and crash reports.'
        },
      ];
    }
  }
}
