import 'package:flutter/material.dart';

void main() => runApp(const SanctuaryApp());

class SanctuaryApp extends StatelessWidget {
  const SanctuaryApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});
  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const HomeScreen(),
    const TaskCatalogPage(),
    const TheoryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "メイン"),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "家事図鑑"),
          BottomNavigationBarItem(icon: Icon(Icons.auto_graph), label: "継続"),
        ],
      ),
    );
  }
}

// --- 1. メイン画面 ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, bool> areas = {"シンク": true, "床": false, "畳": true, "ソファ": false};
  Map<String, String> alerts = {
    "シンク": "洗い物が置きっぱなしだよ",
    "床": "ロボット掃除機が通れないよ",
    "畳": "掃除機を今すぐかけられないよ",
    "ソファ": "洗濯物が置きっぱなしだよ"
  };

  @override
  void initState() {
    super.initState();
    // 月曜日リセットの確認（起動時に実行）
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkMondayReset());
  }

  void _checkMondayReset() {
    if (DateTime.now().weekday == DateTime.monday) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("月曜日のリセット"),
          content: const Text("新しい一週間が始まりました。溜まっているタスクをどうしますか？"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("繰り越す")),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("一括削除してリセット")),
          ],
        ),
      );
    }
  }

  List<String> _getTasksForDate(DateTime date) {
    List<String> tasks = ["シンクの排水溝"]; // 毎日タスク例
    int wd = date.weekday;
    int day = date.day;

    if (wd == DateTime.wednesday || wd == DateTime.saturday) tasks.add("ゴミ出し（燃えるゴミ）");
    if (wd == DateTime.monday) tasks.add("ゴミ出し（資源ごみ＝プラ・PET・紙）");
    if (wd == DateTime.saturday) tasks.add("大型スーパーへの買い出し（一緒に！）");
    
    // 第2火曜日の判定
    if (wd == DateTime.tuesday && day > 7 && day <= 14) tasks.add("ゴミ出し（不燃ごみ）");

    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime tomorrow = now.add(const Duration(days: 1));
    List<String> todayTasks = _getTasksForDate(now);
    List<String> tomorrowTasks = _getTasksForDate(tomorrow);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F2),
      appBar: AppBar(title: Text("${now.month}/${now.day} Sanctuary Status"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: areas.keys.map((name) {
              bool isGreen = areas[name]!;
              return InkWell(
                onTap: () => setState(() => areas[name] = !isGreen),
                child: Container(
                  decoration: BoxDecoration(
                    color: isGreen ? Colors.teal.shade400 : Colors.red.shade400,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(isGreen ? "CLEAN" : "(${alerts[name]})", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text("今日のミッション", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...todayTasks.map((t) => MissionTile(title: t, isToday: true)),
          const SizedBox(height: 24),
          const Text("明日のミッション", style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.bold)),
          ...tomorrowTasks.map((t) => MissionTile(title: t, isToday: false)),
        ],
      ),
    );
  }
}

// --- 2. 家事図鑑ページ ---
class TaskCatalogPage extends StatefulWidget {
  const TaskCatalogPage({super.key});
  @override
  State<TaskCatalogPage> createState() => _TaskCatalogPageState();
}

class _TaskCatalogPageState extends State<TaskCatalogPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, List<String>> catalog = {
    "週一": [
      "大型スーパーへの買い出し（一緒に！）", "畳部屋の掃除機", "ゴミ出し（燃えるゴミ）", "ゴミ出し（資源ごみ）",
      "シンクの排水溝", "お風呂場の排水溝", "お風呂床の磨き掃除", "洗面台のカビ取り",
      "トイレ掃除（便器磨き・スタンプ・モップ）", "本棚・食器棚のほこり取り", "巾木のほこり取り",
      "植物への水やり", "シーツ交換", "ロボット掃除機タンク掃除", "各デスクの見直し", "スリッパの洗濯"
    ],
    "月一": [
      "ゴミ出し（不燃ごみ）", "換気扇フィルター掃除", "風呂場の徹底掃除", "玄関の掃き掃除",
      "枕・クッションの天日干し", "冷蔵庫内の拭き掃除", "電子レンジ内の拭き掃除",
      "トースター下の拭き掃除", "洗濯機のフィルター掃除", "鏡の拭き掃除"
    ],
    "季節": [
      "エアコンのフィルター掃除", "冷凍庫の棚卸し", "窓と網戸ふき", "ベランダ掃除",
      "クローゼットの棚卸し", "洗面所の棚卸し", "パントリーの棚卸し"
    ]
  };

  void _addNewTask() {
    String newTask = "";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("タスクを追加"),
        content: TextField(onChanged: (v) => newTask = v, decoration: const InputDecoration(hintText: "タスク名を入力")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("キャンセル")),
          TextButton(onPressed: () {
            if (newTask.isNotEmpty) {
              setState(() => catalog.values.elementAt(_tabController.index).add(newTask));
              Navigator.pop(context);
            }
          }, child: const Text("追加")),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("家事図鑑"),
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: "週一"), Tab(text: "月一"), Tab(text: "季節")]),
      ),
      body: TabBarView(
        controller: _tabController,
        children: catalog.keys.map((key) => ListView.builder(
          itemCount: catalog[key]!.length,
          itemBuilder: (context, i) => ListTile(
            leading: const Icon(Icons.bookmark_border, size: 18, color: Colors.teal),
            title: Text(catalog[key]![i], style: const TextStyle(fontSize: 14)),
          ),
        )).toList(),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _addNewTask, child: const Icon(Icons.add)),
    );
  }
}

// --- 3. 継続ページ ---
class TheoryPage extends StatelessWidget {
  const TheoryPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("継続するために")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("なぜ、私たちは怠惰なのか？", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text("〜「サボり癖」を科学的にハックする〜", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const Divider(height: 30),
            const Text("このアプリは、脳のバグを回避し、私たちの自由と心の平和を取り戻すための「外部脳」です。"),
            const SizedBox(height: 20),
            _buildSection("1. 脳は「今」が大好き（双曲割引）", "「未来の快適さ」ではなく「今すぐボタンを緑にする」達成感に注目。"),
            _buildBarGraph(),
            _buildSection("2. 1つの汚れがすべてを壊す（割れ窓理論）", "コップ1個が「ここは汚していい場所だ」という信号を送ります。傷が浅いうちに塞ぐこと。"),
            _buildSection("3. 「考える」だけで疲れる", "次に何をすべきかはアプリが提示します。あなたは何も考えず、ただなぞるだけでいい。"),
            const SizedBox(height: 30),
            const Card(
              color: Colors.teal,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text("家を「聖域」に保つことは、あなたたちの「自由な時間」と「尊厳」を守るための、最も効率的な防衛戦なのです。",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
        const SizedBox(height: 5),
        Text(desc, style: const TextStyle(fontSize: 14)),
      ]),
    );
  }

  Widget _buildBarGraph() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      height: 40,
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Container(width: 70, decoration: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(20)), child: const Center(child: Text("今", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
        const Expanded(child: Center(child: Text("------------ 脳のバグ ------------> 未来", style: TextStyle(fontSize: 10, color: Colors.grey)))),
      ]),
    );
  }
}

class MissionTile extends StatelessWidget {
  final String title;
  final bool isToday;
  const MissionTile({super.key, required this.title, required this.isToday});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: isToday ? Colors.white : Colors.white.withAlpha(120),
      shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        dense: !isToday,
        leading: Icon(isToday ? Icons.check_circle_outline : Icons.circle_outlined, color: isToday ? Colors.teal : Colors.grey),
        title: Text(title, style: TextStyle(color: isToday ? Colors.black87 : Colors.grey, fontSize: isToday ? 15 : 13)),
      ),
    );
  }
}