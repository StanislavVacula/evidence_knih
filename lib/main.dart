import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
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
      title: 'Knihovna v Cloudu',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
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
  final CollectionReference _knihyCollection =
      FirebaseFirestore.instance.collection('knihy');

  // PŘIDÁNÍ KNIHY
  Future<void> _addBook(String nazev, String autor, int rok, int hodnoceni, String komentar) {
    return _knihyCollection.add({
      'nazev': nazev,
      'autor': autor,
      'rok': rok,
      'hodnoceni': hodnoceni,
      'komentar': komentar,
      'datum_pridani': FieldValue.serverTimestamp(),
    });
  }

  // ÚPRAVA KNIHY (Update)
  Future<void> _updateBook(String id, String nazev, String autor, int rok, int hodnoceni, String komentar) {
    return _knihyCollection.doc(id).update({
      'nazev': nazev,
      'autor': autor,
      'rok': rok,
      'hodnoceni': hodnoceni,
      'komentar': komentar,
    });
  }

  // SMAZÁNÍ KNIHY
  Future<void> _deleteBook(String id) {
    return _knihyCollection.doc(id).delete();
  }

  // SPOLEČNÝ DIALOG PRO PŘIDÁNÍ I ÚPRAVU
  void _showBookDialog({String? docId, Map<String, dynamic>? data}) {
    final formKey = GlobalKey<FormState>();
    final nazevController = TextEditingController(text: data?['nazev'] ?? '');
    final autorController = TextEditingController(text: data?['autor'] ?? '');
    final rokController = TextEditingController(text: data?['rok']?.toString() ?? '');
    final komentarController = TextEditingController(text: data?['komentar'] ?? '');
    int rating = data?['hodnoceni'] ?? 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(docId == null ? "Nová kniha" : "Upravit knihu", style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: nazevController,
                    decoration: const InputDecoration(labelText: "Název", border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? "Vyplňte název" : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: autorController,
                    decoration: const InputDecoration(labelText: "Autor", border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? "Vyplňte autora" : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: rokController,
                    decoration: const InputDecoration(labelText: "Rok vydání", border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => int.tryParse(v ?? '') == null ? "Zadejte rok" : null,
                  ),
                  const SizedBox(height: 15),
                  Text("Moje hodnocení: $rating/10"),
                  Slider(
                    value: rating.toDouble(),
                    min: 1, max: 10, divisions: 9,
                    label: rating.toString(),
                    onChanged: (v) => setStateDialog(() => rating = v.toInt()),
                  ),
                  TextFormField(
                    controller: komentarController,
                    decoration: const InputDecoration(labelText: "Poznámka", border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          if (docId == null) {
                            _addBook(nazevController.text, autorController.text, int.parse(rokController.text), rating, komentarController.text);
                          } else {
                            _updateBook(docId, nazevController.text, autorController.text, int.parse(rokController.text), rating, komentarController.text);
                          }
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.cloud_done),
                      label: Text(docId == null ? "ULOŽIT DO CLOUDU" : "AKTUALIZOVAT"),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("📚 Evidence Knih"),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: StreamBuilder(
        stream: _knihyCollection.orderBy('datum_pridani', descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Něco se nepovedlo..."));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Knihovna je prázdná", style: TextStyle(fontSize: 18, color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  onTap: () => _showBookDialog(docId: doc.id, data: data), // KLIKNUTÍM UPRAVÍŠ
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal[100],
                    child: Text("${data['hodnoceni']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                  ),
                  title: Text(data['nazev'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text("${data['autor']} • ${data['rok']}\n${data['komentar'] ?? ''}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                    onPressed: () => _deleteBook(doc.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBookDialog(),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Nová kniha"),
      ),
    );
  }
}