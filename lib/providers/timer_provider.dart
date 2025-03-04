import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';

final totalWorkTimeProvider = StateProvider<int>((ref) => 1500);
final remainingTimeProvider = StateProvider<int>((ref) => 1500);
final progressProvider = StateProvider<double>((ref) => 0.0);
final isRunningProvider = StateProvider<bool>((ref) => false);