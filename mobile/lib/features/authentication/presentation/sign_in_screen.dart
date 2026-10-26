import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianroute/features/authentication/presentation/auth_controller.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.read(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.shield, size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Sign in to GuardianRoute',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use Google or continue anonymously for demos and testing.',
                style: theme.textTheme.bodyMedium,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const Spacer(),
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(auth.signInWithGoogle),
                icon: const Icon(Icons.g_mobiledata),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _run(auth.signInAnonymously),
                child: const Text('Continue as guest'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
