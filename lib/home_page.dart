import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:pocketbase/pocketbase.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  Map<String, List<dynamic>> groupedProducts = {};
  bool isLoading = true;
  late PocketBase pb;
  UnsubscribeFunc? unsubscribe;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    pb = PocketBase('http://127.0.0.1:8090');
    fetchProducts();
    subscribeRealtime();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unsubscribe?.call();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      fetchProducts();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    const url = 'http://127.0.0.1:8090/api/collections/products/records';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List<dynamic> items = data['items'];
      final Map<String, List<dynamic>> grouped = {};
      for (final p in items) {
        final category = p['category'] ?? 'Other';
        grouped.putIfAbsent(category, () => []);
        grouped[category]!.add(p);
      }
      setState(() {
        groupedProducts = grouped;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> subscribeRealtime() async {
    unsubscribe = await pb.realtime.subscribe('collections.products.records', (e) {
      fetchProducts();
    });
  }

  String _slugify(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9ก-๙\s-]'), '')
        .replaceAll(' ', '-');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'iTShop',
          style: GoogleFonts.prompt(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white.withOpacity(0.8),
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Get.toNamed('/products');
            },
            child: Text(
              'All Products',
              style: GoogleFonts.prompt(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : width * 0.1,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: groupedProducts.entries.map((entry) {
            final category = entry.key;
            final products = entry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.toUpperCase(),
                  style: GoogleFonts.prompt(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 2 : 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.6,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final p = products[index];
                    final slug = _slugify(p['title']);
                    return GestureDetector(
                      onTap: () {
                        Get.toNamed('/product/$slug', arguments: p);
                      },
                      child: Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Colors.black12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child: Image.network(
                                  p['image'],
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                p['title'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.prompt(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '฿${p['price']}',
                                style: GoogleFonts.prompt(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
