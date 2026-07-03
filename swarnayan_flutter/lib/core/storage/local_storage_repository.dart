import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/product.dart';
import '../../models/customer.dart';
import '../../models/invoice.dart';
import '../../models/daily_rate.dart';

class LocalStorageRepository {
  LocalStorageRepository._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Storage keys
  static const _keyProducts = 'swarnayan_products';
  static const _keyCustomers = 'swarnayan_customers';
  static const _keyInvoices = 'swarnayan_invoices';
  static const _keyDailyRates = 'swarnayan_daily_rates';
  static const _keyInitialized = 'swarnayan_db_initialized';

  /// Check and perform initial seeding of data
  static Future<void> checkAndSeed() async {
    final initialized = await _storage.read(key: _keyInitialized);
    if (initialized == 'true') return;

    // Seed Initial Products
    final initialProducts = [
      const Product(
        id: 'BGL-1042',
        name: '22K Antique Bangle',
        category: 'GOLD',
        purity: '22K',
        hsnCode: '7113',
        stockUnits: 3,
        weight: 25.5,
        makingChargeValue: 500,
      ),
      const Product(
        id: 'RNG-8821',
        name: 'Solitaire Ring',
        category: 'DIAMOND',
        purity: '18K',
        hsnCode: '7113',
        stockUnits: 5,
        weight: 4.2,
        makingChargeValue: 12,
        stoneType: 'Diamond',
        stoneWeight: 0.5,
        stoneValue: 65000,
      ),
      const Product(
        id: 'CHN-3301',
        name: '18K Italian Chain',
        category: 'GOLD',
        purity: '18K',
        hsnCode: '7113',
        stockUnits: 2,
        weight: 18.7,
        makingChargeValue: 150,
      ),
      const Product(
        id: 'ANK-1120',
        name: 'Silver Anklet Pair',
        category: 'SILVER',
        purity: 'SILVER_925',
        hsnCode: '7113',
        stockUnits: 8,
        weight: 35.0,
        makingChargeValue: 250,
      ),
      const Product(
        id: 'BND-5501',
        name: 'Platinum Wedding Band',
        category: 'PLATINUM',
        purity: 'OTHER',
        hsnCode: '7113',
        stockUnits: 1,
        weight: 6.8,
        makingChargeValue: 15,
      ),
    ];
    await saveProducts(initialProducts);

    // Seed Initial Customers
    final initialCustomers = [
      Customer(
        id: 'CUST-001',
        name: 'Ananya Sharma',
        mobile: '9876543210',
        email: 'ananya@gmail.com',
        address: 'Sector 15, Dwarka, New Delhi',
        panCard: 'ABCDE1234F',
        totalPurchaseAmount: 245000,
        totalInvoices: 2,
        lastVisitDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Customer(
        id: 'CUST-002',
        name: 'Rahul Mehta',
        mobile: '9823456789',
        email: 'rahul.mehta@yahoo.com',
        address: 'Bandra West, Mumbai',
        totalPurchaseAmount: 185000,
        totalInvoices: 1,
        lastVisitDate: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Customer(
        id: 'CUST-003',
        name: 'Priya Patel',
        mobile: '9812345678',
        email: 'priya.patel@gmail.com',
        address: 'Satellite, Ahmedabad',
        panCard: 'XYZWP5678G',
        totalPurchaseAmount: 520000,
        totalInvoices: 5,
        lastVisitDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
    await saveCustomers(initialCustomers);

    // Seed Initial Rates
    final today = DateTime.now();
    final initialRate = DailyRate(
      id: 'RATE-${today.year}-${today.month}-${today.day}',
      date: DateTime(today.year, today.month, today.day),
      rateGold22K: 6850.0,
      rateGold18K: 5610.0,
      rateSilver: 82.4,
      enteredBy: 'System Seed',
    );
    await saveDailyRates([initialRate]);

    // Seed Initial Invoices
    final initialInvoices = [
      Invoice(
        id: 'INV-2026-001',
        invoiceNumber: 'INV/2026/001',
        customerId: 'CUST-001',
        items: [
          const InvoiceItem(
            productId: 'BGL-1042',
            productName: '22K Antique Bangle',
            hsnCode: '7113',
            category: 'GOLD',
            purity: '22K',
            quantity: 1,
            grossWeight: 25.5,
            netWeight: 25.5,
            rate: 6850.0,
            metalValue: 174675.0,
            makingChargeType: 'FIXED',
            makingChargeValue: 500.0,
            makingChargeTotal: 500.0,
            itemTotal: 175175.0,
          ),
          const InvoiceItem(
            productId: 'CHN-3301',
            productName: '18K Italian Chain',
            hsnCode: '7113',
            category: 'GOLD',
            purity: '18K',
            quantity: 1,
            grossWeight: 10.0,
            netWeight: 10.0,
            rate: 5610.0,
            metalValue: 56100.0,
            makingChargeType: 'PER_GRAM',
            makingChargeValue: 150.0,
            makingChargeTotal: 1500.0,
            itemTotal: 57600.0,
          ),
        ],
        grossAmount: 232775.0,
        taxableAmount: 232775.0,
        cgst: 3491.62,
        sgst: 3491.62,
        totalTax: 6983.24,
        netAmount: 239758.24,
        finalPayable: 239758.0,
        payments: const [
          Payment(method: 'CASH', amount: 59758.0),
          Payment(method: 'UPI', amount: 180000.0),
        ],
        totalAmountPaid: 239758.0,
        balanceDue: 0.0,
        invoiceDate: DateTime.now().subtract(const Duration(days: 2)),
        status: 'PAID',
        ratesSnapshot: const RatesSnapshot(
          rateGold22K: 6850.0,
          rateGold18K: 5610.0,
          rateSilver: 82.4,
        ),
      ),
    ];
    await saveInvoices(initialInvoices);

    await _storage.write(key: _keyInitialized, value: 'true');
  }

  // ── Products CRUD ──

  static Future<List<Product>> getProducts() async {
    final jsonStr = await _storage.read(key: _keyProducts);
    if (jsonStr == null) return [];
    try {
      final list = json.decode(jsonStr) as List;
      return list.map((item) => Product.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveProducts(List<Product> products) async {
    final jsonStr = json.encode(products.map((p) => p.toJson()).toList());
    await _storage.write(key: _keyProducts, value: jsonStr);
  }

  static Future<void> saveProduct(Product product) async {
    final list = await getProducts();
    final index = list.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      list[index] = product;
    } else {
      list.add(product);
    }
    await saveProducts(list);
  }

  static Future<void> deleteProduct(String id) async {
    final list = await getProducts();
    list.removeWhere((p) => p.id == id);
    await saveProducts(list);
  }

  // ── Customers CRUD ──

  static Future<List<Customer>> getCustomers() async {
    final jsonStr = await _storage.read(key: _keyCustomers);
    if (jsonStr == null) return [];
    try {
      final list = json.decode(jsonStr) as List;
      return list.map((item) => Customer.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCustomers(List<Customer> customers) async {
    final jsonStr = json.encode(customers.map((c) => c.toJson()).toList());
    await _storage.write(key: _keyCustomers, value: jsonStr);
  }

  static Future<void> saveCustomer(Customer customer) async {
    final list = await getCustomers();
    final index = list.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      list[index] = customer;
    } else {
      list.add(customer);
    }
    await saveCustomers(list);
  }

  static Future<void> deleteCustomer(String id) async {
    final list = await getCustomers();
    list.removeWhere((c) => c.id == id);
    await saveCustomers(list);
  }

  // ── Invoices CRUD ──

  static Future<List<Invoice>> getInvoices() async {
    final jsonStr = await _storage.read(key: _keyInvoices);
    if (jsonStr == null) return [];
    try {
      final list = json.decode(jsonStr) as List;
      return list.map((item) => Invoice.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveInvoices(List<Invoice> invoices) async {
    final jsonStr = json.encode(invoices.map((i) => i.toJson()).toList());
    await _storage.write(key: _keyInvoices, value: jsonStr);
  }

  static Future<void> saveInvoice(Invoice invoice) async {
    final list = await getInvoices();
    final index = list.indexWhere((i) => i.id == invoice.id);
    if (index != -1) {
      list[index] = invoice;
    } else {
      list.add(invoice);
    }
    await saveInvoices(list);
  }

  // ── Daily Rates CRUD ──

  static Future<List<DailyRate>> getDailyRates() async {
    final jsonStr = await _storage.read(key: _keyDailyRates);
    if (jsonStr == null) return [];
    try {
      final list = json.decode(jsonStr) as List;
      return list.map((item) => DailyRate.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveDailyRates(List<DailyRate> rates) async {
    final jsonStr = json.encode(rates.map((r) => r.toJson()).toList());
    await _storage.write(key: _keyDailyRates, value: jsonStr);
  }

  static Future<void> saveDailyRate(DailyRate rate) async {
    final list = await getDailyRates();
    final index = list.indexWhere((r) =>
        r.date.year == rate.date.year &&
        r.date.month == rate.date.month &&
        r.date.day == rate.date.day);
    if (index != -1) {
      list[index] = rate;
    } else {
      list.add(rate);
    }
    await saveDailyRates(list);
  }
}
