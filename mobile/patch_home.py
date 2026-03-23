import sys

with open(r'd:\Projects\Mizan\mobile\lib\screens\home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

imports = "import 'package:intl/intl.dart';\nimport '../widgets/mizan_gauge.dart';"
content = content.replace("import 'widgets/home_insights_carousel.dart';", f"import 'widgets/home_insights_carousel.dart';\n{imports}")

hero_code = """
  Widget _buildHeroSection() {
    final safeToSpend = ((_summary?['safe_to_spend_cents'] ?? 0) / 100).toDouble();
    final income = ((_summary?['total_monthly_income_cents'] ?? 0) / 100).toDouble();
    final fixed = ((_summary?['total_monthly_fixed_expenses_cents'] ?? 0) / 100).toDouble();
    final discretionary = (income - fixed) > 0 ? (income - fixed) : 1000.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Safe-to-Spend',
            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              MizanGauge(
                safeToSpend: safeToSpend,
                maxDiscretionary: discretionary,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '\\$${safeToSpend.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Available',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingBills() {
    final bills = _summary?['upcoming_bills'] as List<dynamic>? ?? [];
    if (bills.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Bills',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index];
              final amount = (bill['amount_cents'] / 100).toDouble();
              final days = bill['days_until'];
              final name = bill['name'];
              final dateStr = bill['date'];
              final dateObj = DateTime.tryParse(dateStr) ?? DateTime.now();
              final formattedDate = DateFormat('MMM d').format(dateObj);

              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1e293b),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '\\$${amount.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formattedDate,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                        ),
                        Text(
                          days == 0 ? 'Today' : 'in ${days}d',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
"""

content = content.replace("  @override\n  Widget build(BuildContext context) {", f"{hero_code}\n  @override\n  Widget build(BuildContext context) {{")

ui_insert = """            if (!_isSummaryLoading && _summary != null) ...[
              _buildHeroSection(),
              const SizedBox(height: 24),
              _buildUpcomingBills(),
              const SizedBox(height: 24),
            ],
            // Evaluation trigger card mimicking the design"""

content = content.replace("            // Evaluation trigger card mimicking the design", ui_insert)

with open(r'd:\Projects\Mizan\mobile\lib\screens\home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
