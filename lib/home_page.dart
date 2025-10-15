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
  String searchQuery = '';

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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'iTShop',
          style: GoogleFonts.prompt(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchProducts,
        child: ListView(
          children: [
            _buildHeroSection(),
            _buildSearchBar(),
            ...groupedProducts.entries.map((entry) {
              final category = entry.key;
              final products = entry.value
                  .where((p) => p['title']
                  ?.toString()
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) ??
                  false)
                  .toList();
              if (products.isEmpty) return const SizedBox();
              return _buildCategorySection(category, products, isMobile);
            }),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) Get.toNamed('/products');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าแรก'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'ทั้งหมด'),
        ],
      ),
    );
  }

  /// ✅ Banner เหลือแค่สีพื้นหลัง + ข้อความ
  Widget _buildHeroSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF007AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        'ยินดีต้อนรับสู่ iTShop',
        style: GoogleFonts.prompt(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'ค้นหาสินค้า...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (val) => setState(() => searchQuery = val),
      ),
    );
  }

  Widget _buildCategorySection(String category, List<dynamic> products, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: GoogleFonts.prompt(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 2 : 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.65,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              final imageUrl = p['image'] ?? 'https://via.placeholder.com/300x300?text=No+Image';
              final title = p['title'] ?? 'ไม่มีชื่อสินค้า';
              final price = p['price']?.toString() ?? '0';

              return GestureDetector(
                onTap: () => Get.toNamed('/product/${p['id']}', arguments: p),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(
                          imageUrl,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 120,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.prompt(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '฿$price',
                          style: GoogleFonts.prompt(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
