import 'package:flutter/material.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  // Stores registration numbers
  List<String> registrationNumbers = [];

  // Stores dates
  List<String> dates = [];

  // Stores attendance
  // true = present
  // false = absent
  List<List<bool>> attendance = [];

  // Add a student
  void addStudent() {
    final TextEditingController controller =
    TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Student"),

          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Registration Number",
              border: OutlineInputBorder(),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    registrationNumbers.add(
                      controller.text.trim(),
                    );

                    // Create attendance values
                    // for all existing dates.
                    attendance.add(
                      List.generate(
                        dates.length,
                            (index) => false,
                      ),
                    );
                  });

                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  // Add a new date
  void addDate() {
    setState(() {
      dates.add("Day ${dates.length + 1}");

      // Add false for the new date
      // for every existing student.
      for (int i = 0; i < attendance.length; i++) {
        attendance[i].add(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance"),
        centerTitle: true,
      ),

      body: Column(
        children: [

          // Buttons
          Padding(
            padding: const EdgeInsets.all(12),

            child: Row(
              children: [

                ElevatedButton.icon(
                  onPressed: addStudent,
                  icon: const Icon(Icons.person_add),
                  label: const Text("Add Student"),
                ),

                const SizedBox(width: 10),

                ElevatedButton.icon(
                  onPressed: addDate,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text("Add Date"),
                ),
              ],
            ),
          ),

          const Divider(),

          // Attendance table
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,

              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,

                child: DataTable(
                  border: TableBorder.all(),

                  columns: [
                    const DataColumn(
                      label: Text(
                        "Registration",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Create a column for every date
                    ...dates.map(
                          (date) {
                        return DataColumn(
                          label: Text(
                            date,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  // Create a row for every student
                  rows: List.generate(
                    registrationNumbers.length,
                        (studentIndex) {

                      return DataRow(
                        cells: [

                          // Registration number
                          DataCell(
                            Text(
                              registrationNumbers[
                              studentIndex],
                            ),
                          ),

                          // Attendance checkbox
                          ...List.generate(
                            dates.length,
                                (dateIndex) {

                              return DataCell(
                                Checkbox(
                                  value: attendance[
                                  studentIndex][dateIndex],

                                  onChanged: (value) {
                                    setState(() {
                                      attendance[
                                      studentIndex]
                                      [dateIndex] =
                                          value ?? false;
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}