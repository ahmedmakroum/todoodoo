import 'package:flutter_riverpod/flutter_riverpod.dart';

final focusModeProvider = StateProvider<bool>((ref) => false); // Default to focus mode disabled