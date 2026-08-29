import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_page.dart';

class AttendancePage extends StatefulWidget {
  final String courseDocId;
  final String courseName;
  final bool isTeacher;

  const AttendancePage({
    super.key,
    required this.courseDocId,
    required this.courseName,
    this.isTeacher = false,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final ScrollController _leftVerticalController = ScrollController();
  final ScrollController _rightVerticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  bool _isSyncingLeft = false;
  bool _isSyncingRight = false;

  @override
  void initState() {
    super.initState();

    _leftVerticalController.addListener(() {
      if (_isSyncingRight) return;
      _isSyncingLeft = true;
      if (_rightVerticalController.hasClients) {
        _rightVerticalController.jumpTo(_leftVerticalController.offset);
      }
      _isSyncingLeft = false;
    });

    _rightVerticalController.addListener(() {
      if (_isSyncingLeft) return;
      _isSyncingRight = true;
      if (_leftVerticalController.hasClients) {
        _leftVerticalController.jumpTo(_rightVerticalController.offset);
      }
      _isSyncingRight = false;
    });
  }

  @override
  void dispose() {
    _leftVerticalController.dispose();
    _rightVerticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  DocumentReference get _courseDoc => FirebaseFirestore.instance
      .collection('courses')
      .doc(widget.courseDocId);

  Future<void> _addStudent() async {
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final regNumber = controller.text.trim();
                if (regNumber.isNotEmpty) {
                  await _courseDoc.set({
                    'students': FieldValue.arrayUnion([regNumber]),
                  }, SetOptions(merge: true));

                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addDate() async {
    final now = DateTime.now();
    final dateStr = "${now.day}-${now.month}-${now.year}";

    await _courseDoc.set({
      'dates': FieldValue.arrayUnion([dateStr]),
    }, SetOptions(merge: true));
  }

  Future<void> _toggleAttendance(
      String studentId,
      String dateStr,
      bool currentStatus,
      ) async {
    await _courseDoc.collection('records').doc(dateStr).set({
      studentId: !currentStatus,
    }, SetOptions(merge: true));
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Log Out"),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
      );
    }
  }

  Color _getRowColor(int index) {
    return index.isEven ? Colors.lightBlue.shade50 : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Attendance",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Log Out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _courseDoc.snapshots(),
        builder: (context, courseSnapshot) {
          if (courseSnapshot.hasError) {
            return Center(child: Text("Error: ${courseSnapshot.error}"));
          }
          if (courseSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!courseSnapshot.hasData || !courseSnapshot.data!.exists) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Course '${widget.courseName}' not initialized in Firestore yet.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          final courseData =
              courseSnapshot.data!.data() as Map<String, dynamic>? ?? {};

          final List<String> students = List<String>.from(
            courseData['students'] ?? [],
          );
          final List<String> dates = List<String>.from(
            courseData['dates'] ?? [],
          );

          return StreamBuilder<QuerySnapshot>(
            stream: _courseDoc.collection('records').snapshots(),
            builder: (context, recordsSnapshot) {
              final Map<String, Map<String, bool>> attendanceMap = {};

              if (recordsSnapshot.hasData) {
                for (var doc in recordsSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  attendanceMap[doc.id] = data.map(
                        (key, value) => MapEntry(key, value as bool),
                  );
                }
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(
                      widget.courseName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  if (widget.isTeacher)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _addStudent,
                            icon: const Icon(Icons.person_add),
                            label: const Text("Add Student"),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: _addDate,
                            icon: const Icon(Icons.calendar_month),
                            label: const Text("Add Date"),
                          ),
                        ],
                      ),
                    ),
                  const Divider(),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Registration Column
                        SingleChildScrollView(
                          controller: _leftVerticalController,
                          child: DataTable(
                            border: TableBorder.all(
                              color: Colors.grey.shade300,
                            ),
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
                            rows: List.generate(students.length, (index) {
                              return DataRow(
                                color: WidgetStateProperty.all(
                                  _getRowColor(index),
                                ),
                                cells: [
                                  DataCell(Text(students[index])),
                                ],
                              );
                            }),
                          ),
                        ),
                        // Right Attendance Scrollable Data
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _horizontalController,
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              controller: _rightVerticalController,
                              scrollDirection: Axis.vertical,
                              child: DataTable(
                                border: TableBorder.all(
                                  color: Colors.grey.shade300,
                                ),
                                columns: [
                                  ...dates.map(
                                        (date) => DataColumn(
                                      label: Text(
                                        date,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const DataColumn(
                                    label: Text(
                                      "Present",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const DataColumn(
                                    label: Text(
                                      "Absent",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const DataColumn(
                                    label: Text(
                                      "Percentage",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                rows: List.generate(students.length, (
                                    studentIndex,
                                    ) {
                                  final studentId = students[studentIndex];
                                  int presentCount = 0;

                                  for (var date in dates) {
                                    if (attendanceMap[date]?[studentId] ==
                                        true) {
                                      presentCount++;
                                    }
                                  }

                                  final absentCount =
                                      dates.length - presentCount;
                                  final percentage = dates.isEmpty
                                      ? 0.0
                                      : (presentCount / dates.length) * 100;

                                  return DataRow(
                                    color: WidgetStateProperty.all(
                                      _getRowColor(studentIndex),
                                    ),
                                    cells: [
                                      ...dates.map((dateStr) {
                                        final isPresent =
                                            attendanceMap[dateStr]?[studentId] ??
                                                false;

                                        return DataCell(
                                          Center(
                                            child: Checkbox(
                                              value: isPresent,
                                              activeColor: Colors.green,
                                              onChanged: widget.isTeacher
                                                  ? (_) => _toggleAttendance(
                                                studentId,
                                                dateStr,
                                                isPresent,
                                              )
                                                  : null,
                                            ),
                                          ),
                                        );
                                      }),
                                      DataCell(Text(presentCount.toString())),
                                      DataCell(Text(absentCount.toString())),
                                      DataCell(
                                        Text(
                                          "${percentage.toStringAsFixed(1)}%",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}