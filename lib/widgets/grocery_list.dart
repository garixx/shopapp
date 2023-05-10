import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shopapp/data/categories.dart';

import '../widgets/new_item.dart';
import '../data/dummy_items.dart';
import '../models/grocery_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({Key? key}) : super(key: key);

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  String? _error;
  List<GroceryItem> _groceryItems = [];//groceryItems;
  var _isLoading = true;
  var logger = Logger();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https('flutter-prep-6bfa2-default-rtdb.firebaseio.com', 'shopping-list.json');
    final response = await http.get(url, headers: {'Content-Type': 'application/json'});
    logger.i(response.body);

    if (response.statusCode != 200) {
      setState(() {
        _error = '${response.statusCode} received. Please try again later';
      });
    }

    if (response.body == 'null') {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final Map<String, dynamic>listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries.firstWhere((cat) => cat.value.title == item.value['category']).value;
      loadedItems.add(GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category)
      );
      //await Future.delayed(Duration(seconds: 3)); // long load imitation
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context)
        .push<GroceryItem>(MaterialPageRoute(builder: (ctx) => const NewItem())
    );

    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async  {
    final url = Uri.https('flutter-prep-6bfa2-default-rtdb.firebaseio.com', 'shopping-list/${item.id}.json');
    final response  = await http.delete(url);
    logger.i(response.body);
    if (response.statusCode != 204) {
      // setState(() {
      //   _error = '${response.statusCode} received. Please try again later';
      // });
    }
    if (response.statusCode == 204) {
      setState(() {
        _groceryItems.remove(item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text('No items added yet.'),);
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator(),);
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
          itemCount: _groceryItems.length,
          itemBuilder: (ctx, index) {
            return Dismissible(
              onDismissed: (direction) {
                _removeItem(_groceryItems[index]);
              },
              key: ValueKey(_groceryItems[index].id),
              child: ListTile(
                title: Text(_groceryItems[index].name),
                leading: Container(
                  width: 24,
                  height: 24,
                  color: _groceryItems[index].category.color,
                ),
                trailing: Text(_groceryItems[index].quantity.toString()),
              ),
            );
          });
    }

    if (_error != null) {
      content = Center(child: Text(_error!),);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: Icon(Icons.add),
          )
        ],
      ),
      body: content,
    );
  }
}
