import 'package:flutter/material.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  String? error;

  void login() {
    final u = usernameCtrl.text.trim();
    final p = passwordCtrl.text.trim();
    if ((u == 'admin' && p == '1') || (u == 'user' && p == '1')) {
      final role = u == 'admin' ? 'admin' : 'user';
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(role: role)),
      );
    } else {
      setState(() => error = 'Sai người dung hoặc mật khẩu!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: 360,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Đăng nhập', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: usernameCtrl, decoration: const InputDecoration(labelText: 'Tên đăng nhập')),
                const SizedBox(height: 8),
                TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: 'Mật khẩu'), obscureText: true),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: login, child: const Text('Đăng Nhập'))),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: Colors.red)),
                ]
              ]),
            ),
          ),
        ),
      ),
    );
  }
}