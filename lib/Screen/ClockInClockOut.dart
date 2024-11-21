import 'package:flutter/material.dart';

class ClockInClockOut extends StatefulWidget {
  const ClockInClockOut({super.key});

  @override
  State<ClockInClockOut> createState() => _ClockInClockOutState();
}

class _ClockInClockOutState extends State<ClockInClockOut> {
  int currentPageIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: EdgeInsets.all(20),
          itemCount: 10,
          itemBuilder: (context, index) {
            print(index);
            if (index == 0) {
              return Card(
                margin: EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("OFF THE CLOCK"),
                ),
              );
            } else {
              return ConstrainedBox(
                constraints: BoxConstraints(),
                child: Column(
                  children: [
                    ListTile(

                      tileColor: Colors.red,
                      contentPadding: EdgeInsets.all(20),
                      title: Text("Primary Study $index"),
                    ),
                    Divider(),
                  ],
                ),
              );
            }
          }),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
        destinations: [
          NavigationDestination(icon: Icon(Icons.business), label: "Jobs"),
          NavigationDestination(icon: Icon(Icons.list), label: "Entries"),
          NavigationDestination(
              icon: Icon(Icons.payments), label: "Pay Periods"),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: "More"),
        ],
      ),
    );
  }
}
