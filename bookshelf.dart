import 'package:flutter/material.dart';
import 'api_service.dart';
import 'book_detail_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Shelf',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
      ),
      themeMode: _themeMode,
      home: BookSearchPage(toggleTheme: _toggleTheme),
    );
  }
}

class BookSearchPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  const BookSearchPage({super.key, required this.toggleTheme});

  @override
  State<BookSearchPage> createState() => _BookSearchPageState();
}

class _BookSearchPageState extends State<BookSearchPage> {
  List<dynamic> books = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;

  void searchBooks(String query) async {
    setState(() => isLoading = true);
    try {
      final results = await ApiService.fetchBooks(query);
      setState(() {
        books = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching books: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    searchBooks("Z");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Shelf'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
            tooltip: "Toggle Theme",
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // 🔍 Search bar
            TextField(
              controller: searchController,
              onSubmitted: searchBooks,
              decoration: InputDecoration(
                hintText: "Search for books...",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => searchBooks(searchController.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 🔄 Loading or 📖 Book results
            isLoading
                ? const CircularProgressIndicator()
                : Expanded(
              child: books.isEmpty
                  ? const Center(child: Text("No results"))
                  : ListView.builder(
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index]['volumeInfo'];
                  final title = book['title'] ?? 'No title';
                  final thumbnail = book['imageLinks']?['thumbnail'];
                  final author = (book['authors'] != null)
                      ? book['authors'].join(', ')
                      : 'Unknown';
                  final description = book['description'] ?? 'No description available';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: thumbnail != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          thumbnail,
                          width: 50,
                          fit: BoxFit.cover,
                        ),
                      )
                          : const Icon(Icons.book, size: 50),
                      title: Text(title),
                      subtitle: Text('by $author'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookDetailPage(
                              title: title,
                              author: author,
                              description: description,
                              thumbnailUrl: thumbnail,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
