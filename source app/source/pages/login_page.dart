import 'package:flutter/material.dart';

// Minimal, self-contained LoginPage used for tests and package imports.
// Kept intentionally simple so tests that expect a LoginPage widget succeed.
class LoginPage extends StatefulWidget {
	const LoginPage({super.key});

	@override
	State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
	final TextEditingController _usernameController = TextEditingController();
	final TextEditingController _passwordController = TextEditingController();

	@override
	void dispose() {
		_usernameController.dispose();
		_passwordController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('SMART HOME Đăng nhập')),
			body: Center(
				child: Padding(
					padding: const EdgeInsets.all(24.0),
					child: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Tên đăng nhập')),
							const SizedBox(height: 12),
							  TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu')),
							const SizedBox(height: 20),
							SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {}, child: const Text('Đăng nhập'))),
						],
					),
				),
			),
		);
	}
}
