import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtisanTaskManagementScreen extends StatefulWidget {
  const ArtisanTaskManagementScreen({super.key});

  @override
  State<ArtisanTaskManagementScreen> createState() => _ArtisanTaskManagementScreenState();
}

class _ArtisanTaskManagementScreenState extends State<ArtisanTaskManagementScreen> {
  // Task Queue with Default 2 Tasks initialized on profile creation
  final List<Map<String, dynamic>> _tasks = [
    {
      'id': 'gt_def1',
      'title': 'Arrive at the Workshop',
      'type': 'REQUIRED',
      'category': '📍 Location Geofence',
      'points': 150,
      'workshop': 'Pak Mat Pottery Studio (Melaka)',
      'status': 'APPROVED',
      'isDefault': true,
      'description': 'Arrive within 50m of workshop studio coordinates.',
    },
    {
      'id': 'gt_def2',
      'title': 'Stay for 15 Minutes',
      'type': 'REQUIRED',
      'category': '⏱️ Session Duration',
      'points': 200,
      'workshop': 'Pak Mat Pottery Studio (Melaka)',
      'status': 'APPROVED',
      'isDefault': true,
      'description': 'Engage in workshop session for at least 15 minutes.',
    },
    {
      'id': 'gt1',
      'title': 'Try Hand-Molding Clay on Spinning Wheel',
      'type': 'REQUIRED',
      'category': '🎨 Hands-on Crafting',
      'points': 500,
      'workshop': 'Pak Mat Pottery Studio (Melaka)',
      'status': 'APPROVED',
      'isDefault': false,
      'description': 'Hand-spin miniature labu sayong under master artisan guidance.',
    },
    {
      'id': 'gt2',
      'title': 'Draw Canting Wax on Silk Fabric',
      'type': 'OPTIONAL',
      'category': '🎨 Hands-on Crafting',
      'points': 450,
      'workshop': 'Pak Mat Pottery Studio (Melaka)',
      'status': 'PENDING_APPROVAL',
      'isDefault': false,
      'description': 'Apply natural canting wax motifs onto unbleached silk.',
    },
  ];

  void _openCreateTaskModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => const CreateGamificationTaskDialog(),
    ).then((newTask) {
      if (newTask != null && newTask is Map<String, dynamic>) {
        setState(() {
          _tasks.insert(0, newTask);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Gamification Quest Manager',
          style: GoogleFonts.dmSerifDisplay(color: const Color(0xFF004D40), fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF004D40)),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateTaskModal,
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'CREATE CUSTOM QUEST',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Banner explaining Default Tasks & Fully Customizable Quests
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Color(0xFFD97706), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Default Workshop Quests Active',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF78350F),
                        ),
                      ),
                      Text(
                        'Every artisan profile auto-initializes "Arrive at Workshop" & "Stay 15 Mins". You can fully customize new quests or choose from pre-set library templates (requires Admin Approval).',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Active & Pending Quests (${_tasks.length})',
            style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFF004D40)),
          ),

          const SizedBox(height: 12),

          ..._tasks.map((task) => _buildTaskCard(task)),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final bool isDefault = task['isDefault'] ?? false;
    final String status = task['status'];
    final bool isApproved = status == 'APPROVED';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDefault ? const Color(0xFF004D40).withOpacity(0.3) : Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDefault ? const Color(0xFF004D40).withOpacity(0.12) : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task['category'],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDefault ? const Color(0xFF004D40) : const Color(0xFF0284C7),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isApproved ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isApproved ? 'LIVE & APPROVED' : 'PENDING ADMIN APPROVAL',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isApproved ? const Color(0xFF047857) : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            task['title'],
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),

          if (task['description'] != null) ...[
            const SizedBox(height: 4),
            Text(
              task['description'],
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '+${task['points']} EXP Reward',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFD97706)),
                  ),
                ],
              ),
              if (isDefault)
                Text(
                  '🔒 Mandatory Step',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class CreateGamificationTaskDialog extends StatefulWidget {
  const CreateGamificationTaskDialog({super.key});

  @override
  State<CreateGamificationTaskDialog> createState() => _CreateGamificationTaskDialogState();
}

class _CreateGamificationTaskDialogState extends State<CreateGamificationTaskDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Custom Quest Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController(text: '350');
  String _selectedCategory = '🎨 Hands-on Crafting';
  String _taskType = 'REQUIRED';

  final List<String> _categories = const [
    '🎨 Hands-on Crafting',
    '📍 Location Geofence',
    '⏱️ Session Duration',
    '📸 Photo & Media Tagging',
    '💬 Oral Lore & Q&A',
  ];

  // Pre-defined Templates Library
  final List<Map<String, dynamic>> _libraryTemplates = const [
    {
      'title': 'Try Hand-Molding Clay on Spinning Wheel',
      'category': '🎨 Hands-on Crafting',
      'points': 500,
      'description': 'Hand-spin miniature labu sayong under master artisan guidance.',
    },
    {
      'title': 'Draw Canting Wax on Silk Fabric',
      'category': '🎨 Hands-on Crafting',
      'points': 450,
      'description': 'Apply natural canting wax motifs onto unbleached silk.',
    },
    {
      'title': 'Identify 3 Heritage Clay Types',
      'category': '💬 Oral Lore & Q&A',
      'points': 300,
      'description': 'Listen to Pak Mat explain clay firing differences in Melaka.',
    },
    {
      'title': 'Take a Photo with Master Artisan',
      'category': '📸 Photo & Media Tagging',
      'points': 250,
      'description': 'Capture a memorable photo with master craftsman at studio.',
    },
  ];

  Map<String, dynamic>? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _submitCustomQuest() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final points = int.tryParse(_pointsController.text.trim()) ?? 350;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a Quest Title.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    _finishSubmission(title: title, category: _selectedCategory, points: points, description: description.isEmpty ? 'Custom master artisan quest.' : description);
  }

  void _submitTemplateQuest() {
    if (_selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a template from the library.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    _finishSubmission(
      title: _selectedTemplate!['title'],
      category: _selectedTemplate!['category'],
      points: _selectedTemplate!['points'],
      description: _selectedTemplate!['description'],
    );
  }

  void _finishSubmission({
    required String title,
    required String category,
    required int points,
    required String description,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Quest "$title" submitted to Admin Approval Queue!',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF004D40),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pop({
      'id': 'gt_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'type': _taskType,
      'category': category,
      'points': points,
      'workshop': 'Pak Mat Pottery Studio (Melaka)',
      'status': 'PENDING_APPROVAL',
      'isDefault': false,
      'description': description,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Create Workshop Quest',
                style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFF004D40)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Text(
            'Fully customize your own quest or select a pre-made template.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // Tab Bar Switcher
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF004D40),
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF1E293B),
              labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
              tabs: const [
                Tab(text: '✍️ Custom Builder'),
                Tab(text: '📚 Template Library'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: FULLY CUSTOMIZABLE QUEST BUILDER
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quest Title', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'e.g., Mold Traditional Labu Sayong Neck & Body',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text('Category', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        items: _categories.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat, style: GoogleFonts.plusJakartaSans(fontSize: 13)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('EXP Reward Points', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _pointsController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    suffixText: 'EXP',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Quest Requirement', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: _taskType,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'REQUIRED', child: Text('REQUIRED')),
                                    DropdownMenuItem(value: 'OPTIONAL', child: Text('OPTIONAL')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _taskType = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Text('Instructions / Heritage Lore Description', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Explain how tourists complete this quest and what heritage lore they will learn...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _submitCustomQuest,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF004D40),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.check_circle_rounded, size: 20),
                          label: const Text('SUBMIT CUSTOM QUEST FOR APPROVAL', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),

                // TAB 2: PRE-SET TEMPLATE LIBRARY
                Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _libraryTemplates.length,
                        itemBuilder: (context, index) {
                          final template = _libraryTemplates[index];
                          final bool isSelected = _selectedTemplate?['title'] == template['title'];

                          return GestureDetector(
                            onTap: () => setState(() => _selectedTemplate = template),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF004D40).withOpacity(0.08) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF004D40) : Colors.black.withOpacity(0.06),
                                  width: isSelected ? 1.8 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                    color: isSelected ? const Color(0xFF004D40) : Colors.grey,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          template['title'],
                                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                        ),
                                        Text(
                                          template['description'],
                                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '+${template['points']} EXP',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFB45309)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _submitTemplateQuest,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF004D40),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 20),
                        label: const Text('SUBMIT TEMPLATE QUEST FOR APPROVAL', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
