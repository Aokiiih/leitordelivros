import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Leitor de Livros'),
        ),
        body: const BookList(),
      ),
    );
  }
}

class BookList extends StatefulWidget {
  const BookList({Key? key}) : super(key: key);

  @override
  _BookListState createState() => _BookListState();
}

class _BookListState extends State<BookList> {
  final BookService _bookService = BookService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Book>>(
      future: _bookService.fetchBooks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          List<Book> books = snapshot.data!;
          return BookshelfPage(books: books);
        }
      },
    );
  }
}

class BookService {
  static const String apiEndpoint = 'https://escribo.com/books.json';

  Future<List<Book>> fetchBooks() async {
    final response = await http.get(Uri.parse(apiEndpoint));

    if (response.statusCode == 200) {
      List<Map<String, dynamic>> data =
          List<Map<String, dynamic>>.from(json.decode(response.body));
      return data.map((item) => Book.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load books');
    }
  }
}

class Book {
  final String? title;
  final String? coverUrl;

  Book({required this.title, required this.coverUrl});

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      title: json['title'] ?? 'No Title',
      coverUrl: json['coverUrl'] ?? 'https://example.com/placeholder.jpg',
    );
  }
}

class BookshelfPage extends StatelessWidget {
  final List<Book> books;

  BookshelfPage({required this.books});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Estante Virtual'),
      ),
      body: GridView.builder(
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        itemCount: books.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              _downloadAndReadBook(context, books[index]);
            },
            child: Card(
              child: Image.network(books[index].coverUrl!),
            ),
          );
        },
      ),
    );
  }

  void _downloadAndReadBook(BuildContext context, Book book) {
    // Implementar lógica de download e navegação para leitura do livro
    // Utilize o plugin Vocsy Epub Viewer para exibir o conteúdo do livro
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookReaderPage(bookFilePath: book.coverUrl!),
      ),
    );
  }
}

class BookReaderPage extends StatelessWidget {
  final String bookFilePath;

  BookReaderPage({required this.bookFilePath});

  get VocsyEpubViewer => null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leitura do Livro'),
      ),
      body: FutureBuilder<EpubBook>(
        future: VocsyEpubViewer.openBook(bookFilePath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return VocsyEpubViewer(
              book: snapshot.data!,
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao abrir o livro'),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}

class EpubBook {}
