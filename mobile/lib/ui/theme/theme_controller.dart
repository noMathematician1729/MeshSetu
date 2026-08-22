import 'package:flutter_riverpod/flutter_riverpod.dart';

final darkModeProvider = StateProvider<bool>((ref) => false);
final highContrastProvider = StateProvider<bool>((ref) => false);
final fontScaleProvider = StateProvider<double>((ref) => 1);
final sosTimeoutProvider = StateProvider<double>((ref) => 3);
final locationSharingProvider = StateProvider<bool>((ref) => true);
