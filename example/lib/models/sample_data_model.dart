import 'package:premo_table/premo_table.dart';

class SampleDataModel implements IUniqueIdentifier {
  String uid;
  String? name;
  num? age;
  bool? enabled;
  DateTime? dateOfBirth;
  String? city;

  SampleDataModel({
    required this.uid,
    this.name,
    this.age,
    this.enabled,
    this.dateOfBirth,
    this.city,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'age': age,
      'enabled': enabled,
      'dateOfBirth': dateOfBirth,
      'city': city,
    };
  }
}
