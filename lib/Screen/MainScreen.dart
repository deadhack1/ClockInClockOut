import 'package:clock_in_clock_out/Screen/ClockInClockOut.dart';
import 'package:clock_in_clock_out/Screen/ExpenseTracker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: (){
              Get.to(ClockInClockOut());
            }, child: Text("CLock In Clock Out")),
            ElevatedButton(onPressed: (){
              Get.to(ExpenseTracker());
            }, child: Text("Expense Tracker")),
          ],
        ),
      ),
    );
  }
}
