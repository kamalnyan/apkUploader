import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants.dart';
import '../../core/models/apk_model.dart';
import '../../core/providers/apk_provider.dart';
import '../../core/theme.dart';
import '../../services/download_service.dart';
import '../../utils/helpers.dart';
import '../../widgets/animated_app_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/download_progress_dialog.dart';

/// Screen for displaying APK details for users
class APKDetailsScreen extends StatefulWidget {
  final APKModel apk;
  
  /// Constructor
  const APKDetailsScreen({
    super.key,
    required this.apk,
  });

  @override
  State<APKDetailsScreen> createState() => _APKDetailsScreenState();
}

class _APKDetailsScreenState extends State<APKDetailsScreen> {
  final DownloadService _downloadService = DownloadService();
  bool _isDownloading = false;

  /// Show the download loading dialog
  void _showDownloadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// Handle APK download and installation
  Future<void> _downloadAndInstallAPK() async {
    // Enhanced URL validation
    if (widget.apk.downloadUrl.isEmpty) {
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          'Invalid APK URL. Please contact the administrator.',
          isError: true,
        );
      }
      logger.e('Empty APK URL');
      return;
    }
    
    // Try to ensure the URL is valid
    String downloadUrl = widget.apk.downloadUrl;
    
    // Check if URL needs to be fixed (especially for Firebase Storage)
    try {
      if (!Uri.parse(downloadUrl).isAbsolute || !AppHelpers.isValidUrl(downloadUrl)) {
        // Try to fix Firebase Storage URL
        final fixedUrl = AppHelpers.fixFirebaseStorageUrl(downloadUrl);
        if (fixedUrl.isNotEmpty) {
          downloadUrl = fixedUrl;
          logger.i('Fixed Firebase Storage URL: $downloadUrl');
        } else {
          if (mounted) {
            AppHelpers.showSnackBar(
              context,
              'Invalid APK URL format. Please contact the administrator.',
              isError: true,
            );
          }
          logger.e('Invalid APK URL: $downloadUrl');
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          'Invalid APK URL format. Please contact the administrator.',
          isError: true,
        );
      }
      logger.e('Error parsing APK URL: $e');
      return;
    }
    
    final String fileName = '${widget.apk.name.replaceAll(' ', '_')}.apk';
    double progress = 0;
    bool isCancelled = false;
    DownloadStatus dialogStatus = DownloadStatus.downloading;
    String dialogMessage = 'Downloading ${widget.apk.name} (0%)...';
    
    // Reference to the dialog, so we can dismiss it if needed
    BuildContext? dialogContext;
    
    // Reference to the dialog's setState function
    StateSetter? dialogSetState;
    
    setState(() {
      _isDownloading = true;
    });

    try {
      if (AppHelpers.isAndroid()) {
        // Show the progress dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            dialogContext = context;
            return StatefulBuilder(
              builder: (context, setDialogState) {
                // Store the setState function
                dialogSetState = setDialogState;
                
                return DownloadProgressDialog(
                  fileName: widget.apk.name,
                  progress: progress,
                  status: dialogStatus,
                  message: dialogMessage,
                  onCancel: () {
                    setDialogState(() {
                      isCancelled = true;
                    });
                    Navigator.of(context).pop();
                  },
                );
              }
            );
          },
        );
        
        if (!mounted) return;
        
        // Download the APK file
        final filePath = await _downloadService.downloadAPK(
          downloadUrl,
          fileName,
          onProgress: (downloadProgress) {
            if (dialogContext != null && !isCancelled && dialogSetState != null) {
              // Only update if progress changed by at least 1%
              if ((downloadProgress - progress).abs() >= 1.0) {
                // Update progress value
                progress = downloadProgress;
                
                // Update dialog message
                dialogMessage = 'Downloading ${widget.apk.name} (${progress.toInt()}%)...';
                
                // Update dialog using stored setState function
                dialogSetState!(() {});
              }
            }
          },
          showNotification: false, // We'll show our own UI instead
        );
        
        // If cancelled or unmounted, stop here
        if (isCancelled || !mounted) return;
        
        if (filePath == null) {
          // If download failed, update dialog with error
          if (dialogContext != null) {
            Navigator.of(dialogContext!).pop();
            
            if (mounted) {
              // Show a snackbar instead of error dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Failed to download APK. Please check your internet connection and try again.'),
                  backgroundColor: AppTheme.errorColor,
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: _downloadAndInstallAPK,
                  ),
                ),
              );
            }
          }
          setState(() {
            _isDownloading = false;
          });
          return;
        }
        
        // Increment download count in the database
        context.read<APKProvider>().incrementDownloadCount(widget.apk.id);
        
        // Update dialog to show installation progress
        if (dialogContext != null && mounted) {
          Navigator.of(dialogContext!).pop();
          
          // Show installation dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              dialogContext = context;
              return const DownloadProgressDialog(
                fileName: '',
                progress: 100,
                status: DownloadStatus.installing,
                message: 'APK downloaded successfully. Starting installation...',
              );
            },
          );
        }
        
        // Install the APK
        final installResult = await _downloadService.installAPK(
          filePath,
          showNotification: false, // We'll show our own UI instead
        );
        
        // If installation dialog is still showing, dismiss it
        if (dialogContext != null && mounted) {
          Navigator.of(dialogContext!).pop();
          
          // Just show a brief message if successful
          if (installResult == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Installation has been initiated'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          } else {
            // Show snackbar for installation failure instead of dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Failed to install APK. Permission may be required.'),
                backgroundColor: AppTheme.errorColor,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Settings',
                  textColor: Colors.white,
                  onPressed: () => AppHelpers.openAppSettings(),
                ),
              ),
            );
          }

        }
      } else if (AppHelpers.isIOS()) {
        // Show iOS message
        _downloadService.showInstallMessage(context);
      } else {
        // For other platforms, just show a message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download and installation not supported on this platform'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
        }

      }
    } catch (e) {
      // If an error occurs and the dialog is still showing, dismiss it
      if (dialogContext != null && mounted) {
        Navigator.of(dialogContext!).pop();
        
        // Show snackbar for errors instead of dialog
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString().split('\n').first}'),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
      
      logger.e('Error downloading APK: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  /// Retry installation with the downloaded file
  void _retryInstallation(String filePath) {
    if (mounted) {
      _downloadService.installAPK(filePath, showNotification: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AnimatedAppBar(
        title: widget.apk.name,
        showElevation: false,
      ),
      body: _isDownloading
          ? const LoadingIndicator(message: 'Downloading...')
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App header with icon and title
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacingLarge),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(AppTheme.borderRadiusLarge),
                        bottomRight: Radius.circular(AppTheme.borderRadiusLarge),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // App icon
                        Hero(
                          tag: 'apk-icon-${widget.apk.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusMedium,
                            ),
                            child: CachedNetworkImage(
                              imageUrl: widget.apk.iconUrl ?? '',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  color: Colors.white,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 120,
                                height: 120,
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                child: const Icon(
                                  Icons.android,
                                  color: AppTheme.primaryColor,
                                  size: 60,
                                ),
                              ),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: AppTheme.mediumAnimationDuration)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          duration: AppTheme.mediumAnimationDuration,
                        ),
                        
                        const SizedBox(height: AppTheme.spacingLarge),
                        
                        // App name
                        Hero(
                          tag: 'apk-name-${widget.apk.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              widget.apk.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(
                          duration: AppTheme.mediumAnimationDuration,
                          delay: const Duration(milliseconds: 200),
                        ),
                        
                        const SizedBox(height: AppTheme.spacingMedium),
                        
                        // Upload date
                        Text(
                          'Uploaded: ${AppHelpers.formatDateTime(widget.apk.uploadedAt)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textLightColor,
                          ),
                        )
                        .animate()
                        .fadeIn(
                          duration: AppTheme.mediumAnimationDuration,
                          delay: const Duration(milliseconds: 300),
                        ),
                        
                        const SizedBox(height: AppTheme.spacingLarge),
                        
                        // Download button
                        SizedBox(
                          width: double.infinity,
                          child: AppTheme.successButton(
                            text: 'Install APK',
                            icon: Icons.system_update_alt,
                            onPressed: _downloadAndInstallAPK,
                            size: const Size(double.infinity, AppTheme.buttonHeightLarge),
                          ),
                        )
                        .animate()
                        .fadeIn(
                          duration: AppTheme.mediumAnimationDuration,
                          delay: const Duration(milliseconds: 400),
                        )
                        .slideY(
                          begin: 0.2,
                          end: 0,
                          duration: AppTheme.mediumAnimationDuration,
                          delay: const Duration(milliseconds: 400),
                        ),
                        
                        // Note for iOS users
                        if (AppHelpers.isIOS()) ...[
                          const SizedBox(height: AppTheme.spacingMedium),
                          Text(
                            'Note: APK files cannot be installed on iOS devices.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.warningColor,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Description section
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        .animate()
                        .fadeIn(
                          duration: AppTheme.mediumAnimationDuration,
                          delay: const Duration(milliseconds: 500),
                        )
                        .slideX(
                          begin: -0.1,
                          end: 0,
                          duration: AppTheme.mediumAnimationDuration,
                          delay: const Duration(milliseconds: 500),
                        ),
                        
                        const SizedBox(height: AppTheme.spacingMedium),
                        
                        Text(
                          widget.apk.description.isEmpty
                              ? 'No description available.'
                              : widget.apk.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                        .animate()
                        .fadeIn(
                          duration: AppTheme.mediumAnimationDuration,
                          delay: const Duration(milliseconds: 600),
                        ),
                        
                        const SizedBox(height: AppTheme.spacingLarge),
                        
                        // Technical details section
                        Text(
                          'Technical Details',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        .animate()
                        .fadeIn(
                          duration: AppTheme.mediumAnimationDuration,
                          delay: const Duration(milliseconds: 700),
                        )
                        .slideX(
                          begin: -0.1,
                          end: 0,
                          duration: AppTheme.mediumAnimationDuration,
                          delay: const Duration(milliseconds: 700),
                        ),
                        
                        const SizedBox(height: AppTheme.spacingMedium),
                        
                        // Technical details
                        _buildTechnicalDetails()
                        .animate()
                        .fadeIn(
                          duration: AppTheme.mediumAnimationDuration,
                          delay: const Duration(milliseconds: 800),
                        ),
                        
                        // Show screenshots if available
                        if (widget.apk.screenshots.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.spacingLarge),
                          
                          Text(
                            'Screenshots',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          .animate()
                          .fadeIn(
                            duration: AppTheme.mediumAnimationDuration,
                            delay: const Duration(milliseconds: 900),
                          )
                          .slideX(
                            begin: -0.1,
                            end: 0,
                            duration: AppTheme.mediumAnimationDuration,
                            delay: const Duration(milliseconds: 900),
                          ),
                          
                          const SizedBox(height: AppTheme.spacingMedium),
                          
                          SizedBox(
                            height: 280,
                            child: _buildScreenshotsCarousel(),
                          )
                          .animate()
                          .fadeIn(
                            duration: AppTheme.mediumAnimationDuration,
                            delay: const Duration(milliseconds: 1000),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  /// Build technical details section
  Widget _buildTechnicalDetails() {
    return Card(
      elevation: AppTheme.elevationSmall,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Package Name', widget.apk.packageName),
            const Divider(height: 24),
            _buildDetailRow('Version', '${widget.apk.versionName} (${widget.apk.versionCode})'),
            const Divider(height: 24),
            _buildDetailRow('Min SDK', 'Android ${widget.apk.minSdk}+'),
            const Divider(height: 24),
            _buildDetailRow('Target SDK', 'Android ${widget.apk.targetSdk}'),
            const Divider(height: 24),
            _buildDetailRow('Size', _formatFileSize(widget.apk.sizeBytes)),
            const Divider(height: 24),
            _buildDetailRow('Downloads', widget.apk.downloads.toString()),
            const Divider(height: 24),
            _buildDetailRow('Last Updated', AppHelpers.formatDateTime(widget.apk.updatedAt)),
          ],
        ),
      ),
    );
  }
  
  /// Build a single detail row with label and value
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
  }
  
  /// Format file size to human-readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
  
  /// Build screenshots carousel
  Widget _buildScreenshotsCarousel() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: widget.apk.screenshots.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(right: AppTheme.spacingMedium),
          width: 160,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
          child: GestureDetector(
            onTap: () => _showFullScreenImage(widget.apk.screenshots[index]),
            child: CachedNetworkImage(
              imageUrl: widget.apk.screenshots[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  color: Colors.white,
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(
                  Icons.broken_image,
                  color: AppTheme.errorColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// Show full-screen image viewer
  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: AppTheme.errorColor,
                    size: 64,
                  ),
                ),
              ),
            ),
            
            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.5),
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
