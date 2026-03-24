import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../app_colors.dart';
import '../models/food_item.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

const Map<String, int> kSafeDaysAfterExpiry = {
  'Dairy': 3,
  'Meat': 1,
  'Seafood': 1,
  'Produce': 5,
  'Bakery': 5,
  'Canned Goods': 365,
  'Frozen': 30,
  'Beverages': 7,
  'Snacks': 14,
  'Other': 3,
};

// Keywords used to auto-detect category from food name
const Map<String, List<String>> _kCategoryKeywords = {
  'Dairy': [
    'milk', 'cheese', 'yogurt', 'yoghurt', 'butter', 'cream', 'dairy',
    'cheddar', 'mozzarella', 'parmesan', 'brie', 'gouda', 'ricotta',
    'kefir', 'whey', 'cottage', 'brie', 'camembert', 'feta',
  ],
  'Meat': [
    'chicken', 'beef', 'pork', 'lamb', 'turkey', 'steak', 'bacon',
    'sausage', 'ham', 'veal', 'duck', 'mince', 'ground', 'pepperoni',
    'salami', 'prosciutto', 'brisket', 'ribs', 'tenderloin',
  ],
  'Seafood': [
    'fish', 'salmon', 'tuna', 'shrimp', 'prawn', 'lobster', 'crab',
    'cod', 'tilapia', 'halibut', 'sardine', 'anchovy', 'oyster',
    'mussel', 'clam', 'squid', 'octopus', 'scallop', 'trout',
  ],
  'Produce': [
    'apple', 'banana', 'orange', 'grape', 'strawberry', 'blueberry',
    'lettuce', 'spinach', 'carrot', 'tomato', 'cucumber', 'broccoli',
    'pepper', 'onion', 'garlic', 'potato', 'avocado', 'lemon', 'lime',
    'mango', 'peach', 'pear', 'plum', 'kale', 'celery', 'zucchini',
    'eggplant', 'cauliflower', 'asparagus', 'mushroom', 'berry',
    'melon', 'pineapple', 'watermelon', 'cherry', 'fig', 'apricot',
    'raspberry', 'blackberry', 'grapefruit', 'corn', 'beet', 'squash',
    'arugula', 'radish', 'leek', 'cabbage', 'fennel', 'herb', 'basil',
    'cilantro', 'parsley', 'mint', 'thyme', 'rosemary',
  ],
  'Bakery': [
    'bread', 'muffin', 'cake', 'cookie', 'bagel', 'croissant',
    'roll', 'bun', 'pastry', 'donut', 'doughnut', 'pie', 'waffle',
    'pancake', 'brioche', 'sourdough', 'baguette', 'focaccia', 'pita',
  ],
  'Beverages': [
    'juice', 'coffee', 'tea', 'soda', 'smoothie', 'shake', 'drink',
    'wine', 'beer', 'cider', 'kombucha', 'lemonade', 'almond milk',
    'oat milk', 'soy milk', 'broth', 'stock',
  ],
  'Frozen': [
    'frozen', 'ice cream', 'sorbet', 'gelato', 'popsicle',
  ],
  'Snacks': [
    'chips', 'crackers', 'popcorn', 'nuts', 'granola', 'pretzel',
    'trail mix', 'jerky', 'candy', 'chocolate',
  ],
  'Canned Goods': [
    'canned', 'tinned', 'can of', 'jar of',
  ],
};

String _detectCategory(String name) {
  final lower = name.toLowerCase();
  for (final entry in _kCategoryKeywords.entries) {
    for (final keyword in entry.value) {
      if (lower.contains(keyword)) return entry.key;
    }
  }
  return 'Other';
}

class AddItemScreen extends StatefulWidget {
  final bool startWithScan;
  final FoodItem? existingItem;

  const AddItemScreen({super.key, this.startWithScan = false, this.existingItem});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedCategory = 'Other';
  bool _isScanning = false;
  bool _isLoading = false;
  bool _hasScanned = false;
  String? _capturedImagePath;
  bool _categoryWasAutoDetected = false;

  final DatabaseService _db = DatabaseService();
  final ImagePicker _picker = ImagePicker();
  late final MobileScannerController _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    if (widget.startWithScan && !kIsWeb) {
      _isScanning = true;
    }
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _nameController.text = item.name;
      _selectedDate = item.expiryDate;
      _selectedCategory = item.category;
      _capturedImagePath = item.imagePath;
    }
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    final detected = _detectCategory(_nameController.text);
    if (detected != 'Other') {
      if (detected != _selectedCategory) {
        setState(() {
          _selectedCategory = detected;
          _categoryWasAutoDetected = true;
        });
      }
    } else if (_categoryWasAutoDetected) {
      // Only reset to Other if we had auto-detected and name no longer matches
      setState(() {
        _selectedCategory = 'Other';
        _categoryWasAutoDetected = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _hasScanned = false;
    });
  }

  Future<void> _lookupBarcode(String barcode) async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse(
          'https://world.openfoodfacts.org/api/v0/product/$barcode.json');
      final response = await http.get(url);
      final data = jsonDecode(response.body);
      if (data['status'] == 1) {
        final productName =
            (data['product']['product_name'] as String? ?? '').trim();
        if (productName.isNotEmpty) {
          _nameController.text = productName;
        }
      }
    } catch (_) {
      // silently fail — user can type manually
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    if (kIsWeb) return;
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (photo != null) {
      setState(() => _capturedImagePath = photo.path);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.card,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveItem() async {
    if (_nameController.text.trim().isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a name and expiry date'),
          backgroundColor: AppColors.surface,
        ),
      );
      return;
    }

    try {
      if (widget.existingItem != null) {
        final updated = FoodItem(
          id: widget.existingItem!.id,
          name: _nameController.text.trim(),
          expiryDate: _selectedDate!,
          category: _selectedCategory,
          safeDaysAfterExpiry: kSafeDaysAfterExpiry[_selectedCategory] ?? 3,
          imagePath: _capturedImagePath,
        );
        await _db.updateFoodItem(updated);
        NotificationService.cancelNotifications(updated.id!).ignore();
        NotificationService.scheduleExpiryNotifications(updated).ignore();
      } else {
        final item = FoodItem(
          name: _nameController.text.trim(),
          expiryDate: _selectedDate!,
          category: _selectedCategory,
          safeDaysAfterExpiry: kSafeDaysAfterExpiry[_selectedCategory] ?? 3,
          imagePath: _capturedImagePath,
        );
        final id = await _db.insertFoodItem(item);
        final savedItem = FoodItem(
          id: id,
          name: item.name,
          expiryDate: item.expiryDate,
          category: item.category,
          safeDaysAfterExpiry: item.safeDaysAfterExpiry,
          imagePath: item.imagePath,
        );
        NotificationService.scheduleExpiryNotifications(savedItem).ignore();
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.existingItem != null ? 'Edit Item' : 'Add Food Item',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isScanning ? _buildScanner() : _buildForm(),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            if (_hasScanned) return;
            if (capture.barcodes.isEmpty) return;
            final rawValue = capture.barcodes.first.rawValue;
            if (rawValue != null && rawValue.isNotEmpty) {
              _hasScanned = true;
              _lookupBarcode(rawValue);
            }
          },
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
          ),
          child: Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 2.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'Point at a barcode',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.6),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton(
              onPressed: () => setState(() => _isScanning = false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cancel Scan'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.qr_code_scanner,
                  label: 'Scan Barcode',
                  onTap: _startScanning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Take Photo',
                  onTap: _takePhoto,
                ),
              ),
            ],
          ),

          // Photo preview
          if (_capturedImagePath != null && !kIsWeb) ...[
            const SizedBox(height: 16),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_capturedImagePath!),
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _capturedImagePath = null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          const Center(
            child: Text(
              'or enter manually',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),

          // Name field
          _buildLabel('Food Name'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'e.g. Whole Milk, Chicken Breast',
            ),
          ),
          const SizedBox(height: 20),

          // Category
          Row(
            children: [
              _buildLabel('Category'),
              const SizedBox(width: 8),
              if (_categoryWasAutoDetected)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'auto-detected',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _categoryWasAutoDetected
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.border,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary),
                iconEnabledColor: AppColors.textSecondary,
                items: kSafeDaysAfterExpiry.keys
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat,
                              style: const TextStyle(
                                  color: AppColors.textPrimary)),
                        ))
                    .toList(),
                onChanged: (val) => setState(() {
                  _selectedCategory = val!;
                  _categoryWasAutoDetected = false;
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Expiry date
          _buildLabel('Expiry Date'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate == null
                        ? 'Select expiry date'
                        : DateFormat('MMMM d, yyyy')
                            .format(_selectedDate!),
                    style: TextStyle(
                      fontSize: 15,
                      color: _selectedDate == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Safe days hint
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$_selectedCategory items stay safe for '
                    '${kSafeDaysAfterExpiry[_selectedCategory]} days after expiry',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)
                  : Text(
                      widget.existingItem != null ? 'Save Changes' : 'Save Item',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
