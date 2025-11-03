import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // لإضافة الـ Haptic Feedback
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// =========================================================================
// 1. الثوابت والألوان (AppConstants & AppColors)
// =========================================================================

class AppColors {
  static const Color primaryColor1 = Color(0xFFE81845); // Deep Red
  static const Color accentColor = Color(0xFFF05454); // Bright Red/Pink
  static const Color blackColor = Color(0xFF1F1E1D); // Base Background
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color grayColor = Color(0xFFAAAAAA);
  static const Color darkGrayColor = Color(0xFF666666);
  static const Color cardBackgroundColor = Color(0xFF2C2B29); // Card Color
  static const Color greenColor = Color(0xFF22C55E); // Green
  static const Color redColor = Color(0xFFEF4444); // Red
  static const Color yellowColor = Color(0xFFFBBF24); // Yellow (Rating - تم إبقاء اللون للاستخدام العام)
  static const Color lightShadowColor = Color(0xFF3B3A38); 
  static const Color darkShadowColor = Color(0xFF171615); 
}

// =========================================================================
// 2. الموديلات (CoachModel) - ✨ تم حذف حقول Rating و YOE
// =========================================================================

class ProductModel {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final String category;
  final bool hasDiscount;
  final double discountedPrice;

  ProductModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.category,
    this.hasDiscount = false,
    this.discountedPrice = 0.0,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? 'Unknown Product',
      imageUrl: data['imageUrl'] ?? 'https://placehold.co/400x400/333333/FFFFFF?text=Product',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] ?? 'General',
      hasDiscount: data['hasDiscount'] ?? false,
      discountedPrice: (data['discountedPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CoachModel {
  final String id;
  final String name;
  final String specialization;
  final String bio;
  final String imageUrl;
  // ✨ تم حذف حقول whatsappUrl، instagramUrl، rating، yearsOfExperience
  
  CoachModel({
    required this.id,
    required this.name,
    required this.specialization,
    required this.bio,
    required this.imageUrl,
    // تم حذف الحقول هنا
  });

  factory CoachModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return CoachModel(
      id: doc.id,
      name: data?['name'] ?? 'Unknown Coach',
      specialization: data?['specialization'] ?? 'General',
      bio: data?['bio'] ?? 'No description available for this coach.',
      imageUrl: data?['imageUrl'] ?? 'https://placehold.co/100x100/333333/FFFFFF?text=Coach',
      // تم حذف قيم الحقول المحذوفة من factory
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'specialization': specialization,
      'bio': bio,
      'imageUrl': imageUrl,
      // تم حذف الحقول من toFirestore
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

// =========================================================================
// 3. دوال Firebase Firestore (مختصرة)
// =========================================================================

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Stream<List<CoachModel>> _fetchCoaches() {
  return _firestore.collection('coaches').orderBy('name', descending: false).snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => CoachModel.fromFirestore(doc)).toList();
  });
}

Future<void> addCoach(CoachModel coach) async {
  await _firestore.collection('coaches').add(coach.toFirestore());
}

Future<void> updateCoach(CoachModel coach) async {
  await _firestore.collection('coaches').doc(coach.id).update(coach.toFirestore());
}

Future<void> deleteCoach(String coachId) async {
  await _firestore.collection('coaches').doc(coachId).delete();
}

Future<bool> _fetchAdminStatusFromFirestore() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    
    if (userDoc.exists) {
      final isAdmin = userDoc.data()?['isAdmin'] ?? false;
      return isAdmin;
    }
    return false;
  } catch (e) {
    print('Error fetching admin status: $e');
    return false;
  }
}

// =========================================================================
// 4. مكون الزر الدائري (RoundButton)
// =========================================================================

enum RoundButtonType { primaryBG, secondaryBorder }

class RoundButton extends StatelessWidget {
  final String title;
  final RoundButtonType type;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final double fontSize;

  const RoundButton({
    Key? key,
    required this.title,
    this.type = RoundButtonType.primaryBG,
    this.onPressed,
    this.width = double.infinity,
    this.height = 45,
    this.fontSize = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isPrimary = type == RoundButtonType.primaryBG;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppColors.accentColor : Colors.transparent,
          foregroundColor: isPrimary ? AppColors.blackColor : AppColors.accentColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: isPrimary
                ? BorderSide.none
                : const BorderSide(color: AppColors.accentColor, width: 1.5),
          ),
          elevation: isPrimary ? 5 : 0,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}


// =========================================================================
// 5. صفحة المدربين (CoachesPage) - منطق الحذف والـ FAB
// =========================================================================

class CoachesPage extends StatefulWidget {
  static const String routeName = '/coaches_page';
  
  const CoachesPage({Key? key}) : super(key: key); 

  @override
  State<CoachesPage> createState() => _CoachesPageState();
}

class _CoachesPageState extends State<CoachesPage> {
  
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

  void _showAddEditModal(BuildContext context, {CoachModel? coach}) {
    // ✨ إضافة اهتزاز عند فتح نافذة التعديل
    if(coach != null) { 
       HapticFeedback.lightImpact();
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditCoachModal(
        isAdmin: _isAdmin, 
        coachToEdit: coach
      ), 
    );
  }

  // ✨ تحسين تصميم نافذة تأكيد الحذف
  Future<bool?> _confirmDelete(BuildContext context, String itemName) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: AppColors.cardBackgroundColor,
          title: const Text(
            "Confirm Deletion", 
            style: TextStyle(color: AppColors.accentColor, fontWeight: FontWeight.bold)
          ),
          content: Text(
            "Are you sure you want to permanently delete coach '$itemName'? This action cannot be undone.", 
            style: const TextStyle(color: AppColors.whiteColor)
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel", style: TextStyle(color: AppColors.grayColor)),
            ),
            RoundButton(
              title: "DELETE",
              type: RoundButtonType.primaryBG,
              onPressed: () => Navigator.of(context).pop(true),
              width: 100,
              height: 40,
              fontSize: 14,
            ),
          ],
        );
      },
    );
  }

  // ✨ إيماءة الحذف (Swipe-to-Delete)
  Widget _buildDismissibleBackground(Color color, IconData icon) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20)
      ),
      child: const Icon(Icons.delete_sweep_outlined, color: AppColors.whiteColor, size: 30),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          backgroundColor: AppColors.blackColor,
          body: Center(child: CircularProgressIndicator(color: AppColors.accentColor)),
        ),
      );
    }
    
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.blackColor,
        appBar: AppBar(
          title: const Text(
            'Coaches',
            style: TextStyle(color: AppColors.accentColor, fontWeight: FontWeight.bold)
          ),
          backgroundColor: AppColors.blackColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.whiteColor),
        ),
        
        body: StreamBuilder<List<CoachModel>>(
          stream: _fetchCoaches(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.accentColor));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading coaches: ${snapshot.error}', style: const TextStyle(color: AppColors.redColor)));
            }
            
            final coaches = snapshot.data ?? [];
            
            if (coaches.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No coaches available currently.', style: TextStyle(color: AppColors.darkGrayColor)),
                    if (_isAdmin) 
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: RoundButton(
                          title: 'Add First Coach',
                          type: RoundButtonType.primaryBG,
                          onPressed: () => _showAddEditModal(context),
                          width: 200,
                        ),
                      ),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: coaches.length,
              itemBuilder: (context, index) {
                final coach = coaches[index];
                
                Widget coachCard = CoachCard(
                  coach: coach, 
                  isAdmin: _isAdmin,
                  onEdit: () => _showAddEditModal(context, coach: coach),
                );
                
                if (_isAdmin) {
                  coachCard = Dismissible(
                    // ✨ زر الحذف يعمل عن طريق سحب البطاقة لليسار (Swipe-to-Delete)
                    key: Key(coach.id),
                    direction: DismissDirection.endToStart, 
                    background: _buildDismissibleBackground(AppColors.redColor, Icons.delete),
                    confirmDismiss: (direction) async {
                      HapticFeedback.mediumImpact(); // ✨ اهتزاز عند السحب
                      return await _confirmDelete(context, coach.name);
                    },
                    onDismissed: (direction) {
                      deleteCoach(coach.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Coach deleted: ${coach.name}', style: const TextStyle(color: AppColors.whiteColor)), backgroundColor: AppColors.redColor),
                      );
                    },
                    child: coachCard,
                  );
                }
                
                return coachCard;
              },
            );
          },
        ),
        
        // رفع زر الإضافة العائم (FAB)
        floatingActionButton: _isAdmin 
          ? Padding(
              padding: const EdgeInsets.only(bottom: 25.0), 
              child: FloatingActionButton(
                heroTag: 'add_new_coach_fab',           
                onPressed: () {
                   HapticFeedback.lightImpact(); // ✨ اهتزاز عند الضغط
                   _showAddEditModal(context);
                },
                backgroundColor: AppColors.accentColor,
                child: const Icon(Icons.add, color: AppColors.blackColor),
              ),
            )
          : null,
      ),
    );
  }
}

// =========================================================================
// 6. مكون كرت المدرب (CoachCard) - تصميم أبسط وأكثر تركيزاً
// =========================================================================

class CoachCard extends StatefulWidget {
  final CoachModel coach;
  final bool isAdmin;
  final VoidCallback? onEdit;
  
  const CoachCard({Key? key, required this.coach, required this.isAdmin, this.onEdit}) : super(key: key);

  @override
  State<CoachCard> createState() => _CoachCardState();
}

class _CoachCardState extends State<CoachCard> {
  
  bool _isTapped = false;

  void _toggleTap(bool isTapped) {
    setState(() {
      _isTapped = isTapped;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _toggleTap(true), 
      onTapUp: (_) => _toggleTap(false), 
      onTapCancel: () => _toggleTap(false), 
      onTap: () {
         // تنفيذ وظيفة الحجز أو عرض التفاصيل إذا لم يكن وضع الإدارة
         if (!widget.isAdmin) {
            ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Coach Profile Coming Soon...')),
            );
         }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        
        transform: Matrix4.identity()..scale(_isTapped ? 0.98 : 1.0), 
        
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.cardBackgroundColor,
          borderRadius: BorderRadius.circular(20), 
          boxShadow: [
            BoxShadow(
              color: AppColors.darkShadowColor,
              blurRadius: _isTapped ? 5 : 15,
              spreadRadius: _isTapped ? 0 : 2,
              offset: _isTapped ? const Offset(2, 2) : const Offset(5, 5),
            ),
            BoxShadow(
              color: AppColors.lightShadowColor,
              blurRadius: _isTapped ? 5 : 15,
              spreadRadius: _isTapped ? 0 : 2,
              offset: _isTapped ? const Offset(-2, -2) : const Offset(-5, -5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. الصورة المدورة على اليسار
            ClipOval(
              child: Image.network(
                widget.coach.imageUrl,
                width: 80, // تم تقليل الحجم قليلاً للمزيد من الأناقة
                height: 80,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor1));
                },
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 80, color: AppColors.darkGrayColor),
              ),
            ),
            const SizedBox(width: 15),
            
            // 2. البيانات (الاسم والتخصص والوصف فقط)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✨ الاسم (الآن هو العنوان الرئيسي)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.coach.name,
                          style: const TextStyle(
                            color: AppColors.whiteColor, 
                            fontSize: 22, // خط أكبر وأكثر بروزاً
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // زر التعديل
                      if (widget.isAdmin && widget.onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.accentColor, size: 20),
                          onPressed: widget.onEdit,
                        ),
                    ],
                  ),
                  // التخصص
                  Text(
                    widget.coach.specialization,
                    style: const TextStyle(color: AppColors.accentColor, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // الوصف (Bio)
                  Text(
                    widget.coach.bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.grayColor, fontSize: 14),
                  ),
                  
                  // ✨ تم إزالة الـ Row الخاص بالتقييم والخبرة
                  // ✨ تم إزالة زر View Details & Book
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
// 7. نافذة الإضافة/التعديل للمدرب (AddEditCoachModal) - ✨ تم حذف حقول التواصل
// =========================================================================

class AddEditCoachModal extends StatefulWidget {
  final bool isAdmin;
  final CoachModel? coachToEdit;

  const AddEditCoachModal({Key? key, required this.isAdmin, this.coachToEdit}) : super(key: key);

  @override
  State<AddEditCoachModal> createState() => _AddEditCoachModalState();
}

class _AddEditCoachModalState extends State<AddEditCoachModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _specController;
  late TextEditingController _bioController;
  late TextEditingController _imageController;
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final isEdit = widget.coachToEdit != null;
    final coach = widget.coachToEdit;

    _nameController = TextEditingController(text: isEdit ? coach!.name : '');
    _specController = TextEditingController(text: isEdit ? coach!.specialization : '');
    _bioController = TextEditingController(text: isEdit ? coach!.bio : '');
    _imageController = TextEditingController(text: isEdit ? coach!.imageUrl : '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specController.dispose();
    _bioController.dispose();
    _imageController.dispose();
    super.dispose();
  }
  
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    if (!mounted) return;
    setState(() { _isSaving = true; });

    final isEdit = widget.coachToEdit != null;
    final String coachId = widget.coachToEdit?.id ?? ''; 
    final String defaultImageUrl = 'https://placehold.co/100x100/333333/FFFFFF?text=Coach';
    
    final coach = CoachModel(
      id: coachId, 
      name: _nameController.text.trim(),
      specialization: _specController.text.trim(),
      bio: _bioController.text.trim(),
      imageUrl: _imageController.text.trim().isEmpty ? defaultImageUrl : _imageController.text.trim(),
      // لا توجد حقول أخرى للإرسال
    );

    try {
      if (isEdit) {
        await updateCoach(coach);
      } else {
        await addCoach(coach);
      }

      if (!mounted) return; 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Coach updated successfully!' : 'Coach added successfully!'),
          backgroundColor: AppColors.greenColor,
        ),
      );
      
      Navigator.of(context).pop(); 

    } on FirebaseException catch (e) {
       print('Firebase Error saving coach: ${e.code}');
       
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
             content: Text(e.code == 'permission-denied' ? 'Permission Error: Admin required.' : 'Save failed. Check your connection.'),
             backgroundColor: AppColors.redColor,
          ),
       );
    } catch (e) {
      print('General Error saving coach: $e');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred during save.'), backgroundColor: AppColors.redColor),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildStylishTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: AppColors.whiteColor),
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.grayColor),
          prefixIcon: Icon(icon, color: AppColors.accentColor.withOpacity(0.8)),
          filled: true,
          fillColor: AppColors.blackColor.withOpacity(0.7), 
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), 
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.darkGrayColor, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accentColor, width: 2),
          ),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return '$label is required.';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.coachToEdit != null;
    
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom, 
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackgroundColor, 
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)), 
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Directionality(
            textDirection: TextDirection.ltr, 
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.darkGrayColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                
                const SizedBox(height: 15),
                
                Text(
                  isEdit ? 'Edit Coach Details' : 'Add New Coach',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.accentColor,
                    fontSize: 24, 
                    fontWeight: FontWeight.w900,
                  ),
                ),
                
                const Divider(color: AppColors.blackColor, height: 30),
                
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildStylishTextField(
                        controller: _nameController, label: 'Coach Name (Required)', icon: Icons.person_outline, isRequired: true),
                      _buildStylishTextField(
                        controller: _specController, label: 'Specialization (e.g., Fitness, Nutrition)', icon: Icons.sports_gymnastics, isRequired: true),
                      _buildStylishTextField(
                        controller: _bioController, label: 'Short Bio', icon: Icons.description_outlined, maxLines: 3),
                      
                      const SizedBox(height: 5),
                      
                      _buildStylishTextField(
                        controller: _imageController, label: 'Coach Image URL (Optional)', icon: Icons.insert_photo_outlined),
                      
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                RoundButton(
                  title: isEdit ? 'Save Changes' : 'Add Coach',
                  onPressed: _isSaving ? null : _submitForm,
                  type: RoundButtonType.primaryBG,
                  height: 55, 
                ),
                
                const SizedBox(height: 15),
                
                RoundButton(
                  title: 'Cancel',
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  type: RoundButtonType.secondaryBorder,
                  height: 55,
                ),
                
                if (_isSaving)
                  const Padding(
                    padding: EdgeInsets.only(top: 15.0),
                    child: Center(child: CircularProgressIndicator(color: AppColors.accentColor)),
                  ),
                  
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}