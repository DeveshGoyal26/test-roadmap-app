import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillpe/providers/auth_provider.dart' as user_auth_provider;
import 'package:skillpe/pages/login_page.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  final bool requireAuth;

  const AuthGuard({super.key, required this.child, this.requireAuth = true});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<user_auth_provider.AuthProvider>(context);

    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || authProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && authProvider.isAuthenticated) {
            return child;
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
