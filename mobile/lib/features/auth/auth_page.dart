// HEAL — Authentication page.
//
// Tabs:
//   - Sign in
//   - Create account
//   - Forgot password
//
// Providers:
//   - Email + password
//   - Google  (Android / iOS / Web)
//   - Apple   (iOS / macOS / Web only — button hidden elsewhere)
//
// Tone is reverent: copy strings are in the same first-person style as the
// rest of the app. Errors are surface as gentle copy via [AuthError] (see
// auth_service.dart). On success we route to wherever the user was trying
// to go, or pop.

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/theme.dart';
import '../../design/copy.dart';
import '../../design/pressable.dart';
import '../../services/auth_service.dart';

class AuthPage extends HookConsumerWidget {
  /// Optional return route. After successful auth we `go(returnTo)`.
  final String? returnTo;
  const AuthPage({super.key, this.returnTo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(HealTokens.s24),
            child: Column(
              children: [
                _Header(),
                const SizedBox(height: HealTokens.s24),
                _TabBar(),
                const SizedBox(height: HealTokens.s16),
                Expanded(
                  child: TabBarView(
                    children: [
                      _EmailForm(mode: _EmailMode.signIn, returnTo: returnTo),
                      _EmailForm(mode: _EmailMode.signUp, returnTo: returnTo),
                      _EmailForm(mode: _EmailMode.reset, returnTo: returnTo),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'A welcome',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: HealTokens.brass,
                fontWeight: FontWeight.w300,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: HealTokens.s12),
        Text(
          'Your practice can travel with you — across phones, across time.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: HealTokens.cream.withValues(alpha: 0.8),
              ),
        ),
      ],
    );
  }
}

class _TabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TabBar(
      labelColor: HealTokens.brass,
      unselectedLabelColor: HealTokens.cream.withValues(alpha: 0.5),
      indicatorColor: HealTokens.brass,
      indicatorSize: TabBarIndicatorSize.label,
      tabs: const [
        Tab(text: 'Sign in'),
        Tab(text: 'Create'),
        Tab(text: 'Reset'),
      ],
    );
  }
}

enum _EmailMode { signIn, signUp, reset }

class _EmailForm extends HookConsumerWidget {
  final _EmailMode mode;
  final String? returnTo;
  const _EmailForm({required this.mode, this.returnTo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailCtl = useTextEditingController();
    final passCtl = useTextEditingController();
    final nameCtl = useTextEditingController();
    final obscure = useState(true);
    final busy = useState(false);
    final errorText = useState<String?>(null);
    final infoText = useState<String?>(null);

    Future<void> submit() async {
      errorText.value = null;
      infoText.value = null;
      final email = emailCtl.text.trim();
      final password = passCtl.text;
      if (email.isEmpty) {
        errorText.value = 'I need an email to find your account.';
        return;
      }
      if (mode != _EmailMode.reset && password.isEmpty) {
        errorText.value = 'A password is required.';
        return;
      }
      busy.value = true;
      try {
        final svc = ref.read(authServiceProvider);
        switch (mode) {
          case _EmailMode.signIn:
            await svc.signInWithEmail(email: email, password: password);
            break;
          case _EmailMode.signUp:
            await svc.registerWithEmail(
              email: email,
              password: password,
              displayName: nameCtl.text.trim().isEmpty ? null : nameCtl.text.trim(),
            );
            break;
          case _EmailMode.reset:
            await svc.sendPasswordReset(email);
            infoText.value =
                "I've sent a reset link to $email. Check your inbox in a moment.";
            busy.value = false;
            return;
        }
        if (returnTo != null && context.mounted) {
          context.go(returnTo!);
        } else if (context.mounted) {
          context.pop();
        }
      } catch (e) {
        if (kDebugMode) print('Auth error: $e');
        errorText.value = _friendly(e);
      } finally {
        busy.value = false;
      }
    }

    final showName = mode == _EmailMode.signUp;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showName)
            _Field(
              controller: nameCtl,
              label: 'Your name (optional)',
              hint: 'What should I call you?',
              textInputAction: TextInputAction.next,
            ),
          _Field(
            controller: emailCtl,
            label: 'Email',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: mode == _EmailMode.reset
                ? TextInputAction.done
                : TextInputAction.next,
          ),
          if (mode != _EmailMode.reset)
            _Field(
              controller: passCtl,
              label: 'Password',
              hint: mode == _EmailMode.signUp
                  ? 'At least 6 characters'
                  : 'Your password',
              obscure: obscure.value,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => submit(),
              suffix: IconButton(
                icon: Icon(
                  obscure.value
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: HealTokens.cream.withValues(alpha: 0.6),
                ),
                onPressed: () => obscure.value = !obscure.value,
              ),
            ),
          if (errorText.value != null) ...[
            const SizedBox(height: HealTokens.s12),
            _ErrorText(errorText.value!),
          ],
          if (infoText.value != null) ...[
            const SizedBox(height: HealTokens.s12),
            _InfoText(infoText.value!),
          ],
          const SizedBox(height: HealTokens.s20),
          Pressable(
            onTap: busy.value ? null : submit,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: HealTokens.s16),
              decoration: BoxDecoration(
                color: HealTokens.brass,
                borderRadius: BorderRadius.circular(HealTokens.r16),
              ),
              alignment: Alignment.center,
              child: busy.value
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(HealTokens.rosewoodDeep),
                      ),
                    )
                  : Text(
                      _primaryLabel,
                      style: const TextStyle(
                        color: HealTokens.rosewoodDeep,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: HealTokens.s20),
          const _Divider(),
          const SizedBox(height: HealTokens.s20),
          _ProviderButtons(returnTo: returnTo),
        ],
      ),
    );
  }

  String get _primaryLabel {
    switch (mode) {
      case _EmailMode.signIn:
        return 'Sign in';
      case _EmailMode.signUp:
        return 'Create account';
      case _EmailMode.reset:
        return 'Send reset link';
    }
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final Widget? suffix;

  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: HealTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: HealTokens.cream.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            style: const TextStyle(color: HealTokens.cream, fontSize: 16),
            cursorColor: HealTokens.brass,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: HealTokens.cream.withValues(alpha: 0.3),
              ),
              filled: true,
              fillColor: HealTokens.rosewood.withValues(alpha: 0.6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(HealTokens.r16),
                borderSide: BorderSide.none,
              ),
              suffixIcon: suffix,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderButtons extends HookConsumerWidget {
  final String? returnTo;
  const _ProviderButtons({this.returnTo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // After Apple Sign In returns from the web redirect, the auth state
    // stream emits a new user. We listen for that and route accordingly.
    // On iOS / Android the auth state change happens INSIDE the sign-in
    // future, so this listener is mostly a safety net for the web case.
    ref.listen<AsyncValue<HealUser?>>(
      authStateProvider,
      (prev, next) {
        final user = next.valueOrNull;
        if (user == null || !user.isSignedIn) return;
        if (returnTo != null && context.mounted) {
          context.go(returnTo!);
        } else if (context.mounted) {
          context.pop();
        }
      },
    );

    final busy = useState(false);
    final errorText = useState<String?>(null);
    final showApple = AuthService.appleSignInAvailable;

    Future<void> withBusy(Future<void> Function() fn) async {
      errorText.value = null;
      busy.value = true;
      try {
        await fn();
        if (returnTo != null && context.mounted) {
          context.go(returnTo!);
        } else if (context.mounted) {
          context.pop();
        }
      } catch (e) {
        if (kDebugMode) print('Provider auth error: $e');
        errorText.value = _friendly(e);
      } finally {
        busy.value = false;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorText.value != null) ...[
          _ErrorText(errorText.value!),
          const SizedBox(height: HealTokens.s12),
        ],
        _ProviderButton(
          label: 'Continue with Google',
          icon: Icons.g_mobiledata_rounded,
          onTap: busy.value
              ? null
              : () => withBusy(() async {
                    final user =
                        await ref.read(authServiceProvider).signInWithGoogle();
                    if (user == null) {
                      throw const _CancelledByUser();
                    }
                  }),
        ),
        if (showApple) ...[
          const SizedBox(height: HealTokens.s8),
          _ProviderButton(
            label: 'Continue with Apple',
            icon: Icons.apple_rounded,
            onTap: busy.value
                ? null
                : () => withBusy(() async {
                    final user =
                        await ref.read(authServiceProvider).signInWithApple();
                    // signInWithApple() returns null in two cases:
                    //   1. User cancelled the dialog (mobile only).
                    //   2. We're on web and signInWithRedirect kicked off —
                    //      the page will navigate; authStateProvider will
                    //      emit the new user when it returns.
                    // In case 2, we should NOT navigate away here.
                    if (user == null) {
                      if (kIsWeb) {
                        // Don't pop, don't show error. The redirect will
                        // navigate the page; authStateProvider takes over.
                        return;
                      }
                      throw const _CancelledByUser();
                    }
                  }),
          ),
        ],
      ],
    );
  }
}

class _ProviderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const _ProviderButton({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: HealTokens.s12),
        decoration: BoxDecoration(
          color: HealTokens.rosewood.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(HealTokens.r16),
          border: Border.all(
            color: HealTokens.cream.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: HealTokens.cream, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: HealTokens.cream, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: HealTokens.cream.withValues(alpha: 0.15)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: TextStyle(
              color: HealTokens.cream.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: HealTokens.cream.withValues(alpha: 0.15)),
        ),
      ],
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String text;
  const _ErrorText(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HealTokens.rosewoodLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(HealTokens.r16),
        border: Border(
          left: BorderSide(color: HealTokens.brass.withValues(alpha: 0.7), width: 3),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: HealTokens.cream,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }
}

class _InfoText extends StatelessWidget {
  final String text;
  const _InfoText(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HealTokens.rosewoodLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(HealTokens.r16),
        border: const Border(
          left: BorderSide(color: HealTokens.brass, width: 3),
        ),
      ),
      child: Text(text, style: const TextStyle(color: HealTokens.cream, fontSize: 13)),
    );
  }
}

// ──────────────────────────  Friendly error copy  ──────────────────────────

class _CancelledByUser implements Exception {
  const _CancelledByUser();
  @override
  String toString() => 'cancelled';
}

String _friendly(Object e) {
  final s = e.toString().toLowerCase();
  if (e is _CancelledByUser) return '';
  if (s.contains('user-not-found') || s.contains('wrong-password') ||
      s.contains('invalid-credential') || s.contains('invalid-login-credentials')) {
    return "I couldn't find that email and password together. Try again, or use 'Reset' to set a new password.";
  }
  if (s.contains('email-already-in-use')) {
    return "That email is already in use. Try signing in instead.";
  }
  if (s.contains('weak-password')) {
    return "Your password needs to be at least 6 characters.";
  }
  if (s.contains('invalid-email')) {
    return "That email doesn't look quite right.";
  }
  if (s.contains('network') || s.contains('socket') || s.contains('timeout')) {
    return "I can't reach the internet right now. Try again in a moment.";
  }
  if (s.contains('too-many-requests')) {
    return "Too many attempts. Take a breath, then try again in a few minutes.";
  }
  if (s.contains('sign_in_canceled') || s.contains('cancelled') || s.contains('canceled')) {
    return '';
  }
  return "Something gentle went wrong. Please try again.";
}
