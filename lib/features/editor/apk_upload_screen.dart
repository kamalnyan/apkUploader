import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/providers/apk_provider.dart';
import '../../core/theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/animated_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_indicator.dart';

/// Screen for editors to upload a new APK
class APKUploadScreen extends StatefulWidget {
  /// Constructor
  const APKUploadScreen({super.key});

  @override
  State<APKUploadScreen> createState() => _APKUploadScreenState();
}

class _APKUploadScreenState extends State<APKUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _versionController = TextEditingController();
  final _changelogController = TextEditingController();
  
  bool _isPinned = false;
  File? _apkFile;
  File? _imageFile;
  bool _isLoading = false;
  String? _errorMessage;
  double _uploadProgress = 0.0;
  bool _showProgress = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _versionController.dispose();
    _changelogController.dispose();
    super.dispose();
  }

  /// Pick APK file from storage
  Future<void> _pickAPK() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['apk'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _apkFile = File(result.files.single.path!);
          
          // If name is empty, set it to the APK file name without extension
          if (_nameController.text.isEmpty) {
            final fileName = result.files.single.name;
            final nameWithoutExtension = fileName.substring(
              0,
              fileName.lastIndexOf('.'),
            );
            _nameController.text = nameWithoutExtension;
          }
        });
      }
    } catch (e) {
      logger.e('Error picking APK: $e');
      AppHelpers.showSnackBar(
        context,
        'Failed to pick APK file. Please try again.',
        isError: true,
      );
    }
  }

  /// Pick image file from gallery
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

  /// Upload the APK
  Future<void> _uploadAPK() async {
    if (_apkFile == null) {
      setState(() {
        _errorMessage = 'Please select an APK file to upload.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _showProgress = true;
      _errorMessage = null;
      _uploadProgress = 0.0;
    });

    try {
      // Get form values
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final version = _versionController.text.trim();
      final changelog = _changelogController.text.trim();

      // Upload to Firebase
      final success = await context.read<APKProvider>().uploadAPK(
        name: name,
        description: description,
        version: version,
        changelog: changelog,
        packageName: 'com.example.$name',
        apkFile: _apkFile!,
        iconFile: _imageFile,
        sizeBytes: await _apkFile!.length(),
      );

      if (!mounted) return;

      if (success) {
        AppHelpers.showSnackBar(
          context,
          AppConstants.uploadSuccessMessage,
        );
        Navigator.of(context).pop();
      } else {
        setState(() {
          _errorMessage = 'Failed to upload APK. Please try again.';
          _isLoading = false;
          _showProgress = false;
        });
      }
    } catch (e) {
      logger.e('Error uploading APK: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to upload APK: ${e.toString()}';
          _isLoading = false;
          _showProgress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AnimatedAppBar(
        title: 'Upload APK',
        actions: [
          // Upload button
          CustomButton(
            onPressed: _isLoading ? null : _uploadAPK,
            icon: Icons.cloud_upload,
            label: 'Upload',
            isLoading: _isLoading && !_showProgress,
          ),
        ],
      ),
      body: _isLoading && _showProgress
          ? LoadingIndicator(
              message: 'Uploading APK...',
              progress: _uploadProgress,
              showProgress: true,
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // APK file selection
                    GestureDetector(
                      onTap: _pickAPK,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTheme.spacingLarge),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusMedium,
                          ),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _apkFile != null
                                  ? Icons.check_circle_outline
                                  : Icons.android,
                              size: 48,
                              color: _apkFile != null
                                  ? Colors.green
                                  : AppTheme.primaryColor,
                            ),
                            const SizedBox(height: AppTheme.spacingMedium),
                            Text(
                              _apkFile != null
                                  ? 'APK selected: ${_apkFile!.path.split('/').last}'
                                  : 'Tap to select APK file',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (_apkFile != null) ...[
                              const SizedBox(height: AppTheme.spacingSmall),
                              TextButton.icon(
                                onPressed: _pickAPK,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Change APK'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: AppTheme.shortAnimationDuration),
                    ),
                    
                    const SizedBox(height: AppTheme.spacingLarge),
                    
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
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: _imageFile == null
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
                    
                    // Caption for image
                    Center(
                      child: Text(
                        'Tap to add app icon (optional)',
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
                    
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name *',
                        hintText: 'Enter APK name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: AppTheme.spacingLarge),
                    
                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter APK description',
                      ),
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: AppTheme.spacingLarge),
                    
                    // Version field
                    TextFormField(
                      controller: _versionController,
                      decoration: const InputDecoration(
                        labelText: 'Version',
                        hintText: 'E.g., 1.0.0',
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spacingLarge),
                    
                    // Changelog field
                    TextFormField(
                      controller: _changelogController,
                      decoration: const InputDecoration(
                        labelText: 'Changelog',
                        hintText: 'Enter changes in this version',
                      ),
                      maxLines: 5,
                    ),
                    
                    const SizedBox(height: AppTheme.spacingLarge),
                    
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
                    
                    const SizedBox(height: AppTheme.spacingXl),
                    
                    // Upload button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _uploadAPK,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_upload),
                            const SizedBox(width: AppTheme.spacingSmall),
                            const Text('Upload APK'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 