import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/routes.dart';
import '../../core/services/pin_service.dart';
import '../../shared/widgets/glass_snackbar.dart';

/// Page de connexion : code PIN 4 chiffres (par défaut 0000).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final PinService _pinService = PinService.instance;
  final _nameController = TextEditingController();
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  String _input = '';

  @override
  void initState() {
    super.initState();
    _loadSavedName();
  }

  Future<void> _loadSavedName() async {
    final name = await _pinService.getUserName();
    if (mounted && name != null && name.isNotEmpty) {
      _nameController.text = name;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged() {
    final sb = StringBuffer();
    for (final c in _controllers) {
      sb.write(c.text);
    }
    setState(() => _input = sb.toString());
    if (_input.length == 4) _validate();
  }

  Future<void> _validate() async {
    final ok = await _pinService.validatePin(_input);
    if (!mounted) return;
    if (ok) {
      final name = _nameController.text.trim();
      if (name.isNotEmpty) {
        await _pinService.setUserName(name);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
    } else {
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes.first.requestFocus();
      setState(() => _input = '');
      showGlassSnackBar(context, message: 'Code incorrect');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/login.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.35)),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      size: 64,
                      color: theme.colorScheme.onPrimary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Connexion',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Entrez votre code à 4 chiffres',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withValues(
                          alpha: 0.9,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'Nom d\'utilisateur',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onPrimary.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.2,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: SizedBox(
                            width: 56,
                            child: TextField(
                              controller: _controllers[i],
                              focusNode: _focusNodes[i],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              obscureText: true,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: theme.colorScheme.onPrimary
                                    .withValues(alpha: 0.2),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (_) {
                                if (_controllers[i].text.isNotEmpty && i < 3) {
                                  _focusNodes[i + 1].requestFocus();
                                }
                                _onDigitChanged();
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
