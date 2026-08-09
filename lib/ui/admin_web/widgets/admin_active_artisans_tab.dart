import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warisan_kita/ui/tourist/artisan_detail_screen.dart';

class AdminActiveArtisansTab extends StatefulWidget {
  const AdminActiveArtisansTab({super.key});

  @override
  State<AdminActiveArtisansTab> createState() => _AdminActiveArtisansTabState();
}

class _AdminActiveArtisansTabState extends State<AdminActiveArtisansTab> {
  String _searchQuery = '';
  String _selectedCategory = 'All Categories';

  final List<Map<String, dynamic>> _activeArtisans = [
    {
      'id': 'a1',
      'name': 'Pak Mat Pottery Studio',
      'category': 'Pottery & Ceramics',
      'state': 'Melaka',
      'experience': '25+ Years',
      'plaques': 28,
      'isLiveOpen': true,
      'statusText': '🟢 OPEN FOR EDUCATIONAL DEMOS',
      'licenseNo': 'KFG-2024-889',
      'verifiedDate': 'Jan 10, 2024',
      'imageUrl': 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=600&auto=format&fit=crop&q=80',
    },
    {
      'id': 'a2',
      'name': 'Tok Guru Crafts',
      'category': 'Wood Carving',
      'state': 'Kelantan',
      'experience': '30+ Years',
      'plaques': 42,
      'isLiveOpen': false,
      'statusText': '🔴 IN KILN SESSION (DEMOS PAUSED)',
      'licenseNo': 'KFG-2023-112',
      'verifiedDate': 'Mar 15, 2023',
      'imageUrl': 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=600&auto=format&fit=crop&q=80',
    },
    {
      'id': 'a3',
      'name': 'Kak Lina Silk Batik',
      'category': 'Batik Weaving',
      'state': 'Terengganu',
      'experience': '18 Years',
      'plaques': 19,
      'isLiveOpen': true,
      'statusText': '🟢 OPEN FOR EDUCATIONAL DEMOS',
      'licenseNo': 'KFG-2024-405',
      'verifiedDate': 'Feb 20, 2024',
      'imageUrl': 'https://images.unsplash.com/photo-1617038220319-276d3cfab638?w=600&auto=format&fit=crop&q=80',
    },
    {
      'id': 'a4',
      'name': 'Sayong Black Clay Master',
      'category': 'Pottery & Ceramics',
      'state': 'Perak',
      'experience': '22 Years',
      'plaques': 35,
      'isLiveOpen': true,
      'statusText': '🟢 OPEN FOR EDUCATIONAL DEMOS',
      'licenseNo': 'KFG-2023-774',
      'verifiedDate': 'Nov 12, 2023',
      'imageUrl': 'https://images.unsplash.com/photo-1528459801416-a9e53bbf4e17?w=600&auto=format&fit=crop&q=80',
    },
  ];

  List<Map<String, dynamic>> get _filteredArtisans {
    return _activeArtisans.where((artisan) {
      final matchesSearch = _searchQuery.isEmpty ||
          artisan['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          artisan['category'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          artisan['state'].toString().toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'All Categories' ||
          artisan['category'] == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _toggleLiveStatus(String id) {
    setState(() {
      final idx = _activeArtisans.indexWhere((a) => a['id'] == id);
      if (idx != -1) {
        final current = _activeArtisans[idx]['isLiveOpen'] as bool;
        _activeArtisans[idx]['isLiveOpen'] = !current;
        _activeArtisans[idx]['statusText'] = !current
            ? '🟢 OPEN FOR EDUCATIONAL DEMOS'
            : '🔴 IN KILN SESSION (DEMOS PAUSED)';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Updated live studio availability status.'),
        backgroundColor: const Color(0xFF004D40),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewArtisanProfile(Map<String, dynamic> artisan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArtisanDetailScreen(
          artisanName: artisan['name'],
          craftCategory: artisan['category'],
          state: artisan['state'],
          bio: 'Master craftsman preserving heritage ${artisan['category']} in ${artisan['state']}. SSM & Kraftangan Malaysia Verified.',
          rating: 4.9,
          imageUrl: artisan['imageUrl'],
          experience: artisan['experience'],
        ),
      ),
    );
  }

  void _confirmDeactivate(Map<String, dynamic> artisan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            const SizedBox(width: 10),
            Text('Suspend Artisan Master?', style: GoogleFonts.dmSerifDisplay(fontSize: 20)),
          ],
        ),
        content: Text(
          'Are you sure you want to suspend license ${artisan['licenseNo']} (${artisan['name']})? They will be hidden from the tourist marketplace until reactivated.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ),
          FilledButton.icon(
            onPressed: () {
              setState(() {
                _activeArtisans.removeWhere((a) => a['id'] == artisan['id']);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Suspended ${artisan['name']} master license.'),
                  backgroundColor: const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            icon: const Icon(Icons.block_rounded, size: 16),
            label: const Text('Suspend License'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verified Master Artisans Directory',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Monitor and manage verified, licensed heritage craft masters across Malaysia.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_activeArtisans.length} Verified Masters Live',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF047857)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Filters Row (Search + Category)
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search master artisan, license #, or location state...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                    items: const [
                      DropdownMenuItem(value: 'All Categories', child: Text('All Craft Categories')),
                      DropdownMenuItem(value: 'Pottery & Ceramics', child: Text('Pottery & Ceramics')),
                      DropdownMenuItem(value: 'Batik Weaving', child: Text('Batik Weaving')),
                      DropdownMenuItem(value: 'Wood Carving', child: Text('Wood Carving')),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Data Table
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: DataTable(
              headingRowHeight: 52,
              dataRowMaxHeight: 76,
              columns: const [
                DataColumn(label: Text('MASTER ARTISAN & STUDIO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text('CRAFT & STATE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text('LICENSE & PLAQUES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text('STUDIO LIVE STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              ],
              rows: _filteredArtisans.map((artisan) {
                final bool isLiveOpen = artisan['isLiveOpen'] as bool;

                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(artisan['imageUrl']),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                artisan['name'],
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0F172A)),
                              ),
                              Text(
                                '${artisan['experience']} Experience',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(artisan['category'], style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12)),
                          Text('📍 ${artisan['state']}, Malaysia', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('License: ${artisan['licenseNo']}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11, color: const Color(0xFF004D40))),
                          Text('🏅 ${artisan['plaques']} Digital Plaques Issued', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFFD97706), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    DataCell(
                      InkWell(
                        onTap: () => _toggleLiveStatus(artisan['id']),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isLiveOpen ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isLiveOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                          ),
                          child: Text(
                            artisan['statusText'],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isLiveOpen ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _viewArtisanProfile(artisan),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              side: const BorderSide(color: Color(0xFF004D40)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.visibility_rounded, size: 14, color: Color(0xFF004D40)),
                            label: Text(
                              'View Profile',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF004D40),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.block_rounded, color: Color(0xFFEF4444), size: 18),
                            tooltip: 'Suspend Master License',
                            onPressed: () => _confirmDeactivate(artisan),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
