class ApiEndpoints {
  ApiEndpoints._();

  static String get baseUrl {
    return 'https://swarnayanjewellers-backend.hf.space/api/v1';
  }

  // Auth
  static const String login = '/auth/login';
  static const String profile = '/auth/profile';
  static const String changePassword = '/auth/change-password';

  // Staff User Management
  static const String users = '/users';
  static const String updateStaffPassword = '/users/staff/password';

  // Company
  static const String company = '/company';

  // Rates
  static const String ratesToday = '/rates/today';
  static const String ratesHistory = '/rates/history';
  static const String rates = '/rates';

  // Customers
  static const String customers = '/customers';
  static String customerLookup(String mobile) => '/customers/lookup/$mobile';
  static String pincodeLookup(String pincode) => '/customers/pincode/$pincode';

  // Products
  static const String products = '/products';
  static const String productStockAdjustment = '/products/stock/adjustment';

  // Invoices
  static const String invoices = '/invoices';
  static const String invoiceCalculate = '/invoices/calculate';
  static String invoicePdf(String id) => '/invoices/$id/pdf';
  static String invoiceCancel(String id) => '/invoices/$id/cancel';
  static String invoiceDelete(String id) => '/invoices/$id';
  static String invoiceRestore(String id) => '/invoices/$id/restore';
  static const String deletedInvoices = '/invoices/deleted';

  // Inventory
  static const String inventorySummary = '/inventory/summary';
  static const String inventoryLowStock = '/inventory/low-stock';

  // Record Book (Expenses/Income)
  static const String recordBook = '/record-book';

  // Coupons
  static const String coupons = '/coupons';
  static String couponValidate(String code) => '/coupons/validate/$code';

  // Dashboard
  static const String dashboardStats = '/dashboard/stats';
}
