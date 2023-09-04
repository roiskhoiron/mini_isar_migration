import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

part 'main.g.dart';

@collection
class Count {
  final Id id;

  final int step;

  Count(this.id, this.step);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Isar.initializeIsarCore();
  // prepare directory for database
  await Permission.storage.request().isGranted;
  final directory = await getApplicationDocumentsDirectory();
  print('database directory: ${directory.path}');
  // Open Isar instance
  final _isar = await Isar.open(
    [CountSchema],
    directory: directory.path,
  );
  runApp(CounterApp(db: _isar));
}

class CounterApp extends StatefulWidget {
  late Isar db;
  CounterApp({super.key, required this.db});

  @override
  State<CounterApp> createState() => _CounterAppState(isar: db);
}

class _CounterAppState extends State<CounterApp> {
  final Isar isar;

  _CounterAppState({required this.isar});

  @override
  void initState() {
    super.initState();
  }

  void _incrementCounter() async {
    // Persist counter value to database
    await isar.writeTxn(
      () async {
        await isar.counts.put(
          Count(Isar.autoIncrement, 1),
        );
      },
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // This is just for demo purposes. You shouldn't perform database queries
    // in the build method.
    final count = isar.counts.where().stepProperty().sumSync();
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
      useMaterial3: true,
    );
    return MaterialApp(
      title: 'Isar Counter',
      theme: theme,
      home: Scaffold(
        appBar: AppBar(title: const Text('Isar Counter')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'You have pushed the button this many times:',
              ),
              Text('$count', style: theme.textTheme.headlineMedium),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _incrementCounter,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
