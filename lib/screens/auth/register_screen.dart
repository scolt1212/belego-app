import 'package:flutter/material.dart';

import '../../services/postal_code_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/max_width_box.dart';
import '../onboarding/company_setup_screen.dart';
import 'login_screen.dart';

/// Registrierungs-Screen. Demonstriert den Ablauf lokal, ohne echte
/// Authentifizierung oder Backend-Anbindung.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.postalCodeService});

  final PostalCodeService postalCodeService;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompanySetupScreen(
          registeredFirstName: _firstNameController.text.trim(),
          registeredLastName: _lastNameController.text.trim(),
          // E-Mail wird intern klein geschrieben behandelt.
          registeredEmail: _emailController.text.trim().toLowerCase(),
          postalCodeService: widget.postalCodeService,
        ),
      ),
    );
  }

  void _openLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            LoginScreen(postalCodeService: widget.postalCodeService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrieren')),
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
                    key: const Key('register_first_name'),
                    controller: _firstNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Vorname'),
                    validator: (v) => Validators.required(
                      v,
                      message: 'Bitte Vorname eingeben',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('register_last_name'),
                    controller: _lastNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nachname'),
                    validator: (v) => Validators.required(
                      v,
                      message: 'Bitte Nachname eingeben',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('register_email'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-Mail-Adresse',
                    ),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('register_password'),
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Passwort',
                      suffixIcon: IconButton(
                        key: const Key('register_password_visibility'),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('register_confirm_password'),
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Passwort bestätigen',
                      suffixIcon: IconButton(
                        key: const Key('register_confirm_password_visibility'),
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                      ),
                    ),
                    validator: (v) =>
                        Validators.confirmPassword(v, _passwordController.text),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    key: const Key('register_submit'),
                    onPressed: _handleRegister,
                    child: const Text('Konto erstellen'),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: _openLogin,
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(text: 'Bereits registriert? '),
                            TextSpan(
                              text: 'Anmelden',
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
