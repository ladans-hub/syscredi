import 'package:flutter/material.dart' hide Icons;
import '../../../app/theme/fluent_icons_compat.dart';
import 'package:syscredi/core/widgets/equal_button_group.dart';
import 'package:syscredi/core/widgets/operation_feedback.dart';
import 'package:syscredi/core/widgets/activation_contact_card.dart';

import '../../../app/theme/app_theme.dart';

const _loginNavy = navy;
const _loginGreen = green;

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({required this.updatePassword, super.key});
  final Future<void> Function(String password) updatePassword;

  @override
  State<PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  final form = GlobalKey<FormState>();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  bool busy = false;
  bool showPassword = false;

  @override
  void dispose() {
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await widget.updatePassword(password.text);
      if (mounted) {
        await showFeedbackDialog(
          context,
          title: 'Palavra-passe atualizada',
          message: 'A sua palavra-passe foi alterada. Entre novamente.',
          kind: FeedbackKind.success,
        );
      }
    } catch (error) {
      if (mounted) {
        await showFeedbackDialog(
          context,
          title: 'Não foi possível atualizar',
          message: feedbackMessage(error),
          kind: FeedbackKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 48,
                      color: _loginGreen,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Definir nova palavra-passe',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Escolha uma palavra-passe segura para continuar.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: password,
                      autofocus: true,
                      obscureText: !showPassword,
                      decoration: InputDecoration(
                        labelText: 'Nova palavra-passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => showPassword = !showPassword),
                          icon: Icon(
                            showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().length < 8
                          ? 'Utilize pelo menos 8 caracteres.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: confirmation,
                      obscureText: !showPassword,
                      onFieldSubmitted: (_) => submit(),
                      decoration: const InputDecoration(
                        labelText: 'Confirmar palavra-passe',
                        prefixIcon: Icon(Icons.verified_user_outlined),
                      ),
                      validator: (value) => value != password.text
                          ? 'As palavras-passe não coincidem.'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: busy ? null : submit,
                        icon: busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          busy ? 'A atualizar…' : 'Guardar nova palavra-passe',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({
    required this.onAuthenticated,
    this.login,
    this.recoverPassword,
    this.register,
    this.onGuest,
    this.showActivationContact = false,
    super.key,
  });
  final ValueChanged<Object?>? onAuthenticated;
  final Future<void> Function(String email, String password)? login;
  final Future<void> Function(String email)? recoverPassword;
  final VoidCallback? onGuest;
  final bool showActivationContact;
  final Future<void> Function(
    String name,
    String email,
    String password,
    String organizationName,
  )?
  register;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false, showPassword = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate() || widget.login == null) return;
    setState(() => busy = true);
    try {
      await widget.login!(email.text.trim(), password.text);
    } catch (e) {
      if (mounted) {
        await showFeedbackDialog(
          context,
          title: 'Não foi possível entrar',
          message: feedbackMessage(e),
          kind: FeedbackKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> createFirstUser() async {
    final name = TextEditingController(),
        organization = TextEditingController(),
        newEmail = TextEditingController(text: email.text),
        newPassword = TextEditingController(),
        confirmPassword = TextEditingController();
    final userForm = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: _popupTitle(
          Icons.person_add_outlined,
          'Criar acesso',
          'Configure o primeiro utilizador da instituição.',
        ),
        content: SizedBox(
          width: 450,
          child: Form(
            key: userForm,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      c,
                    ).colorScheme.primary.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: _loginGreen,
                        size: 19,
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Este acesso pode ser utilizado mesmo quando a ligação estiver indisponível.',
                          style: TextStyle(fontSize: 12, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: name,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v == null || v.trim().length < 3
                      ? 'Indique o nome completo.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: organization,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome da instituição',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  validator: (v) => v == null || v.trim().length < 2
                      ? 'Indique o nome da instituição.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: newEmail,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email profissional',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Indique um email válido.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: newPassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Palavra-passe',
                    helperText: 'Use pelo menos 8 caracteres.',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) => v == null || v.length < 8
                      ? 'A palavra-passe deve ter pelo menos 8 caracteres.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: confirmPassword,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar palavra-passe',
                    prefixIcon: Icon(Icons.verified_outlined),
                  ),
                  validator: (v) => v != newPassword.text
                      ? 'As palavras-passe devem coincidir.'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          EqualButtonGroup(
            alignment: WrapAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (userForm.currentState!.validate()) {
                    Navigator.pop(c, true);
                  }
                },
                child: const Text('Criar utilizador'),
              ),
            ],
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    if (widget.register != null) {
      setState(() => busy = true);
      try {
        await widget.register!(
          name.text.trim(),
          newEmail.text.trim(),
          newPassword.text,
          organization.text.trim(),
        );
        if (mounted) {
          await showFeedbackDialog(
            context,
            title: 'Acesso criado',
            message: 'Acesso criado. Já pode entrar.',
            kind: FeedbackKind.success,
          );
        }
      } catch (e) {
        if (mounted) {
          await showFeedbackDialog(
            context,
            title: 'Não foi possível criar o acesso',
            message: feedbackMessage(e),
            kind: FeedbackKind.error,
          );
        }
      } finally {
        if (mounted) setState(() => busy = false);
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    body: LayoutBuilder(
      builder: (context, size) {
        final compact = size.maxWidth < 820;
        final content = _formContent(context);
        if (compact) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                AppAssets.authBackground,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
              Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xD90B1624)
                    : const Color(0xB8152739),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: size.maxWidth - 40,
                      child: Card(
                        elevation: 18,
                        shadowColor: Colors.black.withValues(alpha: .22),
                        surfaceTintColor: Theme.of(context).colorScheme.primary,
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: content,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(flex: 5, child: _brandPanel()),
            Expanded(
              flex: 6,
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 56,
                      vertical: 42,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: content,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _brandPanel() => Container(
    color: _loginNavy,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AppAssets.authBackground,
          fit: BoxFit.cover,
          // Keep the photographic subject visible when the panel is narrower
          // than the source image; cover preserves the original aspect ratio.
          alignment: Alignment.centerLeft,
          filterQuality: FilterQuality.high,
        ),
        Positioned(
          top: -120,
          right: -90,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: .10),
                width: 38,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 80,
          left: -100,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _loginGreen.withValues(alpha: .10),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                brandVisuals.value.heroGradientStart.withValues(alpha: .85),
                brandVisuals.value.heroGradientEnd.withValues(alpha: .48),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(54),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const BrandLogo(size: 38, fallbackColor: _loginGreen),
                    const SizedBox(width: 12),
                    Text(
                      'Syscredi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'MICROCRÉDITO  /  MOÇAMBIQUE',
                  style: TextStyle(
                    color: Color(0xFFB8CADA),
                    fontSize: 10,
                    letterSpacing: 1.8,
                  ),
                ),
                const Spacer(),
                Text(
                  'Crédito que faz\ncrescer possibilidades.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 39,
                    height: 1.12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Uma operação mais clara para cada cliente, cada prestação e cada decisão.',
                  style: TextStyle(
                    color: Color(0xFFCAD7E1),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 30),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _LoginPill(Icons.lock_outline, 'Dados seguros'),
                    _LoginPill(Icons.bolt_outlined, 'Acesso resiliente'),
                    _LoginPill(Icons.payments_outlined, 'MZN'),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_outlined,
                        color: Color(0xFFB8DCC7),
                        size: 17,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Uma visão mais clara para decisões melhores.',
                          style: TextStyle(
                            color: Color(0xFFD5E2EB),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '“Acreditamos no potencial de cada história.”',
                  style: TextStyle(
                    color: Color(0xFFB8DCC7),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  Widget _formContent(BuildContext context) => Form(
    key: form,
    child: Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (MediaQuery.sizeOf(context).width < 820) ...[
          Row(
            children: [
              const BrandLogo(size: 30),
              SizedBox(width: 9),
              Text(
                'Syscredi',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 42),
        ],
        Text(
          'Bem-vindo de volta',
          style: TextStyle(
            color: null,
            fontSize: 29,
            fontWeight: FontWeight.w800,
            letterSpacing: -.7,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Entre no seu espaço de gestão de crédito.',
          style: TextStyle(color: null, fontSize: 14),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: email,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Email profissional',
            hintText: 'nome@instituicao.co.mz',
            prefixIcon: Icon(Icons.alternate_email),
          ),
          validator: (v) =>
              v == null || !v.contains('@') ? 'Indique um email válido.' : null,
        ),
        TextFormField(
          controller: password,
          obscureText: !showPassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => submit(),
          decoration: InputDecoration(
            labelText: 'Palavra-passe',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: showPassword
                  ? 'Ocultar palavra-passe'
                  : 'Mostrar palavra-passe',
              onPressed: () => setState(() => showPassword = !showPassword),
              icon: Icon(
                showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          validator: (v) =>
              v == null || v.isEmpty ? 'Indique a sua palavra-passe.' : null,
        ),
        if (widget.recoverPassword != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: busy ? null : recoverPassword,
              child: const Text('Esqueci a palavra-passe'),
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: busy || widget.login == null ? null : submit,
            icon: busy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.login, size: 18),
            label: Text(busy ? 'A validar…' : 'Entrar'),
          ),
        ),
        if (widget.onGuest != null)
          Center(
            child: TextButton.icon(
              onPressed: busy ? null : widget.onGuest,
              icon: const Icon(Icons.visibility_outlined, size: 17),
              label: const Text('Explorar como visitante'),
            ),
          ),
        const SizedBox(height: 8),
        if (widget.register != null)
          Center(
            child: TextButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      if (widget.register != null) {
                        try {
                          await createFirstUser();
                        } catch (e) {
                          if (context.mounted) {
                            await showFeedbackDialog(
                              context,
                              title: 'Não foi possível criar o acesso',
                              message: feedbackMessage(e),
                              kind: FeedbackKind.error,
                            );
                          }
                        }
                        return;
                      }
                      if (mounted) {
                        await showFeedbackDialog(
                          context,
                          message:
                              'O cadastro remoto não está disponível nesta sessão.',
                          kind: FeedbackKind.info,
                        );
                      }
                    },
              icon: const Icon(Icons.person_add_alt_1, size: 17),
              label: const Text('Criar primeiro utilizador'),
            ),
          ),
        if (widget.showActivationContact) ...[
          const SizedBox(height: 12),
          const ActivationContactCard(compact: true),
        ],
        const SizedBox(height: 42),
        const Center(
          child: Text(
            'Syscredi • Gestão de crédito em Moçambique',
            style: TextStyle(fontSize: 11),
          ),
        ),
      ],
    ),
  );

  Future<void> recoverPassword() async {
    final value = email.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
      await showFeedbackDialog(
        context,
        message: 'Indique primeiro um email válido.',
        kind: FeedbackKind.info,
      );
      return;
    }
    setState(() => busy = true);
    try {
      await widget.recoverPassword!(value);
      if (mounted) {
        await showFeedbackDialog(
          context,
          title: 'Verifique o seu email',
          message: 'Enviámos as instruções de recuperação para o seu email.',
          kind: FeedbackKind.info,
        );
      }
    } catch (e) {
      if (mounted) {
        await showFeedbackDialog(
          context,
          title: 'Não foi possível recuperar o acesso',
          message: feedbackMessage(e),
          kind: FeedbackKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class _LoginPill extends StatelessWidget {
  const _LoginPill(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFB8DCC7), size: 15),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(color: const Color(0xFFD5E2EB), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

Widget _popupTitle(IconData icon, String title, String subtitle) => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: _loginGreen.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: _loginGreen),
    ),
    const SizedBox(width: 13),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.blueGrey,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    ),
  ],
);
