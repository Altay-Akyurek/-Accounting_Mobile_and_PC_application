import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isLogin = true;
  bool _obscurePassword = true;

  Future<void> _handleAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.fillAllFields)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _authService.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        final response = await _authService.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        
        // Debug için response içeriğini yazdıralım
        // debugPrint('Sign Up Response User: ${response.user}');
        // debugPrint('Sign Up Response Metadata: ${response.user?.appMetadata}');
        
        // Supabase bazen sessizce başarılı döner (güvenlik için), 
        // ancak kullanıcı zaten varsa session boş gelir veya metadata farklı olur.
        if (response.user != null && response.session == null && 
            response.user!.identities != null && response.user!.identities!.isEmpty) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.accountAlreadyRegistered),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _isLogin = true);
          return;
        }

        if (mounted) {
          _showEmailConfirmationDialog();
          setState(() => _isLogin = true);
        }
      }
    } catch (e) {
      // debugPrint('Auth Error: $e');
      if (mounted) {
        String message = e.toString();
        
        final lowerMessage = message.toLowerCase();
        // Giriş hatası kontrolü (E-posta veya şifre yanlış)
        if (lowerMessage.contains('invalid login credentials') || 
            lowerMessage.contains('invalid email or password')) {
          message = AppLocalizations.of(context)!.invalidCredentials;
        }
        // Mükerrer kayıt hatası kontrolü
        else if (lowerMessage.contains('user already registered') || 
            lowerMessage.contains('already exists') ||
            (e is AuthException && (e.message.toLowerCase().contains('already registered') || e.message.toLowerCase().contains('already exists')))) {
          message = AppLocalizations.of(context)!.accountAlreadyRegistered;
        } else if (lowerMessage.contains('email not confirmed')) {
          _showEmailNotConfirmedDialog();
          return;
        } else if (lowerMessage.contains('email rate limit exceeded') || 
                   lowerMessage.contains('over_email_send_rate_limit')) {
          message = AppLocalizations.of(context)!.rateLimitExceeded;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.contains('Exception:') ? message.split('Exception:')[1].trim() : message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEmailConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.mark_email_read_rounded, size: 60, color: Color(0xFF2EC4B6)),
        title: Text(AppLocalizations.of(context)!.registrationSuccess, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.registrationSuccessDetail,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context)!.registrationInstruction,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.okIUnderstand),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmailNotConfirmedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.orange),
        title: Text(AppLocalizations.of(context)!.emailNotConfirmed, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          AppLocalizations.of(context)!.emailNotConfirmedDetail,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.fillAllFields)),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.resetPassword(email);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: const Icon(Icons.mark_email_read_rounded, size: 60, color: Color(0xFF2EC4B6)),
            title: Text(AppLocalizations.of(context)!.emailSent, style: const TextStyle(fontWeight: FontWeight.w900)),
            content: Text(
              AppLocalizations.of(context)!.resetPasswordEmailSent,
              textAlign: TextAlign.center,
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.ok),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('Error sending recovery email')) {
          errorMessage = AppLocalizations.of(context)!.emailSendError;
        } else if (errorMessage.contains('over_email_send_rate_limit')) {
          errorMessage = AppLocalizations.of(context)!.rateLimitExceeded;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Stack(
        children: [
          // Background with a subtle professional gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF011627), // Deep Navy
                  Color(0xFF0F2027), // Ultra Dark
                  Color(0xFF203A43), // Steel Gray Blue
                ],
              ),
            ),
          ),
          
          // Subtle architectural grid overlay for "Muhasebe/İnşaat" feel
          Opacity(
            opacity: 0.03,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10,
              ),
              itemBuilder: (context, index) => Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 0.5),
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Premium Logo Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white10, width: 2),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // App Branding
                  const Text(
                    'MUHASEBE PRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.corporateCloudSolution,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Form Card
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 450),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTextField(
                            controller: _emailController,
                            label: AppLocalizations.of(context)!.email,
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),
                            _buildTextField(
                              controller: _passwordController,
                              label: AppLocalizations.of(context)!.password,
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                            ),
                            if (_isLogin)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _isLoading ? null : _handleForgotPassword,
                                  child: Text(
                                    AppLocalizations.of(context)!.forgotPassword,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF011627),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                                shadowColor: const Color(0xFF011627).withOpacity(0.5),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _isLogin ? AppLocalizations.of(context)!.loginButton : AppLocalizations.of(context)!.registerButton,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          TextButton(
                            onPressed: () => setState(() => _isLogin = !_isLogin),
                            child: RichText(
                              text: TextSpan(
                                text: _isLogin ? AppLocalizations.of(context)!.noAccount : AppLocalizations.of(context)!.haveAccount,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: _isLogin ? AppLocalizations.of(context)!.register : AppLocalizations.of(context)!.login,
                                    style: const TextStyle(
                                      color: Color(0xFF011627),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  Text(
                    AppLocalizations.of(context)!.secureConnection,
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          keyboardType: keyboardType,
          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF011627)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF011627).withOpacity(0.5)),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: const Color(0xFF011627).withOpacity(0.5),
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF011627), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
