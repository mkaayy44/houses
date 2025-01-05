import 'package:flutter/material.dart';
/// import 'product_search.dart';
/// 

import 'dart:convert' as convert;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Base URL for REST API on the local server
const String _baseURL = '127.0.0.1'; // Replace with your local machine's IP


// Class to represent a row from the houses table
class House {
  final int hid;
  final String name;
  final int size;
  final double price;
  final String category;

  House(this.hid, this.name, this.size, this.price, this.category);

  @override
  String toString() {
    return 'HID: $hid\nName: $name\nSize: $size sqm\nPrice: \$${price.toStringAsFixed(2)}\nCategory: $category';
  }
}

// List to hold houses retrieved from getHouses
List<House> _houses = [];

// Asynchronously update the _houses list
void updateHouses(Function(bool success) update) async {
  try {
    final url = Uri.http(_baseURL, '/houses/getHouses.php');
    final response = await http.get(url).timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      print('Error: ${response.statusCode}');
      update(false);
      return;
    }

    final jsonResponse = convert.jsonDecode(response.body);
    if (jsonResponse == null || jsonResponse.isEmpty) {
      print('No houses found or invalid response');
      update(false);
      return;
    }

    _houses.clear();
    for (var row in jsonResponse) {
      try {
        House h = House(
          int.parse(row['hid']),
          row['name'],
          int.parse(row['size']),
          double.parse(row['price']),
          row['category'], // Correct key used here
        );
        _houses.add(h);
      } catch (e) {
        print('Error parsing house: $e');
      }
    }

    update(true);
  } catch (e) {
    print('Error: $e');
    update(false);
  }
}


// Search for a single house by category
void searchHouse(Function(String text) update, String category) async {
  try {
    // Ensure the category is trimmed and not empty
    if (category.isEmpty) {
      update("Please enter a valid category.");
      return;
    }

    // API call to fetch houses by category
    final url = Uri.http(_baseURL, '/houses/searchHouse.php', {'Category': category});
    final response = await http.get(url).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final jsonResponse = convert.jsonDecode(response.body);

      // Check if any houses were returned
      if (jsonResponse == null || jsonResponse.isEmpty) {
        update("No houses found in the '$category' category.");
        return;
      }

      // Clear existing houses and add only the filtered ones
      _houses.clear();
      for (var row in jsonResponse) {
        if (row['category'] == category) {
          try {
            House h = House(
              int.parse(row['hid']),
              row['name'],
              int.parse(row['size']),
              double.parse(row['price']),
              row['category'],
            );
            _houses.add(h);
          } catch (e) {
            print('Error parsing house: $e');
          }
        }
      }

      // Display the list of houses matching the category
      if (_houses.isEmpty) {
        update("No houses found in the '$category' category.");
      } else {
        update(_houses.map((house) => house.toString()).join('\n\n'));
      }
    } else {
      update("Failed to fetch data. Status code: ${response.statusCode}");
    }
  } catch (e) {
    update("Error fetching data: $e");
  }
}



// Widget to display the list of houses
class ShowHouses extends StatelessWidget {
  const ShowHouses({super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    if (_houses.isEmpty) {
      return Center(
        child: Text(
          'No houses available',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _houses.length,
      itemBuilder: (context, index) => Column(
        children: [
          const SizedBox(height: 10),
          Container(
            color: index % 2 == 0
                ? const Color.fromARGB(255, 132, 181, 142)
                : const Color.fromARGB(255, 236, 203, 232),
            padding: const EdgeInsets.all(5),
            width: width * 0.9,
            child: Row(
              children: [
                SizedBox(width: width * 0.15),
                Flexible(
                  child: Text(
                    _houses[index].toString(),
                    style: TextStyle(fontSize: width * 0.045),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// Widget to search houses
class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _controllerID = TextEditingController();
  String _text = '';

  @override
  void dispose() {
    _controllerID.dispose();
    super.dispose();
  }

  void update(String text) {
    setState(() {
      _text = text;
    });
  }

  void getHouse() {
    String category = _controllerID.text.trim();
    if (category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid category')),
      );
      return;
    }

    searchHouse(update, category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search for your house by category:'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 10),
            SizedBox(
              width: 200,
              child: TextField(
                controller: _controllerID,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter Category',
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: getHouse,
              child: const Text('Find', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 10),
            Center(
              child: SingleChildScrollView(
                child: Text(
                  _text,
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _load = false; // used to show products list or progress bar

  void update(bool success) {
    setState(() {
      _load = true; // show product list
      if (!success) { // API request failed
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('failed to load data')));
      }
    });
  }


  @override
  void initState() {
    // update data when the widget is added to the tree the first tome.
    updateHouses(update);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(actions: [
          IconButton(onPressed: !_load ? null : () {
            setState(() {
              _load = false; // show progress bar
              updateHouses(update); // update data asynchronously
            });
          }, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: () {
            setState(() { // open the search product page
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const Search())
              );
            });
          }, icon: const Icon(Icons.search))
        ],
          title: const Text('All Our Available Houses'),
          centerTitle: true,
        ),
        // load products or progress bar
        body: _load ? const ShowHouses() : const Center(
            child: SizedBox(width: 100, height: 100, child: CircularProgressIndicator())
        )
    );
  }
}