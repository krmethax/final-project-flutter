import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class ProductNewPage extends StatefulWidget {
  const ProductNewPage({super.key});

  @override
  State<ProductNewPage> createState() => _ProductNewPageState();
}

class _ProductNewPageState extends State<ProductNewPage> {
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  final imageController = TextEditingController();

  String? selectedCategory;
  bool isSaving = false;
  bool isLoadingCategories = true;
  List<String> categories = [];

  @override
  void initState() {
    super.initState();
    fetchCategoriesFromProducts();
  }

  Future<void> fetchCategoriesFromProducts() async {
    try {
      const url = 'http://127.0.0.1:8090/api/collections/products/records';
      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final items = data['items'] as List<dynamic>;

        final setOfCategories = <String>{};
        for (final item in items) {
          final c = item['category'];
          if (c != null && c.toString().trim().isNotEmpty) {
            setOfCategories.add(c.toString());
          }
        }

        setState(() {
          categories = setOfCategories.toList();
          isLoadingCategories = false;
        });
      } else {
        setState(() => isLoadingCategories = false);
      }
    } catch (e) {
      setState(() => isLoadingCategories = false);
    }
  }

  Future<void> createProduct() async {
    setState(() => isSaving = true);
    const url = 'http://127.0.0.1:8090/api/collections/products/records';

    final body = jsonEncode({
      'title': titleController.text,
      'price': double.tryParse(priceController.text) ?? 0,
      'category': selectedCategory,
      'description': descriptionController.text,
      'image': imageController.text,
    });

    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    setState(() => isSaving = false);

    if (res.statusCode == 200 || res.statusCode == 201) {
      Get.back(result: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เพิ่มสินค้าสำเร็จ')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถเพิ่มสินค้าได้')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text('เพิ่มสินค้าใหม่', style: GoogleFonts.prompt()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: isLoadingCategories
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'ชื่อสินค้า'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ราคา'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(labelText: 'หมวดหมู่'),
              items: categories
                  .map((c) => DropdownMenuItem(
                value: c,
                child: Text(c),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration:
              const InputDecoration(labelText: 'รายละเอียดสินค้า'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: imageController,
              decoration:
              const InputDecoration(labelText: 'URL รูปภาพ'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isSaving ? null : createProduct,
              style:
              ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('บันทึก',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
