import 'package:flutter/material.dart';

class ForgotPinPageWidget extends StatefulWidget {
  const ForgotPinPageWidget({super.key});

  static String routeName = 'forgot_pin_page';
  static String routePath = '/forgotPinPage';

  @override
  State<ForgotPinPageWidget> createState() =>
      _ForgotPinPageWidgetState();
}

class _ForgotPinPageWidgetState extends State<ForgotPinPageWidget> {
  final _contactController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  void submit() {
    if (_newPinController.text != _confirmPinController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PINs do not match")),
      );
      return;
    }

    print("Contact: ${_contactController.text}");
    print("New PIN: ${_newPinController.text}");
    print("Password: ${_passwordController.text}");

    // TODO: connect to backend later
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Forgot PIN")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Reset Your PIN",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: "Phone or Email",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _newPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "New PIN",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _confirmPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Confirm PIN",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Your Password",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submit,
                child: const Text("Reset PIN"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}