import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Flutter',
      home: RandomWords(),
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        highlightColor: Colors.orange,
      ),
    );
  }
}

class RandomWords extends StatefulWidget {
  const RandomWords({Key? key}) : super(key: key);

  @override
  _RandomWordsState createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final _suggestions = <WordPair>[];
  final _saved = <WordPair>{};
  final _biggerFont = const TextStyle(fontSize: 18);

  FlutterBlue flutterBlue = FlutterBlue.instance;

  Widget _buildRow(WordPair pair) {
    final alreadySaved = _saved.contains(pair);
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon(
        alreadySaved ? Icons.favorite : Icons.favorite_border,
        color: alreadySaved ? Theme.of(context).highlightColor : null,
        semanticLabel: alreadySaved ? 'Remove from saved' : 'Save',
      ),
      onTap: () {
        setState(() {
          if (alreadySaved) {
            _saved.remove(pair);
          } else {
            _saved.add(pair);
          }
        });
      },
    );
  }

  Widget _buildSuggestions() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemBuilder: (BuildContext _context, int i) {
        if (i.isOdd) {
          return Divider();
        }
        final int index = i ~/ 2;
        if (index >= _suggestions.length) {
          _suggestions.addAll(generateWordPairs().take(10));
        }
        return _buildRow(_suggestions[index]);
      },
    );
  }

  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          final tiles = _saved.map(
            (pair) {
              return ListTile(
                title: Text(
                  pair.asPascalCase,
                  style: _biggerFont,
                ),
              );
            },
          );
          final divided = tiles.isNotEmpty
              ? ListTile.divideTiles(
                  context: context,
                  tiles: tiles,
                ).toList()
              : <Widget>[];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Saved Suggestions'),
            ),
            body: ListView(children: divided),
          );
        },
      ),
    );
  }

  late BluetoothDevice _device;
  bool _found = false;

  void searchBluetoothDevices() {
    flutterBlue.startScan(timeout: const Duration(seconds: 4));
    // Listen to scan results
    var subscription = flutterBlue.scanResults.listen((results) async {
      // do something with scan results
      for (ScanResult r in results) {
        if (r.device.name == '4B-2033PA-F2E5') {
          if (!_found) {
            print('${r.device.name} found! rssi: ${r.rssi}');
            _device = r.device;
            _found = true;
          }
          // print(r.device.state);
          // await r.device.connect();
          // try {
          //   await r.device.connect();
          //   print('connected to ${r.device}');
          //   var services = await r.device.discoverServices();
          //   for (BluetoothService service in services) {
          //     print('Service found: ${service.toString()}');
          //     var characteristics = service.characteristics;
          //     //for (BluetoothCharacteristic c in characteristics) {
          //     // List<int> value = await c.read();
          //     //print('Characteristic found: ${value}');
          //     // await c.write([77, 84, 80, 45, 50]);
          //     //}
          //   }
          // } catch (e) {
          //   print('Disconnecting due to error');
          //   r.device.disconnect();
          // }
        } else {
          print('weird device: ' + r.device.name);
        }
      }
    });
    // Stop scanning
    flutterBlue.stopScan();
  }

  void connectToDevice() async {
    if (!_found) {
      print('No device selected');
      return;
    }
    try {
      await _device.connect();
      print('Connected to ${_device.name}');
      var services = await _device.discoverServices();
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      final row = generator.row([
        PosColumn(
          text: 'col3',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: true),
        ),
        PosColumn(
          text: 'col6',
          width: 6,
          styles: PosStyles(align: PosAlign.center, underline: true),
        ),
        PosColumn(
          text: 'col3',
          width: 3,
          styles: PosStyles(align: PosAlign.center, underline: true),
        ),
      ]);
      outer:
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic c in service.characteristics) {
          if (c.properties.writeWithoutResponse) {
            print('PRINTING...');
            print(c.properties);
            // await c.write(generator.qrcode('hola'));
            await c.write([77, 84, 80, 45, 50, 10, 00]);
            await c.write([77, 84, 80, 45, 50, 10, 00]);
            await c.write([77, 84, 80, 45, 50, 10, 00]);
            await c.write([77, 84, 80, 45, 50, 10, 00]);
            await c.write([77, 84, 80, 45, 50, 10, 00]);
            // break outer;
          } else {}
          // List<int> value = await c.read();
          // print(c.descriptors);
          // print('Characteristic found: $value');
        }
      }
    } catch (e) {
      print('Disconnecting due to error $e');
      _device.disconnect();
    }
  }

  void disconnectFromDevice() async {
    if (!_found) {
      print('No device selected');
    }
    print('Disconnecting');
    _found = false;
    _device.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Startup Name Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _pushSaved,
            tooltip: 'Saved Suggestions',
          ),
          IconButton(
            onPressed: searchBluetoothDevices,
            icon: const Icon(Icons.bluetooth_searching),
          ),
          IconButton(
            onPressed: connectToDevice,
            icon: const Icon(Icons.bluetooth),
          ),
          IconButton(
            onPressed: disconnectFromDevice,
            icon: const Icon(Icons.bluetooth_disabled),
          ),
        ],
      ),
      body: _buildSuggestions(),
    );
  }
}
