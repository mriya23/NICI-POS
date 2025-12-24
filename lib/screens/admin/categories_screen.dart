import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:uuid/uuid.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/category_model.dart';
import '../../utils/constants.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
      _isInit = false;
    }
    super.didChangeDependencies();
  }

  void _showAddEditDialog(BuildContext context, {Category? category}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Kategori' : 'Tambah Kategori'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Kategori'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Masukkan nama kategori';
                  }
                  final provider = Provider.of<CategoryProvider>(
                    ctx,
                    listen: false,
                  );
                  if (provider.isCategoryNameTaken(
                    value.trim(),
                    excludeId: category?.id,
                  )) {
                    return 'Nama kategori sudah ada';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final provider = Provider.of<CategoryProvider>(
                  context,
                  listen: false,
                );
                final name = nameController.text.trim();

                bool success;
                if (isEditing) {
                  success = await provider.updateCategory(
                    category.copyWith(name: name, updatedAt: DateTime.now()),
                  );
                } else {
                  success = await provider.addCategory(
                    Category(
                      id: const Uuid().v4(),
                      name: name,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                  );
                }

                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  if (success) {
                    // specific fix: Refresh ProductProvider to ensure other screens (like Products/Cashier) have latest categories
                    Provider.of<ProductProvider>(
                      context,
                      listen: false,
                    ).loadAllProducts();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              isEditing ? Icons.check_circle : Icons.add_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isEditing
                                    ? 'Kategori "$name" berhasil diperbarui'
                                    : 'Kategori "$name" berhasil ditambahkan',
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: isEditing
                            ? AppColors.success
                            : AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                provider.errorMessage ?? 'Terjadi kesalahan',
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }
                }
              }
            },
            child: Text(isEditing ? 'Perbarui' : 'Tambah'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Yakin ingin menghapus kategori "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await Provider.of<CategoryProvider>(
                context,
                listen: false,
              ).deleteCategory(category.id);

              if (context.mounted) {
                if (success) {
                  Provider.of<ProductProvider>(
                    context,
                    listen: false,
                  ).loadAllProducts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.delete_sweep,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Kategori "${category.name}" berhasil dihapus',
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              Provider.of<CategoryProvider>(
                                    context,
                                    listen: false,
                                  ).errorMessage ??
                                  'Gagal menghapus kategori',
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final categories = categoryProvider.categories;

    return Scaffold(
      backgroundColor: Colors.transparent, // Uses parent background
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Manage Categories', style: AppTextStyles.heading2),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Category'),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingLG),
            if (categoryProvider.isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (categories.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No categories found. Add one to get started.'),
                ),
              )
            else
              Expanded(
                child: Card(
                  child: ListView.separated(
                    itemCount: categories.length,
                    separatorBuilder: (ctx, i) => const Divider(),
                    itemBuilder: (ctx, i) {
                      final cat = categories[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryBg,
                          child: Text(
                            cat.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(cat.name, style: AppTextStyles.bodyLarge),
                        subtitle: Text(
                          'Created: ${cat.createdAt.toString().split(' ')[0]}',
                          style: AppTextStyles.bodySmall,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: AppColors.info,
                              ),
                              onPressed: () =>
                                  _showAddEditDialog(context, category: cat),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: AppColors.error,
                              ),
                              onPressed: () => _confirmDelete(context, cat),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
