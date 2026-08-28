import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

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

  // Stores highlighted attendance cells
  List<List<bool>> highlighted = [];

  // ==========================================
  // SHARE ATTENDANCE
  // ==========================================

  void shareAttendance() {
    String message = "Attendance Report\n\n";

    for (int studentIndex = 0;
    studentIndex < registrationNumbers.length;
    studentIndex++) {
      int presentCount =
          attendance[studentIndex].where((present) => present).length;

      int absentCount = dates.length - presentCount;

      message +=
      "Registration: ${registrationNumbers[studentIndex]}\n"
          "Present: $presentCount\n"
          "Absent: $absentCount\n"
          "Percentage: "
          "${getPercentage(studentIndex).toStringAsFixed(1)}%\n\n";
    }

    SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: "Attendance Report",
      ),
    );
  }

  // ==========================================
  // ADD STUDENT
  // ==========================================

  void addStudent() {
    final TextEditingController controller = TextEditingController();

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
            // Cancel button
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            // Add button
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    // Add registration number
                    registrationNumbers.add(
                      controller.text.trim(),
                    );

                    // Create attendance values
                    // for all existing dates
                    attendance.add(
                      List.generate(
                        dates.length,
                            (index) => false,
                      ),
                    );

                    // Create highlighted values
                    highlighted.add(
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

  // ==========================================
  // ADD DATE
  // ==========================================

  void addDate() {
    final now = DateTime.now();

    String newDate =
        "${now.day}/${now.month}/${now.year}";

    setState(() {
      dates.add(newDate);

      // Add false for the new date
      // for every existing student
      for (int i = 0; i < attendance.length; i++) {
        attendance[i].add(false);
        highlighted[i].add(false);
      }
    });
  }

  // ==========================================
  // CALCULATE PERCENTAGE
  // ==========================================

  double getPercentage(int studentIndex) {
    if (dates.isEmpty) {
      return 0;
    }

    int presentCount = 0;

    for (int i = 0; i < dates.length; i++) {
      if (attendance[studentIndex][i]) {
        presentCount++;
      }
    }

    return (presentCount / dates.length) * 100;
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Attendance",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),

      body: Column(
        children: [

          // ====================================
          // BUTTONS
          // ====================================

          Padding(
            padding: const EdgeInsets.all(12),

            child: Row(
              children: [

                // Add Student
                ElevatedButton.icon(
                  onPressed: addStudent,
                  icon: const Icon(Icons.person_add),
                  label: const Text("Add Student"),
                ),

                const SizedBox(width: 10),

                // Add Date
                ElevatedButton.icon(
                  onPressed: addDate,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text("Add Date"),
                ),
              ],
            ),
          ),

          const Divider(),

          // ====================================
          // ATTENDANCE TABLE
          // ====================================

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,

              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  // ==================================
                  // FIXED REGISTRATION COLUMN
                  // ==================================

                  DataTable(
                    border: TableBorder.all(),

                    columns: const [
                      DataColumn(
                        label: Text(
                          "Registration",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],

                    rows: List.generate(
                      registrationNumbers.length,
                          (studentIndex) {
                        return DataRow(
                          color: MaterialStateProperty
                              .resolveWith<Color?>(
                                (states) {
                              return studentIndex.isEven
                                  ? Colors.lightBlue.shade50
                                  : Colors.white;
                            },
                          ),

                          cells: [
                            DataCell(
                              Text(
                                registrationNumbers[
                                studentIndex],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // ==================================
                  // SCROLLABLE PART
                  // ==================================

                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,

                      child: DataTable(
                        border: TableBorder.all(),

                        // ==================================
                        // COLUMNS
                        // ==================================

                        columns: [

                          // Date columns
                          ...dates.map(
                                (date) {
                              return DataColumn(
                                label: Text(
                                  date,
                                  style:
                                  const TextStyle(
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),

                          // Present
                          const DataColumn(
                            label: Text(
                              "Present",
                              style: TextStyle(
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),

                          // Absent
                          const DataColumn(
                            label: Text(
                              "Absent",
                              style: TextStyle(
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),

                          // Percentage
                          const DataColumn(
                            label: Text(
                              "Percentage",
                              style: TextStyle(
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                        ],

                        // ==================================
                        // ROWS
                        // ==================================

                        rows: List.generate(
                          registrationNumbers.length,
                              (studentIndex) {

                            int presentCount =
                                attendance[
                                studentIndex]
                                    .where(
                                        (present) =>
                                    present)
                                    .length;

                            int absentCount =
                                dates.length -
                                    presentCount;

                            return DataRow(
                              color:
                              MaterialStateProperty
                                  .resolveWith<
                                  Color?>(
                                    (states) {
                                  return studentIndex
                                      .isEven
                                      ? Colors
                                      .lightBlue
                                      .shade50
                                      : Colors.white;
                                },
                              ),

                              cells: [

                                // ==================================
                                // ATTENDANCE CHECKBOXES
                                // ==================================

                                ...List.generate(
                                  dates.length,
                                      (dateIndex) {

                                    return DataCell(
                                      Container(
                                        width: 60,
                                        height: 48,

                                        color: highlighted[
                                        studentIndex]
                                        [dateIndex]
                                            ? Colors.yellow
                                            : Colors
                                            .transparent,

                                        alignment:
                                        Alignment.center,

                                        child:
                                        GestureDetector(
                                          onDoubleTap: () {
                                            setState(() {
                                              highlighted[
                                              studentIndex]
                                              [dateIndex] =
                                              !highlighted[
                                              studentIndex]
                                              [
                                              dateIndex];
                                            });
                                          },

                                          child: Checkbox(
                                            value: attendance[
                                            studentIndex]
                                            [
                                            dateIndex],

                                            activeColor:
                                            Colors.green,

                                            checkColor:
                                            Colors.white,

                                            onChanged:
                                                (value) {
                                              setState(() {
                                                attendance[
                                                studentIndex]
                                                [
                                                dateIndex] =
                                                    value ??
                                                        false;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                // ==================================
                                // PRESENT
                                // ==================================

                                DataCell(
                                  Text(
                                    presentCount
                                        .toString(),
                                  ),
                                ),

                                // ==================================
                                // ABSENT
                                // ==================================

                                DataCell(
                                  Text(
                                    absentCount
                                        .toString(),
                                  ),
                                ),

                                // ==================================
                                // PERCENTAGE
                                // ==================================

                                DataCell(
                                  Text(
                                    "${getPercentage(studentIndex).toStringAsFixed(1)}%",
                                    style:
                                    const TextStyle(
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ====================================
          // SHARE BUTTON
          // ====================================

          Padding(
            padding: const EdgeInsets.all(12),

            child: SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: shareAttendance,
                icon: const Icon(Icons.share),
                label: const Text(
                  "Share Attendance",
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}