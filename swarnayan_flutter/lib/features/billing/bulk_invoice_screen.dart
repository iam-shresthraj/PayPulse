import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/bulk_invoice_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_card.dart';
import '../../models/customer.dart';
import '../customers/customers_provider.dart';
import '../more/company_provider.dart';
import 'invoices_provider.dart';

class BulkInvoiceScreen extends ConsumerStatefulWidget {
  const BulkInvoiceScreen({super.key});

  @override
  ConsumerState<BulkInvoiceScreen> createState() => _BulkInvoiceScreenState();
}

class _BulkInvoiceScreenState extends ConsumerState<BulkInvoiceScreen> {
  String? _pickedFileName;
  BulkInvoiceParseResult? _parseResult;
  bool _saveInDatabase = false;

  bool _isProcessing = false;
  double _progress = 0.0;
  String _statusMessage = '';
  String? _downloadResultPath;

  Future<void> _pickCsvFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      String content = '';
      if (file.bytes != null) {
        content = utf8.decode(file.bytes!, allowMalformed: true);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      }

      if (content.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Selected CSV file is empty.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final parsed = BulkInvoiceService.parseCsv(content);

      setState(() {
        _pickedFileName = file.name;
        _parseResult = parsed;
        _downloadResultPath = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to read CSV file: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _clearFile() {
    setState(() {
      _pickedFileName = null;
      _parseResult = null;
      _downloadResultPath = null;
      _isProcessing = false;
      _progress = 0.0;
      _statusMessage = '';
    });
  }

  Future<void> _downloadSampleCsv() async {
    final sample = BulkInvoiceService.getSampleCsvTemplate();
    final bytes = Uint8List.fromList(utf8.encode(sample));
    try {
      if (kIsWeb) {
        await BulkInvoiceService.saveOrShareZip(
          bytes,
          defaultFileName: 'sample_invoices_template.csv',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Sample CSV template downloaded.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        return;
      }

      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        final outputFile = await FilePicker.saveFile(
          dialogTitle: 'Save Sample Invoice CSV Template',
          fileName: 'sample_invoices_template.csv',
          type: FileType.custom,
          allowedExtensions: ['csv'],
        );
        if (outputFile != null) {
          final file = File(outputFile.endsWith('.csv') ? outputFile : '$outputFile.csv');
          await file.writeAsBytes(bytes);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sample template saved to: ${file.path}'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      } else {
        await BulkInvoiceService.saveOrShareZip(
          bytes,
          defaultFileName: 'sample_invoices_template.csv',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading template: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _generateAndDownloadZip() async {
    if (_parseResult == null || _parseResult!.invoices.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _progress = 0.05;
      _statusMessage = 'Preparing company details & fonts...';
      _downloadResultPath = null;
    });

    final company = ref.read(companyProvider).value;
    final customersList = ref.read(customersProvider).value ?? [];
    final customerMap = <String, Customer>{};
    for (final c in customersList) {
      if (c.id != null) {
        customerMap[c.id!] = c;
      }
    }
    // Also include parsed customers from CSV
    _parseResult!.customers.forEach((key, cust) {
      customerMap[key] = cust;
    });

    final invoices = _parseResult!.invoices;
    final totalInvoices = invoices.length;

    try {
      // Step 1: Optional database save
      if (_saveInDatabase) {
        setState(() {
          _statusMessage = 'Saving $totalInvoices invoices to database...';
        });
        await ref.read(invoicesProvider.notifier).bulkAddInvoices(invoices);
      }

      // Step 2: Generate ZIP with progress callback
      final zipBytes = await BulkInvoiceService.generateBulkInvoicesZip(
        invoices: invoices,
        customers: customerMap,
        companySettings: company,
        onProgress: (current, total, invNo) {
          if (mounted) {
            setState(() {
              _progress = current / total;
              _statusMessage = 'Rendering invoice $current of $total ($invNo)...';
            });
          }
        },
      );

      setState(() {
        _statusMessage = 'Packaging ZIP file...';
      });

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final defaultZipName = 'Swarnayan_Bulk_Invoices_$timestamp.zip';

      final savedPath = await BulkInvoiceService.saveOrShareZip(
        zipBytes,
        defaultFileName: defaultZipName,
      );

      setState(() {
        _isProcessing = false;
        _progress = 1.0;
        _statusMessage = 'Successfully generated $totalInvoices invoices!';
        _downloadResultPath = savedPath ?? 'Downloaded';
      });

      if (mounted) {
        _showSuccessDialog(totalInvoices, savedPath);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Failed: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating bulk invoices: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(int totalCount, String? savedPath) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          side: BorderSide(color: AppColors.glassBorder),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
            const SizedBox(width: 12),
            Text(
              'Bulk Export Complete',
              style: AppTextStyles.titleLg.copyWith(color: AppColors.success),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generated $totalCount PDF invoices packed into a ZIP archive.',
              style: AppTextStyles.bodyLg,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _saveInDatabase
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: _saveInDatabase ? AppColors.primary : AppColors.glassBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _saveInDatabase ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                    color: _saveInDatabase ? AppColors.primary : AppColors.onSurfaceMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _saveInDatabase
                          ? 'Saved to Database: Yes ($totalCount records added as lightweight text)'
                          : 'Saved to Database: No (Database remains clean with 0 extra records)',
                      style: AppTextStyles.bodySm.copyWith(
                        color: _saveInDatabase ? AppColors.primary : AppColors.onSurfaceMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (savedPath != null) ...[
              const SizedBox(height: 12),
              Text(
                kIsWeb
                    ? 'ZIP Archive downloaded: $savedPath (saved to your browser downloads)'
                    : 'File location: $savedPath',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceDim),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: topPadding > 0 ? topPadding + 20 : 20,
          bottom: 40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      context.go('/billing');
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.onSurface,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generate Bulk Invoices',
                        style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Upload CSV, compile PDF invoices, and download as ZIP',
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _downloadSampleCsv,
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Sample CSV'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 24),

            // ── Information & Benefits Banner ──
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: AppSpacing.radiusLg,
              backgroundColor: AppColors.primary.withValues(alpha: 0.05),
              borderColor: AppColors.primary.withValues(alpha: 0.2),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.folder_zip_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zero Database Bloat & Instant Recovery',
                          style: AppTextStyles.titleSm.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Invoices are rendered dynamically in-memory. If data is accidentally deleted or you only need bulk prints, generate and download directly without cluttering the database.',
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Upload / Drag-Drop Zone ──
            _buildUploadZone(),

            const SizedBox(height: 20),

            // ── Checkbox: "Do you want save in database" ──
            _buildDatabaseOptionCheckbox(),

            if (_parseResult != null && _parseResult!.invoices.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSummaryAndPreviewCard(),
            ],

            // ── Generation Progress or Download Status ──
            if (_isProcessing || _statusMessage.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildProgressCard(),
            ],

            const SizedBox(height: 28),

            // ── Action Button ──
            if (_parseResult != null && _parseResult!.invoices.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                  onPressed: _isProcessing ? null : _generateAndDownloadZip,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.download_for_offline_rounded, size: 22),
                  label: Text(
                    _isProcessing
                        ? 'Generating Invoices...'
                        : 'Generate & Download ZIP (${_parseResult!.invoices.length} Invoices)',
                    style: AppTextStyles.titleSm.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadZone() {
    final hasFile = _pickedFileName != null && _parseResult != null;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: AppSpacing.radiusXl,
      borderColor: hasFile ? AppColors.success.withValues(alpha: 0.5) : AppColors.glassBorder,
      child: Column(
        children: [
          if (!hasFile) ...[
            Center(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Icon(
                      Icons.upload_file_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Upload Invoice CSV File',
                    style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Supports Swarnayan Register format (Inv No, Date, Customer, Particulars, Net Amt, Payment)',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainerHigh,
                      foregroundColor: AppColors.onSurface,
                      side: BorderSide(color: AppColors.glassBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    onPressed: _pickCsvFile,
                    icon: const Icon(Icons.file_open_rounded, size: 18),
                    label: const Text('Select CSV File'),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.table_chart_rounded,
                    color: AppColors.success,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pickedFileName ?? 'Selected File',
                        style: AppTextStyles.titleSm.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Parsed ${_parseResult!.invoices.length} invoices (${_parseResult!.totalRows} rows analyzed)',
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                      ),
                      if (_parseResult!.errors.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${_parseResult!.errors.length} warnings/skipped rows',
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.warning),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Change File',
                  icon: Icon(Icons.sync_rounded, color: AppColors.primary),
                  onPressed: _pickCsvFile,
                ),
                IconButton(
                  tooltip: 'Remove',
                  icon: Icon(Icons.close_rounded, color: AppColors.error),
                  onPressed: _clearFile,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDatabaseOptionCheckbox() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: AppSpacing.radiusLg,
      backgroundColor: _saveInDatabase
          ? AppColors.primary.withValues(alpha: 0.08)
          : AppColors.surfaceContainer,
      borderColor: _saveInDatabase
          ? AppColors.primary.withValues(alpha: 0.4)
          : AppColors.glassBorder,
      child: CheckboxListTile(
        value: _saveInDatabase,
        activeColor: AppColors.primary,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          'Do you want save in database',
          style: AppTextStyles.bodyLg.copyWith(
            fontWeight: FontWeight.bold,
            color: _saveInDatabase ? AppColors.primary : AppColors.onSurface,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _saveInDatabase
                ? 'Checked: Invoices will be saved to your cloud database as lightweight text records.'
                : 'Unchecked: Invoices will be compiled strictly in-memory into the ZIP file. Those invoices will NOT get saved in the database after download.',
            style: AppTextStyles.bodySm.copyWith(
              color: _saveInDatabase ? AppColors.onSurface : AppColors.onSurfaceMuted,
            ),
          ),
        ),
        onChanged: _isProcessing
            ? null
            : (val) {
                setState(() {
                  _saveInDatabase = val ?? false;
                });
              },
      ),
    );
  }

  Widget _buildSummaryAndPreviewCard() {
    final invoices = _parseResult!.invoices;
    final totalInvoices = invoices.length;
    final totalNet = invoices.fold<double>(0.0, (sum, inv) => sum + inv.finalPayable);
    final totalTax = invoices.fold<double>(0.0, (sum, inv) => sum + inv.cgst + inv.sgst);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: AppSpacing.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Parsed Invoice Preview',
                style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalInvoices Invoices',
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Metrics row
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Total Invoices',
                  '$totalInvoices',
                  Icons.receipt_rounded,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  'Total Net Sales',
                  Formatters.formatCurrency(totalNet),
                  Icons.currency_rupee_rounded,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  'Total GST',
                  Formatters.formatCurrency(totalTax),
                  Icons.account_balance_rounded,
                  AppColors.info,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: AppColors.glassBorder),
          const SizedBox(height: 12),

          Text(
            'Preview (First 10 records)',
            style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: 8),

          // Scrollable table/list
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: invoices.take(10).length,
                separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.glassBorder),
                itemBuilder: (context, index) {
                  final inv = invoices[index];
                  final customerName = inv.tempCustomerName ??
                      _parseResult!.customers[inv.customerId ?? '']?.name ??
                      'Customer';
                  final itemsSummary = inv.items.map((i) => i.productName).join(', ');

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          alignment: Alignment.center,
                          child: Text(
                            '#${index + 1}',
                            style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceDim),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                inv.invoiceNumber ?? 'INV',
                                style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                Formatters.formatDate(inv.invoiceDate),
                                style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceDim),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customerName,
                                style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                itemsSummary.isNotEmpty ? itemsSummary : 'Jewellery item',
                                style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                Formatters.formatCurrency(inv.finalPayable),
                                style: AppTextStyles.bodyMd.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                inv.payments.isNotEmpty
                                    ? inv.payments.map((p) => p.method).join('/')
                                    : 'CASH',
                                style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceDim),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          if (totalInvoices > 10) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                'and ${totalInvoices - 10} more invoices included in export',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceDim),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.titleSm.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: AppSpacing.radiusLg,
      borderColor: _progress == 1.0
          ? AppColors.success.withValues(alpha: 0.5)
          : AppColors.primary.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_isProcessing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  _progress == 1.0 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  color: _progress == 1.0 ? AppColors.success : AppColors.primary,
                  size: 20,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _statusMessage,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _progress == 1.0 ? AppColors.success : AppColors.onSurface,
                  ),
                ),
              ),
              if (_isProcessing)
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold),
                ),
            ],
          ),
          if (_isProcessing) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                backgroundColor: AppColors.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 6,
              ),
            ),
          ],
          if (_downloadResultPath != null) ...[
            const SizedBox(height: 8),
            Text(
              'Downloaded to: $_downloadResultPath',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceDim),
            ),
          ],
        ],
      ),
    );
  }
}
