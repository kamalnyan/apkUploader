import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../core/models/apk_model.dart';
import '../core/theme.dart';
import '../utils/helpers.dart';

/// A card widget for displaying APK information
class APKCard extends StatelessWidget {
  final APKModel apk;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTogglePin;
  final bool showActions;
  final bool isAdmin;
  final bool isViewer;
  final int index;

  /// Constructor
  const APKCard({
    super.key,
    required this.apk,
    this.onTap,
    this.onDownload,
    this.onEdit,
    this.onDelete,
    this.onTogglePin,
    this.showActions = true,
    this.isAdmin = false,
    this.isViewer = false,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: AppTheme.elevationSmall,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMedium,
        vertical: AppTheme.spacingSmall,
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            // Pinned label if the APK is pinned
            if (apk.isPinned)
              Container(
                width: double.infinity,
                color: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingXs,
                  horizontal: AppTheme.spacingMedium,
                ),
                child: Text(
                  'Pinned',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
              
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // APK icon
                  Hero(
                    tag: 'apk-icon-${apk.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                      child: CachedNetworkImage(
                        imageUrl: apk.iconUrl ?? '',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 60,
                            height: 60,
                            color: Colors.white,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 60,
                          height: 60,
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          child: const Icon(
                            Icons.android,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMedium),
                  
                  // APK information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // APK name
                        Hero(
                          tag: 'apk-name-${apk.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              apk.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXs),
                        
                        // APK description
                        Text(
                          apk.description,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppTheme.spacingXs),
                        
                        // APK upload date
                        Text(
                          'Uploaded: ${AppHelpers.formatDateTime(apk.uploadedAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textLightColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Download button (for non-admin)
                  if (showActions && !isAdmin && onDownload != null) ...[
                    const SizedBox(width: AppTheme.spacingSmall),
                    Tooltip(
                      message: 'Download and install with real-time progress tracking',
                      child: AppTheme.successButton(
                        text: 'Install',
                        onPressed: onDownload!,
                        icon: Icons.system_update_alt,
                        compact: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Admin actions (for admin)
            if (showActions && isAdmin)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMedium,
                  vertical: AppTheme.spacingSmall,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: theme.dividerTheme.color ?? Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Edit button
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 20),
                      tooltip: 'Edit',
                      color: AppTheme.infoColor,
                    ),
                    
                    // Toggle pin button
                    IconButton(
                      onPressed: onTogglePin,
                      icon: Icon(
                        apk.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 20,
                      ),
                      tooltip: apk.isPinned ? 'Unpin' : 'Pin',
                      color: apk.isPinned ? AppTheme.warningColor : AppTheme.textLightColor,
                    ),
                    
                    // Delete button
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 20),
                      tooltip: 'Delete',
                      color: AppTheme.errorColor,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(
      duration: AppTheme.mediumAnimationDuration,
      delay: Duration(milliseconds: 50 * index),
    )
    .slideY(
      begin: 0.2,
      end: 0,
      duration: AppTheme.mediumAnimationDuration,
      delay: Duration(milliseconds: 50 * index),
      curve: Curves.easeOutQuad,
    );
  }
} 