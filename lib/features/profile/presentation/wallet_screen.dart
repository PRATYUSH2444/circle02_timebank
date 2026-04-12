import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Wallet")),

      body: StreamBuilder(
        stream: supabase
            .from('users')
            .stream(primaryKey: ['id'])
            .eq('id', userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data!.first;
          final tokens = user['tokens'] ?? 0;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                const Text(
                  "Your Tokens",
                  style: TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 10),

                Text(
                  "$tokens",
                  style: const TextStyle(
                    fontSize: 50,
                    color: Colors.cyan,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Earn by teaching • Spend by learning",
                  style: TextStyle(color: Colors.white38),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}