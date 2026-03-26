import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Circle Login 🚀",
              style: TextStyle(fontSize: 22),
            ),

            ElevatedButton(
              onPressed: () async {
                final res = await SupabaseService.client.from('users').select();
                print(res);
              },
              child: const Text("Test DB"),
            ),
          ],
        ),
      ),
    );
  }
}