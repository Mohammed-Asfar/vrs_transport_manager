import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:vrs_transport_manager/core/theme/app_colors.dart';
import 'package:vrs_transport_manager/core/theme/app_text_styles.dart';
import 'package:vrs_transport_manager/core/widgets/app_text_field.dart';
import 'package:vrs_transport_manager/core/widgets/loading_overlay.dart';
import 'package:vrs_transport_manager/features/settings/domain/entities/company_profile.dart';
import 'package:vrs_transport_manager/features/settings/presentation/bloc/company_profile_bloc.dart';
import 'package:vrs_transport_manager/features/settings/presentation/bloc/company_profile_event.dart';
import 'package:vrs_transport_manager/features/settings/presentation/bloc/company_profile_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _companyNameController;
  late TextEditingController _gstinController;
  late TextEditingController _phone1Controller;
  late TextEditingController _phone2Controller;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _taglineController;
  late TextEditingController _bankNameController;
  late TextEditingController _bankBranchController;
  late TextEditingController _accountNoController;
  late TextEditingController _ifscCodeController;

  String? _logoBase64;
  String? _signatureBase64;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController();
    _gstinController = TextEditingController();
    _phone1Controller = TextEditingController();
    _phone2Controller = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _taglineController = TextEditingController();
    _bankNameController = TextEditingController();
    _bankBranchController = TextEditingController();
    _accountNoController = TextEditingController();
    _ifscCodeController = TextEditingController();

    context.read<CompanyProfileBloc>().add(const CompanyProfileLoad());
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _gstinController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _taglineController.dispose();
    _bankNameController.dispose();
    _bankBranchController.dispose();
    _accountNoController.dispose();
    _ifscCodeController.dispose();
    super.dispose();
  }

  void _populateFields(CompanyProfile profile) {
    if (_initialized) return;
    _initialized = true;
    _companyNameController.text = profile.companyName;
    _gstinController.text = profile.gstin;
    _phone1Controller.text = profile.phone1;
    _phone2Controller.text = profile.phone2;
    _emailController.text = profile.email;
    _addressController.text = profile.address;
    _taglineController.text = profile.tagline;
    _bankNameController.text = profile.bankName;
    _bankBranchController.text = profile.bankBranch;
    _accountNoController.text = profile.accountNo;
    _ifscCodeController.text = profile.ifscCode;
    _logoBase64 = profile.logoBase64;
    _signatureBase64 = profile.signatureBase64;
  }

  CompanyProfile _buildProfile() {
    return CompanyProfile(
      companyName: _companyNameController.text.trim(),
      gstin: _gstinController.text.trim(),
      phone1: _phone1Controller.text.trim(),
      phone2: _phone2Controller.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      tagline: _taglineController.text.trim(),
      bankName: _bankNameController.text.trim(),
      bankBranch: _bankBranchController.text.trim(),
      accountNo: _accountNoController.text.trim(),
      ifscCode: _ifscCodeController.text.trim(),
      logoBase64: _logoBase64,
      signatureBase64: _signatureBase64,
    );
  }

  void _onSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context
        .read<CompanyProfileBloc>()
        .add(CompanyProfileSave(_buildProfile()));
  }

  Future<void> _pickImage({required bool isLogo}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final file = File(result.files.single.path!);
    final bytes = await file.readAsBytes();
    final compressed = _compressImage(bytes);
    final base64Str = base64Encode(compressed);

    setState(() {
      if (isLogo) {
        _logoBase64 = base64Str;
      } else {
        _signatureBase64 = base64Str;
      }
    });
  }

  Uint8List _compressImage(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    // Resize to max 300x300 maintaining aspect ratio
    final resized = img.copyResize(
      decoded,
      width: decoded.width > 300 ? 300 : decoded.width,
      height: decoded.height > 300 ? 300 : decoded.height,
      maintainAspect: true,
    );

    // Encode as JPEG at 80% quality
    return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CompanyProfileBloc, CompanyProfileState>(
      listener: (context, state) {
        if (state is CompanyProfileLoaded) {
          _populateFields(state.profile);
        }
        if (state is CompanyProfileSaved) {
          _initialized = false;
          _populateFields(state.profile);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Company profile saved'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        if (state is CompanyProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) => LoadingOverlay(
        isLoading: state is CompanyProfileLoading,
        message: 'Loading profile...',
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              _buildToolbar(),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCompanySection(),
                        const SizedBox(height: 20),
                        _buildBankSection(),
                        const SizedBox(height: 20),
                        _buildImagesSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppColors.toolbar,
        border: Border(
          bottom: BorderSide(color: AppColors.separator, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.settings_outlined, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Text('Company Settings', style: AppTextStyles.heading3),
          const Spacer(),
          SizedBox(
            height: 28,
            child: ElevatedButton.icon(
              onPressed: _onSave,
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: AppTextStyles.button,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanySection() {
    return _SettingsSection(
      title: 'Company Information',
      child: Column(
        children: [
          AppTextField(
            controller: _companyNameController,
            label: 'Company Name',
            prefixIcon: Icons.business_outlined,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Company name is required' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _gstinController,
                  label: 'GSTIN',
                  prefixIcon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  prefixIcon: Icons.email_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _phone1Controller,
                  label: 'Phone 1',
                  prefixIcon: Icons.phone_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  controller: _phone2Controller,
                  label: 'Phone 2',
                  prefixIcon: Icons.phone_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _addressController,
            label: 'Address',
            prefixIcon: Icons.location_on_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _taglineController,
            label: 'Tagline',
            prefixIcon: Icons.short_text_outlined,
            hint: 'e.g. Solution for Electrical, Instrumentation...',
          ),
        ],
      ),
    );
  }

  Widget _buildBankSection() {
    return _SettingsSection(
      title: 'Bank Details',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _bankNameController,
                  label: 'Bank Name',
                  prefixIcon: Icons.account_balance_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  controller: _bankBranchController,
                  label: 'Branch',
                  prefixIcon: Icons.location_city_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _accountNoController,
                  label: 'Account Number',
                  prefixIcon: Icons.numbers_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  controller: _ifscCodeController,
                  label: 'IFSC Code',
                  prefixIcon: Icons.code_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    return _SettingsSection(
      title: 'Logo & Signature',
      child: Row(
        children: [
          Expanded(
            child: _ImageUploadCard(
              label: 'Company Logo',
              base64Data: _logoBase64,
              onPick: () => _pickImage(isLogo: true),
              onRemove: () => setState(() => _logoBase64 = null),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _ImageUploadCard(
              label: 'Signature',
              base64Data: _signatureBase64,
              onPick: () => _pickImage(isLogo: false),
              onRemove: () => setState(() => _signatureBase64 = null),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageUploadCard extends StatelessWidget {
  final String label;
  final String? base64Data;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ImageUploadCard({
    required this.label,
    required this.base64Data,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = base64Data != null && base64Data!.isNotEmpty;

    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.separator, width: 0.5),
      ),
      child: hasImage
          ? Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.memory(
                      base64Decode(base64Data!),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _iconButton(Icons.refresh_rounded, onPick),
                      const SizedBox(width: 4),
                      _iconButton(Icons.close_rounded, onRemove),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 6,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      label,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textTertiary),
                    ),
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_upload_outlined,
                      size: 32, color: AppColors.textTertiary),
                  const SizedBox(height: 8),
                  Text(label, style: AppTextStyles.subtitle),
                  const SizedBox(height: 4),
                  Text(
                    'Click to upload',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 14,
        icon: Icon(icon, color: AppColors.textSecondary),
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surface.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.separator, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Text(title, style: AppTextStyles.heading3),
          ),
          const Divider(height: 0.5),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}
