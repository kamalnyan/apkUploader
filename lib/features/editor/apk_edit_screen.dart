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
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _versionController = TextEditingController();
  final _changelogController = TextEditingController();
  
  late bool _isPinned;
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
    _nameController.dispose();
    _descriptionController.dispose();
    _versionController.dispose();
    _changelogController.dispose();
    super.dispose();
  }

  /// Initialize form values from the APK
  void _initFormValues() {
    _nameController.text = widget.apk.name;
    _descriptionController.text = widget.apk.description ?? '';
    _versionController.text = widget.apk.version ?? '';
    _changelogController.text = widget.apk.changelog ?? '';
    _isPinned = widget.apk.isPinned;
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
      final changelog = _changelogController.text.trim();

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
        iconFile: _imageFile,
        iconFileName: _imageFile != null ? '${name.replaceAll(' ', '_')}_icon.png' : null,
        sizeBytes: widget.apk.sizeBytes,
        screenshotsToKeep: widget.apk.screenshots,
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
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateAPK,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 