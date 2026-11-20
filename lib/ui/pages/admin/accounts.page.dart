import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/user.dto.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/account.exception.dart';
import 'package:lecoteaufleuri/infrastructure/providers/accounts.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/admin/account_edit.page.dart';
import 'package:lecoteaufleuri/ui/pages/admin/account_error_message.dart';
import 'package:lecoteaufleuri/ui/shell/app_shell.dart';
import 'package:lecoteaufleuri/ui/widgets/phone_display.dart';

/// Les comptes de l'association, pour un admin : recherche, création, et
/// accès à la fiche de chacun.
class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key});

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _open(UserDto? account) async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => AccountEditPage(account: account)),
    );
    if (message != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  bool _matches(UserDto account) {
    final search = _search.trim().toLowerCase();
    if (search.isEmpty) return true;
    final digits = search.replaceAll(RegExp(r'\D'), '');
    return account.fullName.toLowerCase().contains(search) ||
        (digits.isNotEmpty &&
            displayPhone(
              account.phoneNumber,
            ).replaceAll(' ', '').contains(digits));
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsControllerProvider);
    final value = accounts.value;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: shellShowsBack(context),
        title: const Text('Comptes'),
      ),
      floatingActionButton: value == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('newAccountButton'),
              onPressed: () => _open(null),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Nouveau compte'),
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: switch ((value, accounts.error)) {
            (final List<UserDto> list, _) => _list(list.where(_matches)),
            (_, final Object error) => _ErrorView(
              message: accountErrorMessage(
                error is AccountException
                    ? error.code
                    : AccountErrorCode.unknown,
              ),
              onRetry: () => ref.invalidate(accountsControllerProvider),
            ),
            _ => const CircularProgressIndicator(),
          },
        ),
      ),
    );
  }

  Widget _list(Iterable<UserDto> accounts) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        TextField(
          key: const Key('accountSearchField'),
          controller: _searchController,
          onChanged: (value) => setState(() => _search = value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Nom ou numéro',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        if (accounts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Aucun compte ne correspond.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final account in accounts)
          ListTile(
            key: Key('account-${account.id}'),
            leading: CircleAvatar(
              child: Text(
                account.firstName.isEmpty ? '?' : account.firstName[0],
              ),
            ),
            title: Text(account.fullName),
            subtitle: Text(displayPhone(account.phoneNumber)),
            trailing: account.isAdmin
                ? Chip(
                    label: const Text('Admin'),
                    avatar: const Icon(Icons.shield_outlined, size: 18),
                    visualDensity: VisualDensity.compact,
                  )
                : null,
            onTap: () => _open(account),
          ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            key: const Key('accountsError'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
