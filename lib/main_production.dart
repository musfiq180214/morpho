
import 'enums.dart';
import 'flavor_config.dart';
import 'main.dart';

void main() async {
  FlavorConfig.instantiate(
    flavor: Flavor.production,
    baseUrl: "",
    appTitle: 'Morpho',
  );
  await morpho();
}