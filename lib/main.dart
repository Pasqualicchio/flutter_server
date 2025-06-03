import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestione Foto',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final commessaController = TextEditingController();
  final matricolaController = TextEditingController();
  final itemController = TextEditingController();

 
  List<Uint8List> _selectedImages = [];
  bool _imagesPendingUpload = false;

  String _macroCategoria = '00 = Rilievi';
  String? _linea;
  String? _step;

  final List<String> macroCategorie = [
    '00 = Rilievi',
    '01 = Produzione',
    '02 = As build',
    '03 = Spedizione',
    '04 = Montaggio',
    '05 = Funzionamento',
    '06 = Inconvenienti',
    '07 = Magazzino',
    '08 = Laboratorio',
  ];

  final Map<String, List<String>> lineaSteps = {
    'FILM': [
      'FEEDING SECTION',
      'PREWASHING',
      'GRINDER',
      'WATER FILTRATION',
      'WASHING + SEPARATION',
      'DRY',
      'ALTRI'
    ],
    'PET': [
      'FEEDING SECTION',
      'HOT PREWASHING',
      'GRINDER',
      'WATER FILTRATION',
      'HOT WASHING',
      'SEPARATION + RINSING',
      'DRY',
      'AERODYNAMIC SEPARATOR',
      'SILO + BIG BAGS',
      'ALTRI'
    ]
  };

  @override
  void initState() {
    super.initState();
    _uploadSavedOfflineImages();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();

    if (source == ImageSource.gallery) {
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        final bytesList = await Future.wait(images.map((img) => img.readAsBytes()));
        setState(() {
          _selectedImages = bytesList;
        
          _imagesPendingUpload = true;
        });
      }
    } else {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImages = [bytes];
         
          _imagesPendingUpload = true;
        });
      }
    }
  }

  Future<void> _attemptUpload(Uint8List bytes) async {
    final commessa = commessaController.text.trim();
    final matricola = matricolaController.text.trim();
    final item = itemController.text.trim();

    if (commessa.isEmpty || matricola.isEmpty || item.isEmpty) {
      _showMessage('⚠️ Tutti i campi sono obbligatori');
      return;
    }

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      await _saveImageOffline(bytes, commessa, matricola, item);
      _showMessage('📁 Nessuna connessione: immagine salvata offline');
    } else {
      await _uploadImageOnline(bytes, commessa, matricola, item);
    }
  }

  Future<void> _uploadImageOnline(Uint8List imageBytes, String commessa, String matricola, String item) async {
    final uri = Uri.parse('http://172.19.65.41:5000/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['macro'] = _macroCategoria
      ..fields['linea'] = _macroCategoria == '05 = Funzionamento' ? (_linea ?? '') : ''
      ..fields['step'] = _macroCategoria == '05 = Funzionamento' ? (_step ?? '') : ''
      ..fields['commessa'] = commessa
      ..fields['matricola'] = matricola
      ..fields['item'] = item
      ..files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'foto.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));

    try {
      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (!mounted) return;

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(body);
          final message = jsonResponse['message'] ?? '✅ Immagine inviata con successo';
          _showMessage(message);
        } catch (_) {
          _showMessage('✅ Immagine inviata con successo');
        }
      } else {
        _showMessage('❌ Errore server: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('❌ Errore rete: $e');
    }
  }

  Future<void> _uploadAllSelectedImages() async {
    for (final image in _selectedImages) {
      await _attemptUpload(image);
    }
    setState(() {
      _selectedImages.clear();
      
      _imagesPendingUpload = false;
    });
    _showMessage("✅ Foto inviate con successo");
  }

  Future<void> _saveImageOffline(Uint8List bytes, String commessa, String matricola, String item) async {
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'offline_$ts.jpg';
    final filePath = path.join(dir.path, fileName);

    await File(filePath).writeAsBytes(bytes);

    final metadata = {
      'macro': _macroCategoria,
      'linea': _linea ?? '',
      'step': _step ?? '',
      'commessa': commessa,
      'matricola': matricola,
      'item': item,
      'filePath': filePath,
    };
    await File('$filePath.json').writeAsString(jsonEncode(metadata));
  }

  Future<void> _uploadSavedOfflineImages() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync();

    for (final file in files) {
      if (file.path.endsWith('.json')) {
        final jsonFile = File(file.path);
        final imageFile = File(file.path.replaceAll('.json', ''));

        if (await imageFile.exists()) {
          final content = await jsonFile.readAsString();
          final data = jsonDecode(content);

          final bytes = await imageFile.readAsBytes();

          await _uploadImageOnline(
            bytes,
            data['commessa'],
            data['matricola'],
            data['item'],
          );

          await jsonFile.delete();
          await imageFile.delete();
        }
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isFunzionamento = _macroCategoria == '05 = Funzionamento';

    return Scaffold(
      appBar: AppBar(title: const Text('Gestione Fotografica')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _macroCategoria,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: macroCategorie.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() {
                  _macroCategoria = val!;
                  _linea = null;
                  _step = null;
                }),
              ),
              if (isFunzionamento)
                DropdownButtonFormField<String>(
                  value: _linea,
                  decoration: const InputDecoration(labelText: 'Linea'),
                  items: ['FILM', 'PET'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() {
                    _linea = val;
                    _step = null;
                  }),
                ),
              if (isFunzionamento && _linea != null)
                DropdownButtonFormField<String>(
                  value: _step,
                  decoration: const InputDecoration(labelText: 'Step'),
                  items: lineaSteps[_linea!]!.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _step = val),
                ),
              TextField(controller: commessaController, decoration: const InputDecoration(labelText: 'Commessa')),
              TextField(controller: matricolaController, decoration: const InputDecoration(labelText: 'Matricola')),
              TextField(controller: itemController, decoration: const InputDecoration(labelText: 'Numero Item')),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Fotocamera'),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galleria'),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_imagesPendingUpload)
                Column(
                  children: [
                    Text("📸 ${_selectedImages.length} foto selezionate. Confermare l'invio?"),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text("Conferma invio"),
                      onPressed: _uploadAllSelectedImages,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
const SizedBox(height: 20),
              if (_imagesPendingUpload)
                Column(
                  children: [
                    Text("📸 ${_selectedImages.length} foto selezionate. Confermare l'invio?"),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text("Conferma invio"),
                      onPressed: _uploadAllSelectedImages,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
if (_selectedImages.isNotEmpty)
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("Anteprima foto selezionate:"),
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _selectedImages.map((imgBytes) {
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  imgBytes,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ],
  ),
            ],
          ),
        ),
      ),
    );
  }
}
