import 'package:flutter/widgets.dart';
import 'package:subs/app/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap();
}
