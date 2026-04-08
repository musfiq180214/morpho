
import 'enums.dart';

class FlavorConfig {
  final Flavor flavor;
  final String baseUrl;
  final String appTitle;

  static FlavorConfig? _instance;

  FlavorConfig._internal(this.flavor, this.baseUrl, this.appTitle);

  static void instantiate({
    required Flavor flavor,
    required String baseUrl,
    required String appTitle,
  }) {
    _instance = FlavorConfig._internal(flavor, baseUrl, appTitle);
  }

  static FlavorConfig get instance {
    return _instance!;
  }

  static bool isStaging() => _instance?.flavor == Flavor.staging;
  static bool isProduction() => _instance?.flavor == Flavor.production;
}