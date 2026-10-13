import 'package:equatable/equatable.dart';

class Member extends Equatable {
  final int? id;
  final int? remoteId;
  final String memberNo;
  final String? nik;
  final String name;
  final String? phone;
  final String? email;
  final String? department;
  final double savingsBalance;
  final double creditLimit;
  final bool isActive;

  const Member({
    this.id,
    this.remoteId,
    required this.memberNo,
    this.nik,
    required this.name,
    this.phone,
    this.email,
    this.department,
    this.savingsBalance = 0,
    this.creditLimit = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'remote_id': remoteId,
      'member_no': memberNo,
      'nik': nik,
      'name': name,
      'phone': phone,
      'email': email,
      'department': department,
      'savings_balance': savingsBalance,
      'credit_limit': creditLimit,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'] as int?,
      remoteId: map['remote_id'] as int?,
      memberNo: (map['member_no'] as String?) ?? '',
      nik: map['nik'] as String?,
      name: (map['name'] as String?) ?? '',
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      department: map['department'] as String?,
      savingsBalance: ((map['savings_balance'] ?? 0) as num).toDouble(),
      creditLimit: ((map['credit_limit'] ?? 0) as num).toDouble(),
      isActive: (map['is_active'] == 1 || map['is_active'] == true),
    );
  }

  factory Member.fromRemoteJson(Map<String, dynamic> json) {
    return Member(
      remoteId: json['id'] as int?,
      memberNo: (json['member_no'] as String?) ?? '',
      nik: json['nik'] as String?,
      name: (json['name'] as String?) ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      department: json['department'] as String?,
      savingsBalance: ((json['savings_balance'] ?? 0) as num).toDouble(),
      creditLimit: ((json['credit_limit'] ?? 0) as num).toDouble(),
      isActive: (json['is_active'] == 1 || json['is_active'] == true),
    );
  }

  @override
  List<Object?> get props => [id, remoteId, memberNo, name, savingsBalance];
}
