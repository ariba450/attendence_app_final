
import 'package:flutter/material.dart';

class AttendancePage extends StatefulWidget {
final String courseName;

const AttendancePage({
super.key,
required this.courseName,
});

@override
State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
// ==========================================
// DATA
// ==========================================

List<String> registrationNumbers = [];

List<String> dates = [];

// true = present
// false = absent
List<List<bool>> attendance = [];

// Highlighted attendance cells
List<List<bool>> highlighted = [];

// ==========================================
// SCROLL CONTROLLER
// ==========================================

final ScrollController verticalController =
ScrollController();

// ==========================================
// ADD STUDENT
// ==========================================

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
final registration =
controller.text.trim();

if (registration.isNotEmpty) {
setState(() {
registrationNumbers.add(
registration,
);

attendance.add(
List.generate(
dates.length,
(_) => false,
),
);

highlighted.add(
List.generate(
dates.length,
(_) => false,
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

final newDate =
"${now.day}/${now.month}/${now.year}";

setState(() {
dates.add(newDate);

for (int i = 0;
i < attendance.length;
i++) {
attendance[i].add(false);
highlighted[i].add(false);
}
});
}

// ==========================================
// PERCENTAGE
// ==========================================

double getPercentage(int studentIndex) {
if (dates.isEmpty) {
return 0;
}

int presentCount = 0;

for (int i = 0;
i < dates.length;
i++) {
if (attendance[studentIndex][i]) {
presentCount++;
}
}

return (presentCount / dates.length) * 100;
}

// ==========================================
// ROW COLOR
// ==========================================

Color getRowColor(int index) {
return index.isEven
? Colors.lightBlue.shade50
    : Colors.white;
}

// ==========================================
// BUILD
// ==========================================

@override
Widget build(BuildContext context) {
return Scaffold(
// ========================================
// APP BAR
// ========================================

appBar: AppBar(
title: const Text(
"Attendance",
style: TextStyle(
color: Colors.white,
fontWeight: FontWeight.bold,
),
),
centerTitle: true,
backgroundColor: Colors.blue,
),

// ========================================
// BODY
// ========================================

body: Column(
children: [
// ======================================
// COURSE NAME
// ======================================

Padding(
padding: const EdgeInsets.only(
top: 16,
bottom: 8,
),
child: Text(
widget.courseName,
style: const TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
color: Colors.blue,
),
),
),

// ======================================
// BUTTONS
// ======================================

Padding(
padding: const EdgeInsets.all(12),
child: Row(
children: [
ElevatedButton.icon(
onPressed: addStudent,
icon: const Icon(
Icons.person_add,
),
label: const Text(
"Add Student",
),
),

const SizedBox(width: 10),

ElevatedButton.icon(
onPressed: addDate,
icon: const Icon(
Icons.calendar_month,
),
label: const Text(
"Add Date",
),
),
],
),
),

const Divider(),

// ======================================
// TABLE
// ======================================

Expanded(
child: Row(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
// ==================================
// FIXED REGISTRATION COLUMN
// ==================================

SingleChildScrollView(
controller: verticalController,
child: DataTable(
border: TableBorder.all(),

columns: const [
DataColumn(
label: Text(
"Registration",
style: TextStyle(
fontWeight:
FontWeight.bold,
),
),
),
],

rows: List.generate(
registrationNumbers.length,
(studentIndex) {
return DataRow(
color:
MaterialStateProperty
    .all(
getRowColor(
studentIndex,
),
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
),

// ==================================
// SCROLLABLE REST OF TABLE
// ==================================

Expanded(
child: SingleChildScrollView(
scrollDirection:
Axis.horizontal,

child: SingleChildScrollView(
controller:
verticalController,
scrollDirection:
Axis.vertical,

child: DataTable(
border:
TableBorder.all(),

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
final presentCount =
attendance[
studentIndex]
    .where(
(present) =>
present,
)
    .length;

final absentCount =
dates.length -
presentCount;

return DataRow(
color:
MaterialStateProperty
    .all(
getRowColor(
studentIndex,
),
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

color:
highlighted[
studentIndex]
[dateIndex]
? Colors
    .yellow
    : Colors
    .transparent,

alignment:
Alignment
    .center,

child:
GestureDetector(
onDoubleTap:
() {
setState(() {
highlighted[
studentIndex]
[dateIndex] =
!highlighted[
studentIndex]
[dateIndex];
});
},

child:
Checkbox(
value: attendance[
studentIndex]
[dateIndex],

activeColor:
Colors
    .green,

checkColor:
Colors
    .white,

onChanged:
(value) {
setState(() {
attendance[
studentIndex]
[dateIndex] =
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
),
],
),
),
],
),
);
}
}

