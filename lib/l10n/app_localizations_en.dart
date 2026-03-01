// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Accounting Pro';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get netCash => 'NET CASH';

  @override
  String get current => 'CURRENT';

  @override
  String get totalCollection => 'TOTAL COLLECTION';

  @override
  String get remainingDebt => 'REMAINING DEBT';

  @override
  String get quickAccess => 'QUICK ACCESS';

  @override
  String get accounting => 'Accounting';

  @override
  String get reports => 'Reports';

  @override
  String get personnel => 'Personnel';

  @override
  String get settlement => 'Settlement';

  @override
  String get bottleneckAnalysis => 'BOTTLENECK AND PROFIT ANALYSIS';

  @override
  String get statusAnalysis => 'STATUS ANALYSIS';

  @override
  String get profitableProjects => 'MOST PROFITABLE PROJECTS';

  @override
  String get performanceIndicator => 'PERFORMANCE INDICATOR';

  @override
  String get openedProjects => 'Open Projects';

  @override
  String get totalCurrentAccounts => 'Total Current Accounts';

  @override
  String get incomeExpenseBalance => 'Income / Expense Balance';

  @override
  String get positive => 'Positive';

  @override
  String get incomeShare => 'Income Share';

  @override
  String get expenseShare => 'Expense Share';

  @override
  String get noProfitData => 'No projects with profit data yet.';

  @override
  String get premiumAnalysis => 'PREMIUM ANALYSIS';

  @override
  String get unlock => 'Unlock';

  @override
  String get workerAnalysis => 'Worker Analysis';

  @override
  String get ourPortfolio => 'Our Portfolio';

  @override
  String get laborSummary => 'Labor Summary';

  @override
  String get premiumPackages => 'Premium Packages';

  @override
  String get logout => 'Logout';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get premiumSubtitle => 'Accounting Pro Premium';

  @override
  String get premiumDescription =>
      'Upgrade to manage your business more professionally.';

  @override
  String get featureRemoveAds => 'Remove all ads';

  @override
  String get featureUnlimitedPDF => 'Create unlimited PDF reports';

  @override
  String get featureCloudBackup => 'Unlimited cloud backup';

  @override
  String get featureB2B => 'B2B/Company features access';

  @override
  String get monthlyPackage => 'Monthly Package';

  @override
  String get yearlyPackage => 'Yearly Package';

  @override
  String get monthlyPrice => '₺99.99 / month';

  @override
  String get yearlyPrice => '₺899.99 / year';

  @override
  String get cancelAnytime => 'Cancel anytime.';

  @override
  String get save25 => '25% more affordable!';

  @override
  String get mostPopular => 'MOST POPULAR';

  @override
  String get continueButton => 'Continue';

  @override
  String get congratulations => 'Congratulations!';

  @override
  String get premiumActivatedMonthly =>
      'Your monthly Premium membership has been successfully activated. You can now enjoy all unlimited features.';

  @override
  String get premiumActivatedYearly =>
      'Your yearly Premium membership has been successfully activated. You can now enjoy all unlimited features.';

  @override
  String get great => 'Great!';

  @override
  String get premiumSuccessSnackBar => 'Premium features activated!';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email Address';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password';

  @override
  String get loginButton => 'LOGIN';

  @override
  String get registerButton => 'REGISTER';

  @override
  String get noAccount => 'Don\'t have an account? ';

  @override
  String get haveAccount => 'Already have an account? ';

  @override
  String get fillAllFields => 'Please fill in all fields';

  @override
  String get accountAlreadyRegistered => 'This account is already registered.';

  @override
  String get invalidCredentials => 'Invalid email or password.';

  @override
  String get emailNotConfirmed => 'Email Confirmation Required';

  @override
  String get emailNotConfirmedDetail =>
      'You need to confirm your email address to log in. Please check your inbox (and spam folder).';

  @override
  String get rateLimitExceeded =>
      'Too many email sending attempts. Please try again later.';

  @override
  String get registrationSuccess => 'Registration Successful!';

  @override
  String get registrationSuccessDetail =>
      'We\'ve created your account! Please click the confirmation link we sent to your email address.';

  @override
  String get registrationInstruction => 'You cannot log in without confirming.';

  @override
  String get okIUnderstand => 'OK, I Understand';

  @override
  String get close => 'Close';

  @override
  String get emailSent => 'Email Sent';

  @override
  String get resetPasswordEmailSent =>
      'Password reset link has been sent to your email address. Please check.';

  @override
  String get ok => 'OK';

  @override
  String get emailSendError =>
      'Email could not be sent. Please check your SMTP settings or try again in 5 minutes.';

  @override
  String get corporateCloudSolution => 'Corporate Cloud Solution';

  @override
  String get secureConnection => 'SSL SECURE CONNECTION';

  @override
  String get appTagline => 'Future of Financial Management';

  @override
  String get projects => 'PROJECTS';

  @override
  String get newProjectCard => 'NEW PROJECT CARD';

  @override
  String get noProjectsDefined => 'No projects defined yet';

  @override
  String noProjectsInStatus(String status) {
    return 'No projects in $status status';
  }

  @override
  String get createFirstProject => 'CREATE FIRST PROJECT';

  @override
  String get all => 'All';

  @override
  String get active => 'Active';

  @override
  String get suspended => 'Suspended';

  @override
  String get completed => 'Completed';

  @override
  String get deleteProject => 'Delete Project';

  @override
  String deleteProjectConfirm(String name) {
    return 'Are you sure you want to delete the project \"$name\"? This action cannot be undone.';
  }

  @override
  String get cancel => 'CANCEL';

  @override
  String get delete => 'DELETE';

  @override
  String get projectDeleted => 'Project successfully deleted';

  @override
  String get projectName => 'Project Name';

  @override
  String get customerFirm => 'Customer / Firm (Current)';

  @override
  String get estimatedBudget => 'Estimated Budget';

  @override
  String get status => 'Status';

  @override
  String get saveProject => 'SAVE PROJECT';

  @override
  String get projectCreated => 'Project successfully created';

  @override
  String get enterProjectName => 'Please enter project name';

  @override
  String errorPrefix(String message) {
    return 'Error: $message';
  }

  @override
  String get budgetLabel => 'BUDGET';

  @override
  String get summary => 'SUMMARY';

  @override
  String get hakedisler => 'HAKEDISLER';

  @override
  String get expenses => 'EXPENSES';

  @override
  String get collected => 'Collected';

  @override
  String get totalExpense => 'Total Expense';

  @override
  String get netProfit => 'Net Profit';

  @override
  String get projectBudget => 'Project Budget';

  @override
  String get projectDetails => 'Project Details';

  @override
  String get startingDate => 'Starting Date';

  @override
  String get description => 'Description';

  @override
  String get notEntered => 'Not Entered';

  @override
  String get changeProjectStatus => 'Change Project Status';

  @override
  String statusUpdated(String status) {
    return 'Project status updated to $status';
  }

  @override
  String get noHakedisYet => 'No payment installments (hakedis) entered yet';

  @override
  String get downloadAllHakedisPDF => 'DOWNLOAD ALL HAKEDIS PDF';

  @override
  String get newHakedis => 'NEW HAKEDIS';

  @override
  String get collected_caps => 'COLLECTED';

  @override
  String get pending => 'PENDING';

  @override
  String get markAsPending => 'Mark as Pending';

  @override
  String get markAsCollected => 'Mark as Collected';

  @override
  String get materialService => 'Material/Service';

  @override
  String get laborPaid => 'Labor (Paid)';

  @override
  String get accountPayments => 'Account Payments';

  @override
  String get cashOutflows => 'Cash Outflows';

  @override
  String get sunday => 'Sunday';

  @override
  String get downloadPDF => 'Download PDF';

  @override
  String get deleteHakedis => 'Delete Hakedis';

  @override
  String get gross => 'Gross';

  @override
  String get deductions => 'Deductions';

  @override
  String get netCollection => 'Net Collection';

  @override
  String deleteHakedisConfirm(String title) {
    return 'Are you sure you want to delete the hakedis \"$title\"?';
  }

  @override
  String get expense => 'Expense';

  @override
  String get laborPayment => 'Labor Payment';

  @override
  String get puantajRecord => 'Attendance Record';

  @override
  String get noExpensesYet => 'No expense records found yet';

  @override
  String get hakedisEntry => 'Payment Installment Entry';

  @override
  String get hakedisTitle => 'Hakedis Title';

  @override
  String get hakedisTitleHint => 'e.g. 1st Hakedis or January Hakedis';

  @override
  String get hakedisAmountExcVat => 'Hakedis Amount (Exc. VAT)';

  @override
  String get taxAndDeductionRates => 'Tax and Deduction Rates (%)';

  @override
  String get vat => 'VAT';

  @override
  String get withholding => 'Withholding';

  @override
  String get guarantee => 'Guarantee';

  @override
  String get hakedisDate => 'Hakedis Date';

  @override
  String get descriptionOptional => 'Description / Note (Optional)';

  @override
  String get saveHakedis => 'SAVE HAKEDIS';

  @override
  String get enterTitleAndAmount => 'Please enter title and amount.';

  @override
  String get accountingAndCurrent => 'ACCOUNTING & CURRENT';

  @override
  String get pleaseSelectCari => 'Please select a current account';

  @override
  String get descriptionRequired => 'Description is required';

  @override
  String get amountRequired => 'Debt or Credit amount must be entered';

  @override
  String get transactionSaved => 'Transaction saved';

  @override
  String get transactionDeleted => 'Transaction deleted';

  @override
  String get collectionIn => 'Collection (In)';

  @override
  String get paymentOut => 'Payment (Out)';

  @override
  String get incomingDebt => 'Incoming (Debt)';

  @override
  String get outgoingCredit => 'Outgoing (Credit)';

  @override
  String get netCashKasa => 'Net Cash (Kasa)';

  @override
  String get netStatusBalance => 'Net Status (Balance)';

  @override
  String get addNewTransaction => 'ADD NEW TRANSACTION';

  @override
  String get quickTransactionEntry => 'Quick Transaction Entry';

  @override
  String get cariAccountSelection => 'Current Account Selection';

  @override
  String get descriptionNote => 'Description / Note';

  @override
  String get debtIncoming => 'Debt (Incoming)';

  @override
  String get creditOutgoing => 'Credit (Outgoing)';

  @override
  String get saveTransaction => 'SAVE TRANSACTION';

  @override
  String get allCaris => 'All Accounts';

  @override
  String get selectProject => 'Select Project';

  @override
  String get allProjects => 'All Projects';

  @override
  String get statusIn => 'IN';

  @override
  String get statusOut => 'OUT';

  @override
  String get statusDebt => 'DEBT';

  @override
  String get statusCredit => 'CREDIT';

  @override
  String get tableDate => 'DATE';

  @override
  String get tableCari => 'ACCOUNT';

  @override
  String get tableDescription => 'DESCRIPTION';

  @override
  String get tableStatus => 'STATUS';

  @override
  String get tableIncoming => 'INCOMING';

  @override
  String get tableOutgoing => 'OUTGOING';

  @override
  String get tableBalance => 'BALANCE';

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get financialAnalysis => 'Financial Analysis';

  @override
  String get profitabilityRate => 'Profitability Rate';

  @override
  String get expenseBreakdown => 'EXPENSE BREAKDOWN';

  @override
  String get projectBasedPerformance => 'PROJECT BASED PERFORMANCE';

  @override
  String get pendingWorkerPayment => 'Pending Worker Payment';

  @override
  String get personnelTracking => 'PERSONNEL TRACKING';

  @override
  String get fieldPersonnelManagement => 'Field Personnel Management';

  @override
  String get personnelSubtitle => 'Attendance and salary accrual tracking';

  @override
  String get getSummary => 'GET SUMMARY';

  @override
  String get personnelRegistration => 'PERSONNEL REGISTRATION';

  @override
  String get dismissed => 'DISMISSED';

  @override
  String get fieldWorker => 'Field Worker';

  @override
  String get attendance => 'ATTENDANCE';

  @override
  String get dismissWorker => 'Dismiss Worker';

  @override
  String get documents => 'Documents';

  @override
  String get permanentlyDelete => 'Permanently Delete';

  @override
  String get personnelListEmpty => 'Personnel list is empty';

  @override
  String get newPersonnelCard => 'New Personnel Card';

  @override
  String get nameSurname => 'Name Surname';

  @override
  String get rolePosition => 'Role / Position';

  @override
  String get salaryAmount => 'Salary Amount';

  @override
  String get salaryType => 'Salary Type';

  @override
  String get daily => 'Daily';

  @override
  String get monthly => 'Monthly';

  @override
  String get hourly => 'Hourly';

  @override
  String get saveAsCari => 'Save as Current Account';

  @override
  String get completeRegistration => 'COMPLETE REGISTRATION';

  @override
  String get personnelGeneralSummary => 'PERSONNEL GENERAL SUMMARY';

  @override
  String get totalPersonnel => 'Total Personnel';

  @override
  String get activePersonnel => 'Active Personnel';

  @override
  String get dismissedPersonnel => 'Dismissed Personnel';

  @override
  String get totalAccrued => 'Total Accrued';

  @override
  String get totalPaid => 'Total Paid';

  @override
  String get remainingBalance => 'Remaining Balance';

  @override
  String get workingHours => 'Working Hours';

  @override
  String get overtimeHours => 'Overtime Hours';

  @override
  String get hourlyWage => 'Hourly Wage';

  @override
  String get calculatedAmount => 'CALCULATED AMOUNT';

  @override
  String get selectStatus => 'SELECT STATUS';

  @override
  String get normal => 'Normal';

  @override
  String get onLeave => 'On Leave';

  @override
  String get medicalLeave => 'Medical Leave';

  @override
  String get excusedLeave => 'Excused Leave';

  @override
  String get unexcusedLeave => 'Unexcused Leave';

  @override
  String get refresh => 'Refresh';

  @override
  String get stockManagement => 'Stock Management';

  @override
  String get stockCode => 'Stock Code';

  @override
  String get stockCodeRequired => 'Stock code is required';

  @override
  String get stockName => 'Stock Name';

  @override
  String get stockNameRequired => 'Stock name is required';

  @override
  String get unit => 'Unit';

  @override
  String get stockAmount => 'Stock Amount';

  @override
  String get criticalStockLevel => 'Critical Stock Level';

  @override
  String get purchasePriceLabel => 'Purchase Price';

  @override
  String get salePriceLabel => 'Sale Price';

  @override
  String get vatRate => 'VAT Rate';

  @override
  String get newStock => 'New Stock';

  @override
  String get editStock => 'Edit Stock';

  @override
  String get noStocksYet => 'No stocks added yet';

  @override
  String get noSearchResultFound => 'No search result found';

  @override
  String get code => 'Code';

  @override
  String get stockLabel => 'Stock';

  @override
  String get companyPortfolio => 'Company Portfolio';

  @override
  String get visionarySolutions => 'Visionary Solutions';

  @override
  String buildingFutureWithXActiveProjects(int count) {
    return 'Building the Future with $count Active Projects';
  }

  @override
  String get companySummary => 'Company Summary';

  @override
  String get financialHealth => 'Financial Health';

  @override
  String get ourProjects => 'Our Projects';

  @override
  String get ourTeam => 'Our Team';

  @override
  String get milestones => 'Milestones';

  @override
  String get collectionDebtRatio => 'Collection / Debt Ratio';

  @override
  String get greenCollectionsRedDebts =>
      'Green: Collections, Red: Pending Debts';

  @override
  String companyOverviewText(String revenue, String debt) {
    return 'Our company leads the sector with its expert personnel in financial management. To date, $revenue worth of payment installments have been collected and $debt worth of labor debt is currently being managed.';
  }

  @override
  String get noProjectRecordsYet => 'No project records yet.';

  @override
  String get noActiveWorkersYet => 'No active workers yet.';

  @override
  String get monthlyPersonnel => 'Monthly Personnel';

  @override
  String get dailyPersonnel => 'Daily Personnel';

  @override
  String get pendingSalary => 'Pending Salary';

  @override
  String get noMilestonesYet => 'No milestones found.';

  @override
  String get newProjectStarted => 'New Project Started';

  @override
  String get projectCompletedSuccessfully => 'Project Completed Successfully';

  @override
  String get projectSuspendedTemporarily => 'Project Suspended Temporarily';

  @override
  String get newTeamMemberJoined => 'New Team Member Joined';

  @override
  String get teamMemberLeft => 'Team Member Left';

  @override
  String get financialCollectionMade => 'Financial Collection Made';

  @override
  String get highAmountExpenseRecord => 'High Amount Expense Record';

  @override
  String get unknownEvent => 'Unknown Event';

  @override
  String get periodIncomeExpenseBalance => 'Period Income / Expense Balance';

  @override
  String xPercentPositive(String percent) {
    return '$percent% Positive';
  }

  @override
  String get laborSummaryReport_caps => 'LABOR SUMMARY REPORT';

  @override
  String get dateRange => 'Date Range';

  @override
  String get selectedPeriodRecords => 'Selected Period Records';

  @override
  String xHoursWork(double hours) {
    return '$hours Hours Work';
  }

  @override
  String get noRecordFoundInRange => 'No record found in this date range.';

  @override
  String get unknown => 'Unknown';

  @override
  String get total => 'Total';

  @override
  String xHours(double hours) {
    return '$hours Hours';
  }

  @override
  String get tableProject_caps => 'PROJECT';

  @override
  String get tableHour_caps => 'HOUR';

  @override
  String get tableMesai_caps => 'OVERTIME';

  @override
  String get tableAmount_caps => 'AMOUNT';

  @override
  String get tableDate_caps => 'DATE';

  @override
  String workerDocuments(String name) {
    return '$name - Documents';
  }

  @override
  String get severanceAndRights => 'Severance and Rights (Editable)';

  @override
  String get severancePay => 'Severance Pay';

  @override
  String get noticePay => 'Notice Pay';

  @override
  String get leavePay => 'Leave Pay';

  @override
  String get separationReason => 'Separation Reason';

  @override
  String get createDocument => 'Create Document';

  @override
  String get serviceCertificate => 'Service Certificate';

  @override
  String get releaseForm => 'Release Form';

  @override
  String get compensationBreakdown => 'Compensation Breakdown';

  @override
  String get payrollPusula => 'Payroll Slip';

  @override
  String get sgkStatement => 'SGK Statement';

  @override
  String get paymentReceipt => 'Payment Receipt';

  @override
  String editDocument(String title) {
    return 'Edit $title';
  }

  @override
  String get save => 'SAVE';

  @override
  String get reasonHint => 'e.g. Retirement, Resignation, etc.';

  @override
  String serviceCertificate_template(
    String name,
    String startDate,
    String endDate,
    String position,
    String reason,
  ) {
    return 'Mr./Ms. $name has worked in our workplace from $startDate to $endDate as \"$position\". Reason for leaving: $reason. This document has been prepared upon the request of the interested party.';
  }

  @override
  String releaseForm_template(String date) {
    return 'Upon leaving the workplace on $date; I declare that I have received my salary, severance pay, notice pay, and all other social rights in full, and that I have no rights or claims from the employer, and I fully release the employer.';
  }

  @override
  String compensationBreakdown_template(
    String severance,
    String notice,
    String leave,
    String total,
  ) {
    return 'PERSONNEL RIGHTS AND RECEIVABLES BREAKDOWN:\n\n1. Severance Pay: $severance\n2. Notice Pay: $notice\n3. Leave Pay: $leave\n\nTOTAL PAID: $total\n\nThis breakdown shows the legal receivables entitled to the personnel when the employment contract ends.';
  }

  @override
  String get payrollPusula_template =>
      'PAYROLL SLIP:\n\nThe last month\'s salary and additional payments accrued during the personnel\'s tenure have been delivered to the bank accounts specified below or in hand.\n\nPayment Item: Severance/Notice/Salary\nDescription: Lump-sum payment as a result of termination of employment contract.';

  @override
  String sgkStatement_template(
    String name,
    String tcNo,
    String date,
    String reason,
  ) {
    return 'SOCIAL SECURITY TERMINATION STATEMENT SUMMARY:\n\nPersonnel: $name\nID No: $tcNo\nTermination Date: $date\nTermination Reason: $reason\n\nThis breakdown is a copy of the termination notification entered into the SGK system.';
  }

  @override
  String paymentReceipt_template(String name, String amount, String date) {
    return 'BANK PAYMENT RECEIPT / VOUCHER:\n\nPaid to: $name\nAmount: $amount\nDescription: It is a collective liquidation payment of salary, severance, notice, and all fringe rights.\n\nPayment Date: $date';
  }

  @override
  String get personnelInfo => 'PERSONNEL INFORMATION:';

  @override
  String get idNo => 'ID No';

  @override
  String get employerSignature => 'Employer Signature';

  @override
  String get workerSignature => 'Worker Signature';

  @override
  String get categoryLabel => 'Category';

  @override
  String get cariLabel => 'Account';

  @override
  String get dateLabel => 'Date';

  @override
  String get edit => 'Edit';

  @override
  String get financeKasaManagement => 'FINANCE & CASH MANAGEMENT';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get pendingCollections => 'Pending Collections';

  @override
  String get noBalanceToReset => 'No balance found to reset.';

  @override
  String get passwordResetSuccess =>
      'Your password has been successfully updated. You can now login.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get pleaseEnterNewPassword => 'Please enter a new password';

  @override
  String get secondPage => 'Second Page';

  @override
  String get goBack => 'Go Back';

  @override
  String get bankKasa => 'BANK / CASH';

  @override
  String get cekSenet => 'CHECK / BILL';

  @override
  String get cashMovement => 'CASH MOVEMENT';

  @override
  String get documentEntry => 'DOCUMENT ENTRY';

  @override
  String get mainVault => 'Main Vault (USD)';

  @override
  String get checksGiven => 'Issued Checks';

  @override
  String get dailyPay => 'DAILY';

  @override
  String get monthlyPay => 'MONTHLY';

  @override
  String get hourlyRate => 'Hourly Wage';

  @override
  String get overtimeHourly => 'Overtime Wage';

  @override
  String deleteWorkerConfirmNote(Object name) {
    return 'Are you sure you want to permanently delete the personnel named $name and all their data (attendance, payments, etc.)?';
  }

  @override
  String dismissConfirmNote(Object name) {
    return 'Are you sure you want to dismiss the personnel named $name? (Past data is preserved)';
  }

  @override
  String get attendanceAndSalaryTracking =>
      'Attendance and salary accrual tracking';

  @override
  String get workerDismissedInfo => 'Personnel dismissed';

  @override
  String get workerDeletedInfo => 'Personnel deleted';

  @override
  String get fullName => 'Full Name';

  @override
  String get dutyPosition => 'Duty / Position';

  @override
  String get saveAsCariAccount => 'Save as Current Account';

  @override
  String get requiredForSalaryPayments =>
      'Required for salary payment tracking';

  @override
  String get remainingDebtBalance => 'Remaining Debt (Balance)';

  @override
  String get onReport => 'On Report';

  @override
  String get onExcuse => 'On Excuse';

  @override
  String get unauthorized => 'Unauthorized';

  @override
  String get noProjectSelected => 'No Project Selected';

  @override
  String get relatedProject => 'Related Project';

  @override
  String get deleteRecord => 'Delete Record';

  @override
  String get monday_short => 'Mon';

  @override
  String get tuesday_short => 'Tue';

  @override
  String get wednesday_short => 'Wed';

  @override
  String get thursday_short => 'Thu';

  @override
  String get friday_short => 'Fri';

  @override
  String get saturday_short => 'Sat';

  @override
  String get sunday_short => 'Sun';

  @override
  String get work_caps => 'WORK';

  @override
  String get leave_report_caps => 'LEAVE/REPORT';

  @override
  String get unauthorized_caps => 'UNAUTHORIZED';

  @override
  String get sunday_caps => 'SUNDAY';

  @override
  String get netIncomes => 'Net Incomes';

  @override
  String get workerRegistration => 'PERSONNEL REGISTRATION';

  @override
  String get statusDismissed => 'DISMISSED';

  @override
  String get fieldPersonnel => 'Field Personnel';

  @override
  String get deletePermanently => 'Delete Permanently';

  @override
  String get newWorkerCard => 'New Personnel Card';

  @override
  String get incomeAndExpense => 'Income / Expense Balance';

  @override
  String get netCashStatus => 'Net Cash Status';

  @override
  String get top3ProfitableProjects => 'TOP 3 PROFITABLE PROJECTS';

  @override
  String get cariTransaction => 'Account Transaction';

  @override
  String workerAnalysisSubtitle(int worked, int leave) {
    return '$worked days worked, $leave days leave/report';
  }

  @override
  String get noDataEntryThisMonth =>
      'No data entries found for the selected range.';

  @override
  String get productivity_caps => 'PRODUCTIVITY';

  @override
  String get editDocumentContentHint => 'Type the document content here...';

  @override
  String get workerAnalysisTitle => 'Personnel Performance Analysis';

  @override
  String get performanceOverTime => 'Performance Over Time';

  @override
  String get workerDistribution => 'Personnel Distribution (Work x Leave)';

  @override
  String get attendanceSummary => 'Attendance Summary';

  @override
  String get noWorkerFound => 'No personnel records found.';

  @override
  String get excelFeatureSoon => 'Excel export feature coming soon';

  @override
  String get printFeatureSoon => 'Print feature coming soon';

  @override
  String get turkish => 'Turkish';

  @override
  String get english => 'English';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get vatTotal => 'VAT Total';

  @override
  String get totalSalesTaxBase => 'Total Sales Tax Base';

  @override
  String get totalPurchaseTaxBase => 'Total Purchase Tax Base';

  @override
  String get salesVat => 'Sales VAT';

  @override
  String get purchaseVat => 'Purchase VAT';

  @override
  String get vatToPay => 'VAT to Pay';

  @override
  String get vatDeferred => 'Deferred VAT';

  @override
  String get cariAccountDeleted => 'Account successfully deleted';

  @override
  String get balance => 'Balance';

  @override
  String get accountNotLinkedToWorker =>
      'This account is not linked to any personnel.';

  @override
  String get noLaborRecordsYet => 'No labor records found yet.';

  @override
  String get project => 'Project';

  @override
  String get overtime_caps => 'OVERTIME';

  @override
  String get hakedis_short => 'Pay.';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get downloadExcel => 'Download Excel';

  @override
  String get markAsCashInfo => 'Mark as cash account (e.g., Cash Register)';

  @override
  String get completeRecord => 'COMPLETE RECORD';

  @override
  String workerAnalysisDetail(String workerName) {
    return '$workerName Analysis Detail';
  }

  @override
  String get accountDetail => 'accountDetail';

  @override
  String get collectionIn_caps => 'collectionIn_caps';

  @override
  String get incomingDebt_caps => 'incomingDebt_caps';

  @override
  String get paymentOut_caps => 'paymentOut_caps';

  @override
  String get outgoingCredit_caps => 'outgoingCredit_caps';

  @override
  String get netCashKasa_caps => 'netCashKasa_caps';

  @override
  String get netStatusBalance_caps => 'netStatusBalance_caps';

  @override
  String get exportExcel => 'exportExcel';

  @override
  String get print => 'print';

  @override
  String get createReceipt => 'createReceipt';

  @override
  String get back => 'back';

  @override
  String get noTransactionsYet => 'noTransactionsYet';

  @override
  String get newCariRecord => 'newCariRecord';

  @override
  String get editCariRecord => 'editCariRecord';

  @override
  String get generalInfo => 'generalInfo';

  @override
  String get accountTitle => 'accountTitle';

  @override
  String get titleRequired => 'titleRequired';

  @override
  String get contactInfo => 'contactInfo';

  @override
  String get address => 'address';

  @override
  String get financialSettings => 'financialSettings';

  @override
  String get startingBalance => 'startingBalance';

  @override
  String get cashAccount => 'cashAccount';

  @override
  String get cariAccounts => 'cariAccounts';

  @override
  String get addNewCari => 'addNewCari';

  @override
  String get searchCariHint => 'searchCariHint';

  @override
  String get noCariAccountsYet => 'noCariAccountsYet';

  @override
  String get noResultsFound => 'noResultsFound';

  @override
  String get deleteConfirmTitle => 'deleteConfirmTitle';

  @override
  String deleteCariConfirm(Object arg) {
    return 'Are you sure you want to delete account $arg?';
  }

  @override
  String get cancel_caps => 'cancel_caps';

  @override
  String get delete_caps => 'delete_caps';

  @override
  String deleteFailed(Object arg) {
    return 'Failed to delete $arg.';
  }

  @override
  String get taxNo_short => 'taxNo_short';

  @override
  String get currentBalance_caps => 'currentBalance_caps';

  @override
  String get totalExpenses => 'totalExpenses';

  @override
  String get mustAddAtLeastOneItem => 'mustAddAtLeastOneItem';

  @override
  String get invoiceAdded => 'invoiceAdded';

  @override
  String get invoiceUpdated => 'invoiceUpdated';

  @override
  String get sales => 'sales';

  @override
  String get purchase => 'purchase';

  @override
  String newInvoiceType(String arg) {
    return 'New $arg Invoice';
  }

  @override
  String editInvoiceType(String arg) {
    return 'Edit $arg Invoice';
  }

  @override
  String get invoiceNo => 'invoiceNo';

  @override
  String get invoiceNoRequired => 'invoiceNoRequired';

  @override
  String get pleaseSelectDate => 'pleaseSelectDate';

  @override
  String get dueDate => 'dueDate';

  @override
  String get selectCariAccount => 'selectCariAccount';

  @override
  String get invoiceItems => 'invoiceItems';

  @override
  String get addItem => 'addItem';

  @override
  String get noItemsYet => 'noItemsYet';

  @override
  String get item => 'Item';

  @override
  String get amountLabel => 'Amount';

  @override
  String get priceLabel => 'priceLabel';

  @override
  String get grandTotal => 'grandTotal';

  @override
  String get editItem => 'editItem';

  @override
  String get newItem => 'newItem';

  @override
  String get itemName => 'itemName';

  @override
  String get unitPrice => 'unitPrice';

  @override
  String get vatRatePercent => 'vatRatePercent';

  @override
  String get invoices => 'invoices';

  @override
  String get salesInvoices => 'salesInvoices';

  @override
  String get purchaseInvoices => 'purchaseInvoices';

  @override
  String get noInvoicesYet => 'noInvoicesYet';

  @override
  String deleteInvoiceConfirm(Object arg) {
    return 'Are you sure you want to delete invoice $arg?';
  }

  @override
  String get invoiceDeleted => 'invoiceDeleted';

  @override
  String get recordAdded => 'recordAdded';

  @override
  String get recordUpdated => 'recordUpdated';

  @override
  String get income => 'income';

  @override
  String newItemType(Object arg) {
    return 'New $arg';
  }

  @override
  String editItemType(Object arg) {
    return 'Edit $arg';
  }

  @override
  String get titleLabel => 'Title';

  @override
  String get pleaseEnterValidAmount => 'pleaseEnterValidAmount';

  @override
  String get selectCariAccountOptional => 'selectCariAccountOptional';

  @override
  String get selectProjectOptional => 'selectProjectOptional';

  @override
  String get incomeExpense => 'incomeExpense';

  @override
  String get incomes => 'incomes';

  @override
  String noIncomeExpenseYet(String arg) {
    return 'No $arg found yet.';
  }

  @override
  String deleteRecordConfirm(String arg) {
    return 'Are you sure you want to delete record $arg?';
  }

  @override
  String get recordDeleted => 'recordDeleted';

  @override
  String get settlementReport_caps => 'SETTLEMENT REPORT';

  @override
  String get noDataFound => 'No Data Found';

  @override
  String get settlementPeriod_caps => 'SETTLEMENT PERIOD';

  @override
  String get selectDate_caps => 'SELECT DATE';

  @override
  String get personnelSalaryStatus_caps => 'PERSONNEL SALARY STATUS';

  @override
  String get projectHakedis_caps => 'PROJECT PAYMENTS';

  @override
  String get settleAccount_caps => 'SETTLE ACCOUNT';

  @override
  String get noPendingHakedisFound => 'noPendingHakedisFound';

  @override
  String get processHakedisCollection => 'processHakedisCollection';

  @override
  String hakedisSettleConfirm(int count, String amount) {
    return '$count progress payments totaling $amount will be collected. Confirm?';
  }

  @override
  String get hakedisCollectionsProcessed => 'hakedisCollectionsProcessed';

  @override
  String get settlePersonnelAccount => 'settlePersonnelAccount';

  @override
  String laborSettleConfirm(int count, String amount) {
    return '$count labor payments totaling $amount will be paid. Confirm?';
  }

  @override
  String get personnelPaymentsProcessed => 'personnelPaymentsProcessed';

  @override
  String get closeCariAccounts => 'closeCariAccounts';

  @override
  String cariSettleConfirm(int count) {
    return '$count account operations will be closed. Confirm?';
  }

  @override
  String get cariAccountBalancesClosed => 'cariAccountBalancesClosed';

  @override
  String get confirm_caps => 'confirm_caps';

  @override
  String get periodNetProfit_caps => 'PERIOD NET PROFIT';

  @override
  String get totalRevenue_caps => 'TOTAL REVENUE';

  @override
  String get totalCost_caps => 'TOTAL COST';

  @override
  String get totalEarned => 'Total Earned';

  @override
  String get remainingPersonnelDebt => 'Remaining Personnel Debt';

  @override
  String get seePersonnelDetails => 'See Personnel Details';

  @override
  String laborSummaryDetail(int worked, int leave, int sunday) {
    return 'Worked: $worked | Leave: $leave | Sunday: $sunday';
  }

  @override
  String get producedHakedisNet => 'Produced Net Hakedis';

  @override
  String get pendingCollection => 'Pending Collection';

  @override
  String get customerReceivables => 'Customer Receivables';

  @override
  String get supplierPayables => 'Supplier Payables';

  @override
  String get mainCashStatus => 'Main Cash Status';

  @override
  String get search => 'Search';

  @override
  String get workerSummaryReport_caps => 'WORKER SUMMARY REPORT';

  @override
  String totalWorkHours(String hours) {
    return '$hours Hours Total Work';
  }

  @override
  String workerReport_caps(String name) {
    return '$name SUMMARY REPORT';
  }

  @override
  String totalHoursAndAmount(String hours, String amount) {
    return 'Total: $hours Hours | $amount';
  }

  @override
  String get hakedisDocument_caps => 'PAYMENT INSTALLMENT DOCUMENT';

  @override
  String get projectHakedisReport_caps => 'PROJECT PAYMENT REPORT';

  @override
  String get brutAmount_caps => 'GROSS AMOUNT';

  @override
  String get netAccrual_caps => 'NET ACCRUAL';

  @override
  String get quantity => 'Quantity';

  @override
  String get totalBrut => 'Total Gross';

  @override
  String get totalNet => 'Total Net';

  @override
  String reportDateLabel(String date) {
    return 'Report Date: $date';
  }

  @override
  String documentDateLabel(String date) {
    return 'Document Date: $date';
  }

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get date => 'Date';

  @override
  String get hour => 'Hour';

  @override
  String get mesai => 'Overtime';

  @override
  String get personal => 'Personnel';

  @override
  String get rate => 'Rate';

  @override
  String get stopaj => 'Withholding';

  @override
  String get teminat => 'Guarantee';

  @override
  String get pending_caps => 'PENDING';
}
