import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_address.dart';
import '../../services/address_service.dart';
import '../../theme/app_theme.dart';
import 'address_form_screen.dart';

class AddressListScreen extends StatefulWidget {
  final bool isSelecting;
  final int? selectedId;

  const AddressListScreen({
    super.key,
    this.isSelecting = false,
    this.selectedId,
  });

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  final _addressService = AddressService();
  List<UserAddress> _addresses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _addressService.getAddresses();
      if (!mounted) return;
      setState(() {
        _addresses = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _setDefault(UserAddress address) async {
    try {
      await _addressService.setDefaultAddress(address.id);
      await _loadAddresses();
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  Future<void> _delete(UserAddress address) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.commonDelete),
        content: Text(l10n.addressDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonDelete,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _addressService.deleteAddress(address.id);
        await _loadAddresses();
      } catch (e) {
        if (!mounted) return;
        _toast(e.toString().replaceFirst('Exception: ', ''), error: true);
      }
    }
  }

  Future<void> _openForm([UserAddress? address]) async {
    final res = await Navigator.push<UserAddress>(
      context,
      MaterialPageRoute(builder: (_) => AddressFormScreen(address: address)),
    );
    if (res != null) {
      if (widget.isSelecting && mounted) {
        Navigator.pop(context, res);
      } else {
        _loadAddresses();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelecting
            ? l10n.checkoutSelectAddress
            : l10n.addressListTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: l10n.addressAddTitle,
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: _buildBody(l10n),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          l10n.addressAddTitle,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: _loadAddresses,
                child: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
      );
    }

    if (_addresses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_outlined,
                  size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.addressEmpty,
                style: AppTypography.heading2
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
                label: Text(l10n.addressAddTitle),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAddresses,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 100),
        itemCount: _addresses.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (ctx, i) {
          final addr = _addresses[i];
          final isSelected = widget.isSelecting && widget.selectedId == addr.id;

          return _buildAddressCard(addr, isSelected, l10n);
        },
      ),
    );
  }

  Widget _buildAddressCard(
      UserAddress addr, bool isSelected, AppLocalizations l10n) {
    return InkWell(
      onTap: widget.isSelecting ? () => Navigator.pop(context, addr) : null,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  addr.label.toLowerCase() == 'kantor'
                      ? Icons.business_outlined
                      : addr.label.toLowerCase() == 'kost'
                          ? Icons.apartment_outlined
                          : Icons.home_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  addr.label,
                  style: AppTypography.subheading
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (addr.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      l10n.addressDefaultBadge,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const Spacer(),
                if (widget.isSelecting)
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            if (addr.receiverName != null && addr.receiverName!.isNotEmpty)
              Text(
                '${addr.receiverName}${addr.phone != null && addr.phone!.isNotEmpty ? ' (${addr.phone})' : ''}',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

            const SizedBox(height: 2),
            Text(
              addr.fullAddress,
              style: AppTypography.body
                  .copyWith(color: AppColors.textSecondary),
            ),

            if (addr.notes != null && addr.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      addr.notes!,
                      style: AppTypography.caption.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const Divider(height: AppSpacing.xl, color: AppColors.border),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!addr.isDefault && !widget.isSelecting)
                  TextButton(
                    onPressed: () => _setDefault(addr),
                    child: Text(l10n.addressSetDefault),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: l10n.addressEditTitle,
                  color: AppColors.textSecondary,
                  onPressed: () => _openForm(addr),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: l10n.commonDelete,
                  color: AppColors.error,
                  onPressed: () => _delete(addr),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
