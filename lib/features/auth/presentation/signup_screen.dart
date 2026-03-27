import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // ✅ IMPORTANT

import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  void signup() async {
    setState(() => isLoading = true);

    try {
      await ref.read(authRepositoryProvider).signUp(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      // ✅ Professional UX: success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup successful. Please login.")),
      );

      // ✅ Redirect cleanly
      context.go('/login');

    } catch (e) {
      if (!mounted) return;

      String errorMessage = "Signup failed";

      if (e.toString().contains('User already registered')) {
        errorMessage = "Email already exists";
      } else if (e.toString().contains('over_email_send_rate_limit')) {
        errorMessage = "Too many attempts. Try again in 1 minute";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    // ✅ VERY IMPORTANT (memory leak fix)
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Create Account",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : signup,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Signup"),
              ),
            ),

            const SizedBox(height: 10),

            // ✅ Back to login option
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text("Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}