import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_app_6/models/category.dart';
import '../data/categories.dart';
import '../models/grocery_item.dart';
import '../screens/new_item_page.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryList = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    _loadItems();
    super.initState();
  }

  void _loadItems() async {
    final url = Uri.https(
        "shopping-app-lr-default-rtdb.firebaseio.com", "shopping-list.json");

    try {
      final response = await http.get(url);

      if (response.body == "null") {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (response.statusCode >= 400) {
        setState(() {
          _error = "Error loading data";
        });
      }
      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedList = [];

      for (final item in listData.entries) {
        final Category loadedCategory = categories.entries
            .singleWhere((value) => value.value.title == item.value["category"])
            .value;

        loadedList.add(GroceryItem(
            id: item.key,
            name: item.value["name"],
            quantity: item.value["quantity"],
            category: loadedCategory));
      }
      setState(() {
        _groceryList = loadedList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error loading data, please try again";
      });
    }
  }

  void removeItem(GroceryItem item) async {
    final index = _groceryList.indexOf(item);
    setState(() {
      _groceryList.remove(item);
    });

    final url = Uri.https("shopping-app-lr-default-rtdb.firebaseio.com",
        "shopping-list/${item.id}.json");
    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryList.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text("No Items Added Yet"),
    );

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryList.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryList.length,
        itemBuilder: (ctx, index) => Dismissible(
          key: ValueKey(_groceryList[index].id),
          onDismissed: (direction) {
            removeItem(_groceryList[index]);
          },
          child: ListTile(
            title: Text(_groceryList[index].name),
            leading: CircleAvatar(
              radius: 15,
              backgroundColor: _groceryList[index].category.color,
            ),
            trailing: Text(
              _groceryList[index].quantity.toString(),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      content = Center(
        child: Text(_error!),
      );
    }

    void addItem() async {
      final response = await Navigator.of(context).push<GroceryItem>(
          MaterialPageRoute(builder: ((context) => const NewItemPage())));

      setState(() {
        _groceryList.add(response!);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: addItem,
          ),
        ],
      ),
      body: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _loadItems();
            });
          },
          child: Padding(
              padding: const EdgeInsets.only(top: 15.0), child: content)),
    );
  }
}
