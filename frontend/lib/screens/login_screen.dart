import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  String? _errorMsg;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMsg = null);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success =
        await auth.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
    if (!success && mounted) {
      setState(() => _errorMsg = 'Invalid email or password. Please try again.');
    }
  }

  void _fillDoctor(String email) {
    setState(() {
      _emailCtrl.text = email;
      _passCtrl.text = 'doctor123';
      _errorMsg = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final locale = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          child: Column(
            children: [
                // ── Hero gradient header ──
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF004D40), Color(0xFF00897B), Color(0xFF26C6DA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3), width: 2),
                          ),
                          child: const Icon(Icons.medical_services_rounded,
                              color: Colors.white, size: 38),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          locale.translate('app_title'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          locale.translate('app_subtitle'),
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Login card ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locale.translate('welcome_back'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(locale.translate('sign_in_msg'),
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 13)),
                          const SizedBox(height: 28),

                          // Email
                          _buildField(
                            controller: _emailCtrl,
                            hint: locale.translate('email_hint'),
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) =>
                                (v == null || !v.contains('@'))
                                    ? 'Enter a valid email'
                                    : null,
                          ),
                          const SizedBox(height: 14),

                          // Password
                          _buildField(
                            controller: _passCtrl,
                            hint: locale.translate('password_hint'),
                            icon: Icons.lock_outline,
                            obscure: _obscure,
                            suffix: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.white38,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                            validator: (v) =>
                                (v == null || v.length < 6)
                                    ? 'Password must be at least 6 characters'
                                    : null,
                          ),
                          const SizedBox(height: 6),

                          // Error message
                          if (_errorMsg != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, bottom: 4),
                              child: Row(children: [
                                const Icon(Icons.error_outline,
                                    color: Color(0xFFEF5350), size: 15),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(_errorMsg!,
                                      style: const TextStyle(
                                          color: Color(0xFFEF5350),
                                          fontSize: 12)),
                                ),
                              ]),
                            ),

                          const SizedBox(height: 22),

                          // Login button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: auth.isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                        color: Color(0xFF00BFA5)))
                                : ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00897B),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                      elevation: 4,
                                      shadowColor:
                                          const Color(0xFF00897B).withOpacity(0.4),
                                      textStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    child: Text(locale.translate('sign_in_btn')),
                                  ),
                          ),
                          const SizedBox(height: 16),

                          // Sign up link
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SignupScreen()),
                              ),
                              child: RichText(
                                text: TextSpan(
                                  text: locale.translate('no_account'),
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 13),
                                  children: [
                                    TextSpan(
                                      text: locale.translate('sign_up'),
                                      style: const TextStyle(
                                          color: Color(0xFF26C6DA),
                                          fontWeight: FontWeight.bold),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00BFA5), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF5350)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFEF5350), fontSize: 11),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
