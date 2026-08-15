import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main_holder.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscure = true;
  bool _isLoading = false;

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email or password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null && mounted) {
        // 👑 关键：登录成功后，将系统开关设为 true，并把当前真实登录的 user.id 写入数据库
        try {
          await Supabase.instance.client
              .from('system_control')
              .update({
                'is_running': true,
                'current_user_id': response.user!.id,
              })
              .eq('id', 1);
        } catch (e) {
          debugPrint('Failed to update system_control on login: $e');
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainHolder()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        final errorMessage = e.message.toLowerCase();
        if (errorMessage.contains('invalid') || errorMessage.contains('credential') || errorMessage.contains('grant')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid email or password')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection error, please try again')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/app_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent, 
          resizeToAvoidBottomInset: true, 
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 120), 
                Center(
                  child: ClipOval(
                    child: Image.asset(
                      'assets/app_logo.png', 
                      width: 100, 
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text('Welcome Back', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))
                            ),
                            const SizedBox(height: 6),
                            const Center(
                              child: Text('Sign in to continue', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w400))
                            ),
                            const SizedBox(height: 24),
                            const Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                hintText: 'Email Address', 
                                prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text('Password', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _passwordController,
                              obscureText: _isObscure,
                              decoration: InputDecoration(
                                hintText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outlined, color: Colors.grey),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                suffixIcon: IconButton(
                                  icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _isObscure = !_isObscure),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: const Text('Forgot Password ?', style: TextStyle(color: Colors.grey)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFA3FFA3),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF497E66)))
                                    : const Text('Sign In', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("Don't have an account ? ", style: TextStyle(color: Colors.grey)),
                                  GestureDetector(
                                    onTap: () {
                                      FocusManager.instance.primaryFocus?.unfocus();
                                      Navigator.push(
                                        context, 
                                        MaterialPageRoute(builder: (_) => const SignUpScreen())
                                      ).then((_) {
                                        FocusManager.instance.primaryFocus?.unfocus();
                                      });
                                    },
                                    child: const Text('Sign Up', style: TextStyle(color: Color(0xFF497E66), fontWeight: FontWeight.bold)),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}