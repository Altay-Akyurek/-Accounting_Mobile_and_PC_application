import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'Muhasebe Pro'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get dashboard;

  /// No description provided for @netCash.
  ///
  /// In tr, this message translates to:
  /// **'NET NAKİT (KASA)'**
  String get netCash;

  /// No description provided for @current.
  ///
  /// In tr, this message translates to:
  /// **'GÜNCEL'**
  String get current;

  /// No description provided for @totalCollection.
  ///
  /// In tr, this message translates to:
  /// **'TAHSİLAT'**
  String get totalCollection;

  /// No description provided for @remainingDebt.
  ///
  /// In tr, this message translates to:
  /// **'KALAN BORÇ'**
  String get remainingDebt;

  /// No description provided for @quickAccess.
  ///
  /// In tr, this message translates to:
  /// **'HIZLI ERİŞİM'**
  String get quickAccess;

  /// No description provided for @accounting.
  ///
  /// In tr, this message translates to:
  /// **'Muhasebe'**
  String get accounting;

  /// No description provided for @reports.
  ///
  /// In tr, this message translates to:
  /// **'Raporlar'**
  String get reports;

  /// No description provided for @personnel.
  ///
  /// In tr, this message translates to:
  /// **'Personel'**
  String get personnel;

  /// No description provided for @settlement.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Kesimi'**
  String get settlement;

  /// No description provided for @bottleneckAnalysis.
  ///
  /// In tr, this message translates to:
  /// **'DARBOĞAZ VE KAZANÇ ANALİZİ'**
  String get bottleneckAnalysis;

  /// No description provided for @statusAnalysis.
  ///
  /// In tr, this message translates to:
  /// **'DURUM ANALİZİ'**
  String get statusAnalysis;

  /// No description provided for @profitableProjects.
  ///
  /// In tr, this message translates to:
  /// **'EN KARLI PROJELER'**
  String get profitableProjects;

  /// No description provided for @performanceIndicator.
  ///
  /// In tr, this message translates to:
  /// **'PERFORMANS GÖSTERGESİ'**
  String get performanceIndicator;

  /// No description provided for @openedProjects.
  ///
  /// In tr, this message translates to:
  /// **'Açık Projeler'**
  String get openedProjects;

  /// No description provided for @totalCurrentAccounts.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Cari'**
  String get totalCurrentAccounts;

  /// No description provided for @incomeExpenseBalance.
  ///
  /// In tr, this message translates to:
  /// **'Gelir / Gider Dengesi'**
  String get incomeExpenseBalance;

  /// No description provided for @positive.
  ///
  /// In tr, this message translates to:
  /// **'Pozitif'**
  String get positive;

  /// No description provided for @incomeShare.
  ///
  /// In tr, this message translates to:
  /// **'Gelir Payı'**
  String get incomeShare;

  /// No description provided for @expenseShare.
  ///
  /// In tr, this message translates to:
  /// **'Gider Payı'**
  String get expenseShare;

  /// No description provided for @noProfitData.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kârlılık verisi olan proje yok.'**
  String get noProfitData;

  /// No description provided for @premiumAnalysis.
  ///
  /// In tr, this message translates to:
  /// **'PREMİUM ANALİZ'**
  String get premiumAnalysis;

  /// No description provided for @unlock.
  ///
  /// In tr, this message translates to:
  /// **'Kilidi Aç'**
  String get unlock;

  /// No description provided for @workerAnalysis.
  ///
  /// In tr, this message translates to:
  /// **'İşçi Analizi'**
  String get workerAnalysis;

  /// No description provided for @ourPortfolio.
  ///
  /// In tr, this message translates to:
  /// **'Portföyümüz'**
  String get ourPortfolio;

  /// No description provided for @laborSummary.
  ///
  /// In tr, this message translates to:
  /// **'İşçilik Özeti'**
  String get laborSummary;

  /// No description provided for @premiumPackages.
  ///
  /// In tr, this message translates to:
  /// **'Premium Paketler'**
  String get premiumPackages;

  /// No description provided for @logout.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get logout;

  /// No description provided for @language.
  ///
  /// In tr, this message translates to:
  /// **'Dil Seçeneği'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Dil Seçin'**
  String get selectLanguage;

  /// No description provided for @premiumSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Muhasebe Pro Premium'**
  String get premiumSubtitle;

  /// No description provided for @premiumDescription.
  ///
  /// In tr, this message translates to:
  /// **'İşinizi daha profesyonel yönetmek için yükseltin.'**
  String get premiumDescription;

  /// No description provided for @featureRemoveAds.
  ///
  /// In tr, this message translates to:
  /// **'Tüm reklamları kaldırın'**
  String get featureRemoveAds;

  /// No description provided for @featureUnlimitedPDF.
  ///
  /// In tr, this message translates to:
  /// **'Sınırsız PDF raporu oluşturun'**
  String get featureUnlimitedPDF;

  /// No description provided for @featureCloudBackup.
  ///
  /// In tr, this message translates to:
  /// **'Sınırsız bulut yedekleme'**
  String get featureCloudBackup;

  /// No description provided for @featureB2B.
  ///
  /// In tr, this message translates to:
  /// **'B2B/Şirket özellikleri erişimi'**
  String get featureB2B;

  /// No description provided for @monthlyPackage.
  ///
  /// In tr, this message translates to:
  /// **'Aylık Paket'**
  String get monthlyPackage;

  /// No description provided for @yearlyPackage.
  ///
  /// In tr, this message translates to:
  /// **'Yıllık Paket'**
  String get yearlyPackage;

  /// No description provided for @monthlyPrice.
  ///
  /// In tr, this message translates to:
  /// **'₺99.99 / ay'**
  String get monthlyPrice;

  /// No description provided for @yearlyPrice.
  ///
  /// In tr, this message translates to:
  /// **'₺899.99 / yıl'**
  String get yearlyPrice;

  /// No description provided for @cancelAnytime.
  ///
  /// In tr, this message translates to:
  /// **'İstediğiniz zaman iptal edin.'**
  String get cancelAnytime;

  /// No description provided for @save25.
  ///
  /// In tr, this message translates to:
  /// **'%25 daha hesaplı!'**
  String get save25;

  /// No description provided for @mostPopular.
  ///
  /// In tr, this message translates to:
  /// **'EN POPÜLER'**
  String get mostPopular;

  /// No description provided for @continueButton.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get continueButton;

  /// No description provided for @congratulations.
  ///
  /// In tr, this message translates to:
  /// **'Tebrikler!'**
  String get congratulations;

  /// No description provided for @premiumActivatedMonthly.
  ///
  /// In tr, this message translates to:
  /// **'Aylık Premium üyeliğiniz başarıyla aktif edildi. Artık tüm sınırsız özelliklerin tadını çıkarabilirsiniz.'**
  String get premiumActivatedMonthly;

  /// No description provided for @premiumActivatedYearly.
  ///
  /// In tr, this message translates to:
  /// **'Yıllık Premium üyeliğiniz başarıyla aktif edildi. Artık tüm sınırsız özelliklerin tadını çıkarabilirsiniz.'**
  String get premiumActivatedYearly;

  /// No description provided for @great.
  ///
  /// In tr, this message translates to:
  /// **'Harika!'**
  String get great;

  /// No description provided for @premiumSuccessSnackBar.
  ///
  /// In tr, this message translates to:
  /// **'Premium özellikler aktif edildi!'**
  String get premiumSuccessSnackBar;

  /// No description provided for @login.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get login;

  /// No description provided for @register.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get register;

  /// No description provided for @email.
  ///
  /// In tr, this message translates to:
  /// **'E-posta Adresi'**
  String get email;

  /// No description provided for @password.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifremi Unuttum'**
  String get forgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In tr, this message translates to:
  /// **'GİRİŞ YAP'**
  String get loginButton;

  /// No description provided for @registerButton.
  ///
  /// In tr, this message translates to:
  /// **'KAYIT OL'**
  String get registerButton;

  /// No description provided for @noAccount.
  ///
  /// In tr, this message translates to:
  /// **'Henüz hesabınız yok mu? '**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In tr, this message translates to:
  /// **'Zaten hesabınız var mı? '**
  String get haveAccount;

  /// No description provided for @fillAllFields.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen tüm alanları doldurun'**
  String get fillAllFields;

  /// No description provided for @accountAlreadyRegistered.
  ///
  /// In tr, this message translates to:
  /// **'Bu hesapla daha önce kayıt yapılmış.'**
  String get accountAlreadyRegistered;

  /// No description provided for @invalidCredentials.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresi veya şifre hatalı.'**
  String get invalidCredentials;

  /// No description provided for @emailNotConfirmed.
  ///
  /// In tr, this message translates to:
  /// **'E-posta Onayı Gerekli'**
  String get emailNotConfirmed;

  /// No description provided for @emailNotConfirmedDetail.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yapabilmek için e-posta adresinizi onaylamanız gerekiyor. Lütfen gelen kutunuzu (ve gereksiz kutusunu) kontrol edin.'**
  String get emailNotConfirmedDetail;

  /// No description provided for @rateLimitExceeded.
  ///
  /// In tr, this message translates to:
  /// **'Çok fazla e-posta gönderim denemesi yaptınız. Lütfen bir süre sonra tekrar deneyin.'**
  String get rateLimitExceeded;

  /// No description provided for @registrationSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Başarılı!'**
  String get registrationSuccess;

  /// No description provided for @registrationSuccessDetail.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızı oluşturduk! Lütfen e-posta adresinize gönderdiğimiz onay linkine tıklayın.'**
  String get registrationSuccessDetail;

  /// No description provided for @registrationInstruction.
  ///
  /// In tr, this message translates to:
  /// **'Onaylamadan giriş yapamazsınız.'**
  String get registrationInstruction;

  /// No description provided for @okIUnderstand.
  ///
  /// In tr, this message translates to:
  /// **'Tamam, Anladım'**
  String get okIUnderstand;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @emailSent.
  ///
  /// In tr, this message translates to:
  /// **'E-posta Gönderildi'**
  String get emailSent;

  /// No description provided for @resetPasswordEmailSent.
  ///
  /// In tr, this message translates to:
  /// **'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi. Lütfen kontrol edin.'**
  String get resetPasswordEmailSent;

  /// No description provided for @ok.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get ok;

  /// No description provided for @emailSendError.
  ///
  /// In tr, this message translates to:
  /// **'E-posta gönderilemedi. Lütfen SMTP ayarlarınızı kontrol edin veya 5 dakika sonra tekrar deneyin.'**
  String get emailSendError;

  /// No description provided for @corporateCloudSolution.
  ///
  /// In tr, this message translates to:
  /// **'Kurumsal Bulut Çözümü'**
  String get corporateCloudSolution;

  /// No description provided for @secureConnection.
  ///
  /// In tr, this message translates to:
  /// **'SSL GÜVENLİ BAĞLANTI'**
  String get secureConnection;

  /// No description provided for @appTagline.
  ///
  /// In tr, this message translates to:
  /// **'Geleceğin Finans Yönetimi'**
  String get appTagline;

  /// No description provided for @projects.
  ///
  /// In tr, this message translates to:
  /// **'PROJELER'**
  String get projects;

  /// No description provided for @newProjectCard.
  ///
  /// In tr, this message translates to:
  /// **'YENİ PROJE KARTI'**
  String get newProjectCard;

  /// No description provided for @noProjectsDefined.
  ///
  /// In tr, this message translates to:
  /// **'Henüz tanımlı proje bulunmuyor'**
  String get noProjectsDefined;

  /// No description provided for @noProjectsInStatus.
  ///
  /// In tr, this message translates to:
  /// **'{status} durumunda proje bulunmuyor'**
  String noProjectsInStatus(String status);

  /// No description provided for @createFirstProject.
  ///
  /// In tr, this message translates to:
  /// **'İLK PROJEYİ OLUŞTUR'**
  String get createFirstProject;

  /// No description provided for @all.
  ///
  /// In tr, this message translates to:
  /// **'Hepsi'**
  String get all;

  /// No description provided for @active.
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get active;

  /// No description provided for @suspended.
  ///
  /// In tr, this message translates to:
  /// **'Askıda'**
  String get suspended;

  /// No description provided for @completed.
  ///
  /// In tr, this message translates to:
  /// **'Bitti'**
  String get completed;

  /// No description provided for @deleteProject.
  ///
  /// In tr, this message translates to:
  /// **'Projeyi Sil'**
  String get deleteProject;

  /// No description provided for @deleteProjectConfirm.
  ///
  /// In tr, this message translates to:
  /// **'\"{name}\" projesini silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'**
  String deleteProjectConfirm(String name);

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'İPTAL'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In tr, this message translates to:
  /// **'SİL'**
  String get delete;

  /// No description provided for @projectDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Proje başarıyla silindi'**
  String get projectDeleted;

  /// No description provided for @projectName.
  ///
  /// In tr, this message translates to:
  /// **'Proje Adı'**
  String get projectName;

  /// No description provided for @customerFirm.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri / Firma (Cari)'**
  String get customerFirm;

  /// No description provided for @estimatedBudget.
  ///
  /// In tr, this message translates to:
  /// **'Tahmini Bütçe'**
  String get estimatedBudget;

  /// No description provided for @status.
  ///
  /// In tr, this message translates to:
  /// **'Durum'**
  String get status;

  /// No description provided for @saveProject.
  ///
  /// In tr, this message translates to:
  /// **'PROJEYİ KAYDET'**
  String get saveProject;

  /// No description provided for @projectCreated.
  ///
  /// In tr, this message translates to:
  /// **'Proje başarıyla oluşturuldu'**
  String get projectCreated;

  /// No description provided for @enterProjectName.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen proje adını girin'**
  String get enterProjectName;

  /// No description provided for @errorPrefix.
  ///
  /// In tr, this message translates to:
  /// **'Hata: {message}'**
  String errorPrefix(String message);

  /// No description provided for @budgetLabel.
  ///
  /// In tr, this message translates to:
  /// **'BÜTÇE'**
  String get budgetLabel;

  /// No description provided for @summary.
  ///
  /// In tr, this message translates to:
  /// **'ÖZET'**
  String get summary;

  /// No description provided for @hakedisler.
  ///
  /// In tr, this message translates to:
  /// **'HAKEDİŞLER'**
  String get hakedisler;

  /// No description provided for @expenses.
  ///
  /// In tr, this message translates to:
  /// **'GİDERLER'**
  String get expenses;

  /// No description provided for @collected.
  ///
  /// In tr, this message translates to:
  /// **'Tahsil Edilen'**
  String get collected;

  /// No description provided for @totalExpense.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Gider'**
  String get totalExpense;

  /// No description provided for @netProfit.
  ///
  /// In tr, this message translates to:
  /// **'Net Kar'**
  String get netProfit;

  /// No description provided for @projectBudget.
  ///
  /// In tr, this message translates to:
  /// **'Proje Bütçesi'**
  String get projectBudget;

  /// No description provided for @projectDetails.
  ///
  /// In tr, this message translates to:
  /// **'Proje Detayları'**
  String get projectDetails;

  /// No description provided for @startingDate.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç'**
  String get startingDate;

  /// No description provided for @description.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama'**
  String get description;

  /// No description provided for @notEntered.
  ///
  /// In tr, this message translates to:
  /// **'Girilmemiş'**
  String get notEntered;

  /// No description provided for @changeProjectStatus.
  ///
  /// In tr, this message translates to:
  /// **'Proje Durumu Değiştir'**
  String get changeProjectStatus;

  /// No description provided for @statusUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Proje durumu {status} olarak güncellendi'**
  String statusUpdated(String status);

  /// No description provided for @noHakedisYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz hakediş girilmemiş'**
  String get noHakedisYet;

  /// No description provided for @downloadAllHakedisPDF.
  ///
  /// In tr, this message translates to:
  /// **'TÜM HAKEDİŞLERİ PDF İNDİR'**
  String get downloadAllHakedisPDF;

  /// No description provided for @newHakedis.
  ///
  /// In tr, this message translates to:
  /// **'YENİ HAKEDİŞ'**
  String get newHakedis;

  /// No description provided for @collected_caps.
  ///
  /// In tr, this message translates to:
  /// **'TAHSİL EDİLDİ'**
  String get collected_caps;

  /// No description provided for @pending.
  ///
  /// In tr, this message translates to:
  /// **'BEKLİYOR'**
  String get pending;

  /// No description provided for @markAsPending.
  ///
  /// In tr, this message translates to:
  /// **'Bekliyor İşaretle'**
  String get markAsPending;

  /// No description provided for @markAsCollected.
  ///
  /// In tr, this message translates to:
  /// **'Tahsil Edildi İşaretle'**
  String get markAsCollected;

  /// No description provided for @materialService.
  ///
  /// In tr, this message translates to:
  /// **'Malzeme/Hizmet'**
  String get materialService;

  /// No description provided for @laborPaid.
  ///
  /// In tr, this message translates to:
  /// **'İşçilik (Ödenen)'**
  String get laborPaid;

  /// No description provided for @accountPayments.
  ///
  /// In tr, this message translates to:
  /// **'Cari Ödemeler'**
  String get accountPayments;

  /// No description provided for @cashOutflows.
  ///
  /// In tr, this message translates to:
  /// **'Kasa Çıkışları'**
  String get cashOutflows;

  /// No description provided for @sunday.
  ///
  /// In tr, this message translates to:
  /// **'Pazar'**
  String get sunday;

  /// No description provided for @downloadPDF.
  ///
  /// In tr, this message translates to:
  /// **'PDF İndir'**
  String get downloadPDF;

  /// No description provided for @deleteHakedis.
  ///
  /// In tr, this message translates to:
  /// **'Hakedişi Sil'**
  String get deleteHakedis;

  /// No description provided for @gross.
  ///
  /// In tr, this message translates to:
  /// **'Brüt'**
  String get gross;

  /// No description provided for @deductions.
  ///
  /// In tr, this message translates to:
  /// **'Kesintiler'**
  String get deductions;

  /// No description provided for @netCollection.
  ///
  /// In tr, this message translates to:
  /// **'Net Tahsilat'**
  String get netCollection;

  /// No description provided for @deleteHakedisConfirm.
  ///
  /// In tr, this message translates to:
  /// **'\"{title}\" hakedişini silmek istediğinize emin misiniz?'**
  String deleteHakedisConfirm(String title);

  /// No description provided for @expense.
  ///
  /// In tr, this message translates to:
  /// **'Gider'**
  String get expense;

  /// No description provided for @laborPayment.
  ///
  /// In tr, this message translates to:
  /// **'İşçilik Ödemesi'**
  String get laborPayment;

  /// No description provided for @puantajRecord.
  ///
  /// In tr, this message translates to:
  /// **'Puantaj Kaydı'**
  String get puantajRecord;

  /// No description provided for @noExpensesYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz gider kaydı bulunamadı'**
  String get noExpensesYet;

  /// No description provided for @hakedisEntry.
  ///
  /// In tr, this message translates to:
  /// **'Hakediş Girişi'**
  String get hakedisEntry;

  /// No description provided for @hakedisTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hakediş Başlığı'**
  String get hakedisTitle;

  /// No description provided for @hakedisTitleHint.
  ///
  /// In tr, this message translates to:
  /// **'örn: 1. Hakediş veya Ocak Ayı Hakedişi'**
  String get hakedisTitleHint;

  /// No description provided for @hakedisAmountExcVat.
  ///
  /// In tr, this message translates to:
  /// **'Hakediş Tutarı (KDV Hariç)'**
  String get hakedisAmountExcVat;

  /// No description provided for @taxAndDeductionRates.
  ///
  /// In tr, this message translates to:
  /// **'Vergi ve Kesinti Oranları (%)'**
  String get taxAndDeductionRates;

  /// No description provided for @vat.
  ///
  /// In tr, this message translates to:
  /// **'KDV'**
  String get vat;

  /// No description provided for @withholding.
  ///
  /// In tr, this message translates to:
  /// **'Stopaj'**
  String get withholding;

  /// No description provided for @guarantee.
  ///
  /// In tr, this message translates to:
  /// **'Teminat'**
  String get guarantee;

  /// No description provided for @hakedisDate.
  ///
  /// In tr, this message translates to:
  /// **'Hakediş Tarihi'**
  String get hakedisDate;

  /// No description provided for @descriptionOptional.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama / Not (Opsiyonel)'**
  String get descriptionOptional;

  /// No description provided for @saveHakedis.
  ///
  /// In tr, this message translates to:
  /// **'HAKEDİŞİ KAYDET'**
  String get saveHakedis;

  /// No description provided for @enterTitleAndAmount.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen başlık ve tutar giriniz.'**
  String get enterTitleAndAmount;

  /// No description provided for @accountingAndCurrent.
  ///
  /// In tr, this message translates to:
  /// **'MUHASEBE & CARİ'**
  String get accountingAndCurrent;

  /// No description provided for @pleaseSelectCari.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir cari hesap seçiniz'**
  String get pleaseSelectCari;

  /// No description provided for @descriptionRequired.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama zorunludur'**
  String get descriptionRequired;

  /// No description provided for @amountRequired.
  ///
  /// In tr, this message translates to:
  /// **'Borç veya Alacak tutarından biri girilmelidir'**
  String get amountRequired;

  /// No description provided for @transactionSaved.
  ///
  /// In tr, this message translates to:
  /// **'İşlem kaydedildi'**
  String get transactionSaved;

  /// No description provided for @transactionDeleted.
  ///
  /// In tr, this message translates to:
  /// **'İşlem silindi'**
  String get transactionDeleted;

  /// No description provided for @collectionIn.
  ///
  /// In tr, this message translates to:
  /// **'Tahsilat (Giriş)'**
  String get collectionIn;

  /// No description provided for @paymentOut.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme (Çıkış)'**
  String get paymentOut;

  /// No description provided for @incomingDebt.
  ///
  /// In tr, this message translates to:
  /// **'Gelecek (Borç)'**
  String get incomingDebt;

  /// No description provided for @outgoingCredit.
  ///
  /// In tr, this message translates to:
  /// **'Çıkacak (Alacak)'**
  String get outgoingCredit;

  /// No description provided for @netCashKasa.
  ///
  /// In tr, this message translates to:
  /// **'Net Nakit (Kasa)'**
  String get netCashKasa;

  /// No description provided for @netStatusBalance.
  ///
  /// In tr, this message translates to:
  /// **'Net Durum (Bakiye)'**
  String get netStatusBalance;

  /// No description provided for @addNewTransaction.
  ///
  /// In tr, this message translates to:
  /// **'YENİ İŞLEM EKLE'**
  String get addNewTransaction;

  /// No description provided for @quickTransactionEntry.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı İşlem Girişi'**
  String get quickTransactionEntry;

  /// No description provided for @cariAccountSelection.
  ///
  /// In tr, this message translates to:
  /// **'Cari Hesap Seçimi'**
  String get cariAccountSelection;

  /// No description provided for @descriptionNote.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama / Not'**
  String get descriptionNote;

  /// No description provided for @debtIncoming.
  ///
  /// In tr, this message translates to:
  /// **'Borç (Alınacak)'**
  String get debtIncoming;

  /// No description provided for @creditOutgoing.
  ///
  /// In tr, this message translates to:
  /// **'Alacak (Verilen)'**
  String get creditOutgoing;

  /// No description provided for @saveTransaction.
  ///
  /// In tr, this message translates to:
  /// **'İŞLEMİ KAYDET'**
  String get saveTransaction;

  /// No description provided for @allCaris.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Cariler'**
  String get allCaris;

  /// No description provided for @selectProject.
  ///
  /// In tr, this message translates to:
  /// **'Proje Seç'**
  String get selectProject;

  /// No description provided for @allProjects.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Projeler'**
  String get allProjects;

  /// No description provided for @statusIn.
  ///
  /// In tr, this message translates to:
  /// **'GİRİŞ'**
  String get statusIn;

  /// No description provided for @statusOut.
  ///
  /// In tr, this message translates to:
  /// **'ÇIKIŞ'**
  String get statusOut;

  /// No description provided for @statusDebt.
  ///
  /// In tr, this message translates to:
  /// **'BORÇ'**
  String get statusDebt;

  /// No description provided for @statusCredit.
  ///
  /// In tr, this message translates to:
  /// **'ALACAK'**
  String get statusCredit;

  /// No description provided for @tableDate.
  ///
  /// In tr, this message translates to:
  /// **'TARİH'**
  String get tableDate;

  /// No description provided for @tableCari.
  ///
  /// In tr, this message translates to:
  /// **'CARİ'**
  String get tableCari;

  /// No description provided for @tableDescription.
  ///
  /// In tr, this message translates to:
  /// **'AÇIKLAMA'**
  String get tableDescription;

  /// No description provided for @tableStatus.
  ///
  /// In tr, this message translates to:
  /// **'DURUM'**
  String get tableStatus;

  /// No description provided for @tableIncoming.
  ///
  /// In tr, this message translates to:
  /// **'GELECEK'**
  String get tableIncoming;

  /// No description provided for @tableOutgoing.
  ///
  /// In tr, this message translates to:
  /// **'ÇIKACAK'**
  String get tableOutgoing;

  /// No description provided for @tableBalance.
  ///
  /// In tr, this message translates to:
  /// **'BAKİYE'**
  String get tableBalance;

  /// No description provided for @adminDashboard.
  ///
  /// In tr, this message translates to:
  /// **'Yönetici Kontrol Paneli'**
  String get adminDashboard;

  /// No description provided for @financialAnalysis.
  ///
  /// In tr, this message translates to:
  /// **'Finansal Analiz'**
  String get financialAnalysis;

  /// No description provided for @profitabilityRate.
  ///
  /// In tr, this message translates to:
  /// **'Karlılık Oranı'**
  String get profitabilityRate;

  /// No description provided for @expenseBreakdown.
  ///
  /// In tr, this message translates to:
  /// **'GİDER KIRILIMI'**
  String get expenseBreakdown;

  /// No description provided for @projectBasedPerformance.
  ///
  /// In tr, this message translates to:
  /// **'PROJE BAZLI PERFORMANS'**
  String get projectBasedPerformance;

  /// No description provided for @pendingWorkerPayment.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen İşçi Ödemesi'**
  String get pendingWorkerPayment;

  /// No description provided for @personnelTracking.
  ///
  /// In tr, this message translates to:
  /// **'PERSONEL TAKİBİ'**
  String get personnelTracking;

  /// No description provided for @fieldPersonnelManagement.
  ///
  /// In tr, this message translates to:
  /// **'Saha Personel Yönetimi'**
  String get fieldPersonnelManagement;

  /// No description provided for @personnelSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Puantaj ve maaş tahakkuk takibi'**
  String get personnelSubtitle;

  /// No description provided for @getSummary.
  ///
  /// In tr, this message translates to:
  /// **'ÖZET AL'**
  String get getSummary;

  /// No description provided for @personnelRegistration.
  ///
  /// In tr, this message translates to:
  /// **'PERSONEL KAYIT'**
  String get personnelRegistration;

  /// No description provided for @dismissed.
  ///
  /// In tr, this message translates to:
  /// **'İŞTEN AYRILDI'**
  String get dismissed;

  /// No description provided for @fieldWorker.
  ///
  /// In tr, this message translates to:
  /// **'Saha Personeli'**
  String get fieldWorker;

  /// No description provided for @attendance.
  ///
  /// In tr, this message translates to:
  /// **'PUANTAJ'**
  String get attendance;

  /// No description provided for @dismissWorker.
  ///
  /// In tr, this message translates to:
  /// **'İşten Çıkar'**
  String get dismissWorker;

  /// No description provided for @documents.
  ///
  /// In tr, this message translates to:
  /// **'Belgeler'**
  String get documents;

  /// No description provided for @permanentlyDelete.
  ///
  /// In tr, this message translates to:
  /// **'Kalıcı Olarak Sil'**
  String get permanentlyDelete;

  /// No description provided for @personnelListEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Personel listesi boş'**
  String get personnelListEmpty;

  /// No description provided for @newPersonnelCard.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Personel Kartı'**
  String get newPersonnelCard;

  /// No description provided for @nameSurname.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad'**
  String get nameSurname;

  /// No description provided for @rolePosition.
  ///
  /// In tr, this message translates to:
  /// **'Görev / Pozisyon'**
  String get rolePosition;

  /// No description provided for @salaryAmount.
  ///
  /// In tr, this message translates to:
  /// **'Maaş Tutarı'**
  String get salaryAmount;

  /// No description provided for @salaryType.
  ///
  /// In tr, this message translates to:
  /// **'Maaş Türü'**
  String get salaryType;

  /// No description provided for @daily.
  ///
  /// In tr, this message translates to:
  /// **'Günlük'**
  String get daily;

  /// No description provided for @monthly.
  ///
  /// In tr, this message translates to:
  /// **'Aylık'**
  String get monthly;

  /// No description provided for @hourly.
  ///
  /// In tr, this message translates to:
  /// **'Saatlik'**
  String get hourly;

  /// No description provided for @saveAsCari.
  ///
  /// In tr, this message translates to:
  /// **'Cari Hesap Olarak Kaydet'**
  String get saveAsCari;

  /// No description provided for @completeRegistration.
  ///
  /// In tr, this message translates to:
  /// **'KAYDI TAMAMLA'**
  String get completeRegistration;

  /// No description provided for @personnelGeneralSummary.
  ///
  /// In tr, this message translates to:
  /// **'PERSONEL GENEL ÖZETİ'**
  String get personnelGeneralSummary;

  /// No description provided for @totalPersonnel.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Personel'**
  String get totalPersonnel;

  /// No description provided for @activePersonnel.
  ///
  /// In tr, this message translates to:
  /// **'Aktif Personel'**
  String get activePersonnel;

  /// No description provided for @dismissedPersonnel.
  ///
  /// In tr, this message translates to:
  /// **'Ayrılan Personel'**
  String get dismissedPersonnel;

  /// No description provided for @totalAccrued.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Tahakkuk (Hak)'**
  String get totalAccrued;

  /// No description provided for @totalPaid.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Ödenen'**
  String get totalPaid;

  /// No description provided for @remainingBalance.
  ///
  /// In tr, this message translates to:
  /// **'Kalan Borç (Bakiye)'**
  String get remainingBalance;

  /// No description provided for @workingHours.
  ///
  /// In tr, this message translates to:
  /// **'Çalışma Saati'**
  String get workingHours;

  /// No description provided for @overtimeHours.
  ///
  /// In tr, this message translates to:
  /// **'Mesai Saati'**
  String get overtimeHours;

  /// No description provided for @hourlyWage.
  ///
  /// In tr, this message translates to:
  /// **'Saatlik Ücret'**
  String get hourlyWage;

  /// No description provided for @calculatedAmount.
  ///
  /// In tr, this message translates to:
  /// **'HESAPLANAN TUTAR'**
  String get calculatedAmount;

  /// No description provided for @selectStatus.
  ///
  /// In tr, this message translates to:
  /// **'DURUM SEÇİN'**
  String get selectStatus;

  /// No description provided for @normal.
  ///
  /// In tr, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @onLeave.
  ///
  /// In tr, this message translates to:
  /// **'İzinli'**
  String get onLeave;

  /// No description provided for @medicalLeave.
  ///
  /// In tr, this message translates to:
  /// **'Raporlu'**
  String get medicalLeave;

  /// No description provided for @excusedLeave.
  ///
  /// In tr, this message translates to:
  /// **'Mazeretli'**
  String get excusedLeave;

  /// No description provided for @unexcusedLeave.
  ///
  /// In tr, this message translates to:
  /// **'İzinsiz'**
  String get unexcusedLeave;

  /// No description provided for @refresh.
  ///
  /// In tr, this message translates to:
  /// **'Yenile'**
  String get refresh;

  /// No description provided for @stockManagement.
  ///
  /// In tr, this message translates to:
  /// **'Stok Yönetimi'**
  String get stockManagement;

  /// No description provided for @stockCode.
  ///
  /// In tr, this message translates to:
  /// **'Stok Kodu'**
  String get stockCode;

  /// No description provided for @stockCodeRequired.
  ///
  /// In tr, this message translates to:
  /// **'Stok kodu zorunludur'**
  String get stockCodeRequired;

  /// No description provided for @stockName.
  ///
  /// In tr, this message translates to:
  /// **'Stok Adı'**
  String get stockName;

  /// No description provided for @stockNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Stok adı zorunludur'**
  String get stockNameRequired;

  /// No description provided for @unit.
  ///
  /// In tr, this message translates to:
  /// **'Birim'**
  String get unit;

  /// No description provided for @stockAmount.
  ///
  /// In tr, this message translates to:
  /// **'Stok Miktarı'**
  String get stockAmount;

  /// No description provided for @criticalStockLevel.
  ///
  /// In tr, this message translates to:
  /// **'Kritik Stok Seviyesi'**
  String get criticalStockLevel;

  /// No description provided for @purchasePriceLabel.
  ///
  /// In tr, this message translates to:
  /// **'Alış Fiyatı'**
  String get purchasePriceLabel;

  /// No description provided for @salePriceLabel.
  ///
  /// In tr, this message translates to:
  /// **'Satış Fiyatı'**
  String get salePriceLabel;

  /// No description provided for @vatRate.
  ///
  /// In tr, this message translates to:
  /// **'KDV Oranı'**
  String get vatRate;

  /// No description provided for @newStock.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Stok'**
  String get newStock;

  /// No description provided for @editStock.
  ///
  /// In tr, this message translates to:
  /// **'Stok Düzenle'**
  String get editStock;

  /// No description provided for @noStocksYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz stok eklenmemiş'**
  String get noStocksYet;

  /// No description provided for @noSearchResultFound.
  ///
  /// In tr, this message translates to:
  /// **'Arama sonucu bulunamadı'**
  String get noSearchResultFound;

  /// No description provided for @code.
  ///
  /// In tr, this message translates to:
  /// **'Kod'**
  String get code;

  /// No description provided for @stockLabel.
  ///
  /// In tr, this message translates to:
  /// **'Stok'**
  String get stockLabel;

  /// No description provided for @companyPortfolio.
  ///
  /// In tr, this message translates to:
  /// **'Şirket Portföyü'**
  String get companyPortfolio;

  /// No description provided for @visionarySolutions.
  ///
  /// In tr, this message translates to:
  /// **'Vizyoner Çözümler'**
  String get visionarySolutions;

  /// No description provided for @buildingFutureWithXActiveProjects.
  ///
  /// In tr, this message translates to:
  /// **'{count} Aktif Proje ile Geleceği İnşa Ediyoruz'**
  String buildingFutureWithXActiveProjects(int count);

  /// No description provided for @companySummary.
  ///
  /// In tr, this message translates to:
  /// **'Şirket Özeti'**
  String get companySummary;

  /// No description provided for @financialHealth.
  ///
  /// In tr, this message translates to:
  /// **'Finansal Sağlık'**
  String get financialHealth;

  /// No description provided for @ourProjects.
  ///
  /// In tr, this message translates to:
  /// **'Projelerimiz'**
  String get ourProjects;

  /// No description provided for @ourTeam.
  ///
  /// In tr, this message translates to:
  /// **'Ekibimiz'**
  String get ourTeam;

  /// No description provided for @milestones.
  ///
  /// In tr, this message translates to:
  /// **'Kilometre Taşları'**
  String get milestones;

  /// No description provided for @collectionDebtRatio.
  ///
  /// In tr, this message translates to:
  /// **'Tahsilat / Borç Oranı'**
  String get collectionDebtRatio;

  /// No description provided for @greenCollectionsRedDebts.
  ///
  /// In tr, this message translates to:
  /// **'Yeşil: Tahsilatlar, Kırmızı: Bekleyen Borçlar'**
  String get greenCollectionsRedDebts;

  /// No description provided for @companyOverviewText.
  ///
  /// In tr, this message translates to:
  /// **'Şirketimiz, finansal yönetim alanında uzman personeliyle sektöre liderlik etmektedir. Bugüne kadar {revenue} değerinde hakediş tahsilatı gerçekleştirilmiş ve şu an {debt} tutarında işçilik borcu yönetilmektedir.'**
  String companyOverviewText(String revenue, String debt);

  /// No description provided for @noProjectRecordsYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz proje kaydı bulunmuyor.'**
  String get noProjectRecordsYet;

  /// No description provided for @noActiveWorkersYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz aktif çalışan bulunmuyor.'**
  String get noActiveWorkersYet;

  /// No description provided for @monthlyPersonnel.
  ///
  /// In tr, this message translates to:
  /// **'Aylık Personel'**
  String get monthlyPersonnel;

  /// No description provided for @dailyPersonnel.
  ///
  /// In tr, this message translates to:
  /// **'Yevmiyeli Personel'**
  String get dailyPersonnel;

  /// No description provided for @pendingSalary.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen Maaş'**
  String get pendingSalary;

  /// No description provided for @noMilestonesYet.
  ///
  /// In tr, this message translates to:
  /// **'Kilometre taşı bulunmuyor.'**
  String get noMilestonesYet;

  /// No description provided for @newProjectStarted.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Proje Başlatıldı'**
  String get newProjectStarted;

  /// No description provided for @projectCompletedSuccessfully.
  ///
  /// In tr, this message translates to:
  /// **'Proje Başarıyla Tamamlandı'**
  String get projectCompletedSuccessfully;

  /// No description provided for @projectSuspendedTemporarily.
  ///
  /// In tr, this message translates to:
  /// **'Proje Geçici Olarak Durduruldu'**
  String get projectSuspendedTemporarily;

  /// No description provided for @newTeamMemberJoined.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Ekip Arkadaşı Katıldı'**
  String get newTeamMemberJoined;

  /// No description provided for @teamMemberLeft.
  ///
  /// In tr, this message translates to:
  /// **'Ekip Arkadaşı Ayrıldı'**
  String get teamMemberLeft;

  /// No description provided for @financialCollectionMade.
  ///
  /// In tr, this message translates to:
  /// **'Finansal Tahsilat Yapıldı'**
  String get financialCollectionMade;

  /// No description provided for @highAmountExpenseRecord.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek Tutarlı Gider Kaydı'**
  String get highAmountExpenseRecord;

  /// No description provided for @unknownEvent.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmeyen Olay'**
  String get unknownEvent;

  /// No description provided for @periodIncomeExpenseBalance.
  ///
  /// In tr, this message translates to:
  /// **'Dönem Gelir / Gider Dengesi'**
  String get periodIncomeExpenseBalance;

  /// No description provided for @xPercentPositive.
  ///
  /// In tr, this message translates to:
  /// **'%{percent} Pozitif'**
  String xPercentPositive(String percent);

  /// No description provided for @laborSummaryReport_caps.
  ///
  /// In tr, this message translates to:
  /// **'İŞÇİLİK ÖZET RAPORU'**
  String get laborSummaryReport_caps;

  /// No description provided for @dateRange.
  ///
  /// In tr, this message translates to:
  /// **'Tarih Aralığı'**
  String get dateRange;

  /// No description provided for @selectedPeriodRecords.
  ///
  /// In tr, this message translates to:
  /// **'Seçili Dönem Kayıtları'**
  String get selectedPeriodRecords;

  /// No description provided for @xHoursWork.
  ///
  /// In tr, this message translates to:
  /// **'{hours} Saat Çalışma'**
  String xHoursWork(double hours);

  /// No description provided for @noRecordFoundInRange.
  ///
  /// In tr, this message translates to:
  /// **'Bu tarih aralığında kayıt bulunamadı.'**
  String get noRecordFoundInRange;

  /// No description provided for @unknown.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmiyor'**
  String get unknown;

  /// No description provided for @total.
  ///
  /// In tr, this message translates to:
  /// **'Toplam'**
  String get total;

  /// No description provided for @xHours.
  ///
  /// In tr, this message translates to:
  /// **'{hours} Saat'**
  String xHours(double hours);

  /// No description provided for @tableProject_caps.
  ///
  /// In tr, this message translates to:
  /// **'PROJE'**
  String get tableProject_caps;

  /// No description provided for @tableHour_caps.
  ///
  /// In tr, this message translates to:
  /// **'SAAT'**
  String get tableHour_caps;

  /// No description provided for @tableMesai_caps.
  ///
  /// In tr, this message translates to:
  /// **'MESAİ'**
  String get tableMesai_caps;

  /// No description provided for @tableAmount_caps.
  ///
  /// In tr, this message translates to:
  /// **'TUTAR'**
  String get tableAmount_caps;

  /// No description provided for @tableDate_caps.
  ///
  /// In tr, this message translates to:
  /// **'TARİH'**
  String get tableDate_caps;

  /// No description provided for @workerDocuments.
  ///
  /// In tr, this message translates to:
  /// **'{name} - Belgeler'**
  String workerDocuments(String name);

  /// No description provided for @severanceAndRights.
  ///
  /// In tr, this message translates to:
  /// **'Tazminat ve Haklar (Düzenlenebilir)'**
  String get severanceAndRights;

  /// No description provided for @severancePay.
  ///
  /// In tr, this message translates to:
  /// **'Kıdem Tazminatı'**
  String get severancePay;

  /// No description provided for @noticePay.
  ///
  /// In tr, this message translates to:
  /// **'İhbar Tazminatı'**
  String get noticePay;

  /// No description provided for @leavePay.
  ///
  /// In tr, this message translates to:
  /// **'İzin Ücretleri'**
  String get leavePay;

  /// No description provided for @separationReason.
  ///
  /// In tr, this message translates to:
  /// **'Ayrılma Nedeni'**
  String get separationReason;

  /// No description provided for @createDocument.
  ///
  /// In tr, this message translates to:
  /// **'Belge Oluştur'**
  String get createDocument;

  /// No description provided for @serviceCertificate.
  ///
  /// In tr, this message translates to:
  /// **'Çalışma Belgesi'**
  String get serviceCertificate;

  /// No description provided for @releaseForm.
  ///
  /// In tr, this message translates to:
  /// **'İbraname'**
  String get releaseForm;

  /// No description provided for @compensationBreakdown.
  ///
  /// In tr, this message translates to:
  /// **'Tazminat Dökümü'**
  String get compensationBreakdown;

  /// No description provided for @payrollPusula.
  ///
  /// In tr, this message translates to:
  /// **'Ücret Pusulası'**
  String get payrollPusula;

  /// No description provided for @sgkStatement.
  ///
  /// In tr, this message translates to:
  /// **'SGK Bildirgesi'**
  String get sgkStatement;

  /// No description provided for @paymentReceipt.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme Dekontu'**
  String get paymentReceipt;

  /// No description provided for @editDocument.
  ///
  /// In tr, this message translates to:
  /// **'{title} - Düzenle'**
  String editDocument(String title);

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'KAYDET'**
  String get save;

  /// No description provided for @reasonHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Emeklilik, İstifa, 4857/25-II...'**
  String get reasonHint;

  /// No description provided for @serviceCertificate_template.
  ///
  /// In tr, this message translates to:
  /// **'Sayın {name}, işyerimizde {startDate} tarihinden {endDate} tarihine kadar \"{position}\" görevinde çalışmıştır. Ayrılma nedeni: {reason}. Bu belge, ilgilinin isteği üzerine düzenlenmiştir.'**
  String serviceCertificate_template(
    String name,
    String startDate,
    String endDate,
    String position,
    String reason,
  );

  /// No description provided for @releaseForm_template.
  ///
  /// In tr, this message translates to:
  /// **'İşyerinden {date} tarihinde ayrılırken; almış olduğum maaş, kıdem tazminatı, ihbar tazminatı ve diğer tüm sosyal haklarımı eksiksiz olarak teslim aldığımı, işverenden herhangi bir hak ve alacağımın kalmadığını beyan ederek işvereni tamamen ibra ederim.'**
  String releaseForm_template(String date);

  /// No description provided for @compensationBreakdown_template.
  ///
  /// In tr, this message translates to:
  /// **'PERSONEL HAK VE ALACAK DÖKÜMÜ:\n\n1. Kıdem Tazminatı: {severance}\n2. İhbar Tazminatı: {notice}\n3. İzin Ücretleri: {leave}\n\nTOPLAM ÖDENEN: {total}\n\nİşbu döküm personelin iş akdi sonlandığında hak ettiği yasal alacakları göstermektedir.'**
  String compensationBreakdown_template(
    String severance,
    String notice,
    String leave,
    String total,
  );

  /// No description provided for @payrollPusula_template.
  ///
  /// In tr, this message translates to:
  /// **'ÜCRET HESAP PUSULASI:\n\nPersonelin görev süresi boyunca tahakkuk eden son ay ücreti ve ek ödemeleri aşağıda belirtilen banka hesaplarına veya elden teslim edilmiştir.\n\nÖdeme Kalemi: Kıdem/İhbar/Maaş\nAçıklama: İş akdi feshi neticesinde yapılan toplu ödeme.'**
  String get payrollPusula_template;

  /// No description provided for @sgkStatement_template.
  ///
  /// In tr, this message translates to:
  /// **'SGK İŞTEN AYRILIŞ BİLDİRGESİ ÖZETİ:\n\nPersonel: {name}\nTC No: {tcNo}\nAyrılış Tarihi: {date}\nAyrılış Nedeni: {reason}\n\nBu döküm SGK sistemine girilen işten ayrılış bildiriminin bir kopyasıdır.'**
  String sgkStatement_template(
    String name,
    String tcNo,
    String date,
    String reason,
  );

  /// No description provided for @paymentReceipt_template.
  ///
  /// In tr, this message translates to:
  /// **'BANKA ÖDEME DEKONTU / TEDİYE MAKBUZU:\n\nÖdeme Yapılan: {name}\nTutar: {amount}\nAçıklama: Maaş, kıdem, ihbar ve tüm yan hakların toplu tasfiye ödemesidir.\n\nÖdeme Tarihi: {date}'**
  String paymentReceipt_template(String name, String amount, String date);

  /// No description provided for @personnelInfo.
  ///
  /// In tr, this message translates to:
  /// **'PERSONEL BİLGİLERİ:'**
  String get personnelInfo;

  /// No description provided for @idNo.
  ///
  /// In tr, this message translates to:
  /// **'TC No'**
  String get idNo;

  /// No description provided for @employerSignature.
  ///
  /// In tr, this message translates to:
  /// **'İşveren İmza'**
  String get employerSignature;

  /// No description provided for @workerSignature.
  ///
  /// In tr, this message translates to:
  /// **'İşçi İmza'**
  String get workerSignature;

  /// No description provided for @categoryLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get categoryLabel;

  /// No description provided for @cariLabel.
  ///
  /// In tr, this message translates to:
  /// **'Cari'**
  String get cariLabel;

  /// No description provided for @dateLabel.
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get dateLabel;

  /// No description provided for @edit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get edit;

  /// No description provided for @financeKasaManagement.
  ///
  /// In tr, this message translates to:
  /// **'FİNANS & KASA YÖNETİMİ'**
  String get financeKasaManagement;

  /// No description provided for @recentTransactions.
  ///
  /// In tr, this message translates to:
  /// **'Son Hareketler'**
  String get recentTransactions;

  /// No description provided for @pendingCollections.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen Tahsilatlar'**
  String get pendingCollections;

  /// No description provided for @noBalanceToReset.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırlanacak bakiye bulunamadı.'**
  String get noBalanceToReset;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Şifreniz başarıyla güncellendi. Giriş yapabilirsiniz.'**
  String get passwordResetSuccess;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In tr, this message translates to:
  /// **'Şifreler eşleşmiyor'**
  String get passwordsDoNotMatch;

  /// No description provided for @pleaseEnterNewPassword.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen yeni şifre girin'**
  String get pleaseEnterNewPassword;

  /// No description provided for @secondPage.
  ///
  /// In tr, this message translates to:
  /// **'İkinci Sayfa'**
  String get secondPage;

  /// No description provided for @goBack.
  ///
  /// In tr, this message translates to:
  /// **'Geri Dön'**
  String get goBack;

  /// No description provided for @bankKasa.
  ///
  /// In tr, this message translates to:
  /// **'BANKA / KASA'**
  String get bankKasa;

  /// No description provided for @cekSenet.
  ///
  /// In tr, this message translates to:
  /// **'ÇEK / SENET'**
  String get cekSenet;

  /// No description provided for @cashMovement.
  ///
  /// In tr, this message translates to:
  /// **'NAKİT HAREKETİ'**
  String get cashMovement;

  /// No description provided for @documentEntry.
  ///
  /// In tr, this message translates to:
  /// **'EVRAK GİRİŞİ'**
  String get documentEntry;

  /// No description provided for @mainVault.
  ///
  /// In tr, this message translates to:
  /// **'Ana Kasa (TL)'**
  String get mainVault;

  /// No description provided for @checksGiven.
  ///
  /// In tr, this message translates to:
  /// **'Verilen Çekler'**
  String get checksGiven;

  /// No description provided for @dailyPay.
  ///
  /// In tr, this message translates to:
  /// **'YEVMİYE'**
  String get dailyPay;

  /// No description provided for @monthlyPay.
  ///
  /// In tr, this message translates to:
  /// **'MAAŞ'**
  String get monthlyPay;

  /// No description provided for @hourlyRate.
  ///
  /// In tr, this message translates to:
  /// **'Saatlik Ücret'**
  String get hourlyRate;

  /// No description provided for @overtimeHourly.
  ///
  /// In tr, this message translates to:
  /// **'Mesai Ücreti'**
  String get overtimeHourly;

  /// No description provided for @deleteWorkerConfirmNote.
  ///
  /// In tr, this message translates to:
  /// **'isimli personeli ve tüm verilerini (puantaj, ödemeler vb.) kalıcı olarak silmek istediğinize emin misiniz?'**
  String deleteWorkerConfirmNote(Object name);

  /// No description provided for @dismissConfirmNote.
  ///
  /// In tr, this message translates to:
  /// **'isimli personeli işten çıkarmak istediğinize emin misiniz? (Geçmiş veriler korunur)'**
  String dismissConfirmNote(Object name);

  /// No description provided for @attendanceAndSalaryTracking.
  ///
  /// In tr, this message translates to:
  /// **'Puantaj ve maaş tahakkuk takibi'**
  String get attendanceAndSalaryTracking;

  /// No description provided for @workerDismissedInfo.
  ///
  /// In tr, this message translates to:
  /// **'Personel işten çıkarıldı'**
  String get workerDismissedInfo;

  /// No description provided for @workerDeletedInfo.
  ///
  /// In tr, this message translates to:
  /// **'Personel silindi'**
  String get workerDeletedInfo;

  /// No description provided for @fullName.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad'**
  String get fullName;

  /// No description provided for @dutyPosition.
  ///
  /// In tr, this message translates to:
  /// **'Görev / Pozisyon'**
  String get dutyPosition;

  /// No description provided for @saveAsCariAccount.
  ///
  /// In tr, this message translates to:
  /// **'Cari Hesap Olarak Kaydet'**
  String get saveAsCariAccount;

  /// No description provided for @requiredForSalaryPayments.
  ///
  /// In tr, this message translates to:
  /// **'Maaş ödemeleri takibi için gereklidir'**
  String get requiredForSalaryPayments;

  /// No description provided for @remainingDebtBalance.
  ///
  /// In tr, this message translates to:
  /// **'Kalan Borç (Bakiye)'**
  String get remainingDebtBalance;

  /// No description provided for @onReport.
  ///
  /// In tr, this message translates to:
  /// **'Raporlu'**
  String get onReport;

  /// No description provided for @onExcuse.
  ///
  /// In tr, this message translates to:
  /// **'Mazeretli'**
  String get onExcuse;

  /// No description provided for @unauthorized.
  ///
  /// In tr, this message translates to:
  /// **'İzinsiz'**
  String get unauthorized;

  /// No description provided for @noProjectSelected.
  ///
  /// In tr, this message translates to:
  /// **'Proje Seçilmedi'**
  String get noProjectSelected;

  /// No description provided for @relatedProject.
  ///
  /// In tr, this message translates to:
  /// **'İlgili Proje'**
  String get relatedProject;

  /// No description provided for @deleteRecord.
  ///
  /// In tr, this message translates to:
  /// **'Kaydı Sil'**
  String get deleteRecord;

  /// No description provided for @monday_short.
  ///
  /// In tr, this message translates to:
  /// **'Pzt'**
  String get monday_short;

  /// No description provided for @tuesday_short.
  ///
  /// In tr, this message translates to:
  /// **'Sal'**
  String get tuesday_short;

  /// No description provided for @wednesday_short.
  ///
  /// In tr, this message translates to:
  /// **'Çar'**
  String get wednesday_short;

  /// No description provided for @thursday_short.
  ///
  /// In tr, this message translates to:
  /// **'Per'**
  String get thursday_short;

  /// No description provided for @friday_short.
  ///
  /// In tr, this message translates to:
  /// **'Cum'**
  String get friday_short;

  /// No description provided for @saturday_short.
  ///
  /// In tr, this message translates to:
  /// **'Cmt'**
  String get saturday_short;

  /// No description provided for @sunday_short.
  ///
  /// In tr, this message translates to:
  /// **'Paz'**
  String get sunday_short;

  /// No description provided for @work_caps.
  ///
  /// In tr, this message translates to:
  /// **'ÇALIŞMA'**
  String get work_caps;

  /// No description provided for @leave_report_caps.
  ///
  /// In tr, this message translates to:
  /// **'İZİN/RAPOR'**
  String get leave_report_caps;

  /// No description provided for @unauthorized_caps.
  ///
  /// In tr, this message translates to:
  /// **'İZİNSİZ'**
  String get unauthorized_caps;

  /// No description provided for @sunday_caps.
  ///
  /// In tr, this message translates to:
  /// **'PAZAR'**
  String get sunday_caps;

  /// No description provided for @netIncomes.
  ///
  /// In tr, this message translates to:
  /// **'Net Gelirler'**
  String get netIncomes;

  /// No description provided for @workerRegistration.
  ///
  /// In tr, this message translates to:
  /// **'PERSONEL KAYIT'**
  String get workerRegistration;

  /// No description provided for @statusDismissed.
  ///
  /// In tr, this message translates to:
  /// **'İŞTEN AYRILDI'**
  String get statusDismissed;

  /// No description provided for @fieldPersonnel.
  ///
  /// In tr, this message translates to:
  /// **'Saha Personeli'**
  String get fieldPersonnel;

  /// No description provided for @deletePermanently.
  ///
  /// In tr, this message translates to:
  /// **'Kalıcı Olarak Sil'**
  String get deletePermanently;

  /// No description provided for @newWorkerCard.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Personel Kartı'**
  String get newWorkerCard;

  /// No description provided for @incomeAndExpense.
  ///
  /// In tr, this message translates to:
  /// **'Gelir / Gider Dengesi'**
  String get incomeAndExpense;

  /// No description provided for @netCashStatus.
  ///
  /// In tr, this message translates to:
  /// **'Net Nakit Durumu'**
  String get netCashStatus;

  /// No description provided for @top3ProfitableProjects.
  ///
  /// In tr, this message translates to:
  /// **'EN KARLI 3 PROJE'**
  String get top3ProfitableProjects;

  /// No description provided for @cariTransaction.
  ///
  /// In tr, this message translates to:
  /// **'Cari İşlem'**
  String get cariTransaction;

  /// No description provided for @workerAnalysisSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{worked} gün çalışma, {leave} gün izin/rapor'**
  String workerAnalysisSubtitle(int worked, int leave);

  /// No description provided for @noDataEntryThisMonth.
  ///
  /// In tr, this message translates to:
  /// **'Bu ay seçili aralıkta henüz veri girişi bulunmuyor.'**
  String get noDataEntryThisMonth;

  /// No description provided for @productivity_caps.
  ///
  /// In tr, this message translates to:
  /// **'VERİMLİLİK'**
  String get productivity_caps;

  /// No description provided for @editDocumentContentHint.
  ///
  /// In tr, this message translates to:
  /// **'Belge içeriğini buraya yazın...'**
  String get editDocumentContentHint;

  /// No description provided for @workerAnalysisTitle.
  ///
  /// In tr, this message translates to:
  /// **'Personel Performans Analizi'**
  String get workerAnalysisTitle;

  /// No description provided for @performanceOverTime.
  ///
  /// In tr, this message translates to:
  /// **'Zaman İçinde Performans'**
  String get performanceOverTime;

  /// No description provided for @workerDistribution.
  ///
  /// In tr, this message translates to:
  /// **'Personel Dağılımı (Çalışma x İzin)'**
  String get workerDistribution;

  /// No description provided for @attendanceSummary.
  ///
  /// In tr, this message translates to:
  /// **'Puantaj Özeti'**
  String get attendanceSummary;

  /// No description provided for @noWorkerFound.
  ///
  /// In tr, this message translates to:
  /// **'Henüz personel kaydı bulunmuyor.'**
  String get noWorkerFound;

  /// No description provided for @excelFeatureSoon.
  ///
  /// In tr, this message translates to:
  /// **'Excel çıktı özelliği yakında eklenecek'**
  String get excelFeatureSoon;

  /// No description provided for @printFeatureSoon.
  ///
  /// In tr, this message translates to:
  /// **'Yazdırma özelliği yakında eklenecek'**
  String get printFeatureSoon;

  /// No description provided for @turkish.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get turkish;

  /// No description provided for @english.
  ///
  /// In tr, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @subtotal.
  ///
  /// In tr, this message translates to:
  /// **'Ara Toplam'**
  String get subtotal;

  /// No description provided for @vatTotal.
  ///
  /// In tr, this message translates to:
  /// **'KDV Toplamı'**
  String get vatTotal;

  /// No description provided for @totalSalesTaxBase.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Satış Matrahı'**
  String get totalSalesTaxBase;

  /// No description provided for @totalPurchaseTaxBase.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Alış Matrahı'**
  String get totalPurchaseTaxBase;

  /// No description provided for @salesVat.
  ///
  /// In tr, this message translates to:
  /// **'Hesaplanan KDV'**
  String get salesVat;

  /// No description provided for @purchaseVat.
  ///
  /// In tr, this message translates to:
  /// **'İndirilecek KDV'**
  String get purchaseVat;

  /// No description provided for @vatToPay.
  ///
  /// In tr, this message translates to:
  /// **'Ödenecek KDV'**
  String get vatToPay;

  /// No description provided for @vatDeferred.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki Döneme Devreden KDV'**
  String get vatDeferred;

  /// No description provided for @cariAccountDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Cari hesap başarıyla silindi'**
  String get cariAccountDeleted;

  /// No description provided for @balance.
  ///
  /// In tr, this message translates to:
  /// **'Bakiye'**
  String get balance;

  /// No description provided for @accountNotLinkedToWorker.
  ///
  /// In tr, this message translates to:
  /// **'Bu cari hesap herhangi bir personelle ilişkilendirilmemiş.'**
  String get accountNotLinkedToWorker;

  /// No description provided for @noLaborRecordsYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz işçilik kaydı bulunmuyor.'**
  String get noLaborRecordsYet;

  /// No description provided for @project.
  ///
  /// In tr, this message translates to:
  /// **'Proje'**
  String get project;

  /// No description provided for @overtime_caps.
  ///
  /// In tr, this message translates to:
  /// **'MESAİ'**
  String get overtime_caps;

  /// No description provided for @hakedis_short.
  ///
  /// In tr, this message translates to:
  /// **'Hak.'**
  String get hakedis_short;

  /// No description provided for @notSpecified.
  ///
  /// In tr, this message translates to:
  /// **'Belirtilmedi'**
  String get notSpecified;

  /// No description provided for @downloadExcel.
  ///
  /// In tr, this message translates to:
  /// **'Excel İndir'**
  String get downloadExcel;

  /// No description provided for @markAsCashInfo.
  ///
  /// In tr, this message translates to:
  /// **'Kasa hesabı olarak işaretleyin (Örn: Nakit Kasa)'**
  String get markAsCashInfo;

  /// No description provided for @completeRecord.
  ///
  /// In tr, this message translates to:
  /// **'KAYDI TAMAMLA'**
  String get completeRecord;

  /// No description provided for @workerAnalysisDetail.
  ///
  /// In tr, this message translates to:
  /// **'{workerName} Analiz Detayı'**
  String workerAnalysisDetail(String workerName);

  /// No description provided for @accountDetail.
  ///
  /// In tr, this message translates to:
  /// **'accountDetail'**
  String get accountDetail;

  /// No description provided for @collectionIn_caps.
  ///
  /// In tr, this message translates to:
  /// **'collectionIn_caps'**
  String get collectionIn_caps;

  /// No description provided for @incomingDebt_caps.
  ///
  /// In tr, this message translates to:
  /// **'incomingDebt_caps'**
  String get incomingDebt_caps;

  /// No description provided for @paymentOut_caps.
  ///
  /// In tr, this message translates to:
  /// **'paymentOut_caps'**
  String get paymentOut_caps;

  /// No description provided for @outgoingCredit_caps.
  ///
  /// In tr, this message translates to:
  /// **'outgoingCredit_caps'**
  String get outgoingCredit_caps;

  /// No description provided for @netCashKasa_caps.
  ///
  /// In tr, this message translates to:
  /// **'netCashKasa_caps'**
  String get netCashKasa_caps;

  /// No description provided for @netStatusBalance_caps.
  ///
  /// In tr, this message translates to:
  /// **'netStatusBalance_caps'**
  String get netStatusBalance_caps;

  /// No description provided for @exportExcel.
  ///
  /// In tr, this message translates to:
  /// **'exportExcel'**
  String get exportExcel;

  /// No description provided for @print.
  ///
  /// In tr, this message translates to:
  /// **'print'**
  String get print;

  /// No description provided for @createReceipt.
  ///
  /// In tr, this message translates to:
  /// **'createReceipt'**
  String get createReceipt;

  /// No description provided for @back.
  ///
  /// In tr, this message translates to:
  /// **'back'**
  String get back;

  /// No description provided for @noTransactionsYet.
  ///
  /// In tr, this message translates to:
  /// **'noTransactionsYet'**
  String get noTransactionsYet;

  /// No description provided for @newCariRecord.
  ///
  /// In tr, this message translates to:
  /// **'newCariRecord'**
  String get newCariRecord;

  /// No description provided for @editCariRecord.
  ///
  /// In tr, this message translates to:
  /// **'editCariRecord'**
  String get editCariRecord;

  /// No description provided for @generalInfo.
  ///
  /// In tr, this message translates to:
  /// **'generalInfo'**
  String get generalInfo;

  /// No description provided for @accountTitle.
  ///
  /// In tr, this message translates to:
  /// **'accountTitle'**
  String get accountTitle;

  /// No description provided for @titleRequired.
  ///
  /// In tr, this message translates to:
  /// **'titleRequired'**
  String get titleRequired;

  /// No description provided for @contactInfo.
  ///
  /// In tr, this message translates to:
  /// **'contactInfo'**
  String get contactInfo;

  /// No description provided for @address.
  ///
  /// In tr, this message translates to:
  /// **'address'**
  String get address;

  /// No description provided for @financialSettings.
  ///
  /// In tr, this message translates to:
  /// **'financialSettings'**
  String get financialSettings;

  /// No description provided for @startingBalance.
  ///
  /// In tr, this message translates to:
  /// **'startingBalance'**
  String get startingBalance;

  /// No description provided for @cashAccount.
  ///
  /// In tr, this message translates to:
  /// **'cashAccount'**
  String get cashAccount;

  /// No description provided for @cariAccounts.
  ///
  /// In tr, this message translates to:
  /// **'cariAccounts'**
  String get cariAccounts;

  /// No description provided for @addNewCari.
  ///
  /// In tr, this message translates to:
  /// **'addNewCari'**
  String get addNewCari;

  /// No description provided for @searchCariHint.
  ///
  /// In tr, this message translates to:
  /// **'searchCariHint'**
  String get searchCariHint;

  /// No description provided for @noCariAccountsYet.
  ///
  /// In tr, this message translates to:
  /// **'noCariAccountsYet'**
  String get noCariAccountsYet;

  /// No description provided for @noResultsFound.
  ///
  /// In tr, this message translates to:
  /// **'noResultsFound'**
  String get noResultsFound;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'deleteConfirmTitle'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteCariConfirm.
  ///
  /// In tr, this message translates to:
  /// **'{arg} carisini silmek istediğinize emin misiniz?'**
  String deleteCariConfirm(Object arg);

  /// No description provided for @cancel_caps.
  ///
  /// In tr, this message translates to:
  /// **'cancel_caps'**
  String get cancel_caps;

  /// No description provided for @delete_caps.
  ///
  /// In tr, this message translates to:
  /// **'delete_caps'**
  String get delete_caps;

  /// No description provided for @deleteFailed.
  ///
  /// In tr, this message translates to:
  /// **'{arg} silinemedi.'**
  String deleteFailed(Object arg);

  /// No description provided for @taxNo_short.
  ///
  /// In tr, this message translates to:
  /// **'taxNo_short'**
  String get taxNo_short;

  /// No description provided for @currentBalance_caps.
  ///
  /// In tr, this message translates to:
  /// **'currentBalance_caps'**
  String get currentBalance_caps;

  /// No description provided for @totalExpenses.
  ///
  /// In tr, this message translates to:
  /// **'totalExpenses'**
  String get totalExpenses;

  /// No description provided for @mustAddAtLeastOneItem.
  ///
  /// In tr, this message translates to:
  /// **'mustAddAtLeastOneItem'**
  String get mustAddAtLeastOneItem;

  /// No description provided for @invoiceAdded.
  ///
  /// In tr, this message translates to:
  /// **'invoiceAdded'**
  String get invoiceAdded;

  /// No description provided for @invoiceUpdated.
  ///
  /// In tr, this message translates to:
  /// **'invoiceUpdated'**
  String get invoiceUpdated;

  /// No description provided for @sales.
  ///
  /// In tr, this message translates to:
  /// **'sales'**
  String get sales;

  /// No description provided for @purchase.
  ///
  /// In tr, this message translates to:
  /// **'purchase'**
  String get purchase;

  /// No description provided for @newInvoiceType.
  ///
  /// In tr, this message translates to:
  /// **'Yeni {arg} Faturası'**
  String newInvoiceType(String arg);

  /// No description provided for @editInvoiceType.
  ///
  /// In tr, this message translates to:
  /// **'{arg} Faturası Düzenle'**
  String editInvoiceType(String arg);

  /// No description provided for @invoiceNo.
  ///
  /// In tr, this message translates to:
  /// **'invoiceNo'**
  String get invoiceNo;

  /// No description provided for @invoiceNoRequired.
  ///
  /// In tr, this message translates to:
  /// **'invoiceNoRequired'**
  String get invoiceNoRequired;

  /// No description provided for @pleaseSelectDate.
  ///
  /// In tr, this message translates to:
  /// **'pleaseSelectDate'**
  String get pleaseSelectDate;

  /// No description provided for @dueDate.
  ///
  /// In tr, this message translates to:
  /// **'dueDate'**
  String get dueDate;

  /// No description provided for @selectCariAccount.
  ///
  /// In tr, this message translates to:
  /// **'selectCariAccount'**
  String get selectCariAccount;

  /// No description provided for @invoiceItems.
  ///
  /// In tr, this message translates to:
  /// **'invoiceItems'**
  String get invoiceItems;

  /// No description provided for @addItem.
  ///
  /// In tr, this message translates to:
  /// **'addItem'**
  String get addItem;

  /// No description provided for @noItemsYet.
  ///
  /// In tr, this message translates to:
  /// **'noItemsYet'**
  String get noItemsYet;

  /// No description provided for @item.
  ///
  /// In tr, this message translates to:
  /// **'Kalem'**
  String get item;

  /// No description provided for @amountLabel.
  ///
  /// In tr, this message translates to:
  /// **'Tutar'**
  String get amountLabel;

  /// No description provided for @priceLabel.
  ///
  /// In tr, this message translates to:
  /// **'priceLabel'**
  String get priceLabel;

  /// No description provided for @grandTotal.
  ///
  /// In tr, this message translates to:
  /// **'grandTotal'**
  String get grandTotal;

  /// No description provided for @editItem.
  ///
  /// In tr, this message translates to:
  /// **'editItem'**
  String get editItem;

  /// No description provided for @newItem.
  ///
  /// In tr, this message translates to:
  /// **'newItem'**
  String get newItem;

  /// No description provided for @itemName.
  ///
  /// In tr, this message translates to:
  /// **'itemName'**
  String get itemName;

  /// No description provided for @unitPrice.
  ///
  /// In tr, this message translates to:
  /// **'unitPrice'**
  String get unitPrice;

  /// No description provided for @vatRatePercent.
  ///
  /// In tr, this message translates to:
  /// **'vatRatePercent'**
  String get vatRatePercent;

  /// No description provided for @invoices.
  ///
  /// In tr, this message translates to:
  /// **'invoices'**
  String get invoices;

  /// No description provided for @salesInvoices.
  ///
  /// In tr, this message translates to:
  /// **'salesInvoices'**
  String get salesInvoices;

  /// No description provided for @purchaseInvoices.
  ///
  /// In tr, this message translates to:
  /// **'purchaseInvoices'**
  String get purchaseInvoices;

  /// No description provided for @noInvoicesYet.
  ///
  /// In tr, this message translates to:
  /// **'noInvoicesYet'**
  String get noInvoicesYet;

  /// No description provided for @deleteInvoiceConfirm.
  ///
  /// In tr, this message translates to:
  /// **'{arg} faturasını silmek istediğinize emin misiniz?'**
  String deleteInvoiceConfirm(Object arg);

  /// No description provided for @invoiceDeleted.
  ///
  /// In tr, this message translates to:
  /// **'invoiceDeleted'**
  String get invoiceDeleted;

  /// No description provided for @recordAdded.
  ///
  /// In tr, this message translates to:
  /// **'recordAdded'**
  String get recordAdded;

  /// No description provided for @recordUpdated.
  ///
  /// In tr, this message translates to:
  /// **'recordUpdated'**
  String get recordUpdated;

  /// No description provided for @income.
  ///
  /// In tr, this message translates to:
  /// **'income'**
  String get income;

  /// No description provided for @newItemType.
  ///
  /// In tr, this message translates to:
  /// **'Yeni {arg}'**
  String newItemType(Object arg);

  /// No description provided for @editItemType.
  ///
  /// In tr, this message translates to:
  /// **'{arg} Düzenle'**
  String editItemType(Object arg);

  /// No description provided for @titleLabel.
  ///
  /// In tr, this message translates to:
  /// **'Başlık'**
  String get titleLabel;

  /// No description provided for @pleaseEnterValidAmount.
  ///
  /// In tr, this message translates to:
  /// **'pleaseEnterValidAmount'**
  String get pleaseEnterValidAmount;

  /// No description provided for @selectCariAccountOptional.
  ///
  /// In tr, this message translates to:
  /// **'selectCariAccountOptional'**
  String get selectCariAccountOptional;

  /// No description provided for @selectProjectOptional.
  ///
  /// In tr, this message translates to:
  /// **'selectProjectOptional'**
  String get selectProjectOptional;

  /// No description provided for @incomeExpense.
  ///
  /// In tr, this message translates to:
  /// **'incomeExpense'**
  String get incomeExpense;

  /// No description provided for @incomes.
  ///
  /// In tr, this message translates to:
  /// **'incomes'**
  String get incomes;

  /// No description provided for @noIncomeExpenseYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz {arg} bulunmuyor.'**
  String noIncomeExpenseYet(String arg);

  /// No description provided for @deleteRecordConfirm.
  ///
  /// In tr, this message translates to:
  /// **'{arg} kaydını silmek istediğinize emin misiniz?'**
  String deleteRecordConfirm(String arg);

  /// No description provided for @recordDeleted.
  ///
  /// In tr, this message translates to:
  /// **'recordDeleted'**
  String get recordDeleted;

  /// No description provided for @settlementReport_caps.
  ///
  /// In tr, this message translates to:
  /// **'HESAP KESİM RAPORU'**
  String get settlementReport_caps;

  /// No description provided for @noDataFound.
  ///
  /// In tr, this message translates to:
  /// **'Veri Bulunamadı'**
  String get noDataFound;

  /// No description provided for @settlementPeriod_caps.
  ///
  /// In tr, this message translates to:
  /// **'HESAP KESİM DÖNEMİ'**
  String get settlementPeriod_caps;

  /// No description provided for @selectDate_caps.
  ///
  /// In tr, this message translates to:
  /// **'TARİH SEÇ'**
  String get selectDate_caps;

  /// No description provided for @personnelSalaryStatus_caps.
  ///
  /// In tr, this message translates to:
  /// **'PERSONEL MAAŞ DURUMU'**
  String get personnelSalaryStatus_caps;

  /// No description provided for @projectHakedis_caps.
  ///
  /// In tr, this message translates to:
  /// **'PROJE HAKEDİŞLERİ'**
  String get projectHakedis_caps;

  /// No description provided for @settleAccount_caps.
  ///
  /// In tr, this message translates to:
  /// **'HESABI KAPAT'**
  String get settleAccount_caps;

  /// No description provided for @noPendingHakedisFound.
  ///
  /// In tr, this message translates to:
  /// **'noPendingHakedisFound'**
  String get noPendingHakedisFound;

  /// No description provided for @processHakedisCollection.
  ///
  /// In tr, this message translates to:
  /// **'processHakedisCollection'**
  String get processHakedisCollection;

  /// No description provided for @hakedisSettleConfirm.
  ///
  /// In tr, this message translates to:
  /// **'{count} adet hakediş ve toplam {amount} tutarı tahsil edilecek. Onaylıyor musunuz?'**
  String hakedisSettleConfirm(int count, String amount);

  /// No description provided for @hakedisCollectionsProcessed.
  ///
  /// In tr, this message translates to:
  /// **'hakedisCollectionsProcessed'**
  String get hakedisCollectionsProcessed;

  /// No description provided for @settlePersonnelAccount.
  ///
  /// In tr, this message translates to:
  /// **'settlePersonnelAccount'**
  String get settlePersonnelAccount;

  /// No description provided for @laborSettleConfirm.
  ///
  /// In tr, this message translates to:
  /// **'{count} adet işçilik ve toplam {amount} tutarı ödenecek. Onaylıyor musunuz?'**
  String laborSettleConfirm(int count, String amount);

  /// No description provided for @personnelPaymentsProcessed.
  ///
  /// In tr, this message translates to:
  /// **'personnelPaymentsProcessed'**
  String get personnelPaymentsProcessed;

  /// No description provided for @closeCariAccounts.
  ///
  /// In tr, this message translates to:
  /// **'closeCariAccounts'**
  String get closeCariAccounts;

  /// No description provided for @cariSettleConfirm.
  ///
  /// In tr, this message translates to:
  /// **'{count} adet cari işlem kapatılacak. Onaylıyor musunuz?'**
  String cariSettleConfirm(int count);

  /// No description provided for @cariAccountBalancesClosed.
  ///
  /// In tr, this message translates to:
  /// **'cariAccountBalancesClosed'**
  String get cariAccountBalancesClosed;

  /// No description provided for @confirm_caps.
  ///
  /// In tr, this message translates to:
  /// **'confirm_caps'**
  String get confirm_caps;

  /// No description provided for @periodNetProfit_caps.
  ///
  /// In tr, this message translates to:
  /// **'DÖNEM NET KARI'**
  String get periodNetProfit_caps;

  /// No description provided for @totalRevenue_caps.
  ///
  /// In tr, this message translates to:
  /// **'TOPLAM GELİR'**
  String get totalRevenue_caps;

  /// No description provided for @totalCost_caps.
  ///
  /// In tr, this message translates to:
  /// **'TOPLAM MALİYET'**
  String get totalCost_caps;

  /// No description provided for @totalEarned.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Hak Edilen'**
  String get totalEarned;

  /// No description provided for @remainingPersonnelDebt.
  ///
  /// In tr, this message translates to:
  /// **'Kalan Personel Borcu'**
  String get remainingPersonnelDebt;

  /// No description provided for @seePersonnelDetails.
  ///
  /// In tr, this message translates to:
  /// **'Personel Detaylarını Gör'**
  String get seePersonnelDetails;

  /// No description provided for @laborSummaryDetail.
  ///
  /// In tr, this message translates to:
  /// **'Çalışılan: {worked} | İzinli: {leave} | Pazar: {sunday}'**
  String laborSummaryDetail(int worked, int leave, int sunday);

  /// No description provided for @producedHakedisNet.
  ///
  /// In tr, this message translates to:
  /// **'Üretilen Net Hakediş'**
  String get producedHakedisNet;

  /// No description provided for @pendingCollection.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen Tahsilat'**
  String get pendingCollection;

  /// No description provided for @customerReceivables.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri Alacakları'**
  String get customerReceivables;

  /// No description provided for @supplierPayables.
  ///
  /// In tr, this message translates to:
  /// **'Tedarikçi Borçları'**
  String get supplierPayables;

  /// No description provided for @mainCashStatus.
  ///
  /// In tr, this message translates to:
  /// **'Ana Kasa Durumu'**
  String get mainCashStatus;

  /// No description provided for @search.
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get search;

  /// No description provided for @workerSummaryReport_caps.
  ///
  /// In tr, this message translates to:
  /// **'İŞÇİ ÖZET RAPORU'**
  String get workerSummaryReport_caps;

  /// No description provided for @totalWorkHours.
  ///
  /// In tr, this message translates to:
  /// **'{hours} Saat Toplam Çalışma'**
  String totalWorkHours(String hours);

  /// No description provided for @workerReport_caps.
  ///
  /// In tr, this message translates to:
  /// **'{name} ÖZET RAPORU'**
  String workerReport_caps(String name);

  /// No description provided for @totalHoursAndAmount.
  ///
  /// In tr, this message translates to:
  /// **'Toplam: {hours} Saat | {amount}'**
  String totalHoursAndAmount(String hours, String amount);

  /// No description provided for @hakedisDocument_caps.
  ///
  /// In tr, this message translates to:
  /// **'HAKEDİŞ BELGESİ'**
  String get hakedisDocument_caps;

  /// No description provided for @projectHakedisReport_caps.
  ///
  /// In tr, this message translates to:
  /// **'PROJE HAKEDİŞ RAPORU'**
  String get projectHakedisReport_caps;

  /// No description provided for @brutAmount_caps.
  ///
  /// In tr, this message translates to:
  /// **'BRÜT TUTAR'**
  String get brutAmount_caps;

  /// No description provided for @netAccrual_caps.
  ///
  /// In tr, this message translates to:
  /// **'NET TAHAKKUK'**
  String get netAccrual_caps;

  /// No description provided for @quantity.
  ///
  /// In tr, this message translates to:
  /// **'Adet'**
  String get quantity;

  /// No description provided for @totalBrut.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Brüt'**
  String get totalBrut;

  /// No description provided for @totalNet.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Net'**
  String get totalNet;

  /// No description provided for @reportDateLabel.
  ///
  /// In tr, this message translates to:
  /// **'Rapor Tarihi: {date}'**
  String reportDateLabel(String date);

  /// No description provided for @documentDateLabel.
  ///
  /// In tr, this message translates to:
  /// **'Belge Tarihi: {date}'**
  String documentDateLabel(String date);

  /// No description provided for @privacyPolicy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get privacyPolicy;

  /// No description provided for @date.
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get date;

  /// No description provided for @hour.
  ///
  /// In tr, this message translates to:
  /// **'Saat'**
  String get hour;

  /// No description provided for @mesai.
  ///
  /// In tr, this message translates to:
  /// **'Mesai'**
  String get mesai;

  /// No description provided for @personal.
  ///
  /// In tr, this message translates to:
  /// **'Personel'**
  String get personal;

  /// No description provided for @rate.
  ///
  /// In tr, this message translates to:
  /// **'Oran'**
  String get rate;

  /// No description provided for @stopaj.
  ///
  /// In tr, this message translates to:
  /// **'Stopaj'**
  String get stopaj;

  /// No description provided for @teminat.
  ///
  /// In tr, this message translates to:
  /// **'Teminat'**
  String get teminat;

  /// No description provided for @pending_caps.
  ///
  /// In tr, this message translates to:
  /// **'BEKLİYOR'**
  String get pending_caps;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
