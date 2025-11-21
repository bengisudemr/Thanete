import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:thanette/src/providers/theme_provider.dart';
import 'package:thanette/src/screens/login_screen.dart';
import 'package:thanette/src/providers/notes_provider.dart';
import 'package:thanette/src/providers/app_theme_controller.dart';
import 'package:thanette/src/providers/supabase_service.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  static const route = '/profile';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _profileName;
  String? _profilePhotoUrl;
  bool _isLoading = false;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final profile = await SupabaseService.instance.getMyProfile();
      if (profile != null) {
        setState(() {
          _profileName = profile['name'] as String?;
          _profilePhotoUrl = profile['avatar_url'] as String?;
          _nameController.text = _profileName ?? '';
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfileName(String name) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await SupabaseService.instance.upsertProfile(name: name);
      setState(() {
        _profileName = name.isEmpty ? null : name;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profil güncellendi'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil güncellenirken hata: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isLoading = true;
        });

        final file = File(image.path);
        final fileName = 'avatar.jpg'; // Simple filename, path includes user ID

        try {
          final photoUrl = await SupabaseService.instance.uploadProfilePhoto(
            file,
            fileName,
          );

          // Update profile with photo URL
          await SupabaseService.instance.upsertProfile(avatarUrl: photoUrl);

          setState(() {
            _profilePhotoUrl = photoUrl;
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Profil fotoğrafı güncellendi'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
            );
          }
        } catch (uploadError) {
          print('Upload error: $uploadError');
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Fotoğraf yüklenirken hata oluştu. Lütfen Supabase\'de "avatars" storage bucket\'ının oluşturulduğundan emin olun.\n\nHata: $uploadError',
                ),
                backgroundColor: AppTheme.error,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf seçilirken hata: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        );
      }
    }
  }

  void _showEditNameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: Text(
          'İsmini Düzenle',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: AppTheme.fontWeightBold,
          ),
        ),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'İsmin',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateProfileName(_nameController.text.trim());
            },
            child: Text(
              'Kaydet',
              style: TextStyle(color: AppTheme.primaryPink),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '-';
    final phone = user?.phone ?? '';
    final notesProvider = context.watch<NotesProvider>();
    final totalNotes = notesProvider.items.length;
    final pinnedNotes = notesProvider.items
        .where((n) => n.isPinned == true)
        .length;
    final themeController = context.watch<AppThemeController>();
    final currentPalette = themeController.palette;
    final isThemeChanging = themeController.isChangingTheme;
    final themeOptions = [
      {'palette': AccentPalette.green, 'label': 'Yeşil'},
      {'palette': AccentPalette.pink, 'label': 'Pembe'},
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        title: const Text('Profilim'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading && _profileName == null && _profilePhotoUrl == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundPrimary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundColor: AppTheme.primaryPink,
                                    backgroundImage: _profilePhotoUrl != null
                                        ? NetworkImage(_profilePhotoUrl!)
                                        : null,
                                    child: _profilePhotoUrl == null
                                        ? const Icon(
                                            Icons.person_outline,
                                            color: Colors.white,
                                            size: 32,
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: _pickAndUploadProfilePhoto,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryPink,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppTheme.backgroundPrimary,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _profileName != null &&
                                                    _profileName!.isNotEmpty
                                                ? _profileName!
                                                : email,
                                            style: TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontSize: AppTheme.fontSizeLarge,
                                              fontWeight:
                                                  AppTheme.fontWeightSemiBold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 18,
                                          ),
                                          color: AppTheme.textSecondary,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: _showEditNameDialog,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    if (_profileName != null &&
                                        _profileName!.isNotEmpty)
                                      Text(
                                        email,
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: AppTheme.fontSizeSmall,
                                        ),
                                      ),
                                    if (phone.isNotEmpty)
                                      Text(
                                        phone,
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Toplam Not',
                                  value: '$totalNotes',
                                  icon: Icons.note_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: 'Sabitli Not',
                                  value: '$pinnedNotes',
                                  icon: Icons.push_pin_outlined,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundPrimary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hesap',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: AppTheme.fontSizeLarge,
                              fontWeight: AppTheme.fontWeightBold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryPink.withOpacity(
                                0.12,
                              ),
                              child: const Icon(
                                Icons.email_outlined,
                                color: Colors.black54,
                              ),
                            ),
                            title: const Text('E-posta'),
                            subtitle: Text(
                              email,
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                          if (phone.isNotEmpty)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryPink
                                    .withOpacity(0.12),
                                child: const Icon(
                                  Icons.phone_outlined,
                                  color: Colors.black54,
                                ),
                              ),
                              title: const Text('Telefon'),
                              subtitle: Text(
                                phone,
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            ),
                          const Divider(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundPrimary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tema',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: AppTheme.fontSizeLarge,
                              fontWeight: AppTheme.fontWeightBold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Renk Teması',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: AppTheme.fontSizeMedium,
                                  fontWeight: AppTheme.fontWeightSemiBold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: themeOptions.map((option) {
                                  final palette = option['palette'] as AccentPalette;
                                  final label = option['label'] as String;
                                  final isSelected = palette == currentPalette;
                                  return _ThemeChoiceChip(
                                    label: label,
                                    isSelected: isSelected,
                                    isBusy: isThemeChanging,
                                    onTap: () async {
                                      if (isSelected || isThemeChanging) {
                                        return;
                                      }
                                      await themeController.setPalette(palette);
                                      if (mounted) {
                                        final message = palette == AccentPalette.green
                                            ? 'Tema yeşil olarak değiştirildi'
                                            : 'Tema pembe olarak değiştirildi';
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(message),
                                            backgroundColor: AppTheme.primaryPink,
                                            duration: const Duration(seconds: 2),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(
                                                AppTheme.radiusMedium,
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Logout at bottom
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundPrimary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.logout, color: AppTheme.error),
                        title: Text(
                          'Çıkış Yap',
                          style: TextStyle(
                            color: AppTheme.error,
                            fontWeight: AppTheme.fontWeightSemiBold,
                          ),
                        ),
                        onTap: () async {
                          final nav = Navigator.of(context);
                          try {
                            await Supabase.instance.client.auth.signOut();
                          } finally {
                            if (!mounted) return;
                            nav.pushNamedAndRemoveUntil(
                              LoginScreen.route,
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryPink.withOpacity(0.12),
            child: Icon(icon, color: AppTheme.primaryPink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: AppTheme.fontSizeXXLarge,
                    fontWeight: AppTheme.fontWeightBold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeChoiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isBusy;
  final IconData? icon;
  final Future<void> Function()? onTap;

  const _ThemeChoiceChip({
    required this.label,
    required this.isSelected,
    required this.isBusy,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppTheme.radiusMedium);
    final foregroundColor =
        isSelected ? AppTheme.primaryPink : AppTheme.textSecondary;
    final backgroundColor = isSelected
        ? AppTheme.primaryPink.withOpacity(0.12)
        : AppTheme.backgroundSecondary;

    return InkWell(
      onTap: (isBusy || onTap == null) ? null : () => onTap!(),
      borderRadius: borderRadius,
      child: AnimatedContainer(
        duration: AppTheme.animationFast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
          border: Border.all(
            color: isSelected ? AppTheme.primaryPink : AppTheme.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppTheme.buttonShadow : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: foregroundColor, size: 18),
              const SizedBox(width: 8),
            ] else if (isSelected) ...[
              Icon(Icons.check_circle, color: AppTheme.primaryPink, size: 18),
              const SizedBox(width: 8),
            ] else ...[
              Icon(Icons.circle_outlined, color: foregroundColor, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: isSelected
                    ? AppTheme.fontWeightSemiBold
                    : AppTheme.fontWeightMedium,
              ),
            ),
            if (isBusy && isSelected) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryPink,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
