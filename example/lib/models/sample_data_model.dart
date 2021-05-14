import 'package:premo_table/premo_table.dart';

class SampleDataModel implements IUniqueIdentifier {
  String id;
  String? parentId;
  String? name;
  num? age;
  bool? enabled;
  DateTime? dateOfBirth;
  String? city;
  num? salary;

  SampleDataModel({
    required this.id,
    this.parentId,
    this.name,
    this.age,
    this.enabled,
    this.dateOfBirth,
    this.city,
    this.salary,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'name': name,
      'age': age,
      'enabled': enabled,
      'dateOfBirth': dateOfBirth,
      'city': city,
      'salary': salary,
    };
  }

  SampleDataModel.clone(SampleDataModel b)
      : this(
          id: b.id,
          parentId: b.parentId,
          name: b.name,
          age: b.age,
          enabled: b.enabled,
          dateOfBirth: b.dateOfBirth,
          city: b.city,
          salary: b.salary,
        );
}
