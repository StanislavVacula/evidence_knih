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
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.light,
          primary: const Color(0xFF1976D2), 
          secondary: const Color(0xFF1E88E5),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1976D2),
          foregroundColor: Colors.white,
          elevation: 2,
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
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

  // PŘIDÁNÍ KNIHY (přidáno pole 'precteno')
  Future<void> _addBook(String nazev, String autor, int rok, int hodnoceni, String komentar, int stranka, bool precteno) {
    return _knihyCollection.add({
      'nazev': nazev,
      'autor': autor,
      'rok': rok,
      'hodnoceni': hodnoceni,
      'komentar': komentar,
      'stranka': stranka,
      'precteno': precteno,
      'datum_pridani': FieldValue.serverTimestamp(),
    });
  }

  // ÚPRAVA KNIHY
  Future<void> _updateBook(String id, String nazev, String autor, int rok, int hodnoceni, String komentar, int stranka, bool precteno) {
    return _knihyCollection.doc(id).update({
      'nazev': nazev,
      'autor': autor,
      'rok': rok,
      'hodnoceni': hodnoceni,
      'komentar': komentar,
      'stranka': stranka,
      'precteno': precteno,
    });
  }

  // SMAZÁNÍ KNIHY
  Future<void> _confirmDelete(String id, String nazev) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false, 
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Smazat knihu?"),
        content: Text("Opravdu chcete smazat knihu '$nazev'? Tato akce je nevratná."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ZRUŠIT"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red[700]), 
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("SMAZAT"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _knihyCollection.doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Kniha '$nazev' byla smazána."),
            backgroundColor: Colors.black87,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Color _getRatingColor(int rating) {
    if (rating >= 8) return Colors.green[700]!; 
    if (rating >= 5) return Colors.orange[700]!; 
    return Colors.red[700]!; 
  }

  // DIALOG S PŘEPÍNAČEM PŘEČTENO / STRÁNKA
  void _showBookDialog({String? docId, Map<String, dynamic>? data}) {
    final formKey = GlobalKey<FormState>();
    final nazevController = TextEditingController(text: data?['nazev'] ?? '');
    final autorController = TextEditingController(text: data?['autor'] ?? '');
    final rokController = TextEditingController(text: data?['rok']?.toString() ?? '');
    final strankaController = TextEditingController(text: data?['stranka']?.toString() ?? '0');
    final komentarController = TextEditingController(text: data?['komentar'] ?? '');
    int rating = data?['hodnoceni'] ?? 5;
    bool isPrecteno = data?['precteno'] ?? false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Colors.white, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.all(20),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1976D2),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  docId == null ? "PŘIDAT KNIHU" : "UPRAVIT KNIHU",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
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
                  
                  // PŘEPÍNAČ PŘEČTENO
                  CheckboxListTile(
                    title: const Text("Již přečteno?"),
                    value: isPrecteno,
                    activeColor: const Color(0xFF1976D2),
                    onChanged: (bool? value) {
                      setStateDialog(() {
                        isPrecteno = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: rokController,
                          decoration: const InputDecoration(labelText: "Rok", border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          validator: (v) => int.tryParse(v ?? '') == null ? "Rok?" : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // POLÍČKO STRÁNKA (Zobrazí se jen pokud není přečteno)
                      if (!isPrecteno)
                        Expanded(
                          child: TextFormField(
                            controller: strankaController,
                            decoration: const InputDecoration(labelText: "Stránka", border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text("Moje hodnocení: $rating/10", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: rating.toDouble(),
                    min: 1, max: 10, divisions: 9,
                    label: rating.toString(),
                    activeColor: const Color(0xFF1976D2), 
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
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          int curPage = isPrecteno ? 0 : (int.tryParse(strankaController.text) ?? 0);
                          if (docId == null) {
                            _addBook(nazevController.text, autorController.text, int.parse(rokController.text), rating, komentarController.text, curPage, isPrecteno);
                          } else {
                            _updateBook(docId, nazevController.text, autorController.text, int.parse(rokController.text), rating, komentarController.text, curPage, isPrecteno);
                          }
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.cloud_done),
                      label: Text(docId == null ? "ULOŽIT" : "AKTUALIZOVAT"),
                    ),
                  ),
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
      appBar: AppBar(
        title: const Text("📚 Evidence Knih"),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double preferredWidth = constraints.maxWidth > 800 ? 800 : constraints.maxWidth;
          return Center(
            child: SizedBox(
              width: preferredWidth, 
              child: StreamBuilder(
                stream: _knihyCollection.orderBy('datum_pridani', descending: true).snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) return const Center(child: Text("Chyba databáze!"));
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      var data = doc.data() as Map<String, dynamic>;
                      Color hodnoceniBarva = _getRatingColor(data['hodnoceni']);
                      bool precteno = data['precteno'] ?? false;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          onTap: () => _showBookDialog(docId: doc.id, data: data),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          leading: CircleAvatar(
                            backgroundColor: hodnoceniBarva.withOpacity(0.1),
                            radius: 28,
                            child: Text("${data['hodnoceni']}", style: TextStyle(fontWeight: FontWeight.bold, color: hodnoceniBarva, fontSize: 20)),
                          ),
                          title: Text(data['nazev'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${data['autor']} • ${data['rok']}"),
                                const SizedBox(height: 6),
                                // PODMÍNĚNÉ ZOBRAZENÍ STAVU
                                precteno 
                                  ? const Row(
                                      children: [
                                        Icon(Icons.check_circle, size: 16, color: Colors.green),
                                        SizedBox(width: 5),
                                        Text("Přečteno", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        const Icon(Icons.menu_book, size: 16, color: Color(0xFF1976D2)),
                                        SizedBox(width: 5),
                                        Text("Aktuálně na straně: ${data['stranka'] ?? 0}", style: const TextStyle(color: Color(0xFF1976D2))),
                                      ],
                                    ),
                              ],
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey),
                            onPressed: () => _confirmDelete(doc.id, data['nazev']),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
        }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBookDialog(),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}