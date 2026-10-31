import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/storage/secure_storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = SecureStorageService();
  Get.put<SecureStorageService>(storage, permanent: true);
  Get.put<ApiClient>(ApiClient(storage), permanent: true);

  runApp(const LoanApp());
}
