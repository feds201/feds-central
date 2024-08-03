String correctJsonFormat(String jsonString) {
  // Adjusting the regex to correctly format the jsonString
  var correctedData = jsonString
      .replaceAllMapped(RegExp(r'(\w+)\.'), (match) => '${match[1]}')
      .replaceAllMapped(RegExp(r'(\w+):'), (match) => '"${match[1]}":')
      .replaceAllMapped(RegExp(r': (\w+)'), (match) => ': "${match[1]}"')
      .replaceAll("'", '"');
  return correctedData;
}
