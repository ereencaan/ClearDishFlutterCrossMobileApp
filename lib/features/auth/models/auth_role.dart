enum AuthRole {
  user,
  restaurant,
  admin,
}

extension AuthRoleLabel on AuthRole {
  String get label {
    switch (this) {
      case AuthRole.user:
        return 'User';
      case AuthRole.restaurant:
        return 'Restaurant';
      case AuthRole.admin:
        return 'Admin';
    }
  }
}
