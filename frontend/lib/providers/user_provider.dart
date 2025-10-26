import 'package:flutter_riverpod/flutter_riverpod.dart';

// This simple provider will just hold the user's display name.
final userNameProvider = StateProvider<String?>((ref) => null);

// This will hold the user's unique Google ID
final userIdProvider = StateProvider<String?>((ref) => null);

// This will hold the user's email
final userEmailProvider = StateProvider<String?>((ref) => null);

// This will hold the user's photo URL
final userPhotoUrlProvider = StateProvider<String?>((ref) => null);

// This will hold the user's cached photo data (base64)
final userPhotoDataProvider = StateProvider<String?>((ref) => null);
