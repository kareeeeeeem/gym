import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; 
import 'dart:async'; 
import 'package:url_launcher/url_launcher.dart'; 

// =========================================================================
// 0. Widgets Definitions (RoundButton) 
// =========================================================================

enum RoundButtonType { primaryBG, secondaryBG }

class RoundButton extends StatelessWidget {
  final String title;
  final RoundButtonType type;
  final VoidCallback? onPressed;
  final double height;
  final double width;

  const RoundButton({
    super.key,
    required this.title,
    required this.type,
    required this.onPressed,
    this.height = 50, 
    this.width = double.maxFinite
  });

  @override
  Widget build(BuildContext context) {
    // Gradient colors: Dark Red to Amber
    List<Color> primaryG = [const Color(0xFF8B0000), const Color(0xFFFFA500)]; 
    // Gradient colors: Amber to Dark Red
    List<Color> secondaryG = [const Color(0xFFFFA500), const Color(0xFF8B0000)]; 

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: type == RoundButtonType.primaryBG ? primaryG : secondaryG,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(999), 
          boxShadow: [
            BoxShadow(
                color: primaryG[0].withOpacity(0.4), 
                blurRadius: 10, 
                offset: const Offset(0, 4))
          ]),
      child: MaterialButton(
        minWidth: double.maxFinite,
        height: height,
        onPressed: onPressed,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textColor: const Color(0xFFFFFFFF),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}


// =========================================================================
// 1. Function to Check Admin Status
// =========================================================================

Future<bool> _fetchAdminStatusFromFirestore() async {
  // 1. Get the current user
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    try {
      // 2. Attempt to fetch the user document from the 'users' collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users') 
          .doc(user.uid) 
          .get();
          
      // 3. Check if the document exists and contains the field 'isAdmin: true'
      if (userDoc.exists) {
        final isAdminStatus = userDoc.data()?['isAdmin'] as bool? ?? false;
        return isAdminStatus; 
      }
    } catch (e) {
      debugPrint("Error fetching admin status: $e");
      return false;
    }
  }
  return false; 
}


// =========================================================================
// 2. Colors and Models Definitions (Models & Colors)
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

// 💡 Subscription Model
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
      title: data['title'] ?? 'No Title',
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
  String get discountText => hasDiscount ? "${((1 - (discountedPrice / price)) * 100).round()}% Discount" : '';
}

// 💡 Product Model
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
      name: data['name'] ?? 'Unknown Product',
      description: data['description'] ?? '',
      price: _safeToDouble(data['price']), 
      discountedPrice: _safeToDouble(data['discountedPrice']),
      category: data['category'] ?? 'General',
      // Placeholder image URL for no image
      imageUrl: data['imageUrl'] ?? 'https://placehold.co/400x400/1D1617/FFA500?text=No+Image', 
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
// 3. Firestore Functions (CRUD Operations)
// =========================================================================

final FirebaseFirestore _db = FirebaseFirestore.instance;

String get _appId {
  // 💡 Use the global __app_id
  return (const String.fromEnvironment('app_id', defaultValue: 'default-app-id')); 
}

CollectionReference _getPublicDataCollection(String collectionName) {
  // Build the path for the public data collection
  return _db.collection('artifacts')
            .doc(_appId) 
            .collection('public')
            .doc('data')
            .collection(collectionName);
}

// Fetching subscriptions stream
Stream<List<SubscriptionModel>> _fetchSubscriptions() {
  return _getPublicDataCollection('subscriptions')
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => SubscriptionModel.fromFirestore(doc))
                .toList());
}

// Fetching products stream
Stream<List<ProductModel>> _fetchProducts() {
  return _getPublicDataCollection('products')
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => ProductModel.fromFirestore(doc))
                .toList());
}

// Add a new subscription
Future<void> addSubscription(SubscriptionModel sub) async {
  try {
    await _getPublicDataCollection('subscriptions').add(sub.toFirestore());
  } catch (error) { debugPrint("❌ Error adding subscription: $error"); }
}

// Delete a subscription by ID
Future<void> deleteSubscription(String id) async {
  try {
    await _getPublicDataCollection('subscriptions').doc(id).delete();
  } catch (error) { debugPrint("❌ Error deleting subscription: $error"); }
}

// Add a new product
Future<void> addProduct(ProductModel product) async {
  try {
    await _getPublicDataCollection('products').add(product.toFirestore());
  } catch (error) { 
    debugPrint("❌ Error adding product: $error"); 
    rethrow;
  }
}

// Delete a product by ID
Future<void> deleteProduct(String id) async {
  try {
    await _getPublicDataCollection('products').doc(id).delete();
  } catch (error) { debugPrint("❌ Error deleting product: $error"); }
}

// 💡 Function to fetch the reception phone number via Firestore
Future<String> _fetchReceptionNumber() async {
    // Default international format number
    const String defaultNumber = '+201004632660'; 

    try {
      // Default path for public reception settings
      final doc = await FirebaseFirestore.instance
          .collection('artifacts')
          .doc((const String.fromEnvironment('app_id', defaultValue: 'default-app-id'))) 
          .collection('public')
          .doc('data')
          .collection('settings') 
          .doc('reception_info')
          .get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('reception_phone') && data['reception_phone'] is String) {
           final fetchedNumber = (data['reception_phone'] as String).trim();
           // Ensure country code (+) is prepended if missing
           if (!fetchedNumber.startsWith('+')) {
              return '+20$fetchedNumber';
           }
           return fetchedNumber; 
        }
      } 
    } catch (e) {
      debugPrint('❌ Firebase Error fetching phone: $e');
    }
    // Fallback number if fetching fails
    return defaultNumber; 
}


// =========================================================================
// 4. Main Screen (Tabs Screen) - Stateful
// =========================================================================

class StoreAndSubscriptionsScreen extends StatefulWidget {
  static const String routeName = '/store_subscriptions';
  
  const StoreAndSubscriptionsScreen({Key? key}) : super(key: key); 

  @override
  State<StoreAndSubscriptionsScreen> createState() => _StoreAndSubscriptionsScreenState();
}

class _StoreAndSubscriptionsScreenState extends State<StoreAndSubscriptionsScreen> {
  
  bool _isAdmin = false;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }
  
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
    // Show Add Subscription Modal
    if (tabIndex == 0) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AddSubscriptionModal(isAdmin: _isAdmin), 
      );
    } 
    // Show Add Product Modal
    else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AddProductModal(isAdmin: _isAdmin), 
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

    // Changed to LTR (English context)
    return Directionality(
      textDirection: TextDirection.ltr,
      child: DefaultTabController(
        length: 2,
        initialIndex: 1, 

        child: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            
            return Scaffold(
              backgroundColor: AppColors.blackColor,
              appBar: AppBar(
                title: const Text(
                  'Store & Subscriptions',
                  style: TextStyle(color: AppColors.accentColor, fontWeight: FontWeight.bold)
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
                    child: const TabBar(
                      indicator: BoxDecoration(
                        color: AppColors.accentColor,
                      ),
                      labelColor: AppColors.blackColor,
                      unselectedLabelColor: AppColors.darkGrayColor,
                      labelStyle: TextStyle(fontWeight: FontWeight.w700),
                      tabs: [
                        Tab(text: 'Subscriptions'),
                        Tab(text: 'Products Store'),
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
              // The add button only appears in admin mode
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
                  height: 30,
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
// 5. Subscription Offers Widget and SubscriptionCard
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
          title: const Text("Confirm Deletion", style: TextStyle(color: AppColors.whiteColor)),
          content: Text("Are you sure you want to delete '$itemName'?", style: const TextStyle(color: AppColors.darkGrayColor)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel", style: TextStyle(color: AppColors.accentColor)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Delete", style: TextStyle(color: AppColors.redColor)),
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
          return Center(child: Text('Error loading data: ${snapshot.error}', style: const TextStyle(color: AppColors.redColor)));
        }
        
        final subscriptions = snapshot.data ?? [];
        
        if (subscriptions.isEmpty) {
          return const Center(child: Text('No subscriptions available currently.', style: TextStyle(color: AppColors.darkGrayColor)));
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
                    SnackBar(content: Text('Subscription deleted: ${sub.title}', style: const TextStyle(color: AppColors.whiteColor)), backgroundColor: AppColors.primaryColor1),
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
              decoration: const BoxDecoration(
                color: AppColors.accentColor,
                borderRadius: BorderRadius.only(
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
                  maxLines: 2, // Added constraint to prevent overflow
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.whiteColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  sub.description,
                  maxLines: 3, // Added constraint to prevent overflow
                  overflow: TextOverflow.ellipsis,
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
                        ? "${sub.discountedPrice.toStringAsFixed(2)} EGP" 
                        : "${sub.price.toStringAsFixed(2)} EGP",
                      style: TextStyle(
                          color: sub.hasDiscount ? AppColors.redColor : AppColors.accentColor,
                          fontSize: sub.hasDiscount ? 24 : 18,
                          fontWeight: FontWeight.w900),
                    ),
                    if (sub.hasDiscount) ...[
                      const SizedBox(width: 10),
                      Text(
                        "${sub.price.toStringAsFixed(2)} EGP",
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
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                ...sub.features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          const Icon(Icons.check_circle, color: AppColors.greenColor, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(color: AppColors.whiteColor, fontSize: 13),
                              overflow: TextOverflow.ellipsis, // Added constraint
                              maxLines: 2, // Added constraint
                            ),
                          ),
                        ],
                      ),
                    )).toList(),

                const SizedBox(height: 20),
                
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 6. Product Store Widget and ProductCard
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
          title: const Text("Confirm Deletion", style: TextStyle(color: AppColors.whiteColor)),
          content: Text("Are you sure you want to delete '$itemName'?", style: const TextStyle(color: AppColors.darkGrayColor)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel", style: TextStyle(color: AppColors.accentColor)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Delete", style: TextStyle(color: AppColors.redColor)),
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
          return Center(child: Text('Error loading products: ${snapshot.error}', style: const TextStyle(color: AppColors.redColor)));
        }

        final products = snapshot.data ?? [];
        
        if (products.isEmpty) {
          return const Center(child: Text('No products available currently.', style: TextStyle(color: AppColors.darkGrayColor)));
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
                    SnackBar(content: Text('Product deleted: ${product.name}', style: const TextStyle(color: AppColors.whiteColor)), backgroundColor: AppColors.primaryColor1),
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


  // Booking logic and opening WhatsApp (modified to use Firebase fetched number)
  void _handleBooking(BuildContext context) async {
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparing booking chat now...'),
        backgroundColor: AppColors.accentColor,
      ),
    );

    // 💡 Step 1: Fetch the number dynamically from Firebase
    final String receptionNumber = await _fetchReceptionNumber();

    // 1. Build the WhatsApp message
     String message = 
    "Hello, I would like to book the following product:\n\n*Product:* ${product.name}\n\n*Price:* ${product.price.toStringAsFixed(2)} EGP";    
    
    // Add discounted price if available
    if (product.hasDiscount) {
      message +="\n*Discounted Price:* ${product.discountedPrice.toStringAsFixed(2)} EGP";
    }
    
    // 2. Encode the message for the URL
    final encodedMessage = Uri.encodeComponent(message);
    
    // 3. Build the WhatsApp link using the fetched number
    // 🚨 Note: The number is fetched with the country code (+20) from _fetchReceptionNumber
    final Uri whatsappUrl = Uri.parse(
        'whatsapp://send?phone=$receptionNumber&text=$encodedMessage'); 

    // 4. Attempt to open the link
    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      } else {
        // If WhatsApp app is not available, try opening via browser
        final Uri webUrl = Uri.parse(
            'https://wa.me/${receptionNumber.replaceAll('+', '')}?text=$encodedMessage'); 
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Show clear error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open WhatsApp. Ensure it is installed and the number is: $receptionNumber'),
          backgroundColor: AppColors.redColor,
        ),
      );
    }
  }


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
          // Logic for opening details (can add a modal for detailed description later)
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
                        "Offer",
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
                    maxLines: 2, // Reduced maxLines for better fit in card, used 2 instead of 4
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    product.category,
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                    
                    style: const TextStyle(color: AppColors.darkGrayColor, fontSize: 10),
                  ),
                  const SizedBox(height: 8),
                  
                  // The modified button to open WhatsApp
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product.hasDiscount)
                            Text(
                              "${product.price.toStringAsFixed(2)} EGP",
                              style: const TextStyle(
                                color: AppColors.grayColor,
                                fontSize: 10,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            product.hasDiscount 
                              ? "${product.discountedPrice.toStringAsFixed(2)} EGP" 
                              : "${product.price.toStringAsFixed(2)} EGP",
                            style: TextStyle(
                              color: product.hasDiscount ? AppColors.accentColor : AppColors.accentColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 10,),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 5),
                          child: ElevatedButton.icon(
                            onPressed: () => _handleBooking(context), // Call WhatsApp function

                        icon: const Icon(
                          FontAwesomeIcons.whatsapp, 
                          color: AppColors.whiteColor, 
                          size: 16
                        ),
                        label: const Text(
                          "Book",
                          style: TextStyle(color: AppColors.whiteColor, fontSize: 12, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.greenColor, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                          elevation: 0,
                            ),
                           ), 
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
// 7. Add Subscription Interface (Modal) - isAdmin added
// =========================================================================

class AddSubscriptionModal extends StatefulWidget {
  final bool isAdmin; 
  const AddSubscriptionModal({Key? key, this.isAdmin = false}) : super(key: key);

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
            return 'This field is required';
          }
          if (isNumber && value != null && value.isNotEmpty) {
            if (double.tryParse(value) == null) {
              return 'Enter a valid number';
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
      
      if (discountedPrice > price && discountedPrice > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('❌ Discount price cannot be greater than the base price.'), backgroundColor: AppColors.redColor),
          );
          return;
      }
      
      final featuresList = _featuresController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

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
            SnackBar(content: Text('${newSub.title} added successfully!', style: const TextStyle(color: AppColors.whiteColor)), backgroundColor: AppColors.primaryColor1),
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
              const Center(
                child: Text(
                  'Add New Subscription',
                  style: TextStyle(
                    color: AppColors.accentColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: AppColors.darkGrayColor),
              _buildTextField(_titleController, 'Subscription Title', isRequired: true),
              _buildTextField(_descController, 'Short Description', maxLines: 2),
              _buildTextField(_priceController, 'Base Price (EGP)', isRequired: true, isNumber: true),
              _buildTextField(_discountController, 'Discounted Price (EGP) (Optional)', isNumber: true),
              _buildTextField(_durationController, 'Subscription Duration (e.g., Month, 3 Months)', isRequired: true),
              _buildTextField(_featuresController, 'Features (Separate by comma)', maxLines: 3, helpText: 'e.g., Free entry, Personal follow-up, Diet plan'),
              const SizedBox(height: 20),
              
              // 💡 Add button only appears for admins
              if (widget.isAdmin)
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('Add Subscription', style: TextStyle(color: AppColors.whiteColor, fontSize: 16)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// 8. Add Product Interface (Modal) - isAdmin added
// =========================================================================

class AddProductModal extends StatefulWidget {
  final bool isAdmin; 
  const AddProductModal({Key? key, this.isAdmin = false}) : super(key: key);

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

  Widget _buildTextField(
    TextEditingController controller,
     String label,
      {bool isRequired = false, bool isNumber = false, int maxLines = 1, String? helpText}) {
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
            return 'This field is required';
          }
          if (isNumber && value != null && value.isNotEmpty) {
            if (double.tryParse(value) == null) {
              return 'Enter a valid number';
            }
          }
          return null;
        },
      ),
    );
  }

void _submit() async { 
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final discountedPrice = double.tryParse(_discountController.text) ?? 0.0;
      
      if (discountedPrice > price && discountedPrice > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('❌ Discount price cannot be greater than the base price.'), backgroundColor: AppColors.redColor),
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

      try {
        await addProduct(newProduct); 

        if(mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${newProduct.name} added successfully!', style: const TextStyle(color: AppColors.whiteColor)), backgroundColor: AppColors.primaryColor1),
          );
        }
      } catch (e) {
        // Clear error message for the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Addition failed: ${e.toString()}', style: const TextStyle(color: AppColors.whiteColor)), backgroundColor: AppColors.redColor),
        );
      }
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
              const Center(
                child: Text(
                  'Add New Product',
                  style: TextStyle(
                    color: AppColors.accentColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: AppColors.darkGrayColor),
              _buildTextField(_nameController, 'Product Name', isRequired: true),
              _buildTextField(_descController, 'Detailed Description', maxLines: 3),
              _buildTextField(_priceController, 'Base Price (EGP)', isRequired: true, isNumber: true),
              _buildTextField(_discountController, 'Discounted Price (EGP) (Optional)', isNumber: true),
              _buildTextField(_categoryController, 'Category (e.g., Protein, Supplements, Apparel)', isRequired: true),
              _buildTextField(_imageUrlController, 'Product Image Link (URL)', isRequired: true),
              const SizedBox(height: 20),
              
              // Add button only appears for admins
              if (widget.isAdmin) 
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('Add Product', style: TextStyle(color: AppColors.whiteColor, fontSize: 16)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
