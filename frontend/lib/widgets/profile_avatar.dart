import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frontend/providers/user_provider.dart';

/// A reusable profile avatar widget with caching and error handling
class ProfileAvatar extends ConsumerWidget {
  final String? photoUrl;
  final double radius;
  final IconData fallbackIcon;
  final double? fallbackIconSize;

  const ProfileAvatar({
    super.key,
    required this.photoUrl,
    this.radius = 20,
    this.fallbackIcon = Icons.person,
    this.fallbackIconSize,
  });

  /// Optimizes Google profile image URLs to request smaller sizes
  String _optimizeImageUrl(String url) {
    // If it's a Google profile image, modify the size parameter
    if (url.contains('googleusercontent.com')) {
      // Remove existing size parameter (e.g., =s96-c)
      final baseUrl = url.split('=')[0];
      // Request a smaller size to reduce bandwidth and avoid rate limits
      // s96-c means 96x96 pixels with crop
      return '$baseUrl=s${(radius * 2).toInt()}-c';
    }
    return url;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Try to get cached photo data first
    final cachedPhotoData = ref.watch(userPhotoDataProvider);

    // If we have cached base64 data, use it directly (NO NETWORK REQUEST!)
    if (cachedPhotoData != null && cachedPhotoData.isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(cachedPhotoData);
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(bytes),
          backgroundColor: Colors.grey[300],
        );
      } catch (e) {
        debugPrint('Error decoding cached photo: $e');
        // Fall through to network loading
      }
    }

    // If no photo URL, show fallback immediately
    if (photoUrl == null || photoUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        child: Icon(fallbackIcon, size: fallbackIconSize ?? radius),
      );
    }

    // Last resort: try to load from network (may hit 429)
    final optimizedUrl = _optimizeImageUrl(photoUrl!);

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: optimizedUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          memCacheWidth: (radius * 2 * 2).toInt(),
          memCacheHeight: (radius * 2 * 2).toInt(),
          maxWidthDiskCache: (radius * 2 * 2).toInt(),
          maxHeightDiskCache: (radius * 2 * 2).toInt(),
          fadeInDuration: const Duration(milliseconds: 300),
          cacheKey: optimizedUrl,
          useOldImageOnUrlChange: true,
          placeholder: (context, url) => Center(
            child: SizedBox(
              width: radius * 0.6,
              height: radius * 0.6,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey[600],
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            debugPrint('Failed to load profile image: $error');
            return Icon(
              fallbackIcon,
              size: fallbackIconSize ?? radius,
              color: Colors.grey[600],
            );
          },
        ),
      ),
    );
  }
}
