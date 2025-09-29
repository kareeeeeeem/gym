import 'package:fitnessapp/view/dashboard/Room/RoomDetailsScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// =========================================================================
// 0. App Colors (Designed for "Ego Gym" - Dark/Maroon & Gold Theme)
// =========================================================================
class AppColors {
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF1D1617);
  static const Color darkGrayColor = Color(0xFFC0C0C0); // Lighter Gray for better contrast on dark background
  static const Color primaryColor1 = Color(0xFF8B0000); // Dark Maroon/Deep Red for Ego Gym
  static const Color accentColor = Color(0xFFFFA500); // Electric Gold/Amber
  static const Color accentGradientStart = Color(0xFFFFCC00); // Lighter Gold
  static const Color accentGradientEnd = Color(0xFF8B0000); // Maroon/Deep Red
  static const Color cardBackgroundColor = Color(0xFF222222); // Dark background for cards
}

// =========================================================================
// 1. Gym Room Data Model (GymRoom) - Translated & Updated
// =========================================================================

class GymRoom {
  final String id;
  final String title;
  final String description; 
  final String creatorId;
  final String creatorName;
  final String targetMuscle;
  final Timestamp startTime;
  final Timestamp createdAt; 
  final String gymLocation;
  final int maxCapacity;
  final List<dynamic> participants;
  final List<String> participantUids;
  final bool isClosed;

  GymRoom({
    required this.id,
    required this.title,
    this.description = '', 
    required this.creatorId,
    required this.creatorName,
    required this.targetMuscle,
    required this.startTime,
    required this.createdAt, 
    required this.gymLocation,
    required this.maxCapacity,
    required this.participants,
    required this.participantUids,
    this.isClosed = false,
  });

  factory GymRoom.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Convert dynamic list to string list
    List<String> uids = (data['participantUids'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ?? [];
    
    // Ensure createdAt is read correctly, handling server timestamp
    final createdAtTimestamp = data['createdAt'] as Timestamp? ?? Timestamp.now();

    return GymRoom(
      id: doc.id,
      title: data['title'] ?? 'Training Room',
      description: data['description'] ?? '', 
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? 'Unknown User',
      targetMuscle: data['targetMuscle'] ?? 'General Workout',
      startTime: data['startTime'] ?? Timestamp.now(),
      createdAt: createdAtTimestamp, // Use the extracted timestamp
      gymLocation: data['gymLocation'] ?? 'Unspecified Gym',
      maxCapacity: data['maxCapacity'] ?? 5,
      participants: data['participants'] ?? [],
      participantUids: uids, 
      isClosed: data['isClosed'] ?? false,
    );
  }
}

// =========================================================================
// 2. Social Gym Rooms Screen (GymRoomsScreen)
// =========================================================================

class GymRoomsScreen extends StatefulWidget {
  static const String routeName = '/room';
  const GymRoomsScreen({super.key});

  @override
  State<GymRoomsScreen> createState() => _GymRoomsScreenState();
}

class _GymRoomsScreenState extends State<GymRoomsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  // State to track if authentication is ready
  bool _isAuthReady = false; 

  // Get current user data
  String get currentUserId => _auth.currentUser?.uid ?? '';
  String get currentUserName => _auth.currentUser?.displayName ?? 'New Player';

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }
// =========================================================================
// 3. Authentication Initialization Logic - Translated & Improved
// =========================================================================
void _initializeAuth() async {
  try {
    // Wait for Firebase Auth to finish initialization
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (_auth.currentUser != null) {
      print('Auth is ready. User ID: ${_auth.currentUser!.uid}');
      setState(() {
        _isAuthReady = true;
      });
      return;
    }
    
    // Attempt Anonymous Sign-in as a Fallback
    try {
      final userCredential = await _auth.signInAnonymously();
      print('Firebase Auth: Signed in Anonymously. UID: ${userCredential.user?.uid}');
    } catch (e) {
      print('Firebase Auth Error during anonymous sign-in: $e');
    }
  } finally {
    // Allow data reading to start regardless of sign-in success
    setState(() {
      _isAuthReady = true;
    });
  }
}

  // =========================================================================
  // 4. Create Room Logic - Translated & Updated
  // =========================================================================

  Future<void> _showCreateRoomModal() async {
    if (currentUserId.isEmpty) {
       _showAlertDialog('Authentication Error', 'Please ensure you are logged in before creating a room.');
       return;
    }
    final titleController = TextEditingController();
    final descriptionController = TextEditingController(); 
    final muscleController = TextEditingController();
    final locationController = TextEditingController();
    DateTime selectedTime = DateTime.now().add(const Duration(hours: 1));
    int capacity = 5; // Default capacity

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackgroundColor, // Dark modal background
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          top: 30,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Create New Training Room',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.whiteColor)),
              Divider(color: AppColors.darkGrayColor),
              _buildTextField(titleController, 'Room Title', Icons.title),
              const SizedBox(height: 15),
              // Description field
              _buildTextField(descriptionController, 'Additional Description (Optional)', Icons.info_outline, isOptional: true),
              const SizedBox(height: 15),
              _buildTextField(muscleController, 'Target Muscle (Ex: Biceps & Triceps)', Icons.fitness_center),
              const SizedBox(height: 15),
              _buildTextField(locationController, 'Gym Location', Icons.location_on),
              const SizedBox(height: 15),
              // Capacity and Time Picker
              StatefulBuilder(
                builder: (context, setModalState) {
                  return Column(
                    children: [
                      // Max Capacity Control
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Max Participants:', style: TextStyle(color: AppColors.darkGrayColor)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: AppColors.accentColor),
                                onPressed: () {
                                  if (capacity > 2) setModalState(() => capacity--);
                                },
                              ),
                              Text('$capacity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.whiteColor)),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: AppColors.accentColor),
                                onPressed: () {
                                  if (capacity < 15) setModalState(() => capacity++); // Reasonable Max
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      // Time Picker
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Start Time:', style: TextStyle(color: AppColors.darkGrayColor)),
                          TextButton.icon(
                            icon: const Icon(Icons.access_time, color: AppColors.primaryColor1),
                            label: Text(
                              // Using 'en' for date/time format
                              DateFormat('MMM d, hh:mm a', 'en').format(selectedTime), 
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryColor1),
                            ),
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(selectedTime),
                              );
                              if (time != null) {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: selectedTime,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 30)),
                                );
                                if (date != null) {
                                  setModalState(() {
                                    selectedTime = DateTime(
                                      date.year, date.month, date.day, time.hour, time.minute,
                                    );
                                  });
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 25),
              _buildGradientButton('Create Room & Start', () async {
                if (titleController.text.isEmpty || muscleController.text.isEmpty) {
                  _showAlertDialog('Missing Data', 'Please enter a room title and target muscle.');
                  return; 
                }
                
                // Firestore Path
                final roomCollectionRef = _firestore
                    .collection('artifacts')
                    .doc('default-app-id')
                    .collection('public')
                    .doc('data')
                    .collection('room');

                // Create Room in Firestore
                await roomCollectionRef.add({
                  'title': titleController.text,
                  'description': descriptionController.text, 
                  'creatorId': currentUserId,
                  'creatorName': currentUserName,
                  'targetMuscle': muscleController.text,
                  'startTime': Timestamp.fromMicrosecondsSinceEpoch(selectedTime.microsecondsSinceEpoch),
                  'gymLocation': locationController.text,
                  'maxCapacity': capacity, 
                  'isClosed': false,
                  'participants': [
                    {'uid': currentUserId, 'name': currentUserName, 'joinedAt': Timestamp.now()}
                  ],
                  'participantUids': [currentUserId],
                  'createdAt': FieldValue.serverTimestamp(), // Use serverTimestamp for accuracy
                });

                if (mounted) Navigator.pop(context);
              }),
            ],
          ),
        ),
      ),
    );
  }
// =========================================================================
// 5. Join Room Logic - Translated
// =========================================================================
Future<void> _joinRoom(GymRoom room) async {
  if (currentUserId.isEmpty) {
    _showAlertDialog('Authentication Error', 'Please ensure you are logged in before joining a room.');
    return;
  }

  final roomRef = _firestore
      .collection('artifacts')
      .doc('default-app-id')
      .collection('public')
      .doc('data')
      .collection('room')
      .doc(room.id);
  
  // Check Capacity and if already joined
  if (room.participants.length >= room.maxCapacity) {
    _showAlertDialog('Room Full', 'Sorry, this room has reached its maximum capacity.');
    return;
  }
  
  if (room.participantUids.contains(currentUserId)) {
    _showAlertDialog('Already Joined', 'You can navigate to room details for chat and starting.');
    _navigateToRoomDetails(room); 
    return;
  }

  try {
    // Use FieldValue.arrayUnion for safe list update
    await roomRef.update({
      'participants': FieldValue.arrayUnion([
        {'uid': currentUserId, 'name': currentUserName, 'joinedAt': Timestamp.now()}
      ]),
      'participantUids': FieldValue.arrayUnion([currentUserId]), 
    });
    
    if (mounted) {
      _navigateToRoomDetails(room);
    }
  } catch (e) {
    print('Join Room Error Details: $e');
    _showAlertDialog('Join Error', 'An error occurred while attempting to join. This may be due to security rules or internet connection.');
  }
}  

// =========================================================================
// 5.1. Room Deletion Logic (New Requirement)
// =========================================================================
Future<void> _deleteRoomIfAllowed(GymRoom room) async {
  if (room.creatorId != currentUserId) {
    _showAlertDialog('Access Denied', 'Only the creator can delete this room.');
    return;
  }

  final now = DateTime.now();
  final creationTime = room.createdAt.toDate();
  final difference = now.difference(creationTime);
  
  // Check if more than 60 minutes (1 hour) has passed
  if (difference.inMinutes > 60) {
    _showAlertDialog('Deletion Time Limit Passed', 'You can only delete the room within 60 minutes of creation.');
    return;
  }
  
  // Confirmation dialog
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.cardBackgroundColor,
      title: const Text('Confirm Deletion', style: TextStyle(color: AppColors.whiteColor)),
      content: const Text('Are you sure you want to delete this room? This action cannot be undone.', style: TextStyle(color: AppColors.darkGrayColor)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: AppColors.darkGrayColor)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      await _firestore
          .collection('artifacts')
          .doc('default-app-id')
          .collection('public')
          .doc('data')
          .collection('room')
          .doc(room.id)
          .delete();
      if (mounted) {
        // Show success message or simply allow the stream to refresh
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room deleted successfully!')),
        );
      }
    } catch (e) {
      _showAlertDialog('Deletion Error', 'Failed to delete room: $e');
    }
  }
}

// =========================================================================
  // 6. Real-time Room List View - Translated & Updated
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    Intl.defaultLocale = 'en'; // Set default locale for date formatting
    
    // Calculate 24 hours ago for filtering
    final twentyFourHoursAgo = Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24)));
    
    return Scaffold(
      backgroundColor: AppColors.blackColor, // Dark background for the screen
      appBar: AppBar(
        title: const Text('Ego Gym Social Rooms', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.whiteColor)),
        backgroundColor: AppColors.blackColor,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.whiteColor),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: _buildSearchField(),
          ),
          Expanded(
            // Show loading indicator if Auth is not ready
            child: !_isAuthReady
                ? const Center(child: CircularProgressIndicator(color: AppColors.accentColor))
                : StreamBuilder<QuerySnapshot>(
                    // Filter Rooms:
                    // 1. Not started yet
                    // 2. Not closed
                    // 3. Created within the last 24 hours (for display filtering)
                    stream: _firestore
                        .collection('artifacts')
                        .doc('default-app-id')
                        .collection('public')
                        .doc('data')
                        .collection('room')
                        // .where('createdAt', isGreaterThan: twentyFourHoursAgo) 
                        // .where('startTime', isGreaterThan: Timestamp.now()) 
                        .where('isClosed', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        print('Firestore Stream Error: ${snapshot.error}');
                        return Center(
                          child: Text('Error loading rooms! Check security rules. Error: ${snapshot.error}',
                           textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700, fontSize: 14)),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.accentColor));
                      }

                      final rooms = snapshot.data!.docs.map(GymRoom.fromFirestore).toList();

                      // Filter based on search query
                      final filteredRooms = rooms.where((room) {
                        final query = _searchQuery.toLowerCase();
                        return room.title.toLowerCase().contains(query) ||
                               room.targetMuscle.toLowerCase().contains(query) ||
                               room.creatorName.toLowerCase().contains(query);
                      }).toList();
                      
                      if (filteredRooms.isEmpty) {
                        return const Center(
                          child: Text('No rooms currently available. Be the first to create one!',
                              textAlign: TextAlign.center, style: TextStyle(color: AppColors.darkGrayColor)),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        itemCount: filteredRooms.length,
                        itemBuilder: (context, index) {
                          return _buildRoomCard(filteredRooms[index]);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      // Floating Action Button to create a new room
      floatingActionButton: FloatingActionButton.extended(
        onPressed: currentUserId.isEmpty ? () => _showAlertDialog('Login Required', 'You must log in first to create a room.') : _showCreateRoomModal,
        label: const Text('Create Room', style: TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: AppColors.whiteColor),
        backgroundColor: AppColors.primaryColor1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  // =========================================================================
  // 7. Helper Widgets (Widgets for Design) - Translated & Themed
  // =========================================================================

  Widget _buildRoomCard(GymRoom room) {
    final participantsCount = room.participants.length;
    final isFull = participantsCount >= room.maxCapacity;

    return GestureDetector(
      onTap: () => _navigateToRoomDetails(room),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackgroundColor, // Dark card background
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.blackColor.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          // Subtle gradient using theme colors
          gradient: LinearGradient(
            colors: [AppColors.cardBackgroundColor, AppColors.primaryColor1.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Creator (Enhanced Visibility)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    room.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.whiteColor, // HIGH VISIBILITY
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Creator: ${room.creatorName}',
                  style: const TextStyle(fontSize: 12, color: AppColors.darkGrayColor), // IMPROVED VISIBILITY
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Description (Enhanced Visibility)
            if (room.description.isNotEmpty) 
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  room.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.darkGrayColor, // IMPROVED VISIBILITY
                  ),
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Muscle and Time
            Row(
              children: [
                Icon(Icons.directions_run, size: 16, color: AppColors.accentColor),
                const SizedBox(width: 5),
                Text(
                  room.targetMuscle,
                  style: TextStyle(color: AppColors.accentColor, fontWeight: FontWeight.bold), 
                ),
                const Spacer(),
                Icon(Icons.access_time_filled, size: 16, color: AppColors.primaryColor1),
                const SizedBox(width: 5),
                Text(
                  DateFormat('hh:mm a', 'en').format(room.startTime.toDate()),
                  style: TextStyle(color: AppColors.primaryColor1, fontWeight: FontWeight.bold), 
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Participants and Join Button (Enhanced Visibility)
            Row(
              children: [
                Icon(Icons.people_alt, size: 18, color: AppColors.darkGrayColor),
                const SizedBox(width: 5),
                Text(
                  '$participantsCount / ${room.maxCapacity} Members',
                  style: const TextStyle(color: AppColors.darkGrayColor, fontSize: 14), // IMPROVED VISIBILITY
                ),
                const Spacer(),
                
                // Join Button / Creator Status / Delete Button
                _buildJoinButton(room, isFull),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinButton(GymRoom room, bool isFull) {
    final isJoined = room.participantUids.contains(currentUserId); 
    final isCreator = room.creatorId == currentUserId;

    // Check if the 60 minute deletion window is open
    bool canDelete = false;
    if (isCreator) {
        final now = DateTime.now();
        final creationTime = room.createdAt.toDate();
        final difference = now.difference(creationTime);
        canDelete = difference.inMinutes <= 60;
    }

    // If user is the creator
    if (isCreator) {
        if (canDelete) {
            // Show Delete Button and Creator Status (or just Delete)
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor1.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Creator', style: TextStyle(color: AppColors.whiteColor, fontSize: 12)),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _deleteRoomIfAllowed(room),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.red.shade800,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Delete', style: TextStyle(color: AppColors.whiteColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            );
        } else {
             // Creator, but deletion time passed
             return _buildGradientButton('Details & Chat', () => _navigateToRoomDetails(room), isSmall: true);
        }
    }

    // If full
    if (isFull) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('Full', style: TextStyle(color: AppColors.whiteColor, fontSize: 12)),
      );
    }
    
    // If already joined
    if (isJoined) {
      return _buildGradientButton('Details & Chat', () => _navigateToRoomDetails(room), isSmall: true);
    }

    // Join Button
    return _buildGradientButton('Join Now', () => _joinRoom(room), isSmall: true);
  }


  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      style: const TextStyle(color: AppColors.whiteColor), // White text for search
      decoration: InputDecoration(
        hintText: 'Search room by name or target muscle',
        hintStyle: TextStyle(color: AppColors.darkGrayColor),
        prefixIcon: const Icon(Icons.search, color: AppColors.accentColor), // Gold/Amber icon
        filled: true,
        fillColor: AppColors.cardBackgroundColor, // Dark fill
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
      ),
    );
  }
  
  // Gradient Button
  Widget _buildGradientButton(String text, VoidCallback onPressed, {bool isSmall = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmall ? 15 : 30),
        gradient: const LinearGradient(
          colors: [AppColors.accentColor, AppColors.primaryColor1], // Gold to Maroon
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor1.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 15 : 25, vertical: isSmall ? 8 : 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isSmall ? 15 : 30)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.whiteColor,
            fontSize: isSmall ? 12 : 16,
            fontWeight: isSmall ? FontWeight.normal : FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Modified TextField for Optional Multi-line Text
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isOptional = false}) {
    return TextField(
      controller: controller,
      maxLines: isOptional ? 3 : 1, // Allows 3 lines for description
      style: const TextStyle(color: AppColors.whiteColor), // White text input
      decoration: InputDecoration(
        labelText: isOptional ? '$label (Optional)' : label, 
        labelStyle: const TextStyle(color: AppColors.darkGrayColor), // Darker label text
        prefixIcon: Icon(icon, color: AppColors.accentColor), // Gold/Amber icon
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.darkGrayColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.darkGrayColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.accentColor, width: 2), // Gold/Amber focus border
        ),
      ),
    );
  }
  
  // Alert Dialog function
  void _showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackgroundColor, // Dark Alert background
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.whiteColor)),
        content: Text(message, style: const TextStyle(color: AppColors.whiteColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.accentColor)), // Gold/Amber action button
          )
        ],
      ),
    );
  }
  
  // Navigate to Details function
void _navigateToRoomDetails(GymRoom room) {
  // Navigate to the new screen
  Navigator.push(
    context, 
    MaterialPageRoute(
      builder: (context) => RoomDetailsScreen(room: room) 
    )
  );
}
}