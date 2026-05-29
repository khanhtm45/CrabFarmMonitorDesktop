import 'auth_models.dart';

class FarmRecord {
  const FarmRecord({
    required this.id,
    required this.code,
    required this.name,
    this.address,
    this.description,
    this.ownerId,
    this.createdAt,
  });

  final String id;
  final String code;
  final String name;
  final String? address;
  final String? description;
  final String? ownerId;
  final DateTime? createdAt;

  factory FarmRecord.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    final raw = json['createdAt'] ?? json['CreatedAt'];
    if (raw != null) created = DateTime.tryParse(raw.toString());

    return FarmRecord(
      id: (json['id'] ?? json['Id']).toString(),
      code: (json['code'] ?? json['Code'] ?? '').toString(),
      name: (json['name'] ?? json['Name'] ?? 'Farm').toString(),
      address: (json['address'] ?? json['Address'])?.toString(),
      description: (json['description'] ?? json['Description'])?.toString(),
      ownerId: (json['ownerId'] ?? json['OwnerId'])?.toString(),
      createdAt: created,
    );
  }

  FarmSummary toSummary() => FarmSummary(id: id, code: code, name: name);
}
