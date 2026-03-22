import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  // 1. Inicializace Flutteru a Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Evidence knih',
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
  // Odkaz na kolekci "knihy" ve Firestore
  final CollectionReference _knihyRef =
      FirebaseFirestore.instance.collection('knihy');

  // FUNKCE: Přidání knihy do Firebase
  Future<void> _addBookToFirebase(
      String nazev, String autor, int rok, int hodnoceni, String komentar) {
    return _knihyRef.add({
      'nazev': nazev,
      'autor': autor,
      'rok': rok,
      'hodnoceni': hodnoceni,
      'komentar': komentar,
      'vytvoreno': Timestamp.now(), // Abychom mohli řadit od nejnovějších
    });
  }

  // FUNKCE: Smazání knihy z Firebase podle ID dokumentu
  Future<void> _deleteBook(String id) {
    return _knihyRef.doc(id).delete();
  }

  // DIALOG: Formulář pro zadání nové knihy
  void _showAddDialog() {
    final formKey = GlobalKey<FormState>();
    final nazevController = TextEditingController();
    final autorController = TextEditingController();
    final rokController = TextEditingController();
    final komentarController = TextEditingController();
    int rating = 5;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Nová kniha do cloudu"),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nazevController,
                        decoration: const InputDecoration(labelText: "Název"),
                        validator: (v) => (v == null || v.isEmpty) ? "Povinné" : null,
                      ),
                      TextFormField(
                        controller: autorController,
                        decoration: const InputDecoration(labelText: "Autor"),
                        validator: (v) => (v == null || v.isEmpty) ? "Povinné" : null,
                      ),
                      TextFormField(
                        controller: rokController,
                        decoration: const InputDecoration(labelText: "Rok"),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || int.tryParse(v) == null) ? "Číslo!" : null,
                      ),
                      const SizedBox(height: 15),
                      Text("Hodnocení: $rating/10"),
                      Slider(
                        value: rating.toDouble(),
                        min: 1, max: 10, divisions: 9,
                        onChanged: (v) => setStateDialog(() => rating = v.toInt()),
                      ),
                      TextFormField(
                        controller: komentarController,
                        decoration: const InputDecoration(labelText: "Komentář"),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Zrušit"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      _addBookToFirebase(
                        nazevController.text,
                        autorController.text,
                        int.parse(rokController.text),
                        rating,
                        komentarController.text,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Uložit"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cloudová Evidence"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      // StreamBuilder automaticky poslouchá změny v databázi
      body: StreamBuilder(
        stream: _knihyRef.orderBy('vytvoreno', descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Chyba databáze"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Zatím žádné knihy v cloudu."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.menu_book)),
                  title: Text(doc['nazev'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${doc['autor']} (${doc['rok']})\n${doc['hodnoceni']}/10 ⭐"),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteBook(doc.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        label: const Text("Přidat knihu"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}