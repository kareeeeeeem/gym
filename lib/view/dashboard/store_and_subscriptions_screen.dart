import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

// ⚠️ استبدل هذا باستدعاء دالة التحقق من صلاحية المدير الفعلية في مشروعك.
// هذه مجرد دالة وهمية للمحاكاة.
// *************************************************************************
Future<bool> _fetchAdminStatusFromFirestore() async {
  // 💡 يجب أن تستبدل هذا بالمنطق الذي يحقق من حقل 'isAdmin' في وثيقة المستخدم الحالية.
  // مثال:
  // final user = FirebaseAuth.instance.currentUser;
  // if (user != null) {
  //   final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  //   return userDoc.data()?['isAdmin'] ?? false;
  // }
  // return false;

  await Future.delayed(const Duration(milliseconds: 500)); 
  return true; // استخدم True للاختبار بوضع المدير، ثم عدلها إلى المنطق الفعلي
}
// *************************************************************************

// =========================================================================
// 1. تعريف الألوان والنماذج (Ego Gym Theme - Deep Red/Maroon & Electric Gold)
// =========================================================================

class AppColors {
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF1D1617);
  static const Color darkGrayColor = Color(0xFFC0C0C0);
  static const Color primaryColor1 = Color(0xFF8B0000); // Dark Maroon/Deep Red
  static const Color accentColor = Color(0xFFFFA500); // Electric Gold/Amber
  static const Color cardBackgroundColor = Color(0xFF222222);
  static const Color lightGrayColor = Color(0xFF333333);
  static const Color grayColor = Color(0xFF7B6F72);
  static const Color greenColor = Color(0xFF4DD17E);
  static const Color redColor = Color(0xFFEA4E79);
}

double _safeToDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class SubscriptionModel {
  final String title;
  final String description;
  final double price;
  final double discountedPrice;
  final String duration;
  final List<String> features;
  final String id;

  SubscriptionModel({
    required this.title,
    required this.description,
    required this.price,
    this.discountedPrice = 0,
    required this.duration,
    required this.features,
    required this.id, 
  });
  
  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionModel(
      id: doc.id,
      title: data['title'] ?? 'بدون عنوان',
      description: data['description'] ?? '',
      price: _safeToDouble(data['price']), 
      discountedPrice: _safeToDouble(data['discountedPrice']), 
      duration: data['duration'] ?? 'N/A',
      features: List<String>.from((data['features'] is List) ? data['features'].where((e) => e is String).toList() : []),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'discountedPrice': discountedPrice,
      'duration': duration,
      'features': features,
    };
  }

  bool get hasDiscount => discountedPrice > 0 && discountedPrice < price;
  String get discountText => hasDiscount ? "${((1 - (discountedPrice / price)) * 100).round()}% خصم" : '';
}

class ProductModel {
  final String name;
  final String description;
  final double price;
  final double discountedPrice;
  final String category;
  final String imageUrl;
  final String id;

  ProductModel({
    required this.name,
    required this.description,
    required this.price,
    this.discountedPrice = 0,
    required this.category,
    required this.imageUrl,
    required this.id,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? 'منتج غير معرف',
      description: data['description'] ?? '',
      price: _safeToDouble(data['price']), 
      discountedPrice: _safeToDouble(data['discountedPrice']),
      category: data['category'] ?? 'عام',
      imageUrl: data['imageUrl'] ?? 'assets/images/placeholder.png',
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'discountedPrice': discountedPrice,
      'category': category,
      'imageUrl': imageUrl,
    };
  }
  
  bool get hasDiscount => discountedPrice > 0 && discountedPrice < price;
}

// =========================================================================
// 2. دوال Firestore (CRUD Operations)
// =========================================================================

final FirebaseFirestore _db = FirebaseFirestore.instance;

String get _appId {
  return (const String.fromEnvironment('app_id', defaultValue: 'default-app-id')); 
}

CollectionReference _getPublicDataCollection(String collectionName) {
  return _db.collection('artifacts')
            .doc(_appId) 
            .collection('public')
            .doc('data')
            .collection(collectionName);
}

Stream<List<SubscriptionModel>> _fetchSubscriptions() {
  return _getPublicDataCollection('subscriptions')
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => SubscriptionModel.fromFirestore(doc))
                .toList());
}

Stream<List<ProductModel>> _fetchProducts() {
  return _getPublicDataCollection('products')
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => ProductModel.fromFirestore(doc))
                .toList());
}

Future<void> addSubscription(SubscriptionModel sub) async {
  try {
    await _getPublicDataCollection('subscriptions').add(sub.toFirestore());
  } catch (error) { print("❌ Error adding subscription: $error"); }
}

Future<void> deleteSubscription(String id) async {
  try {
    await _getPublicDataCollection('subscriptions').doc(id).delete();
  } catch (error) { print("❌ Error deleting subscription: $error"); }
}

Future<void> addProduct(ProductModel product) async {
  try {
    await _getPublicDataCollection('products').add(product.toFirestore());
  } catch (error) { print("❌ Error adding product: $error"); }
}

Future<void> deleteProduct(String id) async {
  try {
    await _getPublicDataCollection('products').doc(id).delete();
  } catch (error) { print("❌ Error deleting product: $error"); }
}


// =========================================================================
// 3. الشاشة الرئيسية (Tabs Screen) - Stateful
// =========================================================================

class StoreAndSubscriptionsScreen extends StatefulWidget {
  static const String routeName = '/store_subscriptions';
  
  const StoreAndSubscriptionsScreen({Key? key}) : super(key: key); 

  @override
  State<StoreAndSubscriptionsScreen> createState() => _StoreAndSubscriptionsScreenState();
}

class _StoreAndSubscriptionsScreenState extends State<StoreAndSubscriptionsScreen> {
  
  bool _isAdmin = false;
  bool _isLoading = true; // لمعالجة حالة التحميل
  
  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }
  
  // دالة جلب حالة المدير
  Future<void> _checkAdminStatus() async {
    final status = await _fetchAdminStatusFromFirestore();
    if (mounted) {
      setState(() {
        _isAdmin = status;
        _isLoading = false;
      });
    }
  }

  void _showAddModal(BuildContext context, int tabIndex) {
    if (tabIndex == 0) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AddSubscriptionModal(), 
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AddProductModal(), 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.blackColor,
        body: Center(child: CircularProgressIndicator(color: AppColors.accentColor)),
      );
    }
    
    final bool currentAdminStatus = _isAdmin; 

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            
            return Scaffold(
              backgroundColor: AppColors.blackColor,
              appBar: AppBar(
                title: Text(
                  currentAdminStatus ? 'المتجر والاشتراكات (إدارة)' : 'المتجر والاشتراكات', 
                  style: const TextStyle(color: AppColors.accentColor, fontWeight: FontWeight.bold)
                ),
                backgroundColor: AppColors.blackColor,
                elevation: 0,
                centerTitle: true,
                iconTheme: const IconThemeData(color: AppColors.whiteColor),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(50.0),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: AppColors.primaryColor1.withOpacity(0.5)),
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        color: AppColors.accentColor,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      labelColor: AppColors.blackColor,
                      unselectedLabelColor: AppColors.darkGrayColor,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                      tabs: const [
                        Tab(text: 'الاشتراكات والعروض'),
                        Tab(text: 'متجر المنتجات'),
                      ],
                    ),
                  ),
                ),
              ),
              body: TabBarView(
                children: [
                  SubscriptionsTab(isAdmin: currentAdminStatus),
                  ProductsTab(isAdmin: currentAdminStatus),
                ],
              ),
              // زر الإضافة يظهر فقط في وضع الإدارة
              floatingActionButton: currentAdminStatus 
                ? FloatingActionButton(
                    heroTag: 'add_new_item_fab',           
                    onPressed: () {
                      _showAddModal(context, tabController.index);
                    },
                    backgroundColor: AppColors.primaryColor1,
                    child: const Icon(Icons.add, color: AppColors.whiteColor),
                  )
                : null,
                bottomNavigationBar: const BottomAppBar(
                  color: Colors.transparent, 
                  elevation: 0, 
                  height: 30, // لرفع زر الإضافة قليلاً
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[],
                  ),
                ),
            );
          }
        ),
      ),
    );
  }
}

// =========================================================================
// 4. مكون (Widget) عروض الاشتراكات
// =========================================================================

class SubscriptionsTab extends StatelessWidget {
  final bool isAdmin;
  const SubscriptionsTab({Key? key, required this.isAdmin}) : super(key: key);
  
  Widget _buildDismissibleBackground(Color color, IconData icon) {
    return Container(
      color: color,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 20),
      child: const Icon(Icons.delete, color: AppColors.whiteColor),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String itemName) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackgroundColor,
          title: const Text("تأكيد الحذف", style: TextStyle(color: AppColors.whiteColor)),
          content: Text("هل أنت متأكد أنك تريد حذف '$itemName'؟", style: const TextStyle(color: AppColors.darkGrayColor)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("إلغاء", style: TextStyle(color: AppColors.accentColor)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("حذف", style: TextStyle(color: AppColors.redColor)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SubscriptionModel>>(
      key: const ValueKey('SubscriptionStream'), 
      stream: _fetchSubscriptions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accentColor));
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ في تحميل البيانات: ${snapshot.error}', style: const TextStyle(color: AppColors.redColor)));
        }
        
        final subscriptions = snapshot.data ?? [];
        
        if (subscriptions.isEmpty) {
          return const Center(child: Text('لا توجد اشتراكات متاحة حالياً.', style: TextStyle(color: AppColors.darkGrayColor)));
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: subscriptions.length,
          itemBuilder: (context, index) {
            final sub = subscriptions[index];
            
            if (isAdmin) {
              return Dismissible(
                key: Key(sub.id),
                direction: DismissDirection.endToStart, 
                background: _buildDismissibleBackground(AppColors.primaryColor1, Icons.delete),
                confirmDismiss: (direction) => _confirmDelete(context, sub.title),
                onDismissed: (direction) {
                  deleteSubscription(sub.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم حذف الاشتراك: ${sub.title}', style: TextStyle(color: AppColors.whiteColor)), backgroundColor: AppColors.primaryColor1),
                  );
                },
                child: SubscriptionCard(sub: sub),
              );
            }
            
            return SubscriptionCard(sub: sub);
          },
        );
      },
    );
  }
}

class SubscriptionCard extends StatelessWidget {
  final SubscriptionModel sub;
  const SubscriptionCard({Key? key, required this.sub}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackColor.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: sub.hasDiscount 
            ? Border.all(color: AppColors.accentColor, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sub.hasDiscount)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 15),
              decoration: BoxDecoration(
                color: AppColors.accentColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(15),
                  topLeft: Radius.circular(15),
                ),
              ),
              child: Center(
                child: Text(
                  sub.discountText,
                  style: const TextStyle(color: AppColors.blackColor, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.title,
                  style: const TextStyle(
                      color: AppColors.whiteColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  sub.description,
                  style: const TextStyle(
                      color: AppColors.darkGrayColor,
                      fontSize: 12),
                ),
                const SizedBox(height: 15),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      sub.hasDiscount 
                        ? "${sub.discountedPrice.toStringAsFixed(2)} ج.م" 
                        : "${sub.price.toStringAsFixed(2)} ج.م",
                      style: TextStyle(
                          color: sub.hasDiscount ? AppColors.redColor : AppColors.accentColor,
                          fontSize: sub.hasDiscount ? 24 : 18,
                          fontWeight: FontWeight.w900),
                    ),
                    if (sub.hasDiscount) ...[
                      const SizedBox(width: 10),
                      Text(
                        "${sub.price.toStringAsFixed(2)} ج.م",
                        style: const TextStyle(
                          color: AppColors.grayColor,
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough, 
                        ),
                      ),
                    ],
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor1.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        sub.duration,
                        style: const TextStyle(color: AppColors.primaryColor1, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                ...sub.features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.greenColor, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            feature,
                            style: const TextStyle(color: AppColors.whiteColor, fontSize: 13),
                          ),
                        ],
                      ),
                    )).toList(),

                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // منطق الشراء
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("اشترك الآن", style: TextStyle(color: AppColors.whiteColor, fontSize: 16, fontWeight: FontWeight.bold)),
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


// =========================================================================
// 5. مكون (Widget) متجر المنتجات
// =========================================================================

class ProductsTab extends StatelessWidget {
  final bool isAdmin;
  const ProductsTab({Key? key, required this.isAdmin}) : super(key: key);

  Widget _buildDismissibleBackground(Color color, IconData icon) {
    return Container(
      color: color,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Icon(Icons.delete, color: AppColors.whiteColor),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String itemName) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackgroundColor,
          title: const Text("تأكيد الحذف", style: TextStyle(color: AppColors.whiteColor)),
          content: Text("هل أنت متأكد أنك تريد حذف '$itemName'؟", style: const TextStyle(color: AppColors.darkGrayColor)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("إلغاء", style: TextStyle(color: AppColors.accentColor)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("حذف", style: TextStyle(color: AppColors.redColor)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProductModel>>(
      key: const ValueKey('ProductStream'),
      stream: _fetchProducts(), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accentColor));
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ في تحميل المنتجات: ${snapshot.error}', style: const TextStyle(color: AppColors.redColor)));
        }

        final products = snapshot.data ?? [];
        
        if (products.isEmpty) {
          return const Center(child: Text('لا توجد منتجات متاحة حالياً.', style: TextStyle(color: AppColors.darkGrayColor)));
        }
        
        return GridView.builder(
          padding: const EdgeInsets.all(15),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.7,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];

            Widget productWidget = ProductCard(product: product);
            
            if (isAdmin) {
              productWidget = Dismissible(
                key: Key(product.id),
                direction: DismissDirection.endToStart,
                background: _buildDismissibleBackground(AppColors.primaryColor1, Icons.delete),
                confirmDismiss: (direction) => _confirmDelete(context, product.name),
                onDismissed: (direction) {
                  deleteProduct(product.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم حذف المنتج: ${product.name}', style: TextStyle(color: AppColors.whiteColor)), backgroundColor: AppColors.primaryColor1),
                  );
                },
                child: productWidget,
              );
            }
            
            return productWidget;
          },
        );
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  final ProductModel product;
  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackColor.withOpacity(0.5),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // منطق فتح التفاصيل
        },
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(15),
                    topLeft: Radius.circular(15),
                  ),
                  child: Image.network(
                    product.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 120,
                        color: AppColors.lightGrayColor,
                        child: const Center(child: CircularProgressIndicator(color: AppColors.accentColor)),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                       height: 120,
                       color: AppColors.primaryColor1.withOpacity(0.2),
                       child: const Center(child: Icon(Icons.fitness_center, color: AppColors.accentColor, size: 50)),
                    ),
                  ),
                ),
                if (product.hasDiscount)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "عرض",
                        style: TextStyle(color: AppColors.blackColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    product.category,
                    style: const TextStyle(color: AppColors.darkGrayColor, fontSize: 10),
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product.hasDiscount)
                            Text(
                              "${product.price.toStringAsFixed(2)} ج.م",
                              style: const TextStyle(
                                color: AppColors.grayColor,
                                fontSize: 10,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            product.hasDiscount 
                              ? "${product.discountedPrice.toStringAsFixed(2)} ج.م" 
                              : "${product.price.toStringAsFixed(2)} ج.م",
                            style: TextStyle(
                              color: product.hasDiscount ? AppColors.accentColor : AppColors.primaryColor1,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      
                      Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor1,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          onTap: () {
                            // منطق الإضافة للسلة
                          },
                          child: const Icon(Icons.add_shopping_cart, color: AppColors.whiteColor, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 6. واجهة إضافة اشتراك (Modal)
// =========================================================================

class AddSubscriptionModal extends StatefulWidget {
  @override
  _AddSubscriptionModalState createState() => _AddSubscriptionModalState();
}

class _AddSubscriptionModalState extends State<AddSubscriptionModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController();
  final _durationController = TextEditingController();
  final _featuresController = TextEditingController(); 

  Widget _buildTextField(TextEditingController controller, String label, {bool isRequired = false, bool isNumber = false, int maxLines = 1, String? helpText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.whiteColor),
        decoration: InputDecoration(
          labelText: label,
          hintText: helpText,
          labelStyle: const TextStyle(color: AppColors.darkGrayColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          fillColor: AppColors.lightGrayColor,
          filled: true,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.accentColor, width: 1.5),
          ),
        ),
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        inputFormatters: isNumber ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))] : null,
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'هذا الحقل مطلوب';
          }
          if (isNumber && value != null && value.isNotEmpty) {
            if (double.tryParse(value) == null) {
              return 'أدخل رقماً صحيحاً';
            }
          }
          return null;
        },
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final featuresList = _featuresController.text.split(',').map((f) => f.trim()).where((f) => f.isNotEmpty).toList();
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final discountedPrice = double.tryParse(_discountController.text) ?? 0.0;

      // 🟢 التحقق من منطقية الخصم
      if (discountedPrice > price && discountedPrice > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('❌ سعر الخصم لا يمكن أن يكون أكبر من السعر الأصلي.'), backgroundColor: AppColors.redColor),
          );
          return;
      }
      
      final newSub = SubscriptionModel(
        id: '', 
        title: _titleController.text,
        description: _descController.text,
        price: price,
        discountedPrice: discountedPrice,
        duration: _durationController.text,
        features: featuresList,
      );

      addSubscription(newSub).then((_) {
        if(mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم إضافة ${newSub.title} بنجاح!', style: const TextStyle(color: AppColors.whiteColor)), backgroundColor: AppColors.primaryColor1),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.cardBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              Center(
                child: Text(
                  'إضافة اشتراك جديد',
                  style: const TextStyle(
                    color: AppColors.accentColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: AppColors.darkGrayColor),
              _buildTextField(_titleController, 'عنوان الاشتراك', isRequired: true),
              _buildTextField(_descController, 'الوصف المختصر', maxLines: 3),
              _buildTextField(_priceController, 'السعر الأساسي (ج.م)', isRequired: true, isNumber: true),
              _buildTextField(_discountController, 'السعر بعد الخصم (ج.م) (اختياري)', isNumber: true),
              _buildTextField(_durationController, 'مدة الاشتراك (مثال: شهر، 3 أشهر)', isRequired: true),
              _buildTextField(
                _featuresController, 
                'مميزات الاشتراك', 
                maxLines: 3, 
                helpText: 'افصل بين المميزات بفواصل (،)'
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('إضافة الاشتراك', style: TextStyle(color: AppColors.whiteColor, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// 7. واجهة إضافة منتج (Modal)
// =========================================================================

class AddProductModal extends StatefulWidget {
  @override
  _AddProductModalState createState() => _AddProductModalState();
}

class _AddProductModalState extends State<AddProductModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _imageUrlController = TextEditingController();

  Widget _buildTextField(TextEditingController controller, String label, {bool isRequired = false, bool isNumber = false, int maxLines = 1, String? helpText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.whiteColor),
        decoration: InputDecoration(
          labelText: label,
          hintText: helpText,
          labelStyle: const TextStyle(color: AppColors.darkGrayColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          fillColor: AppColors.lightGrayColor,
          filled: true,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.accentColor, width: 1.5),
          ),
        ),
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        inputFormatters: isNumber ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))] : null,
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'هذا الحقل مطلوب';
          }
          if (isNumber && value != null && value.isNotEmpty) {
            if (double.tryParse(value) == null) {
              return 'أدخل رقماً صحيحاً';
            }
          }
          return null;
        },
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final discountedPrice = double.tryParse(_discountController.text) ?? 0.0;
      
      // 🟢 التحقق من منطقية الخصم
      if (discountedPrice > price && discountedPrice > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('❌ سعر الخصم لا يمكن أن يكون أكبر من السعر الأصلي.'), backgroundColor: AppColors.redColor),
          );
          return;
      }

      final newProduct = ProductModel(
        id: '', 
        name: _nameController.text,
        description: _descController.text,
        price: price,
        discountedPrice: discountedPrice,
        category: _categoryController.text,
        imageUrl: _imageUrlController.text,
      );

      addProduct(newProduct).then((_) {
        if(mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم إضافة ${newProduct.name} بنجاح!', style: const TextStyle(color: AppColors.whiteColor)), backgroundColor: AppColors.primaryColor1),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.cardBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              Center(
                child: Text(
                  'إضافة منتج جديد',
                  style: const TextStyle(
                    color: AppColors.accentColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: AppColors.darkGrayColor),
              _buildTextField(_nameController, 'اسم المنتج', isRequired: true),
              _buildTextField(_descController, 'الوصف التفصيلي', maxLines: 3),
              _buildTextField(_priceController, 'السعر الأساسي (ج.م)', isRequired: true, isNumber: true),
              _buildTextField(_discountController, 'السعر بعد الخصم (ج.م) (اختياري)', isNumber: true),
              _buildTextField(_categoryController, 'التصنيف (مثال: بروتين، مكملات، ملابس)', isRequired: true),
              _buildTextField(_imageUrlController, 'رابط صورة المنتج (URL)', isRequired: true),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('إضافة المنتج', style: TextStyle(color: AppColors.whiteColor, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}