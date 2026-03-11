import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import 'define_your_goal_screen.dart';

class FixedExpensesScreen extends StatefulWidget {
  const FixedExpensesScreen({super.key});

  @override
  State<FixedExpensesScreen> createState() => _FixedExpensesScreenState();
}

class _FixedExpensesScreenState extends State<FixedExpensesScreen> {
  final _rentController = TextEditingController();
  final _utilitiesController = TextEditingController();
  final _otherController = TextEditingController();

  int? _rentDueDate;
  int? _utilitiesDueDate;
  int? _otherDueDate;

  bool _isLoading = false;

  int? _parseAmount(String text) {
    if (text.isEmpty) return null;
    final value = double.tryParse(text.replaceAll(',', ''));
    if (value == null) return null;
    return (value * 100).toInt();
  }

  void _submitExpenses() async {
    final rentCents = _parseAmount(_rentController.text);
    final utilitiesCents = _parseAmount(_utilitiesController.text);
    final otherCents = _parseAmount(_otherController.text);

    if ((rentCents == null || _rentDueDate == null) &&
        (utilitiesCents == null || _utilitiesDueDate == null) &&
        (otherCents == null || _otherDueDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one expense and its due date.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (rentCents != null && _rentDueDate != null) {
        await ApiService.createExpense(
          name: 'Rent/Mortgage',
          amountCents: rentCents,
          isFixed: true,
          dueDateDay: _rentDueDate,
        );
      }

      if (utilitiesCents != null && _utilitiesDueDate != null) {
        await ApiService.createExpense(
          name: 'Utilities & Subscriptions',
          amountCents: utilitiesCents,
          isFixed: true,
          dueDateDay: _utilitiesDueDate,
        );
      }

      if (otherCents != null && _otherDueDate != null) {
        await ApiService.createExpense(
          name: 'Other Fixed Expenses',
          amountCents: otherCents,
          isFixed: true,
          dueDateDay: _otherDueDate,
        );
      }

      if (!mounted) return;

      // Navigate to Goal Definition Step
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DefineYourGoalScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save expenses: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<int?> _selectDueDate(BuildContext context, int? currentValue) async {
    // Show a bottom sheet or simple dialog to pick a day 1-31
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1e293b),
          title: const Text(
            'Select Due Date (Day of Month)',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: 31,
              itemBuilder: (context, index) {
                final day = index + 1;
                final isSelected = day == currentValue;
                return InkWell(
                  onTap: () => Navigator.pop(context, day),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF30e8c9)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF30e8c9).withValues(alpha: 0.3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF11211e)
                            : Colors.white,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExpenseField({
    required String title,
    required String hint,
    required String subtext,
    required TextEditingController controller,
    required int? dueDate,
    required VoidCallback onDateTap,
  }) {
    const primaryColor = Color(0xFF30e8c9);
    const surfaceDark = Color(0xFF1e293b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: onDateTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: primaryColor,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dueDate != null ? 'Day $dueDate' : 'Set Due Date',
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color:
                surfaceDark, // Match the dark theme background of the mockups
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: surfaceDark),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Text(
                  '\$',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(color: Colors.white30),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (subtext.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(
              subtext,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF30e8c9);
    const bgDark = Color(0xFF11211e);
    const surfaceDark = Color(0xFF1e293b);

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      Container(
                        height: 6,
                        width: 32,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 6,
                        width: 32,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 6,
                        width: 32,
                        decoration: BoxDecoration(
                          color: surfaceDark,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 6,
                        width: 32,
                        decoration: BoxDecoration(
                          color: surfaceDark,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 48), // spacer
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Text(
                    'Spending Habits',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tell us about your fixed costs to calculate your Safe-to-Spend amount.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Visual Summary Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.05),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.2),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 56,
                            width: 56,
                            decoration: const BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet,
                              color: bgDark,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ESTIMATED BALANCE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white54,
                                    letterSpacing: 1,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '\$2,450.00 remaining',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Inputs Section
                    _buildExpenseField(
                      title: 'Monthly Rent or Mortgage',
                      hint: '1,200',
                      subtext: '',
                      controller: _rentController,
                      dueDate: _rentDueDate,
                      onDateTap: () async {
                        final val = await _selectDueDate(context, _rentDueDate);
                        if (val != null) setState(() => _rentDueDate = val);
                      },
                    ),
                    const SizedBox(height: 24),

                    _buildExpenseField(
                      title: 'Utilities & Subscriptions',
                      hint: '250',
                      subtext: 'Think: Electricity, Internet, Netflix, Gym.',
                      controller: _utilitiesController,
                      dueDate: _utilitiesDueDate,
                      onDateTap: () async {
                        final val = await _selectDueDate(
                          context,
                          _utilitiesDueDate,
                        );
                        if (val != null) {
                          setState(() => _utilitiesDueDate = val);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    _buildExpenseField(
                      title: 'Other Fixed Expenses',
                      hint: '400',
                      subtext: 'Think: Groceries, Insurances, Commuting.',
                      controller: _otherController,
                      dueDate: _otherDueDate,
                      onDateTap: () async {
                        final val = await _selectDueDate(
                          context,
                          _otherDueDate,
                        );
                        if (val != null) setState(() => _otherDueDate = val);
                      },
                    ),

                    const SizedBox(height: 32),

                    // Helpful Tip
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb, color: primaryColor, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Most people underestimate their monthly spending by about 20%. Round up your numbers for a safer budget.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Action
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitExpenses,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: bgDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: bgDark,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Calculate Safe-to-Spend',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'I\'ll do this later',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
