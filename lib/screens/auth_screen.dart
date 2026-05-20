import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  final bool initialIsRegister;

  const AuthScreen({super.key, this.initialIsRegister = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late bool _isRegister;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.initialIsRegister;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getLocalizedError(dynamic error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('invalid login credentials') || msg.contains('invalid credential')) {
      return 'Nieprawidłowy e-mail lub hasło.';
    } else if (msg.contains('user already exists') || msg.contains('already registered')) {
      return 'Ten adres e-mail jest już zarejestrowany.';
    } else if (msg.contains('should be at least 6 characters') || msg.contains('password should be at least')) {
      return 'Hasło musi mieć co najmniej 6 znaków.';
    } else if (msg.contains('email not confirmed')) {
      return 'Adres e-mail nie został potwierdzony. Sprawdź swoją pocztę.';
    } else if (msg.contains('network') || msg.contains('connection')) {
      return 'Brak połączenia z siecią. Spróbuj ponownie.';
    }
    return 'Wystąpił nieoczekiwany błąd. Spróbuj ponownie.';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isRegister) {
        // Sign Up
        final response = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          if (response.session != null) {
            // E-mail confirmation jest wyłączone - zalogowano od razu!
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Konto utworzone i zalogowane pomyślnie!'),
                backgroundColor: Colors.blueAccent,
              ),
            );
          } else {
            // E-mail confirmation jest włączone - wymagane potwierdzenie
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF16161A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFF24242A), width: 1),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.mark_email_read_rounded, color: Colors.blueAccent),
                    SizedBox(width: 10),
                    Text(
                      'Potwierdź e-mail',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                content: const Text(
                  'Wysłaliśmy link aktywacyjny na Twój adres e-mail. Sprawdź skrzynkę i kliknij w link, aby aktywować konto i móc się zalogować.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Zamknij dialog
                      Navigator.of(context).pop(); // Cofnij do profilu
                    },
                    child: const Text(
                      'Rozumiem',
                      style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }
        }
      } else {
        // Sign In
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          Navigator.of(context).pop(); // Pop back to profile screen which will automatically show logged in UI
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getLocalizedError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Brand Icon with glow
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blueAccent.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.1),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.sports_soccer_rounded,
                  size: 32,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                _isRegister ? 'Utwórz konto' : 'Witaj z powrotem',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isRegister
                    ? 'Dołącz do społeczności kibiców MatchDay'
                    : 'Zaloguj się, aby zsynchronizować dane kibica',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              // Segment Control (Animated login / register toggle)
              Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF16161A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
                ),
                child: Row(
                  children: [
                    // Login segment button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_isRegister) {
                            setState(() {
                              _isRegister = false;
                              _errorMessage = null;
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: !_isRegister ? Colors.blueAccent : Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              'Logowanie',
                              style: TextStyle(
                                color: !_isRegister ? Colors.black : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Register segment button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!_isRegister) {
                            setState(() {
                              _isRegister = true;
                              _errorMessage = null;
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: _isRegister ? Colors.blueAccent : Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              'Rejestracja',
                              style: TextStyle(
                                color: _isRegister ? Colors.black : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form fields card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF16161A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Error message view if any
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.2), width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Adres E-mail',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          hintText: 'user@example.com',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12),
                          prefixIcon: const Icon(Icons.email_rounded, color: Colors.grey, size: 20),
                          filled: true,
                          fillColor: const Color(0xFF0E0E10),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.redAccent),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Wprowadź adres e-mail.';
                          }
                          final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegExp.hasMatch(value.trim())) {
                            return 'Niepoprawny format adresu e-mail.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Hasło',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          prefixIcon: const Icon(Icons.lock_rounded, color: Colors.grey, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0E0E10),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.redAccent),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Wprowadź hasło.';
                          }
                          if (value.trim().length < 6) {
                            return 'Hasło musi mieć co najmniej 6 znaków.';
                          }
                          return null;
                        },
                      ),

                      // Password confirmation (Only for register)
                      if (_isRegister) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Potwierdź hasło',
                            labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                            prefixIcon: const Icon(Icons.lock_reset_rounded, color: Colors.grey, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0E0E10),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.redAccent),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Potwierdź hasło.';
                            }
                            if (value != _passwordController.text) {
                              return 'Hasła muszą być identyczne.';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Primary Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : Text(
                                  _isRegister ? 'Zarejestruj się' : 'Zaloguj się',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Swap prompt link
              GestureDetector(
                onTap: () {
                  if (!_isLoading) {
                    setState(() {
                      _isRegister = !_isRegister;
                      _errorMessage = null;
                    });
                  }
                },
                child: Text(
                  _isRegister
                      ? 'Masz już konto? Zaloguj się'
                      : 'Nie masz konta? Zarejestruj się',
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
