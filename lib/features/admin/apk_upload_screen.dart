import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/providers/apk_provider.dart';
import '../../core/theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_indicator.dart';

/// Screen for uploading a new APK
class APKUploadScreen extends StatefulWidget {
  /// Constructor
  const APKUploadScreen({super.key});

  @override
  State<APKUploadScreen> createState() => _APKUploadScreenState();
}

class _APKUploadScreenState extends State<APKUploadScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _playStoreUrlController = TextEditingController();
  final TextEditingController _developerController = TextEditingController();
  final TextEditingController _versionController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _minReqController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Files
  File? _apkFile;
  String? _apkFileName;
  File? _iconFile;
  String? _iconFileName;
  List<File> _screenshotFiles = [];
  List<String> _screenshotFileNames = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _playStoreUrlController.dispose();
    _developerController.dispose();
    _versionController.dispose();
    _sizeController.dispose();
    _minReqController.dispose();
    super.dispose();
  }

  /// Pick APK file
  Future<void> _pickAPK() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['apk'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _apkFile = File(result.files.single.path!);
          _apkFileName = result.files.single.name;
        });
      }
    } catch (e) {
      logger.e('Error picking APK file: $e');
      _showErrorSnackBar('Failed to select APK file.');
    }
  }

  /// Pick icon file
  Future<void> _pickIcon() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _iconFile = File(result.files.single.path!);
          _iconFileName = result.files.single.name;
        });
      }
    } catch (e) {
      logger.e('Error picking icon file: $e');
      _showErrorSnackBar('Failed to select icon file.');
    }
  }

  /// Pick screenshot files
  Future<void> _pickScreenshots() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null) {
        final files = <File>[];
        final fileNames = <String>[];
        
        for (final platformFile in result.files) {
          if (platformFile.path != null) {
            files.add(File(platformFile.path!));
            fileNames.add(platformFile.name);
          }
        }
        
        setState(() {
          _screenshotFiles = files;
          _screenshotFileNames = fileNames;
        });
      }
    } catch (e) {
      logger.e('Error picking screenshot files: $e');
      _showErrorSnackBar('Failed to select screenshot files.');
    }
  }

  /// Handle APK upload
  Future<void> _uploadAPK() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_apkFile == null || _iconFile == null) {
      _showErrorSnackBar('Please select both APK and icon files.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await context.read<APKProvider>().addAPK(
        name: _nameController.text.trim(),
        packageName: 'com.example.app', // Default for now, should be extracted from APK
        versionName: _versionController.text.isEmpty ? '1.0.0' : _versionController.text.trim(),
        versionCode: 1, // Default for now, should be extracted from APK
        minSdk: 21, // Default for now, should be extracted from APK
        targetSdk: 33, // Default for now, should be extracted from APK
        description: _descriptionController.text.trim(),
        apkFile: _apkFile!,
        iconFile: _iconFile,
        apkFileName: _apkFileName!,
        iconFileName: _iconFileName,
        screenshotFiles: _screenshotFiles.isEmpty ? null : _screenshotFiles,
        screenshotFileNames: _screenshotFileNames.isEmpty ? null : _screenshotFileNames,
        sizeBytes: _apkFile!.lengthSync(), // Get actual file size
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
        });
      }
    } catch (e) {
      logger.e('Error uploading APK: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred while uploading. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload APK'),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Uploading APK...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
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
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),
                    ],
                    
                    // APK file
                    InkWell(
                      onTap: _pickAPK,
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusMedium,
                      ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                                decoration: BoxDecoration(
                                  border: Border.all(
                            color: _apkFile != null
                                        ? AppTheme.successColor
                                        : Theme.of(context).dividerColor,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadiusMedium,
                                  ),
                          color: _apkFile != null
                                      ? AppTheme.successColor.withOpacity(0.1)
                                      : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                  _apkFile != null
                                              ? Icons.check_circle
                                      : Icons.upload_file,
                                  color: _apkFile != null
                                              ? AppTheme.successColor
                                              : Theme.of(context).iconTheme.color,
                                        ),
                                        const SizedBox(width: AppTheme.spacingSmall),
                                        Expanded(
                                          child: Text(
                                    _apkFile != null
                                                ? 'APK file selected'
                                        : 'Select APK file (required)',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: _apkFile != null
                                                  ? AppTheme.successColor
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            if (_apkFile != null) ...[
                                      const SizedBox(height: AppTheme.spacingSmall),
                                      Text(
                                        'File: $_apkFileName',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: AppTheme.spacingMedium),
                          
                    // Icon file
                    InkWell(
                      onTap: _pickIcon,
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusMedium,
                      ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                                decoration: BoxDecoration(
                                  border: Border.all(
                            color: _iconFile != null
                                        ? AppTheme.successColor
                                        : Theme.of(context).dividerColor,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadiusMedium,
                                  ),
                          color: _iconFile != null
                                      ? AppTheme.successColor.withOpacity(0.1)
                                      : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                  _iconFile != null
                                              ? Icons.check_circle
                                              : Icons.image,
                                  color: _iconFile != null
                                              ? AppTheme.successColor
                                              : Theme.of(context).iconTheme.color,
                                        ),
                                        const SizedBox(width: AppTheme.spacingSmall),
                                        Expanded(
                                          child: Text(
                                    _iconFile != null
                                                ? 'Icon file selected'
                                        : 'Select app icon (required)',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: _iconFile != null
                                                  ? AppTheme.successColor
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            if (_iconFile != null) ...[
                                      const SizedBox(height: AppTheme.spacingSmall),
                                      Text(
                                        'File: $_iconFileName',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                    ),
                    
                    const SizedBox(height: AppTheme.spacingMedium),
                    
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Enter app name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the app name';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: AppTheme.spacingMedium),
                    
                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter app description',
                        alignLabelWithHint: true,
                      ),
                      minLines: 3,
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: AppTheme.spacingLarge),
                    
                    // Optional fields section title
                    Text(
                      'Additional Information (Optional)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    
                    const SizedBox(height: AppTheme.spacingMedium),
                    
                    // Version field
                    TextFormField(
                      controller: _versionController,
                      decoration: const InputDecoration(
                        labelText: 'Version',
                        hintText: 'e.g., 1.0.0',
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spacingMedium),
                    
                    // Size field
                    TextFormField(
                      controller: _sizeController,
                      decoration: const InputDecoration(
                        labelText: 'Size',
                        hintText: 'e.g., 15 MB',
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spacingMedium),
                    
                    // Developer field
                    TextFormField(
                      controller: _developerController,
                      decoration: const InputDecoration(
                        labelText: 'Developer',
                        hintText: 'Enter developer name',
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spacingMedium),
                    
                    // Minimum requirements field
                    TextFormField(
                      controller: _minReqController,
                      decoration: const InputDecoration(
                        labelText: 'Minimum Requirements',
                        hintText: 'e.g., Android 6.0+',
                            ),
                          ),
                          
                          const SizedBox(height: AppTheme.spacingMedium),
                          
                    // Play Store URL field
                    TextFormField(
                      controller: _playStoreUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Play Store URL',
                        hintText: 'Enter Play Store URL if available',
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    
                    const SizedBox(height: AppTheme.spacingMedium),
                    
                    // Screenshots picker
                    InkWell(
                      onTap: _pickScreenshots,
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusMedium,
                      ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _screenshotFiles.isNotEmpty
                                        ? AppTheme.successColor
                                        : Theme.of(context).dividerColor,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadiusMedium,
                                  ),
                                  color: _screenshotFiles.isNotEmpty
                                      ? AppTheme.successColor.withOpacity(0.1)
                                      : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _screenshotFiles.isNotEmpty
                                              ? Icons.check_circle
                                              : Icons.photo_library,
                                          color: _screenshotFiles.isNotEmpty
                                              ? AppTheme.successColor
                                              : Theme.of(context).iconTheme.color,
                                        ),
                                        const SizedBox(width: AppTheme.spacingSmall),
                                        Expanded(
                                          child: Text(
                                            _screenshotFiles.isNotEmpty
                                        ? '${_screenshotFiles.length} screenshots selected'
                                        : 'Select screenshots (optional)',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: _screenshotFiles.isNotEmpty
                                                  ? AppTheme.successColor
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            if (_screenshotFiles.isNotEmpty) ...[
                              const SizedBox(height: AppTheme.spacingSmall),
                              Text(
                                'Selected ${_screenshotFiles.length} files',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spacingXl),
                    
                    // Upload button
                    SizedBox(
                        width: double.infinity,
                      height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _uploadAPK,
                        icon: const Icon(Icons.upload),
                          label: const Text('Upload APK'),
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spacingMedium),
                  ],
                ),
              ),
            ),
    );
  }
} 