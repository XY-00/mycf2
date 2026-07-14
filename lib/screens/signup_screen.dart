import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main_holder.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPasswordObscure = true;
  bool _isConfirmObscure = true;

  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
    _confirmController.addListener(_validateConfirmPassword);
  }

  void _validateEmail() {
    final text = _emailController.text.trim();
    if (text.isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(text)) {
      setState(() => _emailError = "Invalid email format");
    } else {
      setState(() => _emailError = null);
    }
  }

  void _validatePassword() {
    final text = _passwordController.text;
    if (text.isNotEmpty && text.length < 6) {
      setState(() => _passwordError = "Must be at least 6 characters");
    } else {
      setState(() => _passwordError = null);
    }
  }

  void _validateConfirmPassword() {
    final text = _confirmController.text;
    if (text.isNotEmpty && text != _passwordController.text) {
      setState(() => _confirmError = "Passwords do not match");
    } else {
      setState(() => _confirmError = null);
    }
  }

  // 👑 智能提示保底拦截核心方法
  void _register() async {
    // 1️⃣ 情况一：任何一个框留白了，立刻无条件拦截弹出 Please fill in all blanks
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all blanks')),
      );
      return;
    }

    // 判断当前邮箱格式以及密码格式是否有红字报错
    final isEmailInvalid = _emailError != null;
    final isPasswordInvalid = _passwordError != null || _confirmError != null;

    // 2️⃣ 情况二：Email 和 密码 同时都不对
    if (isEmailInvalid && isPasswordInvalid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check your email and password')),
      );
      return;
    }

    // 3️⃣ 情况三：仅仅是 Email 格式不对
    if (isEmailInvalid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check your email')),
      );
      return;
    }

    // 4️⃣ 情况四：仅仅是密码格式或匹配不对
    if (isPasswordInvalid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check your password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! 🎉')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainHolder()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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
                const SizedBox(height: 100), 
                
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Image.asset('assets/app_logo.png', width: 90, height: 90),
                  ),
                ),
                const SizedBox(height: 20),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(child: Text('Create Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                            const SizedBox(height: 6),
                            const Center(child: Text('join myCF', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w400))),
                            const SizedBox(height: 16),
                            _buildField('Full Name', _nameController, icon: Icons.person_outline),
                            _buildField('Email Address', _emailController, errorText: _emailError, icon: Icons.email_outlined),
                            _buildField(
                              'Password', 
                              _passwordController, 
                              obscure: _isPasswordObscure,
                              errorText: _passwordError,
                              icon: Icons.lock_outlined,
                              suffixIcon: IconButton(
                                icon: Icon(_isPasswordObscure ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _isPasswordObscure = !_isPasswordObscure),
                              ),
                            ),
                            _buildField(
                              'Confirm Password', 
                              _confirmController, 
                              obscure: _isConfirmObscure,
                              errorText: _confirmError,
                              icon: Icons.lock_outlined,
                              suffixIcon: IconButton(
                                icon: Icon(_isConfirmObscure ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _isConfirmObscure = !_isConfirmObscure),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: !_isLoading ? _register : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFA3FFA3),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF497E66)))
                                    : const Text('Register', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("Already have an account? ", style: TextStyle(color: Colors.grey)),
                                  GestureDetector(
                                    onTap: () {
                                      // 👑 彻底释放当前页面所有输入框的焦点，退回时绝不会携带任何残留光标
                                      FocusScope.of(context).unfocus();
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Login', style: TextStyle(color: Color(0xFF497E66), fontWeight: FontWeight.bold)),
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

  Widget _buildField(String label, TextEditingController controller, {bool obscure = false, String? errorText, Widget? suffixIcon, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller, 
          obscureText: obscure, 
          decoration: InputDecoration(
            hintText: label, 
            errorText: errorText, 
            prefixIcon: Icon(icon, color: Colors.grey),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 14), 
      ],
    );
  }
}