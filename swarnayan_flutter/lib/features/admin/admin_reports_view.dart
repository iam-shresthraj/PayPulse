import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' hide Border;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/utils/file_saver_helper.dart';
import 'admin_provider.dart';

class AdminReportsView extends ConsumerStatefulWidget {
  const AdminReportsView({super.key});

  @override
  ConsumerState<AdminReportsView> createState() => _AdminReportsViewState();
}

class _AdminReportsViewState extends ConsumerState<AdminReportsView> {
  bool _exportingCompany = false;
  bool _exportingCustomer = false;

  CellStyle _headerStyle() {
    return CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1A237E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );
  }

  Future<void> _exportCompanyReport(AdminState state) async {
    setState(() => _exportingCompany = true);
    try {
      final excel = Excel.createExcel();
      const sheetName = 'Company Report';
      excel.rename(excel.getDefaultSheet()!, sheetName);
      final sheet = excel[sheetName];

      final headers = [
        'Company Name',
        'Category',
        'Date Joined',
        'Renew Date',
        'Owners',
        'Managers',
        'Staff',
        'Total Users',
        'Customers',
      ];
      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = _headerStyle();
      }

      int rowIndex = 1;
      for (final company in state.companies) {
        final companyUsers = state.users.where((u) => u.companyId == company.id).toList();
        final ownerCount = companyUsers.where((u) => u.role == 'OWNER').length;
        final managerCount = companyUsers.where((u) => u.role == 'MANAGER').length;
        final staffCount = companyUsers.where((u) => u.role == 'STAFF').length;
        final customerCount = state.customers.where((c) => c.companyId == company.id).length;

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(company.name);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue(company.category);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = TextCellValue(DateFormat('dd/MM/yyyy').format(company.createdAt));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = TextCellValue(
          company.renewDate != null ? DateFormat('dd/MM/yyyy').format(company.renewDate!) : 'Not Set',
        );
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = IntCellValue(ownerCount);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = IntCellValue(managerCount);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = IntCellValue(staffCount);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).value = IntCellValue(companyUsers.length);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex)).value = IntCellValue(customerCount);
        rowIndex++;
      }

      final bytes = excel.save();
      if (bytes != null) {
        await FileSaverHelper.saveExcelFile(
          bytes,
          'PayPulse_Company_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Company Report exported!'), backgroundColor: AppColors.success),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _exportingCompany = false);
    }
  }

  Future<void> _exportCustomerReport(AdminState state) async {
    setState(() => _exportingCustomer = true);
    try {
      final excel = Excel.createExcel();
      // Remove default empty sheet later
      final defaultSheet = excel.getDefaultSheet()!;

      final customerHeaders = [
        'Customer Name',
        'Mobile',
        'Email',
        'Address',
        'Pincode',
        'Date Added',
      ];

      bool firstSheet = true;

      for (final company in state.companies) {
        final companyCustomers = state.customers.where((c) => c.companyId == company.id).toList();
        // Use truncated name for sheet tab (max 31 chars Excel limit)
        final tabName = company.name.length > 28 ? '${company.name.substring(0, 28)}...' : company.name;

        if (firstSheet) {
          excel.rename(defaultSheet, tabName);
          firstSheet = false;
        } else {
          excel.copy(defaultSheet, tabName);
        }

        final sheet = excel[tabName];

        for (var i = 0; i < customerHeaders.length; i++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
          cell.value = TextCellValue(customerHeaders[i]);
          cell.cellStyle = _headerStyle();
        }

        int rowIndex = 1;
        for (final customer in companyCustomers) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(customer.name);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue(customer.mobile);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = TextCellValue(customer.email ?? '');
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = TextCellValue(customer.address ?? '');
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = TextCellValue(customer.pincode ?? '');
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = TextCellValue(
            customer.createdAt != null ? DateFormat('dd/MM/yyyy').format(customer.createdAt!) : '',
          );
          rowIndex++;
        }
      }

      final bytes = excel.save();
      if (bytes != null) {
        await FileSaverHelper.saveExcelFile(
          bytes,
          'PayPulse_Customer_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Customer Report exported (one tab per company)!'), backgroundColor: AppColors.success),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _exportingCustomer = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Admin Reports',
                  style: AppTextStyles.headlineLgMobile.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => ref.read(adminProvider.notifier).loadAdminData(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Report
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.business_rounded, color: AppColors.primary, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Company Report',
                                    style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Export a complete list of all registered companies including their category, join date, subscription renewal date, and role-wise user counts (owners, managers, staff). Does not include any financial or invoice data.',
                                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(Icons.table_chart_rounded, size: 14, color: AppColors.onSurfaceMuted),
                            const SizedBox(width: 6),
                            Text(
                              '${state.companies.length} companies • Single sheet',
                              style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _exportingCompany ? null : () => _exportCompanyReport(state),
                            icon: _exportingCompany
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                            label: Text(
                              _exportingCompany ? 'Exporting...' : 'Export Company Report (.xlsx)',
                              style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Customer Report
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.people_alt_rounded, color: AppColors.success, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Customer Report',
                                    style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Export all customers grouped by company, with each company on a separate tab in the Excel file. Includes customer name, mobile, email, address, and date added.',
                                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(Icons.table_chart_rounded, size: 14, color: AppColors.onSurfaceMuted),
                            const SizedBox(width: 6),
                            Text(
                              '${state.customers.length} customers • ${state.companies.length} tabs (one per company)',
                              style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _exportingCustomer ? null : () => _exportCustomerReport(state),
                            icon: _exportingCustomer
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                            label: Text(
                              _exportingCustomer ? 'Exporting...' : 'Export Customer Report (.xlsx)',
                              style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
