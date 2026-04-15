import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cover/core/theme/app_theme.dart';
import 'package:cover/presentation/screens/vault/vault_shell_screen.dart';
import 'package:cover/presentation/screens/vault/password/create_password_screen.dart';
import 'package:cover/presentation/screens/vault/contact/create_contact_screen.dart';
import 'package:cover/core/di/di_container.dart';

class VaultOverviewTab extends ConsumerStatefulWidget {
  const VaultOverviewTab({super.key});

  @override
  ConsumerState<VaultOverviewTab> createState() => _VaultOverviewTabState();
}

class _VaultOverviewTabState extends ConsumerState<VaultOverviewTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final vaultStatsAsync = ref.watch(vaultStatsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: vaultStatsAsync.when(
        data: (stats) => ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatCard(
              'Total Items',
              stats.totalItems.toString(),
              CupertinoIcons.grid,
              AppTheme.systemOrange,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Storage Used',
              _formatStorage(stats.storageUsed),
              CupertinoIcons.folder,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Vaults',
              stats.vaultCount.toString(),
              CupertinoIcons.lock,
              Colors.green,
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8, top: 24),
              child: Text(
                'CATEGORIES',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0x99FFFFFF), // secondaryLabel
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildCategoryCard(
              'Photos & Videos',
              '${stats.photosCount} items',
              CupertinoIcons.photo,
              const Color(0xFF30D158),
              () => _navigateToTab(VaultTab.gallery),
            ),
            const SizedBox(height: 12),
            _buildCategoryCard(
              'Files',
              '${stats.filesCount} items',
              CupertinoIcons.folder_fill,
              const Color(0xFF0A84FF),
              () => _navigateToTab(VaultTab.files),
            ),
            const SizedBox(height: 12),
            _buildCategoryCard(
              'Notes',
              '${stats.notesCount} items',
              CupertinoIcons.doc_fill,
              const Color(0xFFFFD60A),
              () => _navigateToTab(VaultTab.notes),
            ),
            const SizedBox(height: 12),
            _buildCategoryCard(
              'Passwords',
              '${stats.passwordsCount} items',
              CupertinoIcons.lock_fill,
              const Color(0xFFFF9F0A),
              () => _navigateToTab(VaultTab.passwords),
            ),
            const SizedBox(height: 12),
            _buildCategoryCard(
              'Contacts',
              '${stats.contactsCount} items',
              CupertinoIcons.person_fill,
              const Color(0xFF64D2FF),
              () => _navigateToTab(VaultTab.contacts),
            ),
            const SizedBox(height: 32),
            // Section divider
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Container(
                height: 0.5,
                color: const Color(0x33545458), // separator color
              ),
            ),
            const SizedBox(height: 32),
            _buildQuickActionsSection(),
          ],
        ),
        loading: () => const Center(
          child: CupertinoActivityIndicator(color: AppTheme.systemOrange),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error loading stats: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  void _navigateToTab(VaultTab tab) {
    ref.read(vaultTabStateProvider.notifier).setTab(tab);
  }

  void _navigateToCreateNote() {
    // Navigate to notes tab (note creation will be implemented in notes_tab)
    _navigateToTab(VaultTab.notes);
  }

  void _navigateToCreatePassword() {
    context.push('/vault/password/create');
  }

  void _navigateToCreateContact() {
    context.push('/vault/contact/create');
  }

  String _formatStorage(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8, top: 24),
          child: const Text(
            'QUICK ACTIONS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0x99FFFFFF), // secondaryLabel
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: CupertinoIcons.add,
                label: 'Add Note',
                onTap: _navigateToCreateNote,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: CupertinoIcons.lock_rotation,
                label: 'Password',
                onTap: _navigateToCreatePassword,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: CupertinoIcons.person_add,
                label: 'Contact',
                onTap: _navigateToCreateContact,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E), // secondaryBackground
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15), // semantic color at 15% opacity
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0x99FFFFFF), // secondaryLabel
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF), // label
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E), // secondaryBackground
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15), // semantic color at 15% opacity
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF), // label
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0x99FFFFFF), // secondaryLabel
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_forward,
              color: Color(0x4DFFFFFF), // tertiaryLabel
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.systemOrange.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.systemOrange.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppTheme.systemOrange,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
