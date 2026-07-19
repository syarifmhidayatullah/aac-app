import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../../state/account_state.dart';
import '../../state/communication_state.dart';

/// Layar akun & sinkronisasi (di balik parental gate): login/registrasi,
/// status sync, sinkronisasi manual, impor papan dari kode, logout.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  void initState() {
    super.initState();
    // Verifikasi terjadi di luar app (klik link email) — sinkronkan
    // status lokal tiap kali layar akun dibuka.
    context.read<AccountState>().refreshVerificationStatus();
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Akun & Sinkronisasi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            account.loggedIn ? const _AccountPanel() : const _AuthForm(),
            const SizedBox(height: 32),
            // Atribusi wajib lisensi CC BY-SA.
            Text(
              'Simbol: Mulberry Symbols © Steve Lee & Garry Paxton, '
              'lisensi CC BY-SA 2.0 UK (mulberrysymbols.org).',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ login form

class _AuthForm extends StatefulWidget {
  const _AuthForm();

  @override
  State<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<_AuthForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  late final TextEditingController _serverController;
  final _googleSignIn = GoogleSignIn(scopes: ['email']);
  bool _register = false;
  bool _showServer = false;
  bool _googleBusy = false;

  @override
  void initState() {
    super.initState();
    _serverController =
        TextEditingController(text: context.read<AccountState>().baseUrl);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final account = context.read<AccountState>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;

    final server = _serverController.text.trim();
    if (server.isNotEmpty && server != account.baseUrl) {
      await account.setBaseUrl(server);
    }

    try {
      final newProfileId = await account.signIn(
        email: email,
        password: password,
        register: _register,
        displayName: _nameController.text.trim(),
      );
      if (!mounted) return;
      if (newProfileId != null) {
        // Data lokal diganti data server — pindah ke profile server.
        await context.read<CommunicationState>().switchProfile(newProfileId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Berhasil masuk — data tersinkronisasi.')));
      }
    } catch (_) {
      // Pesan error tampil dari account.lastError.
    }
  }

  Future<void> _signInWithGoogle() async {
    final account = context.read<AccountState>();
    setState(() => _googleBusy = true);
    try {
      final googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) return; // dibatalkan user
      final googleAuth = await googleAccount.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Gagal mengambil token dari Google.')));
        }
        return;
      }

      final newProfileId = await account.signInWithGoogle(idToken);
      if (!mounted) return;
      if (newProfileId != null) {
        await context.read<CommunicationState>().switchProfile(newProfileId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Berhasil masuk dengan Google.')));
      }
    } catch (_) {
      // Pesan error tampil dari account.lastError.
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _register ? 'Buat akun baru' : 'Masuk',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Akun dipakai untuk sinkronisasi antar perangkat dan berbagi '
          'papan. Tanpa akun, aplikasi tetap berfungsi penuh.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        if (_register) ...[
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nama',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            helperText: _register ? 'Minimal 8 karakter' : null,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submit(),
        ),
        if (account.lastError != null) ...[
          const SizedBox(height: 12),
          Text(
            account.lastError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: account.busy ? null : _submit,
          child: account.busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_register ? 'Daftar' : 'Masuk'),
        ),
        TextButton(
          onPressed: () => setState(() => _register = !_register),
          child: Text(_register
              ? 'Sudah punya akun? Masuk'
              : 'Belum punya akun? Daftar'),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('atau', style: Theme.of(context).textTheme.bodySmall),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed:
              (account.busy || _googleBusy) ? null : _signInWithGoogle,
          icon: _googleBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.login),
          label: const Text('Masuk dengan Google'),
        ),
        const Divider(height: 32),
        TextButton.icon(
          onPressed: () => setState(() => _showServer = !_showServer),
          icon: Icon(_showServer ? Icons.expand_less : Icons.expand_more),
          label: const Text('Pengaturan server'),
        ),
        if (_showServer)
          TextField(
            controller: _serverController,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Alamat server',
              hintText: 'https://aac-app.up.railway.app',
              border: OutlineInputBorder(),
            ),
          ),
      ],
    );
  }
}

// --------------------------------------------------------- account panel

class _AccountPanel extends StatelessWidget {
  const _AccountPanel();

  Future<void> _importBoard(BuildContext context) async {
    final account = context.read<AccountState>();
    final comm = context.read<CommunicationState>();
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Impor papan'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Kode berbagi (8 karakter)',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Impor'),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = code?.trim() ?? '';
    if (trimmed.isEmpty || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await account.importBoard(trimmed.toUpperCase());
      await comm.reload();
      messenger.showSnackBar(const SnackBar(
          content: Text('Papan berhasil diimpor — lihat di mode edit.')));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(AccountState.friendlyError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountState>();
    final lastSync = account.lastSync;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.account_circle_outlined, size: 40),
            title: Text(account.displayName?.isNotEmpty == true
                ? account.displayName!
                : (account.email ?? '')),
            subtitle: Text(account.email ?? ''),
          ),
        ),
        if (!account.isVerified) ...[
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email belum diverifikasi',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Cek inbox kamu untuk link verifikasi. Berbagi papan '
                    'butuh email terverifikasi.',
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: account.busy
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await account.resendVerification();
                            if (account.lastError == null) {
                              messenger.showSnackBar(const SnackBar(
                                  content:
                                      Text('Email verifikasi dikirim ulang.')));
                            }
                          },
                    child: const Text('Kirim ulang email verifikasi'),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.sync),
          title: const Text('Sinkronisasi terakhir'),
          subtitle: Text(lastSync == null
              ? 'Belum pernah'
              : '${lastSync.toLocal()}'.split('.').first),
        ),
        if (account.lastError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              account.lastError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: account.busy
              ? null
              : () async {
                  final comm = context.read<CommunicationState>();
                  final ok = await account.syncNow();
                  if (ok) await comm.reload();
                },
          icon: account.busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.sync),
          label: const Text('Sinkronkan sekarang'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: account.busy ? null : () => _importBoard(context),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Impor papan dengan kode'),
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: account.busy
              ? null
              : () => context.read<AccountState>().logout(),
          icon: const Icon(Icons.logout),
          label: const Text('Keluar (data lokal tetap ada)'),
        ),
      ],
    );
  }
}
