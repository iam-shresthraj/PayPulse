import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' hide Border;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/utils/file_saver_helper.dart';
import '../../models/user.dart';
import 'admin_provider.dart';

class AdminReportsView extends ConsumerStatefulWidget {
  const AdminReportsView({super.key});

  @override
  ConsumerState<AdminReportsView> createState() => _AdminReportsViewState();
}

class _AdminReportsViewState extends ConsumerState<AdminReportsView> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  String _selectedCompanyId = 'ALL';
  String _selectedStatus = 'ALL';

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  List<AdminInvoice> _getFilteredInvoices(AdminState state) {
    final startOfDay = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final endOfDay = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

    return state.invoices.where((inv) {
      // Date filter
      final dateMatch = inv.invoiceDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
          inv.invoiceDate.isBefore(endOfDay.add(const Duration(seconds: 1))) &&
          inv.deletedAt == null;
      if (!dateMatch) return false;

      // Company filter
      if (_selectedCompanyId != 'ALL' && inv.companyId != _selectedCompanyId) return false;

      // Status filter
      if (_selectedStatus != 'ALL') {
        final isPaid = inv.balanceDue <= 0.05 && inv.status != 'CANCELLED';
        final isPartial = inv.balanceDue > 0.05 && inv.status != 'CANCELLED';
        final isCancelled = inv.status == 'CANCELLED';
        if (_selectedStatus == 'PAID' && !isPaid) return false;
        if (_selectedStatus == 'PARTIAL' && !isPartial) return false;
        if (_selectedStatus == 'CANCELLED' && !isCancelled) return false;
      }

      return true;
    }).toList();
  }

  String _getCompanyName(AdminState state, String companyId) {
    final company = state.companies.firstWhere(
      (c) => c.id == companyId,
      orElse: () => AdminBusiness(id: '', name: 'Unknown', staffCode: '', managerCode: '', ownerCode: '', createdAt: DateTime.now()),
    );
    return company.name;
  }

  Future<void> _exportSystemAuditExcel(AdminState state) async {
    final excel = Excel.createExcel();
    final sheetName = 'System Audit Report';
    excel.rename(excel.getDefaultSheet()!, sheetName);
    final sheet = excel[sheetName];

    // Header
    final headers = ['Business Name', 'Active Users', 'Total Invoices', 'Total Revenue (₹)', 'Total Collected (₹)', 'Total Outstanding (₹)'];
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
    }

    // Data per company
    int rowIndex = 1;
    for (final company in state.companies) {
      final companyUsers = state.users.where((User u) => u.companyId == company.id && u.isActive).length;
      final companyInvoices = state.invoices.where((i) => i.companyId == company.id && i.deletedAt == null).toList();
      final totalRevenue = companyInvoices.fold(0.0, (sum, i) => sum + i.finalPayable);
      final totalCollected = companyInvoices.fold(0.0, (sum, i) => sum + i.totalAmountPaid);
      final totalOutstanding = companyInvoices.fold(0.0, (sum, i) => sum + i.balanceDue);

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(company.name);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = IntCellValue(companyUsers);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = IntCellValue(companyInvoices.length);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = DoubleCellValue(totalRevenue);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = DoubleCellValue(totalCollected);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = DoubleCellValue(totalOutstanding);
      rowIndex++;
    }

    final bytes = excel.save();
    if (bytes != null) {
      await FileSaverHelper.saveExcelFile(
        bytes,
        'PayPulse_System_Audit_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('System Audit exported!'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  Future<void> _exportCumulativeInvoicesExcel(AdminState state) async {
    final filtered = _getFilteredInvoices(state);
    final excel = Excel.createExcel();
    final sheetName = 'Cumulative Invoices';
    excel.rename(excel.getDefaultSheet()!, sheetName);
    final sheet = excel[sheetName];

    // Headers
    final headers = ['Invoice #', 'Company', 'Date', 'Gross (₹)', 'Final Payable (₹)', 'Paid (₹)', 'Balance Due (₹)', 'Status'];
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
    }

    int rowIndex = 1;
    for (final inv in filtered) {
      final companyName = _getCompanyName(state, inv.companyId);
      final statusLabel = inv.status == 'CANCELLED' ? 'CANCELLED' : (inv.balanceDue <= 0.05 ? 'PAID' : 'PARTIAL');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(inv.invoiceNumber ?? inv.id);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue(companyName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = TextCellValue(DateFormat('dd/MM/yyyy').format(inv.invoiceDate));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = DoubleCellValue(inv.grossAmount);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = DoubleCellValue(inv.finalPayable);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = DoubleCellValue(inv.totalAmountPaid);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = DoubleCellValue(inv.balanceDue);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).value = TextCellValue(statusLabel);
      rowIndex++;
    }

    final bytes = excel.save();
    if (bytes != null) {
      await FileSaverHelper.saveExcelFile(
        bytes,
        'PayPulse_Invoices_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoices report exported!'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);
    final filtered = _getFilteredInvoices(state);

    final totalRevenue = filtered.fold(0.0, (sum, i) => sum + i.finalPayable);
    final totalCollected = filtered.fold(0.0, (sum, i) => sum + i.totalAmountPaid);
    final totalOutstanding = filtered.fold(0.0, (sum, i) => sum + i.balanceDue);
    final fmt = NumberFormat('#,##,###');

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PAYPULSE', style: AppTextStyles.labelSm.copyWith(color: AppColors.primary, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text('Admin Reports & Audit', style: AppTextStyles.headlineLgMobile.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _exportSystemAuditExcel(state),
                      icon: Icon(Icons.summarize_rounded, size: 18, color: AppColors.primary),
                      label: Text('System Audit', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _exportCumulativeInvoicesExcel(state),
                      icon: const Icon(Icons.download_rounded, size: 18, color: Colors.white),
                      label: Text('Export Invoices', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Filters Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                // Date Range
                _buildFilterChip(
                  label: 'From: ${DateFormat('dd MMM yyyy').format(_startDate)}',
                  onTap: () => _pickDate(true),
                ),
                _buildFilterChip(
                  label: 'To: ${DateFormat('dd MMM yyyy').format(_endDate)}',
                  onTap: () => _pickDate(false),
                ),
                // Company Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCompanyId,
                      items: [
                        const DropdownMenuItem(value: 'ALL', child: Text('All Businesses')),
                        ...state.companies.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCompanyId = val);
                      },
                      dropdownColor: AppColors.surfaceContainer,
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.onBackground),
                    ),
                  ),
                ),
                // Status Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      items: const [
                        DropdownMenuItem(value: 'ALL', child: Text('All Statuses')),
                        DropdownMenuItem(value: 'PAID', child: Text('Paid')),
                        DropdownMenuItem(value: 'PARTIAL', child: Text('Partial')),
                        DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStatus = val);
                      },
                      dropdownColor: AppColors.surfaceContainer,
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.onBackground),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Summary Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard('Total Revenue', '₹${fmt.format(totalRevenue)}', AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard('Total Collected', '₹${fmt.format(totalCollected)}', AppColors.success),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard('Outstanding', '₹${fmt.format(totalOutstanding)}', AppColors.warning),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard('Invoice Count', '${filtered.length}', AppColors.info),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Invoices Table
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Filtered Invoices'),
                    const SizedBox(height: 12),
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text('Invoice #', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted, fontWeight: FontWeight.bold))),
                          Expanded(flex: 3, child: Text('Business', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('Date', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('Payable', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('Paid', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('Due', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted, fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text('Status', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Table Body
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text('No invoices match the current filters.', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted)),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final inv = filtered[index];
                                final companyName = _getCompanyName(state, inv.companyId);
                                final statusLabel = inv.status == 'CANCELLED'
                                    ? 'CANCELLED'
                                    : (inv.balanceDue <= 0.05 ? 'PAID' : 'PARTIAL');

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.3))),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(flex: 2, child: Text(inv.invoiceNumber ?? inv.id, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold))),
                                      Expanded(flex: 3, child: Text(companyName, style: AppTextStyles.bodyMd)),
                                      Expanded(flex: 2, child: Text(DateFormat('dd MMM yy').format(inv.invoiceDate), style: AppTextStyles.bodyMd)),
                                      Expanded(flex: 2, child: Text('₹${fmt.format(inv.finalPayable)}', style: AppTextStyles.bodyMd)),
                                      Expanded(flex: 2, child: Text('₹${fmt.format(inv.totalAmountPaid)}', style: AppTextStyles.bodyMd.copyWith(color: AppColors.success))),
                                      Expanded(flex: 2, child: Text('₹${fmt.format(inv.balanceDue)}', style: AppTextStyles.bodyMd.copyWith(color: inv.balanceDue > 0.05 ? AppColors.warning : AppColors.onSurfaceMuted))),
                                      Expanded(
                                        flex: 1,
                                        child: StatusBadge(
                                          status: statusLabel,
                                          fontSize: 8.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted)),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
