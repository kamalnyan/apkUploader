import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;

import '../../core/constants.dart';
import '../../core/providers/apk_provider.dart';
import '../../core/theme.dart';
import '../../utils/helpers.dart';
import '../../utils/apk_parser.dart';
import '../../widgets/loading_indicator.dart';

/// Enhanced APK Upload Form that ensures all fields are captured
class EnhancedUploadForm extends StatefulWidget {
  const EnhancedUploadForm({Key? key}) : super(key: key);

  @override
  State<EnhancedUploadForm> createState() => _EnhancedUploadFormState();
}

class _EnhancedUploadFormState extends State<EnhancedUploadForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Basic fields
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _versionController = TextEditingController();
  final _developerController = TextEditingController();
  final _packageNameController = TextEditingController();
  
  // New additional fields - all will be explicitly saved
  final _categoryController = TextEditingController();
  final _releaseDateController = TextEditingController();
  final _languagesController = TextEditingController();
  final _installInstructionsController = TextEditingController();
  final _changelogController = TextEditingController();
  final _supportEmailController = TextEditingController();
  final _privacyPolicyController = TextEditingController();
  final _downloadPasswordController = TextEditingController();
  final _minSdkController = TextEditingController();
  final _targetSdkController = TextEditingController();
  final _sizeController = TextEditingController();
  final _playStoreUrlController = TextEditingController();
  
  // Files and control states
  File? _apkFile;
  String? _apkFileName;
  File? _iconFile;
  String? _iconFileName;
  List<File> _screenshotFiles = [];
  List<String> _screenshotFileNames = [];
  List<String>? _permissions;
  
  bool _isLoading = false;
  bool _isPinned = false;
  bool _isRestricted = false;
  double _uploadProgress = 0.0;
  
  @override
  void dispose() {
    // Dispose all controllers
    _nameController.dispose();
    _descriptionController.dispose();
    _versionController.dispose();
    _developerController.dispose();
    _packageNameController.dispose();
    _categoryController.dispose();
    _releaseDateController.dispose();
    _languagesController.dispose();
    _installInstructionsController.dispose();
    _changelogController.dispose();
    _supportEmailController.dispose();
    _privacyPolicyController.dispose();
    _downloadPasswordController.dispose();
    _minSdkController.dispose();
    _targetSdkController.dispose();
    _sizeController.dispose();
    _playStoreUrlController.dispose();
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

        await _extractApkMetadata();
      }
    } catch (e) {
      _showError('Error picking APK file: $e');
    }
  }

  /// Extract metadata from APK
  Future<void> _extractApkMetadata() async {
    if (_apkFile == null) return;

    setState(() => _isLoading = true);

    try {
      final apkInfo = await APKParser.getAPKInfo(_apkFile!.path);
      
      if (apkInfo != null) {
        setState(() {
          // Basic info
          if (apkInfo.appName != null && apkInfo.appName!.isNotEmpty) {
            _nameController.text = apkInfo.appName!;
          }
          
          if (apkInfo.versionName != null && apkInfo.versionName!.isNotEmpty) {
            _versionController.text = apkInfo.versionName!;
          }
          
          if (apkInfo.packageName != null && apkInfo.packageName!.isNotEmpty) {
            _packageNameController.text = apkInfo.packageName!;
          } else {
            _packageNameController.text = _extractPackageNameFromFileName(_apkFileName ?? '');
          }
          
          // SDK info
          if (apkInfo.minSdkVersion != null) {
            _minSdkController.text = apkInfo.minSdkVersion.toString();
          } else {
            _minSdkController.text = '21'; // Default Android 5.0
          }
          
          if (apkInfo.targetSdkVersion != null) {
            _targetSdkController.text = apkInfo.targetSdkVersion.toString();
          } else {
            _targetSdkController.text = '33'; // Default Android 13
          }
          
          // Size info
          _sizeController.text = AppHelpers.formatFileSize(apkInfo.sizeBytes);
          
          // Developer
          if (apkInfo.developer != null && apkInfo.developer!.isNotEmpty) {
            _developerController.text = apkInfo.developer!;
          }
          
          // Permissions
          _permissions = apkInfo.permissions;
        });
      }
    } catch (e) {
      _showError('Error extracting APK metadata: $e');
      
      // Set some basic defaults
      if (_apkFile != null) {
        setState(() {
          _packageNameController.text = _extractPackageNameFromFileName(_apkFileName ?? '');
          
          final versionMatch = RegExp(r'[vV]?(\d+\.\d+\.\d+|\d+\.\d+)').firstMatch(_apkFileName!);
          if (versionMatch != null && versionMatch.group(1) != null) {
            _versionController.text = versionMatch.group(1)!;
          } else {
            _versionController.text = '1.0.0';
          }
          
          _minSdkController.text = '21';
          _targetSdkController.text = '33';
          
          final nameWithoutExtension = _apkFileName!.replaceAll(RegExp(r'\.apk$', caseSensitive: false), '');
          _nameController.text = nameWithoutExtension.replaceAll(RegExp(r'[_\-]'), ' ');
          
          _sizeController.text = AppHelpers.formatFileSize(_apkFile!.lengthSync());
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Extract package name from filename
  String _extractPackageNameFromFileName(String fileName) {
    String nameWithoutExtension = fileName.replaceAll(RegExp(r'\.apk$', caseSensitive: false), '');
    nameWithoutExtension = nameWithoutExtension.replaceAll(RegExp(r'[vV]?(\d+\.\d+\.\d+|\d+\.\d+)'), '');
    
    nameWithoutExtension = nameWithoutExtension
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '.')
        .replaceAll(RegExp(r'\.+'), '.')
        .toLowerCase()
        .trim();
    
    nameWithoutExtension = nameWithoutExtension.replaceAll(RegExp(r'^\.+|\.+$'), '');
    
    if (nameWithoutExtension.split('.').length < 2) {
      return 'com.example.${nameWithoutExtension.isEmpty ? 'app' : nameWithoutExtension}';
    }
    
    return nameWithoutExtension;
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
      _showError('Error picking icon file: $e');
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
      _showError('Error picking screenshot files: $e');
    }
  }

  /// Upload APK with all fields
  Future<void> _uploadAPK() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_apkFile == null) {
      _showError('Please select an APK file');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<APKProvider>();
      
      // Parse version code
      int versionCode = 1;
      try {
        final versionParts = _versionController.text.split('.');
        if (versionParts.length >= 2) {
          versionCode = int.parse(versionParts[0]) * 10000;
          versionCode += int.parse(versionParts[1]) * 100;
          if (versionParts.length >= 3) {
            versionCode += int.parse(versionParts[2]);
          }
        }
      } catch (e) {
        print('Error parsing version code: $e');
      }
      
      // Parse SDK values
      int minSdk = 21;
      int targetSdk = 33;
      
      try {
        minSdk = int.parse(_minSdkController.text);
      } catch (e) {
        print('Error parsing minSdk: $e');
      }
      
      try {
        targetSdk = int.parse(_targetSdkController.text);
      } catch (e) {
        print('Error parsing targetSdk: $e');
      }
      
      // Upload with ALL fields
      final success = await provider.addAPK(
        name: _nameController.text.trim(),
        packageName: _packageNameController.text.trim(),
        versionName: _versionController.text.trim(),
        versionCode: versionCode,
        minSdk: minSdk,
        targetSdk: targetSdk,
        description: _descriptionController.text.trim(),
        developer: _developerController.text.trim(),
        minRequirements: "Android $minSdk+",
        playStoreUrl: _playStoreUrlController.text.trim(),
        permissions: _permissions ?? [],
        apkFile: _apkFile!,
        iconFile: _iconFile,
        apkFileName: _apkFileName ?? 'app.apk',
        iconFileName: _iconFileName,
        screenshotFiles: _screenshotFiles.isEmpty ? null : _screenshotFiles,
        screenshotFileNames: _screenshotFileNames.isEmpty ? null : _screenshotFileNames,
        sizeBytes: _apkFile!.lengthSync(),
        isPinned: _isPinned,
        // Explicitly include all additional fields
        category: _categoryController.text.trim(),
        releaseDate: _releaseDateController.text.trim(),
        languages: _languagesController.text.trim(),
        installInstructions: _installInstructionsController.text.trim(),
        changelog: _changelogController.text.trim(),
        supportEmail: _supportEmailController.text.trim(),
        privacyPolicyUrl: _privacyPolicyController.text.trim(),
        isRestricted: _isRestricted,
        downloadPassword: _downloadPasswordController.text.trim(),
        onProgress: (progress) {
          if (mounted) {
            setState(() => _uploadProgress = progress);
          }
        },
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('APK uploaded successfully')),
        );
        Navigator.of(context).pop();
      } else {
        _showError('Failed to upload APK');
      }
    } catch (e) {
      _showError('Error uploading APK: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced APK Upload'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.upload),
            label: const Text('UPLOAD'),
            onPressed: _isLoading ? null : _uploadAPK,
          ),
        ],
      ),
      body: _isLoading 
        ? LoadingIndicator(
            message: 'Processing...',
            progress: _uploadProgress,
            showProgress: _uploadProgress > 0,
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File Selection Section
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Files', style: Theme.of(context).textTheme.titleLarge),
                          const Divider(),
                          
                          // APK file picker
                          ListTile(
                            leading: Icon(
                              _apkFile != null ? Icons.check_circle : Icons.android,
                              color: _apkFile != null ? Colors.green : Colors.grey,
                            ),
                            title: Text(
                              _apkFile != null ? 'APK Selected: $_apkFileName' : 'Select APK File (Required)'
                            ),
                            trailing: const Icon(Icons.file_upload),
                            onTap: _pickAPK,
                          ),
                          
                          // Icon picker
                          ListTile(
                            leading: Icon(
                              _iconFile != null ? Icons.check_circle : Icons.image,
                              color: _iconFile != null ? Colors.green : Colors.grey,
                            ),
                            title: Text(
                              _iconFile != null ? 'Icon Selected: $_iconFileName' : 'Select App Icon'
                            ),
                            trailing: const Icon(Icons.file_upload),
                            onTap: _pickIcon,
                          ),
                          
                          // Screenshots picker
                          ListTile(
                            leading: Icon(
                              _screenshotFiles.isNotEmpty ? Icons.check_circle : Icons.photo_library,
                              color: _screenshotFiles.isNotEmpty ? Colors.green : Colors.grey,
                            ),
                            title: Text(
                              _screenshotFiles.isNotEmpty 
                                ? 'Screenshots: ${_screenshotFiles.length} selected' 
                                : 'Select Screenshots (Optional)'
                            ),
                            trailing: const Icon(Icons.file_upload),
                            onTap: _pickScreenshots,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Basic Info Section
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Basic Information', style: Theme.of(context).textTheme.titleLarge),
                          const Divider(),
                          
                          // Name field - REQUIRED
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'App Name *',
                              hintText: 'Enter app name',
                              prefixIcon: Icon(Icons.app_shortcut),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'App name is required';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Package name - REQUIRED
                          TextFormField(
                            controller: _packageNameController,
                            decoration: const InputDecoration(
                              labelText: 'Package Name *',
                              hintText: 'com.example.app',
                              prefixIcon: Icon(Icons.api),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Package name is required';
                              }
                              if (!value.contains('.')) {
                                return 'Enter a valid package name (e.g., com.example.app)';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Version - REQUIRED
                          TextFormField(
                            controller: _versionController,
                            decoration: const InputDecoration(
                              labelText: 'Version *',
                              hintText: '1.0.0',
                              prefixIcon: Icon(Icons.verified),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Version is required';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Description - REQUIRED
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description *',
                              hintText: 'Enter app description',
                              prefixIcon: Icon(Icons.description),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Description is required';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Developer
                          TextFormField(
                            controller: _developerController,
                            decoration: const InputDecoration(
                              labelText: 'Developer',
                              hintText: 'Enter developer name',
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Technical Details Section
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Technical Details', style: Theme.of(context).textTheme.titleLarge),
                          const Divider(),
                          
                          // Min SDK
                          TextFormField(
                            controller: _minSdkController,
                            decoration: const InputDecoration(
                              labelText: 'Minimum SDK',
                              hintText: '21',
                              prefixIcon: Icon(Icons.settings_suggest),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Target SDK
                          TextFormField(
                            controller: _targetSdkController,
                            decoration: const InputDecoration(
                              labelText: 'Target SDK',
                              hintText: '33',
                              prefixIcon: Icon(Icons.settings_applications),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Size
                          TextFormField(
                            controller: _sizeController,
                            decoration: const InputDecoration(
                              labelText: 'Size',
                              hintText: '10 MB',
                              prefixIcon: Icon(Icons.data_usage),
                            ),
                            readOnly: true,
                          ),
                          
                          const SizedBox(height: 16),
                          
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
                  
                  const SizedBox(height: 16),
                  
                  // Additional Details Section
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
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
                          
                          const SizedBox(height: 16),
                          
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
                          
                          const SizedBox(height: 16),
                          
                          // Languages
                          TextFormField(
                            controller: _languagesController,
                            decoration: const InputDecoration(
                              labelText: 'Languages Supported',
                              hintText: 'e.g., English, Spanish, French',
                              prefixIcon: Icon(Icons.language),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
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
                          
                          const SizedBox(height: 16),
                          
                          // Changelog
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
                          
                          const SizedBox(height: 16),
                          
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
                          
                          const SizedBox(height: 16),
                          
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
                  
                  const SizedBox(height: 16),
                  
                  // Access Control Section
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Access Control', style: Theme.of(context).textTheme.titleLarge),
                          const Divider(),
                          
                          // Pin toggle
                          SwitchListTile(
                            title: Row(
                              children: [
                                Icon(
                                  Icons.push_pin,
                                  color: _isPinned ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                const Text('Pin this APK'),
                              ],
                            ),
                            subtitle: const Text('Pinned APKs appear at the top of the list'),
                            value: _isPinned,
                            activeColor: Colors.green,
                            onChanged: (value) {
                              setState(() => _isPinned = value);
                            },
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
                  
                  const SizedBox(height: 24),
                  
                  // Upload Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('UPLOAD APK'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isLoading ? null : _uploadAPK,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
    );
  }
} 