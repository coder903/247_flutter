import 'base_model.dart';

class Customer extends BaseModel {
  final String? companyName;
  final String contactName;
  final String email;
  final String? phone;
  final String? phoneSecondary;
  final String? billingAddress;
  final String? billingCity;
  final String? billingState;
  final String? billingZip;
  final bool portalAccess;

  Customer({
    super.id,
    super.serverId,
    this.companyName,
    required this.contactName,
    required this.email,
    this.phone,
    this.phoneSecondary,
    this.billingAddress,
    this.billingCity,
    this.billingState,
    this.billingZip,
    this.portalAccess = false,
    super.createdAt,
    super.updatedAt,
    super.syncStatus,
    super.deleted,
  });

  /// Create Customer from SQLite map
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      companyName: map['company_name'] as String?,
      contactName: map['contact_name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      phoneSecondary: map['phone_secondary'] as String?,
      billingAddress: map['billing_address'] as String?,
      billingCity: map['billing_city'] as String?,
      billingState: map['billing_state'] as String?,
      billingZip: map['billing_zip'] as String?,
      portalAccess: map['portal_access'] == 1,
      createdAt: BaseModel.parseDateTime(map['created_at'] as String?),
      updatedAt: BaseModel.parseDateTime(map['updated_at'] as String?),
      syncStatus: map['sync_status'] as String? ?? 'pending',
      deleted: map['deleted'] == 1,
    );
  }

  /// Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      'company_name': companyName,
      'contact_name': contactName,
      'email': email,
      'phone': phone,
      'phone_secondary': phoneSecondary,
      'billing_address': billingAddress,
      'billing_city': billingCity,
      'billing_state': billingState,
      'billing_zip': billingZip,
      'portal_access': portalAccess ? 1 : 0,
      'created_at': BaseModel.formatDateTime(createdAt),
      'updated_at': BaseModel.formatDateTime(updatedAt),
      'sync_status': syncStatus,
      'deleted': deleted ? 1 : 0,
    };
  }

  /// Create copy with updated fields
  Customer copyWith({
    int? id,
    int? serverId,
    String? companyName,
    String? contactName,
    String? email,
    String? phone,
    String? phoneSecondary,
    String? billingAddress,
    String? billingCity,
    String? billingState,
    String? billingZip,
    bool? portalAccess,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    bool? deleted,
  }) {
    return Customer(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      companyName: companyName ?? this.companyName,
      contactName: contactName ?? this.contactName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      phoneSecondary: phoneSecondary ?? this.phoneSecondary,
      billingAddress: billingAddress ?? this.billingAddress,
      billingCity: billingCity ?? this.billingCity,
      billingState: billingState ?? this.billingState,
      billingZip: billingZip ?? this.billingZip,
      portalAccess: portalAccess ?? this.portalAccess,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      deleted: deleted ?? this.deleted,
    );
  }

  /// Get display name (company name if available, otherwise contact name)
  String get displayName => companyName ?? contactName;

  /// Get full billing address
  String get billingAddressFull {
    final parts = <String>[
      if (billingAddress != null) billingAddress!,
      if (billingCity != null) billingCity!,
      if (billingState != null && billingZip != null) '$billingState $billingZip',
    ];
    return parts.join(', ');
  }

  /// Get primary phone for display
  String? get primaryPhone => phone ?? phoneSecondary;

  @override
  String toString() => 'Customer(id: $id, name: $displayName)';
}