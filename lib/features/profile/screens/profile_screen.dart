import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/repositories/user_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  
  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _isEditing = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: isWide ? 500 : screenWidth * 0.9,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(isDark),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Avatar Section
                      _buildAvatarSection(user, isDark),
                      const SizedBox(height: 24),
                      // Profile Info
                      _buildProfileForm(user, isDark),
                      const SizedBox(height: 20),
                      // Account Info (Read Only)
                      _buildAccountInfo(user, isDark),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            _buildActions(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.grey50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(Iconsax.user, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            'My Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (!_isEditing)
            TextButton.icon(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Iconsax.edit, size: 18),
              label: const Text('Edit'),
            ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: isDark ? Colors.white54 : AppColors.grey500),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(User? user, bool isDark) {
    final hasAvatar = user?.avatarUrl != null || _selectedImageBytes != null;
    
    return Stack(
      children: [
        GestureDetector(
          onTap: _isEditing ? _pickImage : null,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 3),
            ),
            child: _isUploadingImage
                ? const CircularProgressIndicator(strokeWidth: 2)
                : ClipOval(
                    child: hasAvatar
                        ? _selectedImageBytes != null
                            ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover, width: 100, height: 100)
                            : Image.network(user!.avatarUrl!, fit: BoxFit.cover, width: 100, height: 100)
                        : Center(
                            child: Text(
                              user?.name.substring(0, 1).toUpperCase() ?? 'U',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                  ),
          ),
        ),
        if (_isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? Colors.grey[800]! : Colors.white, width: 2),
                ),
                child: const Icon(Iconsax.camera, color: Colors.white, size: 18),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileForm(User? user, bool isDark) {
    return Column(
      children: [
        AppTextField(
          label: 'Full Name',
          hint: 'Enter your name',
          controller: _nameController,
          enabled: _isEditing,
          prefixIcon: const Icon(Iconsax.user, size: 20),
          validator: (v) => v?.isEmpty == true ? 'Name is required' : null,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Email',
          hint: 'Enter your email',
          controller: _emailController,
          enabled: false, // Email usually can't be changed
          prefixIcon: const Icon(Iconsax.sms, size: 20),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Phone Number',
          hint: 'Enter phone number',
          controller: _phoneController,
          enabled: _isEditing,
          prefixIcon: const Icon(Iconsax.call, size: 20),
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    );
  }

  Widget _buildAccountInfo(User? user, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Information',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow(Iconsax.security_user, 'Role', user?.roleDisplayName ?? 'Unknown', isDark),
          const SizedBox(height: 8),
          _infoRow(Iconsax.calendar, 'Member Since', _formatDate(user?.createdAt), isDark),
          const SizedBox(height: 8),
          _infoRow(
            user?.isActive == true ? Iconsax.tick_circle : Iconsax.close_circle,
            'Status',
            user?.isActive == true ? 'Active' : 'Inactive',
            isDark,
            valueColor: user?.isActive == true ? AppColors.success : AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, bool isDark, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.white38 : AppColors.grey500),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : AppColors.textSecondary),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: valueColor ?? (isDark ? Colors.white : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(bool isDark) {
    if (!_isEditing) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.grey50,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        child: Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Change Password',
                icon: Iconsax.lock,
                variant: AppButtonVariant.outlined,
                onPressed: _showChangePasswordDialog,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.grey50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.outlined,
              onPressed: () {
                final user = ref.read(authProvider).user;
                setState(() {
                  _isEditing = false;
                  _nameController.text = user?.name ?? '';
                  _phoneController.text = user?.phone ?? '';
                  _selectedImageBytes = null;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: AppButton(
              label: 'Save Changes',
              icon: Iconsax.tick_circle,
              isLoading: _isLoading,
              onPressed: _saveProfile,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = pickedFile.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(authProvider).user;
      if (currentUser == null) throw Exception('User not found');

      String? finalAvatarUrl = currentUser.avatarUrl;

      // Upload image if selected
      if (_selectedImageBytes != null) {
        setState(() => _isUploadingImage = true);
        final fileName = 'avatar_${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        // uploadAvatar throws on error, so no need to check for null
        final uploadedUrl = await UserRepository().uploadAvatar(_selectedImageBytes!.toList(), fileName);
        setState(() => _isUploadingImage = false);
        
        // Delete old avatar if exists
        if (currentUser.avatarUrl != null) {
          await UserRepository().deleteAvatar(currentUser.avatarUrl!);
        }
        finalAvatarUrl = uploadedUrl;
      }

      final updatedUser = currentUser.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        avatarUrl: finalAvatarUrl,
      );

      // Save to database
      await UserRepository().update(updatedUser);
      // Update local state
      ref.read(authProvider.notifier).updateUser(updatedUser);

      if (mounted) {
        setState(() {
          _isEditing = false;
          _selectedImageBytes = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; _isUploadingImage = false; });
    }
  }

  void _showChangePasswordDialog() {
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Iconsax.lock, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Change PIN'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Current PIN',
                hintText: 'Enter current 4-digit PIN',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'New PIN',
                hintText: 'Enter new 4-digit PIN',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                hintText: 'Re-enter new PIN',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPinController.text != confirmPinController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PINs do not match'), backgroundColor: AppColors.error),
                );
                return;
              }
              if (newPinController.text.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN must be 4 digits'), backgroundColor: AppColors.error),
                );
                return;
              }
              
              try {
                final currentUser = ref.read(authProvider).user;
                if (currentUser == null) throw Exception('User not found');
                
                // Verify current PIN first
                final verified = await UserRepository().authenticateWithPin(currentPinController.text);
                if (verified == null || verified.id != currentUser.id) {
                  throw Exception('Current PIN is incorrect');
                }
                
                // Update PIN
                await UserRepository().updatePin(currentUser.id, newPinController.text);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN changed successfully!'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
