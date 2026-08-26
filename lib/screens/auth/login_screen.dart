import 'package:flutter/material.dart';

import '../../services/postal_code_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/max_width_box.dart';
import '../root_shell.dart';
import 'register_screen.dart';

/// Anmelde-Screen. Demonstriert den Ablauf lokal, ohne echte
/// Authentifizierung oder Backend-Anbindung.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.postalCodeService});

  final PostalCodeService postalCodeService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diese Funktion ist noch nicht verfügbar.')),
    );
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => RootShell(
          isDemoMode: false,
          postalCodeService: widget.postalCodeService,
        ),
      ),
      (route) => false,
    );
  }

  void _openRegister() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            RegisterScreen(postalCodeService: widget.postalCodeService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anmelden')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: MaxWidthBox(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const Key('login_email'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-Mail-Adresse',
                    ),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('login_password'),
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Passwort'),
                    validator: (value) => Validators.required(
                      value,
                      message: 'Bitte Passwort eingeben',
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _handleForgotPassword,
                      child: const Text('Passwort vergessen?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    key: const Key('login_submit'),
                    onPressed: _handleLogin,
                    child: const Text('Anmelden'),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: _openRegister,
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(text: 'Noch kein Konto? '),
                            TextSpan(
                              text: 'Jetzt registrieren',
                              style: TextStyle(
                                color: AppColors.sky600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
