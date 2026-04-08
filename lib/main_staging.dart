
import 'enums.dart';
import 'flavor_config.dart';
import 'main.dart';

void main() async {
  FlavorConfig.instantiate(
    flavor: Flavor.staging,
    baseUrl: "",
    appTitle: 'Morpho (Staging)',
  );
  await morpho();
}