import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/screens/add_expense_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // final List<ExpenseModel> expenses = [
  //   ExpenseModel(title: "Groceries", amount: 46, date: DateTime.now()),
  //   ExpenseModel(
  //     title: "Dinner",
  //     amount: 30,
  //     date: DateTime.now().subtract(Duration(days: 1)),
  //   ),
  // ];

  final expenseBox = Hive.box<ExpenseModel>("expenses");
  List<ExpenseModel> get expenses => expenseBox.values.toList();

  final double totalBudget = 5000;
  double get totalExpense =>
      expenses.fold(0.0, (sum, item) => sum + item.amount);
  double get balance => totalBudget - totalExpense;

  //delete function:
  confirmDelete(index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Expense"),
        content: Text("Are you sure you want to delete?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final expenseBox = Hive.box<ExpenseModel>("expenses");
              await expenseBox.deleteAt(index);
              Navigator.pop(context);
              setState(() {});
            },
            child: Text("Delete"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newExpense =
              await Navigator.pushNamed(context, "/add-expense")
                  as ExpenseModel;
          setState(() {
            //  expenses.add(newExpense); //to dynamically add in the list
            expenseBox.add(
              newExpense,
            ); // to add the dyunamic list to store in local storage
          });
          // print(
          //   "New Expense : ${newExpense.title},${newExpense.amount},${newExpense.date}",
          // );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.indigoAccent,
        foregroundColor: Colors.white,
      ),
      appBar: AppBar(title: Text("Expense Tracker")),
      // body: Column(
      //   children: [
      //     ExpenseCard(title: "Groceries", date: "Sep 15 2025", amount: 250.0),
      //     ExpenseCard(
      //       title: "Electric Bill",
      //       date: "Sep 19 2025",
      //       amount: 1500.0,
      //     ),
      //   ],
      // ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: "Total Expenses: ",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    children: [
                      TextSpan(
                        text: totalExpense.toStringAsFixed(2),
                        style: TextStyle(fontSize: 14, color: Colors.red),
                      ),
                    ],
                  ),
                ),

                Text.rich(
                  TextSpan(
                    text: "Balance: ",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    children: [
                      TextSpan(
                        text: balance.toStringAsFixed(2),
                        style: TextStyle(fontSize: 14, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (contect, index) {
                final expense = expenses[index];
                return ExpenseCard(
                  title: expense.title,
                  date: expense.date,
                  amount: expense.amount,
                  onDelete: () => confirmDelete(
                    index,
                  ), //to delete just this funtion call is enough
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
      margin: EdgeInsets.all(20.0),
      elevation: 5,

      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.length > 12 ? '${title.substring(0, 15)}...' : title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 16, color: Colors.brown),
                ),
              ],
            ),
            Container(
              child: Text(
                "₹ ${amount.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(5.0),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            ),
            Container(
              padding: EdgeInsetsDirectional.only(start: 30),
              child: IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete, color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
