import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDb.instance.database;
  runApp(const DrAzizurApp());
}

class DrAzizurApp extends StatelessWidget {
  const DrAzizurApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Dr. Azizur',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1769AA)),
      scaffoldBackgroundColor: const Color(0xFFF5F8FC),
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    ),
    home: const LoginPage(),
  );
}

class LocalDb {
  LocalDb._();
  static final instance = LocalDb._();
  Database? _db;
  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'dr_azizur.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE appointments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          age INTEGER NOT NULL,
          phone TEXT NOT NULL,
          patient_type TEXT NOT NULL,
          appointment_date TEXT NOT NULL,
          serial INTEGER NOT NULL,
          notes TEXT,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('CREATE UNIQUE INDEX unique_daily_serial ON appointments(appointment_date, serial)');
    });
    return _db!;
  }

  Future<int> addAppointment(Map<String, Object?> data) async {
    final db = await database;
    return db.insert('appointments', data);
  }

  Future<List<Map<String, Object?>>> forDate(String date) async {
    final db = await database;
    return db.query('appointments', where: 'appointment_date = ?', whereArgs: [date], orderBy: 'serial ASC');
  }

  Future<List<Map<String, Object?>>> all() async {
    final db = await database;
    return db.query('appointments', orderBy: 'appointment_date DESC, serial ASC');
  }

  Future<int> nextSerial(String date) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COALESCE(MAX(serial), 0) + 1 AS next FROM appointments WHERE appointment_date = ?',
      [date],
    );
    return (rows.first['next'] as int?) ?? 1;
  }

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final user = TextEditingController();
  final pass = TextEditingController();
  String error = '';
  void login() {
    final u = user.text.trim().toLowerCase();
    final pw = pass.text;
    String? role;
    if (u == 'doctor' && pw == 'doctor123') role = 'Doctor';
    if (u == 'assistant' && pw == 'assistant123') role = 'Assistant';
    if (role == null) {
      setState(() => error = 'Login তথ্য সঠিক নয়। Demo credentials ব্যবহার করুন।');
      return;
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Dashboard(role: role!)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(borderRadius: BorderRadius.circular(24),
            child: Image.asset('assets/doctor_logo.png', height: 190, width: 190, fit: BoxFit.cover)),
          const SizedBox(height: 14),
          const Text('Dr. Azizur', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          const Text('Doctor Appointment Manager', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 28),
          TextField(controller: user, decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person))),
          const SizedBox(height: 12),
          TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock))),
          if (error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: login, child: const Text('Login'))),
          const SizedBox(height: 16),
          const Text('Demo: doctor / doctor123', style: TextStyle(fontSize: 12, color: Colors.black54)),
          const Text('Demo: assistant / assistant123', style: TextStyle(fontSize: 12, color: Colors.black54)),
        ]),
      ),
    )),
  );
}

class Dashboard extends StatefulWidget {
  final String role;
  const Dashboard({super.key, required this.role});
  @override
  State<Dashboard> createState() => _DashboardState();
}
class _DashboardState extends State<Dashboard> {
  List<Map<String, Object?>> records = [];
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  @override
  void initState() { super.initState(); refresh(); }
  Future<void> refresh() async {
    final data = await LocalDb.instance.forDate(today);
    if (mounted) setState(() => records = data);
  }
  int get newCount => records.where((r) => r['patient_type'] == 'New').length;
  int get oldCount => records.where((r) => r['patient_type'] == 'Old').length;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('${widget.role} Dashboard'),
      actions: [IconButton(onPressed: refresh, icon: const Icon(Icons.refresh)), IconButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())), icon: const Icon(Icons.logout))],
    ),
    floatingActionButton: widget.role == 'Assistant'
      ? FloatingActionButton.extended(onPressed: () async {
          final saved = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPatientPage()));
          if (saved == true) refresh();
        }, icon: const Icon(Icons.person_add), label: const Text('New Appointment'))
      : null,
    body: RefreshIndicator(onRefresh: refresh, child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/doctor_logo.png', width: 66, height: 66, fit: BoxFit.cover)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Dr. Azizur', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
            Text('Physical Medicine • Appointment Register'),
          ])),
        ]),
        const SizedBox(height: 18),
        Text("Today's Overview • $today", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 10),
        Row(children: [
          _stat('Total', records.length, Colors.blue),
          const SizedBox(width: 8),
          _stat('New', newCount, Colors.indigo),
          const SizedBox(width: 8),
          _stat('Old', oldCount, Colors.green),
        ]),
        const SizedBox(height: 20),
        const Text("Today's Appointments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 8),
        if (records.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(22), child: Center(child: Text('আজকের কোনো appointment নেই।')))),
        ...records.map((r) => Card(
          child: ListTile(
            leading: CircleAvatar(child: Text((r['serial'] as int).toString().padLeft(3, '0'))),
            title: Text('${r['name']}  •  ${r['patient_type']} Patient'),
            subtitle: Text('Age: ${r['age']}  |  Phone: ${r['phone']}'),
            trailing: widget.role == 'Assistant'
              ? IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async {
                  await LocalDb.instance.delete(r['id'] as int); refresh();
                })
              : null,
          ),
        )),
        const SizedBox(height: 18),
        OutlinedButton.icon(onPressed: () async {
          final all = await LocalDb.instance.all();
          if (!context.mounted) return;
          Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryPage(records: all)));
        }, icon: const Icon(Icons.history), label: const Text('Appointment History')),
        const SizedBox(height: 50),
      ],
    )),
  );

  Widget _stat(String label, int value, Color color) => Expanded(child: Card(
    child: Padding(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(children: [
        Text('$value', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ]),
    ),
  ));
}

class AddPatientPage extends StatefulWidget {
  const AddPatientPage({super.key});
  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}
class _AddPatientPageState extends State<AddPatientPage> {
  final name = TextEditingController();
  final age = TextEditingController();
  final phone = TextEditingController();
  final notes = TextEditingController();
  String type = 'New';
  bool listening = false;
  final speech = stt.SpeechToText();

  Future<void> voice() async {
    final available = await speech.initialize();
    if (!available) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Speech recognition unavailable. Manual entry ব্যবহার করুন।')));
      return;
    }
    setState(() => listening = true);
    speech.listen(localeId: 'bn_BD', onResult: (result) {
      final spoken = result.recognizedWords;
      if (spoken.isNotEmpty) {
        // Dictation is placed in the name field for review; other fields remain manually editable.
        name.text = spoken;
      }
    });
  }

  Future<void> save() async {
    final n = name.text.trim();
    final a = int.tryParse(age.text.trim());
    final ph = phone.text.trim();
    if (n.isEmpty || a == null || ph.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('নাম, সঠিক বয়স ও ফোন নম্বর দিন।')));
      return;
    }
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final serial = await LocalDb.instance.nextSerial(date);
    await LocalDb.instance.addAppointment({
      'name': n, 'age': a, 'phone': ph, 'patient_type': type,
      'appointment_date': date, 'serial': serial, 'notes': notes.text.trim(),
      'created_at': DateTime.now().toIso8601String(),
    });
    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    name.dispose(); age.dispose(); phone.dispose(); notes.dispose(); speech.stop(); super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('New Appointment')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'New', label: Text('New Patient'), icon: Icon(Icons.person_add)),
          ButtonSegment(value: 'Old', label: Text('Old Patient'), icon: Icon(Icons.person)),
        ],
        selected: {type}, onSelectionChanged: (s) => setState(() => type = s.first),
      ),
      const SizedBox(height: 16),
      TextField(controller: name, decoration: InputDecoration(labelText: 'Patient Name', suffixIcon: IconButton(
        icon: Icon(listening ? Icons.mic : Icons.mic_none),
        onPressed: () async { if (listening) { await speech.stop(); setState(() => listening = false); } else { await voice(); } },
      ))),
      const SizedBox(height: 12),
      TextField(controller: age, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age')),
      const SizedBox(height: 12),
      TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
      const SizedBox(height: 12),
      TextField(controller: notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes (optional)')),
      const SizedBox(height: 20),
      FilledButton.icon(onPressed: save, icon: const Icon(Icons.check_circle), label: const Text('Confirm Appointment')),
      const SizedBox(height: 8),
      const Text('SMS sending is disabled. Records are stored locally on this device.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 12)),
    ]),
  );
}

class HistoryPage extends StatelessWidget {
  final List<Map<String, Object?>> records;
  const HistoryPage({super.key, required this.records});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Appointment History')),
    body: records.isEmpty ? const Center(child: Text('No records found')) : ListView.builder(
      padding: const EdgeInsets.all(12), itemCount: records.length,
      itemBuilder: (_, i) {
        final r = records[i];
        return Card(child: ListTile(
          leading: CircleAvatar(child: Text((r['serial'] as int).toString().padLeft(3, '0'))),
          title: Text('${r['name']} • ${r['patient_type']}'),
          subtitle: Text('${r['appointment_date']} | Age ${r['age']} | ${r['phone']}'),
        ));
      },
    ),
  );
}
