import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async'; // Required for Timer management

// --- 1. Enhanced Color Palette (Deep Cyan / Light Slate) ---
class AppColors {
  // Primary (Health/Wellness - Cyan/Teal)
  static const Color primary = Color(0xFF00BCD4); // Deep Cyan
  // Accent (Alerts/Action - Vibrant Orange)
  static const Color accent = Color(0xFFFF9800); // Orange 500
  // Backgrounds
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF0F4F8); // Light Blue-Grey
  // Text Colors
  static const Color darkText = Color(0xFF263238); // Dark Slate
  static const Color lightText = Color(0xFFFFFFFF);
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
}

class AppConfig {
  static const String appTitle = 'Wellness Tracker Dashboard';
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Using ColorScheme to define modern M3 colors
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          background: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Water Tracking State
  final double _waterGoal = 8.0; // Liters
  double _waterLiters = 1.2;
  double _waterIntakeRatio = 0.0; // 0.0 to 1.0
  
  // Calorie & Workout State (Simulated)
  final double _calorieGoal = 2200;
  double _caloriesConsumed = 1800;
  double _caloriesBurnt = 300;
  // Base consumption to start the day with a non-zero value, reset to this value
  final double _initialCaloriesConsumed = 500; 

  bool _isWorkoutActive = false;
  int _workoutTimeSeconds = 0;
  Timer? _workoutTimerInstance; // Timer for proper management
  
  // Sleep State
  int _sleepHours = 7;
  int _sleepMinutes = 30;

  @override
  void initState() {
    super.initState();
    _calculateWaterRatio();
  }

  @override
  void dispose() {
    _workoutTimerInstance?.cancel(); // Important: Cancel timer when widget is removed
    super.dispose();
  }

  void _calculateWaterRatio() {
    setState(() {
      // Ratio clamps at 1.0 (100%), even if intake exceeds the goal
      _waterIntakeRatio = (_waterLiters / _waterGoal).clamp(0.0, 1.0);
    });
  }

  // --- Water Intake Logic ---
  void _addWaterIntake(double amountInLiters) {
    setState(() {
      _waterLiters += amountInLiters;
      _waterLiters = _waterLiters.clamp(0.0, double.infinity);
      _calculateWaterRatio();
    });
  }
  
  void _subtractWaterIntake(double amountInLiters) {
    setState(() {
      _waterLiters -= amountInLiters;
      _waterLiters = _waterLiters.clamp(0.0, double.infinity); // Cannot go below zero
      _calculateWaterRatio();
    });
  }
  // --- End of Water Intake Logic ---

  // --- Workout Timer Logic ---
  void _startStopWorkout() {
    setState(() {
      _isWorkoutActive = !_isWorkoutActive;
      if (_isWorkoutActive) {
        _startTimer();
      } else {
        _workoutTimerInstance?.cancel();
      }
    });
  }

  void _startTimer() {
    // 10 kCal burned every 15 seconds simulation
    _workoutTimerInstance = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isWorkoutActive) {
        timer.cancel();
        return;
      }
      setState(() {
        _workoutTimeSeconds++;
        if (_workoutTimeSeconds % 15 == 0) {
          _caloriesBurnt += 10;
        }
      });
    });
  }
  // --- End of Workout Timer Logic ---
  
  // --- Added Reset Functionality ---
  void _resetDailyStats() {
    // Stop workout timer if active
    _workoutTimerInstance?.cancel();

    setState(() {
      // Reset Water
      _waterLiters = 0.0;
      _calculateWaterRatio();

      // Reset Calories & Workout
      _caloriesConsumed = _initialCaloriesConsumed; 
      _caloriesBurnt = 0;
      _isWorkoutActive = false;
      _workoutTimeSeconds = 0;

      // Reset Sleep to a default/empty state
      _sleepHours = 0;
      _sleepMinutes = 0;
    });
    // Show confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Daily stats reset! Start tracking your new day.'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }
  // --- End of Reset Functionality ---

  // Modal for adding sleep data (kept largely the same but with enhanced styling)
  void _showAddSleepModal(BuildContext context) {
    int newHours = _sleepHours;
    int newMinutes = _sleepMinutes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
          ),
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Log Sleep Duration', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkText)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Hours',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: _sleepHours.toString(),
                        prefixIcon: const Icon(Icons.access_time),
                      ),
                      onChanged: (value) => newHours = int.tryParse(value) ?? _sleepHours,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Minutes (0-59)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: _sleepMinutes.toString(),
                        prefixIcon: const Icon(Icons.schedule),
                      ),
                      onChanged: (value) => newMinutes = int.tryParse(value) ?? _sleepMinutes,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (newMinutes < 60 && newMinutes >= 0 && newHours >= 0) {
                      setState(() {
                        _sleepHours = newHours;
                        _sleepMinutes = newMinutes;
                      });
                      Navigator.pop(context);
                    } else {
                      // Show an error message using SnackBar
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Invalid input: Minutes must be between 0 and 59.'),
                            backgroundColor: AppColors.accent,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.lightText,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Sleep Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculated Values
    final double netCalories = _caloriesConsumed - _caloriesBurnt;
    final double remainingCalories = _calorieGoal - netCalories;
    final double calorieRatio = (netCalories / _calorieGoal).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appTitle, style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.cardBackground,
        elevation: 1, // Slight elevation for better separation
        centerTitle: true,
        actions: [
          // Reset Button
          IconButton(
            icon: const Icon(Icons.restart_alt, color: AppColors.primary),
            onPressed: _resetDailyStats,
            tooltip: 'إعادة تعيين إحصائيات اليوم',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // --- Calories & Workout Cards (Responsive Row) ---
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildCalorieCard(netCalories, remainingCalories, calorieRatio)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildWorkoutCard()),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildCalorieCard(netCalories, remainingCalories, calorieRatio),
                      const SizedBox(height: 16),
                      _buildWorkoutCard(),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 20),

            // --- Water & Sleep Cards (Responsive Row) ---
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildWaterCard()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSleepCard()),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildWaterCard(),
                      const SizedBox(height: 16),
                      _buildSleepCard(),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 20),

            // --- Weekly Calorie Chart ---
            _buildWeeklyActivityChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieCard(double netCalories, double remainingCalories, double ratio) {
    final bool exceeded = remainingCalories.isNegative;
    final Color progressColor = exceeded ? AppColors.accent : AppColors.primary;
    
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Daily Calorie Net', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText)),
            const SizedBox(height: 15),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 130,
                    width: 130,
                    child: CircularProgressIndicator(
                      value: ratio,
                      strokeWidth: 10,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${remainingCalories.abs().round()}', // Always show absolute value
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: progressColor),
                      ),
                      Text(
                        exceeded ? 'kCal OVER' : 'kCal Left',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            const Divider(color: Colors.grey, height: 1),
            const SizedBox(height: 15),
            _buildCalorieRow('Consumed', _caloriesConsumed.round(), AppColors.darkText),
            _buildCalorieRow('Burnt', _caloriesBurnt.round(), AppColors.success),
            _buildCalorieRow('Net Remaining', remainingCalories.round(), progressColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieRow(String label, int value, Color color) {
    // Helper function to show formatted calorie values
    String formattedValue;

    if (label == 'Net Remaining') {
      // Net Remaining is displayed as absolute value + "less" or "left"
      formattedValue = value.isNegative ? '${value.abs()} over' : '${value.abs()} left';
    } else {
      // Consumed/Burnt are just the number
      formattedValue = '$value';
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 15, color: AppColors.darkText.withOpacity(0.8))),
          Text('$formattedValue kCal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard() {
    String formattedTime = _formatTime(_workoutTimeSeconds);
    
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activity Tracker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText)),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.directions_run, size: 48, color: _isWorkoutActive ? AppColors.accent : Colors.grey.shade400),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formattedTime,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkText),
                    ),
                    const Text('Time Elapsed', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              '🔥 ${_caloriesBurnt.round()} kCal Burned Today',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.success),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startStopWorkout,
                icon: Icon(_isWorkoutActive ? Icons.pause_circle_outline : Icons.play_circle_outline),
                label: Text(_isWorkoutActive ? 'PAUSE Workout' : 'START New Workout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isWorkoutActive ? AppColors.accent : AppColors.primary,
                  foregroundColor: AppColors.lightText,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildWaterCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hydration Goal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText)),
            const SizedBox(height: 20),
            Row(
              children: [
                // Animated Water Progress Bar
                SizedBox(
                  height: 100,
                  width: 20,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SimpleAnimationProgressBar(
                      ratio: _waterIntakeRatio,
                      barColor: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Water Stats and Buttons
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_waterLiters.toStringAsFixed(1)} L',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.darkText),
                      ),
                      Text(
                        'Goal: ${_waterGoal.toStringAsFixed(1)} L (${(_waterIntakeRatio * 100).toInt()}%)',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: _buildWaterButton(
                              icon: Icons.remove,
                              label: '-300ml',
                              onPressed: () => _subtractWaterIntake(0.3),
                              color: Colors.red.shade400,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildWaterButton(
                              icon: Icons.add,
                              label: '+300ml',
                              onPressed: () => _addWaterIntake(0.3),
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWaterButton({required IconData icon, required String label, required VoidCallback onPressed, required Color color}) {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.lightText,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSleepCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sleep Quality', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText)),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.nights_stay, size: 48, color: Color(0xFF673AB7)), // Deep Purple
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_sleepHours}h ${_sleepMinutes}m',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkText),
                    ),
                    const Text('Last Logged', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAddSleepModal(context),
                icon: const Icon(Icons.add_task),
                label: const Text('Log Sleep'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF673AB7), // Deep Purple
                  foregroundColor: AppColors.lightText,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyActivityChart() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 10), // Reduced bottom padding for chart
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Weekly Calorie Net', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText)),
            const SizedBox(height: 15),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: _getBarGroups(),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      // Line representing the target calorie goal
                      if (value == _calorieGoal) {
                        return FlLine(color: AppColors.primary.withOpacity(0.5), strokeWidth: 2, dashArray: [6, 4]);
                      }
                      return FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1);
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: _getBottomTitles,
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  alignment: BarChartAlignment.spaceAround,
                  minY: 0,
                  maxY: 3000,
                  // Show tooltip on hover/touch
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final day = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][groupIndex];
                        return BarTooltipItem(
                          '$day\n',
                          const TextStyle(color: AppColors.lightText, fontWeight: FontWeight.bold, fontSize: 12),
                          children: <TextSpan>[
                            TextSpan(
                              text: '${rod.toY.round()} kCal',
                              style: TextStyle(color: AppColors.lightText, fontSize: 14),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(5))),
                const SizedBox(width: 5),
                const Text('Below/At Goal', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 15),
                Container(width: 10, height: 10, decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(5))),
                const SizedBox(width: 5),
                const Text('Above Goal', style: TextStyle(fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Sample data for the bar chart
  List<BarChartGroupData> _getBarGroups() {
    // Fixed sample data for the weekly chart (Net Calories for 7 days)
    final List<double> barData = [2100, 2300, 1950, 2500, 1800, 2200, 1750]; 

    return List.generate(7, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: barData[index],
            color: barData[index] > _calorieGoal ? AppColors.accent : AppColors.primary,
            width: 15,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    });
  }

  Widget _getBottomTitles(double value, TitleMeta meta) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final text = days[value.toInt()];

    return SideTitleWidget(
      space: 4,
      meta: meta,
      child: Text(text, style: const TextStyle(color: AppColors.darkText, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}

// Custom Widget for the Vertical Progress Bar (used in Water Card)
class SimpleAnimationProgressBar extends StatelessWidget {
  final double ratio; // Must be between 0.0 and 1.0
  final Color barColor;

  const SimpleAnimationProgressBar({required this.ratio, required this.barColor, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Use AnimatedContainer for smooth visual transition
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return FractionallySizedBox(
                heightFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [barColor.withOpacity(0.7), barColor],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
          // Water Icon
          Padding(
            padding: const EdgeInsets.only(bottom: 5.0),
            child: Icon(
              Icons.water_drop,
              color: ratio > 0.9 ? AppColors.lightText : barColor.withOpacity(0.5),
              size: 16,
            ),
          )
        ],
      ),
    );
  }
}
