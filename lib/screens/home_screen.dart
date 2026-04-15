import 'package:expense_tracker/models/expense_model.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final expenseBox = Hive.box<ExpenseModel>("expenses");
  final salaryBox = Hive.box<double>("monthly_salaries");
  late DateTime selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = DateTime(now.year, now.month);
  }

  List<ExpenseModel> get expenses => expenseBox.values.toList();

  List<ExpenseModel> get filteredExpenses =>
      expenses.where((expense) => _isInSelectedMonth(expense.date)).toList();

  double get totalExpense =>
      filteredExpenses.fold(0.0, (sum, item) => sum + item.amount);

  double get currentSalary =>
      salaryBox.get(_monthKey(selectedMonth), defaultValue: 0.0) ?? 0.0;

  double get balance => currentSalary - totalExpense;

  List<DateTime> get availableMonths {
    final months = <DateTime>{
      DateTime(DateTime.now().year, DateTime.now().month),
      DateTime(selectedMonth.year, selectedMonth.month),
    };

    for (final expense in expenses) {
      final date = expense.date;
      if (date != null) {
        months.add(DateTime(date.year, date.month));
      }
    }

    for (final key in salaryBox.keys) {
      if (key is String) {
        final month = _parseMonthKey(key);
        if (month != null) {
          months.add(month);
        }
      }
    }

    final sortedMonths = months.toList()
      ..sort((a, b) => b.compareTo(a));
    return sortedMonths;
  }

  bool _isInSelectedMonth(DateTime? date) {
    if (date == null) {
      return false;
    }
    return date.year == selectedMonth.year && date.month == selectedMonth.month;
  }

  String _monthKey(DateTime month) {
    return "${month.year}-${month.month.toString().padLeft(2, '0')}";
  }

  DateTime? _parseMonthKey(String key) {
    final parts = key.split("-");
    if (parts.length != 2) {
      return null;
    }

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) {
      return null;
    }

    return DateTime(year, month);
  }

  Future<void> _showSalaryDialog() async {
    final controller = TextEditingController(
      text: currentSalary == 0 ? "" : currentSalary.toStringAsFixed(2),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentSalary == 0 ? "Set Salary" : "Edit Salary"),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: "Salary for ${DateFormat("MMMM y").format(selectedMonth)}",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final salary = double.tryParse(controller.text.trim());
              if (salary == null || salary < 0) {
                return;
              }

              await salaryBox.put(_monthKey(selectedMonth), salary);
              if (context.mounted) {
                Navigator.pop(context);
              }
              setState(() {});
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Expense"),
        content: const Text("Are you sure you want to delete?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await expenseBox.deleteAt(index);
              if (context.mounted) {
                Navigator.pop(context);
              }
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newExpense = await Navigator.pushNamed(context, "/add-expense");
          if (newExpense is! ExpenseModel) {
            return;
          }

          await expenseBox.add(newExpense);
          setState(() {
            if (newExpense.date != null) {
              selectedMonth = DateTime(
                newExpense.date!.year,
                newExpense.date!.month,
              );
            }
          });
        },
        backgroundColor: Colors.indigoAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(title: const Text("Expense Tracker")),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<DateTime>(
                  value: selectedMonth,
                  decoration: const InputDecoration(
                    labelText: "Month",
                    border: OutlineInputBorder(),
                  ),
                  items: availableMonths.map((month) {
                    return DropdownMenuItem<DateTime>(
                      value: month,
                      child: Text(DateFormat("MMMM y").format(month)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      selectedMonth = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: "Salary: ",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          children: [
                            TextSpan(
                              text: currentSalary.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _showSalaryDialog,
                      child: Text(
                        currentSalary == 0 ? "Set Salary" : "Edit Salary",
                      ),
                    ),
                  ],
                ),
                Text.rich(
                  TextSpan(
                    text: "Total Expenses: ",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    children: [
                      TextSpan(
                        text: totalExpense.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                Text.rich(
                  TextSpan(
                    text: "Balance: ",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    children: [
                      TextSpan(
                        text: balance.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredExpenses.isEmpty
                ? Center(
                    child: Text(
                      "No expenses for ${DateFormat("MMMM y").format(selectedMonth)}",
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = filteredExpenses[index];
                      final actualIndex = expenses.indexOf(expense);
                      return ExpenseCard(
                        title: expense.title,
                        date: expense.date,
                        amount: expense.amount,
                        onDelete: () => confirmDelete(actualIndex),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ExpenseCard extends StatelessWidget {
  final String title;
  final DateTime? date;
  final double amount;
  final VoidCallback onDelete;

  const ExpenseCard({
    required this.title,
    required this.date,
    required this.amount,
    required this.onDelete,
    super.key,
  });

  String get formattedDate {
    return date == null ? "No Date" : DateFormat("MMM d, y").format(date!);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(20.0),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.length > 12 ? "${title.substring(0, 15)}..." : title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 16, color: Colors.brown),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Text(
                "Rs ${amount.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 30),
              child: IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
