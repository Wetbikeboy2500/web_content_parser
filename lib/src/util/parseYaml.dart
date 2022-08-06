import 'package:yaml/yaml.dart';

///Parses a yaml file into a standard formatted map
///This allows for easier predictability of the data conversions
Map<String, dynamic> parseYaml(String input) {
  final yaml = loadYaml(input);

  if (yaml is! YamlMap) {
    throw Exception('Yaml is not a map');
  }

  late final convertMapList;

  convertMapList = (dynamic value) {
    if (value is YamlList) {
      return value.map(convertMapList).toList();
    }

    if (value is YamlMap) {
      return Map.fromEntries(value.entries.map((e) {
        return MapEntry(e.key.toString(), convertMapList(e.value));
      }));
    }

    return value;
  };

  return convertMapList(yaml);
}
