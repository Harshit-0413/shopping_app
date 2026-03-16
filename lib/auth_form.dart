import 'package:flutter/material.dart';

class AuthForm extends StatelessWidget {
  final bool isLogin;

  const AuthForm({super.key, required this.isLogin});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          isLogin ? "Login" : "Sign Up",
          style: const TextStyle(fontSize: 24),
        ),

        const SizedBox(height: 20),

        if (!isLogin)
          TextFormField(
            decoration: const InputDecoration(labelText: "Confirm Password"),
          ),

        //email + password fields same
      ],
    );
  }
}
