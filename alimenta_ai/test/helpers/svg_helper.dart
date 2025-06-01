import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAssetBundle extends Fake implements AssetBundle {
  @override
  Future<String> loadString(String key) async {
    if (key.endsWith('.svg')) {
      return '''
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
          <rect width="24" height="24" fill="none"/>
        </svg>
      ''';
    }
    throw FlutterError('Asset $key not found');
  }

  @override
  Future<ByteData> load(String key) async {
    return ByteData(0);
  }
}

void mockSvgAssets() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
    return null;
  });
}
