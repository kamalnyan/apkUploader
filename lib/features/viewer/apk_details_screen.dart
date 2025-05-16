import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:app_settings/app_settings.dart';

import '../../core/constants.dart';
import '../../core/models/apk_model.dart';
import '../../core/providers/apk_provider.dart';
import '../../core/theme.dart';
import '../../services/download_service.dart';
import '../../utils/helpers.dart';
import '../../utils/storage_permission_handler.dart';
import '../../widgets/animated_app_bar.dart';
import '../../widgets/download_progress_dialog.dart';
import '../../widgets/loading_indicator.dart';

/// APK details screen for viewers
class APKDetailsScreen extends StatefulWidget {
  /// Constructor
  const APKDetailsScreen({
    Key? key,
    required this.apk,
  }) : super(key: key);

  /// APK to display
  final APKModel apk;

  @override
  State<APKDetailsScreen> createState() => _APKDetailsScreenState();
}

class _APKDetailsScreenState extends State<APKDetailsScreen> {
  final DownloadService _downloadService = DownloadService();
  bool _isDownloading = false;
  String? _downloadMessage;

  @override
  void initState() {
    super.initState();
    // Check permissions when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStoragePermission();
    });
  }

  /// Check for storage permissions
  Future<void> _checkStoragePermission() async {
    // Only check on Android
    if (!AppHelpers.isAndroid()) {
      return;
    }
    
    final hasPermission = await StoragePermissionHandler.hasStoragePermission();
    logger.i('Storage permission check: $hasPermission');
  }

  /// Download and install APK
  Future<void> _downloadAPK() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadMessage = 'Preparing download...';
    });

    try {
      // Check if URL exists
      if (widget.apk.downloadUrl.isEmpty) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _downloadMessage = null;
          });
          
          AppHelpers.showSnackBar(
            context,
            'This APK has no download URL. Please contact the administrator.',
            isError: true,
          );
        }
        return;
      }
      
      // Check and request permissions
      final hasPermission = await StoragePermissionHandler.requestAllPermissions(
        context,
        forceRequest: true,
      );
      
      if (!hasPermission) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _downloadMessage = null;
          });
          
          AppHelpers.showSnackBar(
            context,
            'Storage permission required to download APKs.',
            isError: true,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                AppSettings.openAppSettings();
              },
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      
      // Show download progress dialog
      BuildContext? dialogContext;
      StateSetter? dialogSetState;
      double progress = 0;
      DownloadStatus dialogStatus = DownloadStatus.downloading;
      String dialogMessage = 'Starting download...';
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          dialogContext = context;
          return StatefulBuilder(
            builder: (context, setDialogState) {
              dialogSetState = setDialogState;
              return DownloadProgressDialog(
                fileName: widget.apk.name,
                progress: progress,
                status: dialogStatus,
                message: dialogMessage,
              );
            }
          );
        },
      );

      // Increment download count
      await context.read<APKProvider>().incrementDownloadCount(widget.apk.id);
      
      // Custom download and install to track progress
      final String fileName = '${widget.apk.name.replaceAll(' ', '_')}.apk';
      final filePath = await _downloadService.downloadAPK(
        widget.apk.downloadUrl,
        fileName,
        onProgress: (downloadProgress) {
          // Update progress value
          progress = downloadProgress;
          
          // Update dialog message
          dialogMessage = 'Downloading ${widget.apk.name} (${progress.toInt()}%)...';
          
          // Update dialog UI
          if (dialogContext != null && dialogSetState != null && mounted) {
            dialogSetState!(() {});
          }
        },
        showNotification: false,
      );
      
      // If download was successful, try to install
      if (filePath != null) {
        // Update dialog to show installation
        if (dialogSetState != null) {
          dialogSetState!(() {
            progress = 100;
            dialogStatus = DownloadStatus.installing;
            dialogMessage = 'Installing ${widget.apk.name}...';
          });
        }
        
        // Install the APK
        final installResult = await _downloadService.installAPK(
          filePath,
          showNotification: false,
        );
        
        if (!mounted) return;
        
        // Close progress dialog
        if (dialogContext != null && mounted) {
          Navigator.of(dialogContext!).pop();
        }
        
        // Show result
        if (installResult) {
          AppHelpers.showSnackBar(
            context,
            'APK download completed. Installation started.',
          );
        } else {
          AppHelpers.showSnackBar(
            context,
            'APK downloaded but installation permission required.',
            isError: true,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                AppSettings.openAppSettings();
              },
            ),
          );
        }
      } else {
        // Download failed
        if (!mounted) return;
        
        // Close progress dialog
        if (dialogContext != null && mounted) {
          Navigator.of(dialogContext!).pop();
        }
        
        // Show error
        AppHelpers.showSnackBar(
          context,
          'Failed to download APK. Please check your internet connection.',
          isError: true,
        );
      }
    } catch (e) {
      logger.e('Error downloading APK: $e');
      
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          'Failed to download APK: ${e.toString()}',
          isError: true,
        );
        
        // Close progress dialog if open
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadMessage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final apk = widget.apk;
    
    return Scaffold(
      appBar: AnimatedAppBar(
        title: apk.name,
      ),
      body: _isDownloading
          ? LoadingIndicator(message: _downloadMessage ?? 'Processing...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // APK image and basic info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // APK image
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(15),
                          image: apk.imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(apk.imageUrl!),
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
                        child: apk.imageUrl == null
                            ? const Icon(
                                Icons.android,
                                size: 50,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      
                      const SizedBox(width: AppTheme.spacingLarge),
                      
                      // Basic info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              apk.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            
                            const SizedBox(height: AppTheme.spacingSmall),
                            
                            // Version
                            if (apk.version != null && apk.version!.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.tag,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Version ${apk.version}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: AppTheme.spacingSmall),
                            ],
                            
                            // Download count
                            Row(
                              children: [
                                const Icon(
                                  Icons.download,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${apk.downloadCount} downloads',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: AppTheme.spacingMedium),
                            
                            // Download button
                            AppTheme.primaryButton(
                              text: 'Download',
                              leadingIcon: Icons.download,
                              onPressed: _downloadAPK,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppTheme.spacingLarge),
                  
                  // Description section
                  if (apk.description != null && apk.description!.isNotEmpty) ...[
                    const Divider(),
                    
                    const SizedBox(height: AppTheme.spacingMedium),
                    
                    // Section title
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spacingMedium),
                    
                    // Description text
                    Text(
                      apk.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    
                    const SizedBox(height: AppTheme.spacingLarge),
                  ],
                  
                  // Changelog section
                  if (apk.changelog != null && apk.changelog!.isNotEmpty) ...[
                    const Divider(),
                    
                    const SizedBox(height: AppTheme.spacingMedium),
                    
                    // Section title
                    Text(
                      'What\'s New',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spacingMedium),
                    
                    // Changelog text
                    Text(
                      apk.changelog!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    
                    const SizedBox(height: AppTheme.spacingLarge),
                  ],
                  
                  // Download section at the bottom
                  const Divider(),
                  
                  const SizedBox(height: AppTheme.spacingMedium),
                  
                  // Download button (full width)
                  SizedBox(
                    width: double.infinity,
                    child: AppTheme.successButton(
                      text: 'Download and Install',
                      icon: Icons.download,
                      onPressed: _downloadAPK,
                      size: const Size(double.infinity, AppTheme.buttonHeightLarge),
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingSmall),
                  
                  // Help text
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingSmall),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppTheme.textLightColor,
                        ),
                        const SizedBox(width: AppTheme.spacingXs),
                        Flexible(
                          child: Text(
                            'Make sure to allow installation from unknown sources',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textLightColor,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}