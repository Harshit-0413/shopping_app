import 'package:flutter/material.dart';
import 'package:shopping_app/app_drawer.dart';
import 'package:shopping_app/main.dart';
import 'package:shopping_app/product_card.dart';
import 'package:shopping_app/global_variables.dart';
import 'package:shopping_app/product.dart';

class HomePage extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const HomePage({super.key, required this.scaffoldKey});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FocusNode _focusNode = FocusNode();
  String searchQuery = '';

  final List<String> filters = [
    'All',
    'Clothing',
    'Shoes',
    'Beauty',
    'Accessories',
  ];

  late String selectedFilter;

  @override
  void initState() {
    super.initState();
    selectedFilter = filters[0];
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  //CATEGORY + SEARCH FILTERING
  List<Product> get filteredProducts {
    return allProducts.where((product) {
      final matchesSearch = product.title.toLowerCase().contains(
        searchQuery.toLowerCase(),
      );

      final matchesCategory =
          selectedFilter == 'All' ||
          product.category.name.toLowerCase() == selectedFilter.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      drawer: AppDrawer(onOrdersTap: () {}),
      //BODY
      body: SafeArea(
        child: Column(
          children: [
            //HEADER + SEARCH
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //MENU + TITLE
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, size: 28),
                        onPressed: () {
                          widget.scaffoldKey.currentState!.openDrawer();
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Collections',
                        style: TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  //SEARCH BAR
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _focusNode.hasFocus
                            ? const Color.fromARGB(255, 165, 130, 142)
                            : const Color.fromARGB(255, 118, 162, 104),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      focusNode: _focusNode,
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search products',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            //FILTER CHIPS
            SizedBox(
              height: 105,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedFilter = filter;
                        });
                      },
                      child: Chip(
                        backgroundColor: selectedFilter == filter
                            ? const Color.fromARGB(131, 134, 95, 172)
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: const BorderSide(
                            color: Colors.black,
                            width: 1.3,
                          ),
                        ),
                        label: Text(
                          filter,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            //PRODUCT LIST
            Expanded(
              child: ListView.builder(
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return ProductCard(product: product);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
