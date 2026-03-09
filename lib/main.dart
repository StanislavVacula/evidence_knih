import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Evidence knih',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class Book {
  String nazev;
  String autor;
  int rok;
  int hodnoceni;
  String komentar;

  Book({
    required this.nazev,
    required this.autor,
    required this.rok,
    required this.hodnoceni,
    required this.komentar,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Book> knihy = [];

  void _addBook(Book book) {
    setState(() {
      knihy.add(book);
    });
  }

  void _deleteBook(int index) {
    setState(() {
      knihy.removeAt(index);
    });
  }

  void _showAddDialog() {
    final formKey = GlobalKey<FormState>();

    TextEditingController nazevController = TextEditingController();
    TextEditingController autorController = TextEditingController();
    TextEditingController rokController = TextEditingController();
    TextEditingController komentarController = TextEditingController();

    int rating = 5;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Přidat knihu"),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nazevController,
                        decoration: const InputDecoration(
                          labelText: "Název knihy",
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Název nesmí být prázdný";
                          }
                          if (value.length < 2) {
                            return "Název je příliš krátký";
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: autorController,
                        decoration: const InputDecoration(labelText: "Autor"),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Autor nesmí být prázdný";
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: rokController,
                        decoration: const InputDecoration(
                          labelText: "Rok vydání",
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Zadej rok";
                          }

                          int? rok = int.tryParse(value);

                          if (rok == null) {
                            return "Rok musí být číslo";
                          }

                          if (rok < 1000 || rok > DateTime.now().year) {
                            return "Neplatný rok vydání";
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      const Text("Hodnocení (1–10)"),
                      Slider(
                        value: rating.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: rating.toString(),
                        onChanged: (value) {
                          setStateDialog(() {
                            rating = value.toInt();
                          });
                        },
                      ),
                      Text("$rating / 10"),
                      TextFormField(
                        controller: komentarController,
                        decoration: const InputDecoration(
                          labelText: "Komentář",
                        ),
                        maxLength: 200,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Zrušit"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                ElevatedButton(
                  child: const Text("Uložit"),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Book book = Book(
                        nazev: nazevController.text,
                        autor: autorController.text,
                        rok: int.parse(rokController.text),
                        hodnoceni: rating,
                        komentar: komentarController.text,
                      );

                      _addBook(book);

                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget buildStars(int rating) {
    return Row(
      children: List.generate(
        rating,
        (index) => const Icon(Icons.star, color: Colors.amber, size: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Evidence knih")),
      body: knihy.isEmpty
          ? const Center(child: Text("Zatím nejsou přidané žádné knihy"))
          : ListView.builder(
              itemCount: knihy.length,
              itemBuilder: (context, index) {
                final book = knihy[index];

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: const Icon(Icons.book),
                    title: Text(book.nazev),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${book.autor} (${book.rok})"),
                        buildStars(book.hodnoceni),
                        if (book.komentar.isNotEmpty)
                          Text("Komentář: ${book.komentar}"),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        _deleteBook(index);
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
