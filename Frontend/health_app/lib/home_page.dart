import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.userSessionToken,
    required this.username,
  });

  final String userSessionToken;
  final String username;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Match dark theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (BuildContext buildercontext) {
            return IconButton(
              onPressed: () {
                Scaffold.of(buildercontext).openDrawer();
              },
              icon: Icon(Icons.tune, color: Colors.white70),
            );
          },
        ), // Settings icon                       //const Icon(Icons.tune, color: Colors.white70),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.notifications_none, color: Colors.white70),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Section
            Text(
              "Hey $username.",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                decorationColor: Color(0xFF4CB6BD),
                decorationThickness: 2,
              ),
            ),
            const SizedBox(height: 25),

            // 2. Filter Buttons (Daily, Weekly, Monthly)
            Row(
              children: [
                _buildFilterButton("Daily", isActive: true),
                const SizedBox(width: 10),
                _buildFilterButton("Weekly"),
                const SizedBox(width: 10),
                _buildFilterButton("Monthly"),
              ],
            ),
            const SizedBox(height: 25),

            // 3. Large Sleep Analysis Card
            _buildSleepAnalysisCard(),
            const SizedBox(height: 20),

            // 4. Grid of Smaller Metrics
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildMetricCard(
                    title: "More Self love & Fulfilment",
                    color: const Color(0xFF2C4C4D),
                    imagePath:
                        'assets/meditation.png', // Replace with your assets
                  ),
                  _buildMetricCard(
                    title: "1698kcal",
                    subtitle: "Consumed",
                    color: const Color(0xFF2C4C4D),
                    imagePath: 'assets/food.png',
                  ),
                  _buildMetricCard(
                    title: "80bpm",
                    subtitle: "Avg Heart rate",
                    color: const Color(0xFF2C4C4D),
                    imagePath: 'assets/heart.png',
                  ),
                  _buildMetricCard(
                    title: "350kcal",
                    subtitle: "Burned",
                    color: const Color(0xFF2C4C4D),
                    imagePath: 'assets/burn.png',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(),
    );
  }

  // --- UI Helper Methods (Like React Sub-components) ---

  Widget _buildFilterButton(String label, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2C4C4D) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: TextStyle(color: isActive ? Colors.white : Colors.white70),
      ),
    );
  }

  Widget _buildSleepAnalysisCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C4C4D),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "Sleep Analysis",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Circular Progress (React: Recharts or similar)
              Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: 0.804,
                      strokeWidth: 8,
                      backgroundColor: Colors.white10,
                      color: Color(0xFF4CB6BD),
                    ),
                  ),
                  Column(
                    children: const [
                      Text(
                        "Quality",
                        style: TextStyle(color: Colors.white60, fontSize: 10),
                      ),
                      Text(
                        "80.4 %",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "7h 30m",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Sleep Duration",
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "↗ Slightly better than yesterday",
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    String? subtitle,
    required Color color,
    required String imagePath,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          const Spacer(),
          // In a real app, you'd use Image.asset(imagePath)
          Center(
            child: Image.asset(
              imagePath,
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
