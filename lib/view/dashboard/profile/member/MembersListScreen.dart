// members_list_screen.dart (الكود المُعدَّل لإزالة BMI من الفرز)

// ignore_for_file: library_private_types_in_public_api, depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 
import 'package:url_launcher/url_launcher.dart'; 
import 'member_details_screen.dart'; 

// تعريف الألوان (لضمان التناسق)
class AppColors {
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF1D1617); 
  static const Color darkGrayColor = Color(0xFFC0C0C0); 
  static const Color primaryColor1 = Color(0xFF92A3FD); 
  static const Color accentColor = Color(0xFF00C4CC); 
  static const Color cardBackgroundColor = Color(0xFF2E2E2E); 
  static const Color redColor = Color(0xFFEA4E79); 
  static const Color highlightColor = Color(0xFF00BFFF); 
}

// -------------------------------------------------------------------------
// 🔥 تم تعديل الخيارات: إزالة BMI
enum SortOption { name, registrationDate } 
// -------------------------------------------------------------------------

class MembersListScreen extends StatefulWidget {
  static const String routeName = "/MembersListScreen";
  const MembersListScreen({Key? key}) : super(key: key);

  @override
  _MembersListScreenState createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  final CollectionReference _members = 
      FirebaseFirestore.instance.collection('memberships');
      
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  // 🔥 البدء بالفرز حسب التاريخ
  SortOption _currentSort = SortOption.registrationDate; 
  bool _isAscending = false; 

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      // البحث فقط بالاسم
      _searchQuery = _searchController.text.toLowerCase();
    });
  }
  
  // 📞 دالة فتح تطبيق واتساب
  Future<void> _launchWhatsApp(String phoneNumber, String name) async {
    const String defaultPhoneNumber = "966512345678"; 
    final Uri url = Uri.parse("whatsapp://send?phone=$defaultPhoneNumber&text=Hello $name, we would like to check on your gym subscription.");
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("WhatsApp is not installed or the link cannot be opened.", textAlign: TextAlign.right),
          backgroundColor: AppColors.redColor,
        ),
      );
    }
  }

  // 💡 منطق تحديد لون BMI (بقي هذا الجزء لأن BMI ما زال يظهر في البطاقة)
  Color getBmiColor(String bmiString) {
    final bmi = double.tryParse(bmiString) ?? 0.0;
    if (bmi < 18.5) return Colors.blueAccent;       
    if (bmi >= 18.5 && bmi <= 24.9) return Colors.greenAccent; 
    if (bmi >= 25.0 && bmi <= 29.9) return Colors.orangeAccent; 
    return AppColors.redColor;                         
  }

  // 📝 منطق الفرز
  List<QueryDocumentSnapshot> _sortData(List<QueryDocumentSnapshot> data) {
    data.sort((a, b) {
      final Map<String, dynamic> dataA = a.data() as Map<String, dynamic>;
      final Map<String, dynamic> dataB = b.data() as Map<String, dynamic>;
      
      int result = 0;
      
      switch (_currentSort) {
        case SortOption.name:
          result = (dataA['name'] as String? ?? '').compareTo(dataB['name'] as String? ?? '');
          break;

        case SortOption.registrationDate:
          final dateA = dataA['registration_date'] as Timestamp?;
          final dateB = dataB['registration_date'] as Timestamp?;
          // 🔥 الفرز حسب التاريخ (الأحدث أولاً افتراضياً)
          result = dateA?.compareTo(dateB ?? Timestamp.now()) ?? 0;
          break;
        
        // 🔥 تم حذف حالة (case) الفرز حسب BMI هنا
      }
      
      // الترتيب: صاعد (Ascending) أو تنازلي (Descending)
      return _isAscending ? result : -result;
    });
    return data;
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blackColor,
      appBar: AppBar(
        backgroundColor: AppColors.blackColor,
        title: const Text(
          "Gym Members List",
          style: TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by Name...",
                hintStyle: const TextStyle(color: AppColors.darkGrayColor),
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryColor1),
                filled: true,
                fillColor: AppColors.cardBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: AppColors.whiteColor),
            ),
          ),
        ),
      ),
      
      body: Column(
        children: [
          // شريط الفرز (Sorting Bar) - تم تعديله الآن
          _buildSortingBar(),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _members.snapshots(), 
              builder: (context, snapshot) {
                
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading data.', style: TextStyle(color: AppColors.redColor)));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accentColor));
                }
                
                List<QueryDocumentSnapshot> rawData = snapshot.data!.docs;
                
                // 1. تطبيق البحث (فقط بالاسم)
                List<QueryDocumentSnapshot> filteredData = rawData.where((document) {
                  final data = document.data()! as Map<String, dynamic>;
                  final name = (data['name'] as String? ?? '').toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();
                
                // 2. تطبيق الفرز
                List<QueryDocumentSnapshot> finalData = _sortData(filteredData);
                
                if (finalData.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty ? "No active members found." : "No results matched your search.",
                      style: const TextStyle(color: AppColors.darkGrayColor, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: finalData.length,
                  itemBuilder: (context, index) {
                    final Map<String, dynamic> memberData = finalData[index].data()! as Map<String, dynamic>;
                    
                    Timestamp? regTimestamp = memberData['registration_date'] as Timestamp?;
                    String regDate = 'N/A';
                    if (regTimestamp != null) {
                      regDate = DateFormat('MMM d, yyyy').format(regTimestamp.toDate());
                    }
                    
                    final String bmiValue = memberData['bmi'] ?? '--';
                    final Color bmiColor = getBmiColor(bmiValue);
                    
                    // عند النقر، انتقل إلى شاشة التفاصيل
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MemberDetailsScreen(memberData: memberData),
                          ),
                        );
                      },
                      child: _buildMemberCard(memberData, regDate, bmiValue, bmiColor),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  // 🎨 بناء شريط الفرز - تم تعديله لإزالة BMI
  Widget _buildSortingBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          _buildSortButton("Name", SortOption.name),
          _buildSortButton("Date", SortOption.registrationDate),
          // 🔥 تم إزالة زر فرز BMI من هنا
        ],
      ),
    );
  }
  
  // 🎨 بناء زر الفرز
  Widget _buildSortButton(String label, SortOption option) {
    final bool isSelected = _currentSort == option;
    final IconData icon = isSelected 
        ? (_isAscending ? Icons.arrow_upward : Icons.arrow_downward) 
        : Icons.sort;
        
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ActionChip(
        avatar: Icon(icon, color: isSelected ? AppColors.blackColor : AppColors.whiteColor, size: 18),
        label: Text(label, style: TextStyle(color: isSelected ? AppColors.blackColor : AppColors.whiteColor)),
        onPressed: () {
          setState(() {
            if (_currentSort == option) {
              _isAscending = !_isAscending; 
            } else {
              _currentSort = option; 
              _isAscending = false; 
            }
          });
        },
        backgroundColor: isSelected ? AppColors.accentColor : AppColors.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? AppColors.accentColor : AppColors.darkGrayColor.withOpacity(0.5)),
        ),
      ),
    );
  }

  // 📄 بناء بطاقة العميل (Member Card)
  Widget _buildMemberCard(Map<String, dynamic> memberData, String regDate, String bmiValue, Color bmiColor) {
    // ... (بقي الكود هنا كما هو، حيث أن BMI ما زال يظهر داخل البطاقة، وهو أمر منطقي)
    final String memberName = memberData['name'] ?? 'Unknown Member';
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundColor, 
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primaryColor1.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.person, color:Colors.lightBlue, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        memberName,
                        style: const TextStyle(
                          color: AppColors.whiteColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.phone, color:Colors.green, size: 28),
                onPressed: () => _launchWhatsApp("", memberName), 
                tooltip: 'Contact via WhatsApp',
              ),
            ],
          ),
          const Divider(color: AppColors.darkGrayColor, height: 20, thickness: 0.5),

          _buildDetailRow(Icons.cake, "Age", "${memberData['age'] ?? '--'} yrs"),
          // _buildDetailRow(
          //   Icons.trending_up,
          //   "BMI",
          //   bmiValue,
          //   highlightColor: bmiColor, 
          // ),

          const SizedBox(height: 10),
          Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              "Joined: $regDate",
              style: const TextStyle(
                color: AppColors.darkGrayColor,
                fontSize: 11,
              ),
            ),
          )
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(IconData icon, String label, String value, {Color highlightColor = AppColors.whiteColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryColor1, size: 16),
          const SizedBox(width: 8),
          Text(
            "$label:",
            style: const TextStyle(
              color: AppColors.darkGrayColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: highlightColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}