import 'dart:io';

void main() async {
  const String projectRoot = 'd:/company workspace/disaster_management';
  const String templatePath = '$projectRoot/lib/core/config/secrets.template.dart';
  const String secretsPath = '$projectRoot/lib/core/config/secrets.dart';

  if (!File(secretsPath).existsSync()) {
    await File(templatePath).copy(secretsPath);
    print('✓ Created secrets.dart from template');
    print('! Please update lib/core/config/secrets.dart with your actual API keys');
  } else {
    print('! secrets.dart already exists. Skipping creation.');
  }
}