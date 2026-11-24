class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final bool isActive;
  final String? phone;
  final String preferredCurrency;
  final String preferredLanguage;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.isActive = true,
    this.phone,
    this.preferredCurrency = 'INR',
    this.preferredLanguage = 'en',
  });

  bool get isAdmin => role == 'ADMIN';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'USER',
      isActive: json['is_active'] ?? true,
      phone: json['phone'],
      preferredCurrency: json['preferred_currency'] ?? 'INR',
      preferredLanguage: json['preferred_language'] ?? 'en',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'role': role,
      'is_active': isActive,
      'phone': phone,
      'preferred_currency': preferredCurrency,
      'preferred_language': preferredLanguage,
    };
  }
}
