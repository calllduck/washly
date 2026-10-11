import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_store.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_address.dart';
import '../../services/address_service.dart';
import '../../theme/app_theme.dart';

class AddressFormScreen extends StatefulWidget {
  final UserAddress? address;

  const AddressFormScreen({super.key, this.address});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _addressService = AddressService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _labelCtrl;
  late final TextEditingController _receiverCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _fullAddressCtrl;
  late final TextEditingController _notesCtrl;
  late bool _isDefault;
  bool _saving = false;

  final List<String> _quickLabels = ['Rumah', 'Kantor', 'Kost'];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthStore>().currentUser;
    final a = widget.address;

    _labelCtrl = TextEditingController(text: a?.label ?? 'Rumah');
    _receiverCtrl =
        TextEditingController(text: a?.receiverName ?? user?.name ?? '');
    _phoneCtrl = TextEditingController(text: a?.phone ?? user?.phone ?? '');
    _fullAddressCtrl = TextEditingController(text: a?.fullAddress ?? '');
    _notesCtrl = TextEditingController(text: a?.notes ?? '');
    _isDefault = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _receiverCtrl.dispose();
    _phoneCtrl.dispose();
    _fullAddressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);

    setState(() => _saving = true);
    try {
      final UserAddress result;
      if (widget.address == null) {
        result = await _addressService.createAddress(
          label: _labelCtrl.text.trim(),
          receiverName: _receiverCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          fullAddress: _fullAddressCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
          isDefault: _isDefault,
        );
      } else {
        result = await _addressService.updateAddress(
          id: widget.address!.id,
          label: _labelCtrl.text.trim(),
          receiverName: _receiverCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          fullAddress: _fullAddressCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
          isDefault: _isDefault,
        );
      }

      if (!mounted) return;
      _toast(l10n.addressSaveSuccess);
      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.address != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l10n.addressEditTitle : l10n.addressAddTitle),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Text(l10n.addressLabel, style: AppTypography.subheading),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: _quickLabels.map((tag) {
                  final selected = _labelCtrl.text.trim().toLowerCase() ==
                      tag.toLowerCase();
                  return ChoiceChip(
                    label: Text(tag),
                    selected: selected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color:
                          selected ? AppColors.primary : AppColors.border,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() => _labelCtrl.text = tag);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _labelCtrl,
                decoration: InputDecoration(
                  labelText: l10n.addressLabel,
                  hintText: l10n.addressLabelHint,
                  prefixIcon: const Icon(Icons.bookmark_outline,
                      color: AppColors.textSecondary),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.addressLabelHint
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),

              TextFormField(
                controller: _receiverCtrl,
                decoration: InputDecoration(
                  labelText: l10n.addressReceiver,
                  prefixIcon: const Icon(Icons.person_outline,
                      color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.addressPhone,
                  prefixIcon: const Icon(Icons.phone_outlined,
                      color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              TextFormField(
                controller: _fullAddressCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.addressFull,
                  hintText: l10n.addressFullHint,
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.location_on_outlined,
                        color: AppColors.textSecondary),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.addressFullHint
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),

              TextFormField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  labelText: l10n.addressNotes,
                  hintText: l10n.addressNotesHint,
                  prefixIcon: const Icon(Icons.notes_outlined,
                      color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: SwitchListTile(
                  title: Text(l10n.addressSetDefault,
                      style: AppTypography.body
                          .copyWith(fontWeight: FontWeight.w600)),
                  value: _isDefault,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() => _isDefault = val);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        l10n.commonSave,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
