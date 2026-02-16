enum FieldType {
  text,
  number,
  boolean,
  datetime,
  enumType,
  multiEnum,
  list,
  reference,
  image,
  location,
  duration,
  currency,
  rating,
  url,
  phone,
  email;

  static FieldType fromString(String value) {
    return FieldType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FieldType.text,
    );
  }

  String toJson() => name;
}
