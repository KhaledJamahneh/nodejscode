// lib/features/admin/presentation/screens/admin_expenses_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:einhod_water/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/admin_provider.dart';

final expensesFilterProvider = StateProvider<String?>((ref) => null);
final expensesDateFilterProvider = StateProvider<DateTimeRange?>((ref) => null);

class AdminExpensesScreen extends ConsumerWidget {
  const AdminExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(adminExpensesProvider);
    final filter = ref.watch(expensesFilterProvider);
    final dateFilter = ref.watch(expensesDateFilterProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.expenses),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(adminExpensesProvider),
          ),
        ],
      ),
      body: expensesAsync.when(
        data: (expensesData) {
          final allExpenses = List<Map<String, dynamic>>.from(expensesData['data'] ?? []);
          final summary = expensesData['summary'] ?? {};
          
          if (allExpenses.isEmpty) {
            return Center(child: Text(l10n.noExpenses));
          }

          var expenses = filter == null
              ? allExpenses
              : allExpenses.where((e) => e['payment_status'] == filter).toList();

          if (dateFilter != null) {
            expenses = expenses.where((e) {
              final date = DateTime.parse(e['created_at']);
              return date.isAfter(dateFilter.start.subtract(const Duration(days: 1))) &&
                     date.isBefore(dateFilter.end.add(const Duration(days: 1)));
            }).toList();
          }
          
          final companyPaid = (summary['company_paid'] ?? 0.0).toDouble();
          final debtToWorkers = (summary['debt_to_workers'] ?? 0.0).toDouble();
          final reimbursed = (summary['reimbursed'] ?? 0.0).toDouble();
          final totalExpenses = (summary['total'] ?? 0.0).toDouble();

          return Column(
            children: [
              // Premium Stats Card with Chart
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF1E88E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.totalExpenses,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₪${totalExpenses.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStatCard(
                            label: l10n.paid,
                            amount: companyPaid,
                            icon: Icons.check_circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MiniStatCard(
                            label: 'Debt to Workers',
                            amount: debtToWorkers,
                            icon: Icons.account_balance_wallet_outlined,
                            color: AppTheme.iosOrange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _FilterChip(
                      label: l10n.all,
                      selected: filter == null,
                      onTap: () => ref.read(expensesFilterProvider.notifier).state = null,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: l10n.paid,
                      selected: filter == 'paid',
                      color: AppTheme.successGreen,
                      onTap: () => ref.read(expensesFilterProvider.notifier).state = 'paid',
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: l10n.unpaid,
                      selected: filter == 'unpaid',
                      color: AppTheme.iosRed,
                      onTap: () => ref.read(expensesFilterProvider.notifier).state = 'unpaid',
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () async {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: dateFilter,
                        );
                        if (range != null) {
                          ref.read(expensesDateFilterProvider.notifier).state = range;
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: dateFilter != null ? AppTheme.iosBlue.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: dateFilter != null ? AppTheme.iosBlue : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.date_range,
                              size: 16,
                              color: dateFilter != null ? AppTheme.iosBlue : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dateFilter == null
                                  ? l10n.dateRange
                                  : '${DateFormat('MMM d').format(dateFilter.start)} - ${DateFormat('MMM d').format(dateFilter.end)}',
                              style: TextStyle(
                                color: dateFilter != null ? AppTheme.iosBlue : Colors.grey,
                                fontWeight: dateFilter != null ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            if (dateFilter != null) ...[
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => ref.read(expensesDateFilterProvider.notifier).state = null,
                                child: const Icon(Icons.close, size: 16, color: AppTheme.iosBlue),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // List
              Expanded(
                child: expenses.isEmpty
                    ? Center(child: Text(l10n.noExpenses))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: expenses.length,
                        itemBuilder: (context, index) => _ExpenseCard(expense: expenses[index]),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  double _getAmount(Map<String, dynamic> expense) {
    final amount = expense['amount'];
    if (amount == null) return 0;
    if (amount is num) return amount.toDouble();
    if (amount is String) return double.tryParse(amount) ?? 0;
    return 0;
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _StatCard({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('₪${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? chipColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? chipColor : Colors.grey.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? chipColor : Colors.grey,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ExpenseCard extends ConsumerWidget {
  final Map<String, dynamic> expense;

  const _ExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateTime.parse(expense['created_at']);
    final status = expense['payment_status'] as String;
    final paymentMethod = expense['payment_method'] as String?;
    
    // Show pay button if: unpaid status OR worker_pocket/unpaid payment method
    final needsPayment = status != 'paid' || 
                        paymentMethod == 'worker_pocket' || 
                        paymentMethod == 'unpaid';

    Color statusColor;
    switch (status) {
      case 'paid':
        statusColor = AppTheme.successGreen;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense['worker_name'] ?? expense['username'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(date),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₪${_formatAmount(expense['amount'])}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.payment, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _getPaymentMethodText(expense['payment_method'], l10n),
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(status, l10n).toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (expense['destination'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    expense['destination'],
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
            if (expense['notes'] != null && expense['notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                expense['notes'],
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditExpenseDialog(context, ref, expense, l10n),
                    icon: const Icon(Icons.edit, size: 16),
                    label: Text(l10n.edit, style: const TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ),
                if (needsPayment) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final expenseId = expense['id'];
                        final paymentMethod = expense['payment_method'];
                        
                        // If worker_pocket, change to company_pocket (company reimburses/pays)
                        if (paymentMethod == 'worker_pocket') {
                          await ref.read(adminServiceProvider).updateExpense(
                            expenseId,
                            {'payment_method': 'company_pocket'},
                          );
                        } else {
                          await ref.read(adminServiceProvider).updateExpenseStatus(expenseId, 'paid');
                        }
                        
                        ref.refresh(adminExpensesProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.statusUpdated),
                              backgroundColor: AppTheme.successGreen,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: Text(
                        expense['payment_method'] == 'worker_pocket' 
                          ? l10n.reimburse 
                          : l10n.markAsPaid, 
                        style: const TextStyle(fontSize: 13)
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';
    if (amount is num) return amount.toStringAsFixed(2);
    if (amount is String) return (double.tryParse(amount) ?? 0).toStringAsFixed(2);
    return '0.00';
  }

  String _getPaymentMethodText(String method, AppLocalizations l10n) {
    switch (method) {
      case 'my_pocket':
        return l10n.myPocket;
      case 'company':
        return l10n.company;
      default:
        return method;
    }
  }

  void _showEditExpenseDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> expense, AppLocalizations l10n) {
    final amountController = TextEditingController(text: _formatAmount(expense['amount']));
    final destinationController = TextEditingController(text: expense['destination'] ?? '');
    final notesController = TextEditingController(text: expense['notes'] ?? '');
    
    String paymentMethod = expense['payment_method'] ?? 'my_pocket';
    if (!['my_pocket', 'company'].contains(paymentMethod)) {
      paymentMethod = 'my_pocket';
    }
    
    String paymentStatus = expense['payment_status'] ?? 'unpaid';
    if (!['paid', 'pending', 'unpaid'].contains(paymentStatus)) {
      paymentStatus = 'unpaid';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.edit + ' ' + l10n.expenses),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.balance,
                    prefixText: '₪',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: InputDecoration(labelText: l10n.paymentMethod),
                  items: [
                    DropdownMenuItem(value: 'my_pocket', child: Text(l10n.myPocket)),
                    DropdownMenuItem(value: 'company', child: Text(l10n.company)),
                  ],
                  onChanged: (v) => setState(() => paymentMethod = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: paymentStatus,
                  decoration: InputDecoration(labelText: l10n.status),
                  items: [
                    DropdownMenuItem(value: 'paid', child: Text(l10n.paid.toUpperCase())),
                    DropdownMenuItem(value: 'pending', child: Text(l10n.pending.toUpperCase())),
                    DropdownMenuItem(value: 'unpaid', child: Text(l10n.unpaid.toUpperCase())),
                  ],
                  onChanged: (v) => setState(() => paymentStatus = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: destinationController,
                  decoration: InputDecoration(labelText: l10n.destination),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(labelText: l10n.notes),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ref.read(adminServiceProvider).updateExpense(
                    expense['id'],
                    {
                      'amount': double.tryParse(amountController.text) ?? 0,
                      'payment_method': paymentMethod,
                      'payment_status': paymentStatus,
                      'destination': destinationController.text,
                      'notes': notesController.text,
                    },
                  );
                  ref.refresh(adminExpensesProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.statusUpdated)),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status, AppLocalizations l10n) {
    switch (status) {
      case 'paid':
        return l10n.paid;
      case 'unpaid':
        return l10n.unpaid;
      case 'pending':
        return l10n.pending;
      default:
        return status;
    }
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color? color;

  const _MiniStatCard({
    required this.label,
    required this.amount,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.white;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: effectiveColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: effectiveColor.withOpacity(0.9),
                    fontSize: 11,
                  ),
                ),
                Text(
                  '₪${amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: effectiveColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
