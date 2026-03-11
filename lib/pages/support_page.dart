import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  Future<void> _sendEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'destek_muhasebePro@hotmail.com',
      query: _encodeQueryParameters(<String, String>{
        'subject': 'Muhasebe Pro - Destek Talebi / Geri Bildirim',
        'body': 'Lütfen karşılaştığınız sorunu veya önerinizi detaylı bir şekilde açıklayın:\n\n'
                '--- Sorun / Öneri Detayları ---\n\n\n'
                '--- Cihaz ve Uygulama Bilgileri ---\n'
                'Uygulama Sürümü: 1.0.0\n'
                'Cihaz Modeli: (Lütfen Belirtin)\n'
                'İşletim Sistemi: (Lütfen Belirtin)\n'
      }),
    );

    try {
      if (!await launchUrl(emailLaunchUri)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('E-posta uygulaması bulunamadı veya açılamadı.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E-posta uygulaması açılamadı.')),
        );
      }
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Bize Ulaşın / Destek'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.support_agent_rounded,
                  size: 80,
                  color: Color(0xFF2EC4B6),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Müşteri Hizmetleri ve Teknik Destek',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF011627),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Uygulamamızı tercih ettiğiniz için teşekkür ederiz. Muhasebe Pro deneyiminizi en üst seviyeye taşımak amacıyla uzman destek ekibimiz sorularınızı yanıtlamaya ve teknik problemlerinizi çözmeye hazırdır. Uygulama ile ilgili karşılaştığınız her türlü sorunu çözebilmemiz için detaylı olarak bizimle paylaşmaktan çekinmeyin.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 24),
                
                _buildInfoCard(
                  icon: Icons.access_time_filled_rounded,
                  title: 'Çalışma ve Yanıt Süreleri',
                  description: 'Destek taleplerinize hafta içi (Pazartesi-Cuma) 09:00 - 18:00 saatleri arasında, ortalama 24 ile 48 saat içerisinde geri dönüş yapılmaktadır.',
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  icon: Icons.privacy_tip_rounded,
                  title: 'Kişisel Veri Talepleri',
                  description: 'Kullanım koşulları veya gizlilik sözleşmesi uyarınca hesabınızın silinmesi ve verilerinizin yok edilmesi taleplerinizi doğrudan destek mailimize e-posta aracılığıyla iletebilirsiniz.',
                ),
                
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2EC4B6).withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Resmi Destek Adresi',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.email_rounded, color: Color(0xFF2EC4B6)),
                          SizedBox(width: 12),
                          Text(
                            'destek_muhasebePro@hotmail.com',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF011627)
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _sendEmail(context),
                    icon: const Icon(Icons.send_rounded),
                    label: const Text(
                      'Destek Talebi Oluştur (E-posta)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF011627),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Muhasebe Pro v1.0.0 © 2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.orange, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF011627)),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
