import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/auth_service.dart';
import '../services/cloud_service.dart';
import '../services/database_service.dart';
import 'main_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message, 
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message, 
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      if (_isLogin) {
        await _authService.signInWithEmail(
          _emailController.text, 
          _passwordController.text,
        );
      } else {
        await _authService.signUpWithEmail(
          _emailController.text, 
          _passwordController.text,
        );
      }
      
      if (!mounted) return;
      // Clear local data and pull from cloud for this account
      await DatabaseService().deleteAllUserData();
      await CloudService().syncAll();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } catch (e) {
      _showError(e.toString().split(']').last.trim());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    
    try {
      final userCreds = await _authService.signInWithGoogle();
      if (userCreds != null && mounted) {
        // Clear local data and pull from cloud for this account
        await DatabaseService().deleteAllUserData();
        await CloudService().syncAll();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      _showError('Failed to sign in with Google');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildEmailForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: 'Email address',
            prefixIcon: const Icon(LucideIcons.mail, color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.isEmpty || !value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            hintText: 'Password',
            prefixIcon: const Icon(LucideIcons.lock, color: Color(0xFF9CA3AF)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                color: const Color(0xFF9CA3AF),
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
          ),
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submitEmail(),
          validator: (value) {
            if (value == null || value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitEmail,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEC4899),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 24, width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  _isLogin ? 'Sign In' : 'Sign Up',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String titleText = _isLogin ? 'Welcome Back' : 'Create Account';
    String subtitleText = _isLogin ? 'Sign in to continue your journey' : 'Start learning Japanese today';

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF7FB),
              Color(0xFFFCE7F3),
              Color(0xFFF5F3FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Color(0x22EC4899),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.user,
                        size: 64,
                        color: Color(0xFFEC4899), // Pink
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Title
                    Text(
                      titleText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitleText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Inputs Section
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildEmailForm(),
                    ),
                    
                    const SizedBox(height: 24),

                    // Other Login Methods
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 12),
                          ),
                        ),
                        const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Image.network(
                        'https://developers.google.com/identity/images/g-logo.png',
                        height: 24,
                        errorBuilder: (context, error, stackTrace) => 
                            const Icon(Icons.error_outline, size: 24),
                      ),
                      label: Text(
                        'Continue with Google',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Toggle Mode
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _formKey.currentState?.reset();
                        });
                      },
                      child: RichText(
                        text: TextSpan(
                          text: _isLogin ? "Don't have an account? " : "Already have an account? ",
                          style: GoogleFonts.inter(color: const Color(0xFF6B7280)),
                          children: [
                            TextSpan(
                              text: _isLogin ? 'Sign Up' : 'Sign In',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFEC4899),
                                fontWeight: FontWeight.bold,
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
          ),
        ),
      ),
    );
  }
}
