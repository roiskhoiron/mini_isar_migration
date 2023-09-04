import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:mini_isar_migration/dbms_provider.dart';

import 'file_manager_provider.dart';

part 'main.g.dart';

@collection
class Count {
  final Id id;

  final int step;

  Count(this.id, this.step);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Isar
  await Isar.initializeIsarCore();

  // prepare directory for database
  await FileManagerProvider.setup();

  // Open Isar instance

  final dbms = DbmsProvider(isar: await initIsar());
  print('database directory: ${dbms.isar.directory}');

  // Run app
  runApp(CounterApp(db: dbms));
}

class CounterApp extends StatefulWidget {
  late DbmsProvider db;
  CounterApp({super.key, required this.db});

  @override
  State<CounterApp> createState() => _CounterAppState(db: db);
}

class _CounterAppState extends State<CounterApp> {
  final DbmsProvider db;

  _CounterAppState({required this.db});

  @override
  void initState() {
    super.initState();
  }

  void _incrementCounter() async {
    // Persist counter value to database
    await db.isar.writeTxn(
      () async {
        await db.isar.counts.put(
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
    final count = db.isar.counts.where().stepProperty().sumSync();
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
