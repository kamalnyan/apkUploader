import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/models/apk_model.dart';
import '../../core/providers/apk_provider.dart';
import '../../core/theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/animated_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_indicator.dart';

/// APK edit screen for editors
class APKEditScreen extends StatefulWidget {
  /// Constructor
  const APKEditScreen({
    Key? key,
    required this.apk,
  }) : super(key: key);

  /// APK to edit
  final APKModel apk;

  @override
  State<APKEditScreen> createState() => _APKEditScreenState();
}

class _APKEditScreenState extends State<APKEditScreen> {
  final _formKey = GlobalKey<FormState>();
  // Basic information
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _versionController = TextEditingController();
  final _developerController = TextEditingController();
  final _changelogController = TextEditingController();
  final _playStoreUrlController = TextEditingController();
  
  // Additional details
  final _categoryController = TextEditingController();
  final _releaseDateController = TextEditingController();
  final _languagesController = TextEditingController();
  final _installInstructionsController = TextEditingController();
  final _supportEmailController = TextEditingController();
  final _privacyPolicyController = TextEditingController();
  final _downloadPasswordController = TextEditingController();
  
  late bool _isPinned;
  late bool _isRestricted;
  File? _imageFile;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initFormValues();
  }

  @override
  void dispose() {
    // Basic info
    _nameController.dispose();
    _descriptionController.dispose();
    _versionController.dispose();
    _developerController.dispose();
    _changelogController.dispose();
    _playStoreUrlController.dispose();
    
    // Additional details
    _categoryController.dispose();
    _releaseDateController.dispose();
    _languagesController.dispose();
    _installInstructionsController.dispose();
    _supportEmailController.dispose();
    _privacyPolicyController.dispose();
    _downloadPasswordController.dispose();
    
    super.dispose();
  }

  /// Initialize form values from the APK
  void _initFormValues() {
    // Basic info
    _nameController.text = widget.apk.name;
    _descriptionController.text = widget.apk.description;
    _versionController.text = widget.apk.versionName;
    _developerController.text = widget.apk.developer ?? '';
    _changelogController.text = widget.apk.changelog ?? '';
    _playStoreUrlController.text = widget.apk.playStoreUrl ?? '';
    
    // Additional details
    _categoryController.text = widget.apk.toMap()['category'] ?? '';
    _releaseDateController.text = widget.apk.toMap()['release_date'] ?? '';
    _languagesController.text = widget.apk.toMap()['languages'] ?? '';
    _installInstructionsController.text = widget.apk.toMap()['install_instructions'] ?? '';
    _supportEmailController.text = widget.apk.toMap()['support_email'] ?? '';
    _privacyPolicyController.text = widget.apk.toMap()['privacy_policy_url'] ?? '';
    _downloadPasswordController.text = widget.apk.toMap()['download_password'] ?? '';
    
    // Control values
    _isPinned = widget.apk.isPinned;
    _isRestricted = widget.apk.toMap()['is_restricted'] ?? false;
  }

  /// Pick an image from gallery
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      logger.e('Error picking image: $e');
      AppHelpers.showSnackBar(
        context,
        'Failed to pick image. Please try again.',
        isError: true,
      );
    }
  }

  /// Update the APK
  Future<void> _updateAPK() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get form values
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final version = _versionController.text.trim();
      final developer = _developerController.text.trim();
      final changelog = _changelogController.text.trim();
      final playStoreUrl = _playStoreUrlController.text.trim();
      
      // Additional details
      final category = _categoryController.text.trim();
      final releaseDate = _releaseDateController.text.trim();
      final languages = _languagesController.text.trim();
      final installInstructions = _installInstructionsController.text.trim();
      final supportEmail = _supportEmailController.text.trim();
      final privacyPolicyUrl = _privacyPolicyController.text.trim();
      final downloadPassword = _isRestricted ? _downloadPasswordController.text.trim() : null;

      // Update APK in Firebase
      final success = await context.read<APKProvider>().updateAPK(
        id: widget.apk.id,
        name: name,
        packageName: widget.apk.packageName,
        versionName: version,
        versionCode: widget.apk.versionCode,
        minSdk: widget.apk.minSdk,
        targetSdk: widget.apk.targetSdk,
        description: description,
        developer: developer,
        playStoreUrl: playStoreUrl,
        iconFile: _imageFile,
        iconFileName: _imageFile != null ? '${name.replaceAll(' ', '_')}_icon.png' : null,
        sizeBytes: widget.apk.sizeBytes,
        screenshotsToKeep: widget.apk.screenshots,
        permissions: widget.apk.permissions,
        isPinned: _isPinned,
        // Additional fields
        category: category,
        releaseDate: releaseDate,
        languages: languages,
        installInstructions: installInstructions,
        changelog: changelog,
        supportEmail: supportEmail,
        privacyPolicyUrl: privacyPolicyUrl,
        isRestricted: _isRestricted,
        downloadPassword: downloadPassword,
      );

      if (!mounted) return;

      if (success) {
        AppHelpers.showSnackBar(
          context,
          AppConstants.updateSuccessMessage,
        );
        Navigator.of(context).pop();
      } else {
        setState(() {
          _errorMessage = 'Failed to update APK. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.e('Error updating APK: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to update APK: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AnimatedAppBar(
        title: 'Edit APK',
        actions: [
          // Save button
          CustomButton(
            onPressed: _isLoading ? null : _updateAPK,
            icon: Icons.save,
            label: 'Save',
            isLoading: _isLoading,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Updating APK...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // APK image
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(15),
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : widget.apk.imageUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(widget.apk.imageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: _imageFile == null && widget.apk.imageUrl == null
                              ? const Icon(
                                  Icons.add_a_photo,
                                  size: 40,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spacingMedium),
                    
                    // Caption to tap image
                    Center(
                      child: Text(
                        'Tap to change image',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spacingLarge),
                    
                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingMedium),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusMedium,
                          ),
                          border: Border.all(
                            color: AppTheme.errorColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppTheme.errorColor,
                            ),
                            const SizedBox(width: AppTheme.spacingSmall),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),
                    ],
                    
                    // Basic Information Section
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingLarge),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingMedium),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Basic Information', style: Theme.of(context).textTheme.titleLarge),
                            const Divider(),
                            
                            // Name field
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Name *',
                                hintText: 'Enter APK name',
                                prefixIcon: Icon(Icons.app_shortcut),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a name';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: AppTheme.spacingMedium),
                            
                            // Version field
                            TextFormField(
                              controller: _versionController,
                              decoration: const InputDecoration(
                                labelText: 'Version *',
                                hintText: 'E.g., 1.0.0',
                                prefixIcon: Icon(Icons.verified),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a version';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: AppTheme.spacingMedium),
                            
                            // Description field
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Description *',
                                hintText: 'Enter APK description',
                                prefixIcon: Icon(Icons.description),
                                alignLabelWithHint: true,
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a description';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: AppTheme.spacingMedium),
                            
                            // Developer
                            TextFormField(
                              controller: _developerController,
                              decoration: const InputDecoration(
                                labelText: 'Developer',
                                hintText: 'Enter developer name',
                                prefixIcon: Icon(Icons.person),
                              ),
                            ),
                            
                            const SizedBox(height: AppTheme.spacingMedium),
                            
                            // Play Store URL
                            TextFormField(
                              controller: _playStoreUrlController,
                              decoration: const InputDecoration(
                                labelText: 'Play Store URL',
                                hintText: 'https://play.google.com/store/apps/details?id=...',
                                prefixIcon: Icon(Icons.play_arrow),
                              ),
                              keyboardType: TextInputType.url,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Additional Details Section
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingLarge),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingMedium),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Additional Details', style: Theme.of(context).textTheme.titleLarge),
                            const Divider(),
                            
                            // Category
                            TextFormField(
                              controller: _categoryController,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                hintText: 'e.g., Productivity, Games, Education',
                                prefixIcon: Icon(Icons.category),
                              ),
                            ),
                            
                            const SizedBox(height: AppTheme.spacingMedium),
                            
                            // Release Date
                            TextFormField(
                              controller: _releaseDateController,
                              decoration: const InputDecoration(
                                labelText: 'Release Date',
                                hintText: 'YYYY-MM-DD',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) {
                                  _releaseDateController.text = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                                }
                              },
                            ),
                            
                            const SizedBox(height: AppTheme.spacingMedium),
                            
                            // Languages
                            TextFormField(
                              controller: _languagesController,
                              decoration: const InputDecoration(
                                labelText: 'Languages Supported',
                                hintText: 'e.g., English, Spanish, French',
                                prefixIcon: Icon(Icons.language),
                              ),
                            ),
                            
                            const SizedBox(height: AppTheme.spacingMedium),
                            
                            // Installation Instructions
                            TextFormField(
                              controller: _installInstructionsController,
                              decoration: const InputDecoration(
                                labelText: 'Installation Instructions',
                                hintText: 'Enter special installation instructions if any',
                                prefixIcon: Icon(Icons.install_mobile),
                                alignLabelWithHint: true,
                              ),
                              maxLines: 2,
                            ),
                            
                            const SizedBox(height: AppTheme.spacingMedium),
                            
                            // Changelog field
                            TextFormField(
                              controller: _changelogController,
                              decoration: const InputDecoration(
                                labelText: 'Changelog / What\'s New',
                                hintText: 'Enter changes in this version',
                                prefixIcon: Icon(Icons.new_releases),
                                alignLabelWithHint: true,
                              ),
                              maxLines: 3,
                            ),
                            
                            const SizedBox(height: AppTheme.spacingMedium),
                            
                            // Support Email
                            TextFormField(
                              controller: _supportEmailController,
                              decoration: const InputDecoration(
                                labelText: 'Support Email',
                                hintText: 'e.g., support@example.com',
                                prefixIcon: Icon(Icons.email),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            
                            const SizedBox(height: AppTheme.spacingMedium),
                            
                            // Privacy Policy URL
                            TextFormField(
                              controller: _privacyPolicyController,
                              decoration: const InputDecoration(
                                labelText: 'Privacy Policy URL',
                                hintText: 'Enter privacy policy link if available',
                                prefixIcon: Icon(Icons.policy),
                              ),
                              keyboardType: TextInputType.url,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Access Control Section
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingLarge),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingMedium),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Access Control', style: Theme.of(context).textTheme.titleLarge),
                            const Divider(),
                            
                            // Pin option
                            SwitchListTile(
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.push_pin,
                                    color: _isPinned
                                        ? AppTheme.primaryColor
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppTheme.spacingSmall),
                                  const Text('Pin this APK'),
                                ],
                              ),
                              subtitle: const Text(
                                'Pinned APKs appear at the top of the list',
                              ),
                              value: _isPinned,
                              onChanged: (value) {
                                setState(() {
                                  _isPinned = value;
                                });
                              },
                              activeColor: AppTheme.primaryColor,
                            ),
                            
                            // Restrict access toggle
                            SwitchListTile(
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.security,
                                    color: _isRestricted ? Colors.green : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Restrict Access'),
                                ],
                              ),
                              subtitle: const Text('Limit who can download this APK'),
                              value: _isRestricted,
                              activeColor: Colors.green,
                              onChanged: (value) {
                                setState(() => _isRestricted = value);
                              },
                            ),
                            
                            // Download Password
                            TextFormField(
                              controller: _downloadPasswordController,
                              decoration: const InputDecoration(
                                labelText: 'Download Password',
                                hintText: 'Set password to protect downloads',
                                prefixIcon: Icon(Icons.password),
                              ),
                              obscureText: true,
                              enabled: _isRestricted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('SAVE CHANGES'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isLoading ? null : _updateAPK,
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spacingXl),
                  ],
                ),
              ),
            ),
    );
  }
} 