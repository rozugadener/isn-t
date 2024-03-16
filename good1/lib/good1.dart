import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter News App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NewsListPage(),
    );
  }
}

class NewsListPage extends StatefulWidget {
  @override
  _NewsListPageState createState() => _NewsListPageState();
}

class _NewsListPageState extends State<NewsListPage> with AutomaticKeepAliveClientMixin<NewsListPage> {
  List<Article> articles = [];
  String searchQuery = '';
  String selectedCategory = 'General';
  List<Article> savedArticles = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    fetchNews(selectedCategory);
    loadSavedArticles();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter News App'),
      ),
      body: articles.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: articles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(articles[index].title),
                  subtitle: Text(articles[index].description),
                  trailing: IconButton(
                    icon: Icon(savedArticles.contains(articles[index]) ? Icons.bookmark : Icons.bookmark_border),
                    onPressed: () {
                      if (savedArticles.contains(articles[index])) {
                        savedArticles.remove(articles[index]);
                      } else {
                        savedArticles.add(articles[index]);
                      }
                      saveArticles();
                      setState(() {});
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewsDetailPage(article: articles[index]),
                      ),
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Saved'),
        ],
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchPage(),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SavedNewsListPage(savedArticles: savedArticles),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> fetchNews(String category) async {
    final String apiKey = '74bf65d3f8e7499aa9219f4fbba8c207';
    final String url = 'https://newsapi.org/v2/top-headlines?country=us&category=$category&apiKey=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      final List<dynamic> articlesJson = jsonData['articles'];

      setState(() {
        articles = articlesJson.map((json) => Article.fromJson(json)).toList();
      });
    } else {
      throw Exception('Failed to load news');
    }
  }

  void searchNews(String query) async {
    final String apiKey = '74bf65d3f8e7499aa9219f4fbba8c207';
    final String url = 'https://newsapi.org/v2/everything?q=$query&apiKey=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      final List<dynamic> articlesJson = jsonData['articles'];

      setState(() {
        articles = articlesJson.map((json) => Article.fromJson(json)).toList();
      });
    } else {
      throw Exception('Failed to search news');
    }
  }

  void selectCategory(String category) {
    setState(() {
      selectedCategory = category;
    });
    fetchNews(category);
  }

  void saveArticles() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/saved_articles.json');
    final jsonList = savedArticles.map((article) => article.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  void loadSavedArticles() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/saved_articles.json');
    if (file.existsSync()) {
      final jsonString = await file.readAsString();
      final jsonList = jsonDecode(jsonString);
      setState(() {
        savedArticles = jsonList.map<Article>((json) => Article.fromJson(json)).toList();
      });
    }
  }
}

class SearchPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search News'),
      ),
      body: Center(
        child: TextField(
          onChanged: (query) {
            _NewsListPageState().searchNews(query);
          },
          decoration: InputDecoration(
            hintText: 'Enter search query',
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ),
    );
  }
}

class SavedNewsListPage extends StatelessWidget {
  final List<Article> savedArticles;

  SavedNewsListPage({required this.savedArticles});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved News'),
      ),
      body: savedArticles.isEmpty
          ? Center(
              child: Text('No saved articles'),
            )
          : ListView.builder(
              itemCount: savedArticles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(savedArticles[index].title),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewsDetailPage(article: savedArticles[index]),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class Article {
  final String title;
  final String description;

  Article({required this.title, required this.description});

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
    };
  }
}

class NewsDetailPage extends StatelessWidget {
  final Article article;

  NewsDetailPage({required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(article.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(article.description),
          ],
        ),
      ),
    );
  }
}
