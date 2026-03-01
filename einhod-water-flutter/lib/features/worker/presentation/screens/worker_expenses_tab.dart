import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:einhod_water/l10n/app_localizations.dart';
import 'package:einhod_water/core/widgets/widgets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../providers/worker_provider.dart';
import '../../data/models/worker_models.dart';

class WorkerExpensesTab extends ConsumerStatefulWidget {
  const WorkerExpensesTab({super.key});

  @override
  ConsumerState<WorkerExpensesTab> createState() => _WorkerExpensesTabState();
}

class _WorkerExpensesTabState extends ConsumerState<WorkerExpensesTab> {
  final _amountController = TextEditingController();
  final _destinationController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedMainMethod = 'worker_pocket';
  String _selectedSubMethod = 'cash';
  String _selectedStatus = 'unpaid';

  @override
  void dispose() {
    _amountController.dispose();
    _destinationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    print('WorkerExpensesTab initState called');
    // Force refresh on tab open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Calling refresh on expenses provider');
      ref.read(workerExpensesProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final expenses = ref.watch(workerExpensesProvider);
    final profileAsync = ref.watch(workerProfileProvider);
    print('Building WorkerExpensesTab, expenses count: ${expenses.length}');

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.submitExpense,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '${l10n.balance} (₪)',
                    prefixIcon: const Icon(Icons.attach_money_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: l10n.paymentStatus,
                    prefixIcon: const Icon(Icons.account_balance_wallet_rounded),
                  ),
                  items: [
                    DropdownMenuItem(value: 'unpaid', child: Text(l10n.unpaid)),
                    DropdownMenuItem(value: 'paid', child: Text(l10n.paid)),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStatus = val);
                  },
                ),
                if (_selectedStatus == 'paid') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedMainMethod,
                    decoration: InputDecoration(
                      labelText: l10n.paymentMethod,
                      prefixIcon: const Icon(Icons.payment_rounded),
                    ),
                    items: [
                      DropdownMenuItem(value: 'worker_pocket', child: Text(l10n.myPocket)),
                      DropdownMenuItem(value: 'company_pocket', child: Text(l10n.company)),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedMainMethod = val);
                      }
                    },
                  ),
                  if (_selectedMainMethod == 'company_pocket') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedSubMethod,
                      decoration: InputDecoration(
                        labelText: l10n.paymentMethod,
                        prefixIcon: const Icon(Icons.credit_card_rounded),
                      ),
                      items: [
                        DropdownMenuItem(value: 'cash', child: Text(l10n.cashRevenue)),
                        DropdownMenuItem(value: 'card', child: Text(l10n.cardRevenue)),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSubMethod = val);
                      },
                    ),
                  ],
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    labelText: l10n.destination,
                    prefixIcon: const Icon(Icons.store_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: l10n.notes,
                    prefixIcon: const Icon(Icons.note_rounded),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: l10n.submit,
                  icon: Icons.send_rounded,
                  onTap: _submitExpense,
                ),
              ],
            ),
          ),
        ),
        expenses.isEmpty
            ? SliverFillRemaining(
                child: Center(child: Text(l10n.noActivity)),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                    final expense = expenses[index];
                    final isPaid = expense.paymentStatus == 'paid';
                    return ModernCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        onTap: () => _showEditExpenseDialog(expense),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isPaid ? AppTheme.successGreen : AppTheme.iosOrange).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                expense.paymentMethod == 'cash'
                                    ? Icons.money_rounded
                                    : Icons.credit_card_rounded,
                                color: isPaid ? AppTheme.successGreen : AppTheme.iosOrange,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '₪${expense.amount}',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800),
                                  ),
                                  if (expense.notes?.isNotEmpty ?? false)
                                    Text(
                                      expense.notes!,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.iosGray),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  expense.date,
                                  style: const TextStyle(
                                      fontSize: 12, color: AppTheme.iosGray),
                                ),
                                const SizedBox(height: 4),
                                Icon(Icons.edit_rounded,
                                    size: 16, color: AppTheme.iosGray),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: expenses.length,
                  ),
                ),
              ),
      ],
    );
  }

  void _submitExpense() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    final paymentMethod = _selectedStatus == 'paid'
        ? (_selectedMainMethod == 'worker_pocket' ? 'worker_pocket' : _selectedSubMethod)
        : 'unpaid';

    ref.read(workerOpsProvider.notifier).submitExpense({
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_status': _selectedStatus,
      'destination': _destinationController.text,
      'notes': _notesController.text,
    });

    _amountController.clear();
    _destinationController.clear();
    _notesController.clear();
    setState(() {
      _selectedMainMethod = 'worker_pocket';
      _selectedStatus = 'unpaid';
    });
    
    DialogUtils.showMessageDialog(context, 'Success', AppLocalizations.of(context)!.expenseSubmitted);
  }

  void _showEditExpenseDialog(WorkerExpense expense) {
    final l10n = AppLocalizations.of(context)!;
    final amountController = TextEditingController(text: expense.amount.toString());
    final destinationController = TextEditingController(text: expense.destination ?? '');
    final notesController = TextEditingController(text: expense.notes ?? '');
    
    String selectedMethod = expense.paymentMethod;
    if (!['cash', 'card', 'worker_pocket', 'company_pocket', 'unpaid'].contains(selectedMethod)) {
      selectedMethod = 'unpaid';
    }
    
    String selectedStatus = expense.paymentStatus;
    if (!['paid', 'unpaid', 'pending'].contains(selectedStatus)) {
      selectedStatus = 'unpaid';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.edit),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '${l10n.balance} (₪)',
                    prefixIcon: const Icon(Icons.attach_money_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedMethod,
                  decoration: InputDecoration(
                    labelText: l10n.paymentMethod,
                    prefixIcon: const Icon(Icons.payment_rounded),
                  ),
                  items: [
                    DropdownMenuItem(value: 'worker_pocket', child: Text(l10n.myPocket)),
                    DropdownMenuItem(value: 'company_pocket', child: Text(l10n.company)),
                    DropdownMenuItem(value: 'cash', child: Text(l10n.cashRevenue)),
                    DropdownMenuItem(value: 'card', child: Text(l10n.cardRevenue)),
                    DropdownMenuItem(value: 'unpaid', child: Text(l10n.unpaid)),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedMethod = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    labelText: l10n.paymentStatus,
                    prefixIcon: const Icon(Icons.account_balance_wallet_rounded),
                  ),
                  items: [
                    DropdownMenuItem(value: 'unpaid', child: Text(l10n.unpaid)),
                    DropdownMenuItem(value: 'paid', child: Text(l10n.paid)),
                    DropdownMenuItem(value: 'pending', child: Text(l10n.pending)),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedStatus = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: destinationController,
                  decoration: InputDecoration(
                    labelText: l10n.destination,
                    prefixIcon: const Icon(Icons.store_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: l10n.notes,
                    prefixIcon: const Icon(Icons.note_rounded),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.delete),
                    content: Text('${l10n.deleteConfirmation} ${l10n.expenses.toLowerCase()}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l10n.cancel),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(workerOpsProvider.notifier).deleteExpense(expense.id);
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.criticalRed,
                        ),
                        child: Text(l10n.delete),
                      ),
                    ],
                  ),
                );
              },
              child: Text(l10n.delete, style: const TextStyle(color: AppTheme.criticalRed)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) return;

                ref.read(workerOpsProvider.notifier).updateExpense(expense.id, {
                  'amount': amount,
                  'payment_method': selectedMethod,
                  'payment_status': selectedStatus,
                  'destination': destinationController.text,
                  'notes': notesController.text,
                });
                Navigator.pop(context);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
