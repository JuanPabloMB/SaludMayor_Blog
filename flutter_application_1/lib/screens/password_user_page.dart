import 'package:flutter/material.dart';
import 'login_user_page.dart';
class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {

  final TextEditingController correoController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {

    correoController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar contrseña'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.person_add,
              size: 70,
            ),
            const SizedBox(height: 20),
            const Text(
              'Recuperar contraseña',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),
            TextField(
              controller: correoController,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Contraseña restablecida',
                      ),
                    ),
                  );
                },
                child: const Text('Recuperar contraseña'),
              ),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context)=> const LoginPage()),);
              },
              child: const Text(
                'Volver a la pagina de inicio ',
              ),
            ),
          ],
        ),
      ),
    );
  }
}