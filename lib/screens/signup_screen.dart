import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _agree = false;

  void _register() async {
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match!')));
      return;
    }
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/app_background.png', fit: BoxFit.cover)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Image.asset('assets/app_logo.png', width: 90, height: 90),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(child: Text('Create Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                            const SizedBox(height: 16),
                            _buildField('Full Name', _nameController),
                            _buildField('Email Address', _emailController),
                            _buildField('Password', _passwordController, obscure: true),
                            _buildField('Confirm Password', _confirmController, obscure: true),
                            Row(
                              children: [
                                Checkbox(value: _agree, onChanged: (v) => setState(() => _agree = v ?? false)),
                                const Expanded(child: Text('I agree to the environmental terms and conditions for responsible carbon monitoring', style: TextStyle(fontSize: 11, color: Colors.grey)))
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _agree ? _register : null,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA3FFA3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                child: const Text('Register', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(child: GestureDetector(onTap: () => Navigator.pop(context), child: const Text('Already have an account? Login', style: TextStyle(color: Color(0xFF497E66), fontWeight: FontWeight.bold))))
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(controller: controller, obscureText: obscure, decoration: InputDecoration(hintText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 12),
      ],
    );
  }
}