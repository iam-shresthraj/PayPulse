class Validators {
  Validators._();

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email is optional in many retail scenarios
    }
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    final mobileRegExp = RegExp(r'^[6-9]\d{9}$');
    if (!mobileRegExp.hasMatch(value.trim())) {
      return 'Enter a valid 10-digit Indian mobile number';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validatePAN(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional but must be valid if provided
    }
    final panRegExp = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    if (!panRegExp.hasMatch(value.trim().toUpperCase())) {
      return 'Enter a valid 10-character PAN number (e.g. ABCDE1234F)';
    }
    return null;
  }

  static String? validateGSTIN(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional but must be valid if provided
    }
    final gstinRegExp = RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}[Z]{1}[A-Z\d]{1}$');
    if (!gstinRegExp.hasMatch(value.trim().toUpperCase())) {
      return 'Enter a valid 15-digit GSTIN (e.g. 22AAAAA0000A1Z5)';
    }
    return null;
  }
}
