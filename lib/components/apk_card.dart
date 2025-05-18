import 'package:flutter/material.dart';
import '../core/models/apk_model.dart';
import '../utils/helpers.dart';

/// A modern card component for displaying APK items
class APKCard extends StatelessWidget {
  final APKModel apk;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;
  final VoidCallback? onDetails;
  final bool showActions;
  final bool showDownloads;
  final bool isAdmin;

  const APKCard({
    super.key,
    required this.apk,
    this.onTap,
    this.onDownload,
    this.onDetails,
    this.showActions = true,
    this.showDownloads = true,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with app icon and basic info
            _buildHeader(colorScheme),
            
            // Description
            if (apk.description != null && apk.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  apk.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              
            // Stats and metadata
            _buildMetadata(theme, colorScheme),
            
            // Actions
            if (showActions)
              _buildActions(colorScheme),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App icon
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: apk.iconUrl != null && apk.iconUrl!.isNotEmpty
                ? Image.network(
                    apk.iconUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 60,
                      color: colorScheme.primaryContainer,
                      child: Icon(
                        Icons.android,
                        color: colorScheme.primary,
                        size: 32,
                      ),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.android,
                      color: colorScheme.primary,
                      size: 32,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          
          // App info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        apk.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (apk.isPinned ?? false)
                      Icon(
                        Icons.push_pin,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  apk.packageName,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'v${apk.versionName}',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (apk.versionCode != null)
                      Text(
                        ' (${apk.versionCode})',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetadata(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Size information
          if (apk.sizeBytes != null && apk.sizeBytes! > 0)
            _buildMetadataItem(
              icon: Icons.sd_storage_outlined,
              label: AppHelpers.formatFileSize(apk.sizeBytes!),
              colorScheme: colorScheme,
            ),
            
          // SDK information
          if (apk.minSdk != null)
            _buildMetadataItem(
              icon: Icons.android_outlined,
              label: 'API ${apk.minSdk}+',
              colorScheme: colorScheme,
            ),
            
          // Downloads count
          if (showDownloads && apk.downloads != null)
            _buildMetadataItem(
              icon: Icons.download_outlined,
              label: '${apk.downloads}',
              colorScheme: colorScheme,
            ),
        ],
      ),
    );
  }
  
  Widget _buildMetadataItem({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
  
  Widget _buildActions(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (onDetails != null)
            TextButton(
              onPressed: onDetails,
              child: const Text('Details'),
            ),
          if (onDownload != null)
            FilledButton.icon(
              onPressed: onDownload,
              icon: const Icon(Icons.download),
              label: const Text('Download'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          if (isAdmin)
            IconButton(
              onPressed: onTap,
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
            ),
        ],
      ),
    );
  }
} 