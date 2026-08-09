import 'package:flutter/material.dart';

class LanguageViewModel extends ChangeNotifier {
  String _currentLanguageCode = 'EN';
  String _currentLanguageName = 'English (United States)';

  String get currentLanguageCode => _currentLanguageCode;
  String get currentLanguageName => _currentLanguageName;

  final Map<String, Map<String, String>> _translations = {
    'EN': {
      // Navigation & Scaffolds
      'nav_explore': 'Explore',
      'nav_passport': 'Passport',
      'nav_forum': 'Forum',
      'nav_matchmaker': 'Matchmaker',
      'nav_settings': 'Settings',

      // Headers & Titles
      'app_title': 'WarisanKita',
      'discover_heritage': 'Explore Living Heritage',
      'search_placeholder': 'Search master artisans, craft styles, or cities...',
      'all_crafts': 'All Crafts',
      'clay_pottery': 'Clay Pottery & Ceramics',
      'batik_wax': 'Batik Wax Painting',
      'songket_weaving': 'Songket Gold Weaving',
      'woodcarving': 'Traditional Woodcarving',
      'craft_mastery_tree': 'Craft Mastery Skill Tree',
      'passport_stamps': 'Heritage Passport Seals',
      'view_profile': 'View Artisan Profile',
      'start_quest': 'START QUEST',
      'audio_story_lore': 'Audio Story Lore Player',
      'master_artisan_bio': 'Master Artisan Biography & Heritage',
      'accreditation': 'Kraftangan Malaysia Accreditation',
      'materials_used': 'Authentic Materials & Tools',
      'quest_completion': 'Quest Verification & EXP Rewards',
      'settings_title': 'Settings & Account',
      'select_language': 'App Language & Translation',
      'dark_theme': 'Dark Theme Mode',
      'push_notifications': 'Push Notifications',
      'geofence_alerts': 'Geofence Radar Alerts',
      'logout': 'Log Out',
      'edit_profile': 'Edit Profile',
      'change_password': 'Change Password',

      // Artisan Profile & Details
      'pak_mat_name': 'Pak Mat Pottery Studio',
      'pak_mat_bio': 'Master Pak Mat has been hand-crafting traditional clay labu sayong and ceramic vessels for over 25 years in Kampung Morten.',
      'siti_batik_name': 'Siti Batik Craft Workshop',
      'siti_batik_bio': 'Hand-drawn canting batik studio utilizing organic natural dyes and silk fabrics in coastal Terengganu.',
      'wan_songket_name': 'Wan Songket Heritage Weavers',
      'wan_songket_bio': 'Royal songket weaving utilizing metallic gold and silver threads on handloom wooden apparatus in Kota Bharu.',
      'wong_woodcraft_name': 'Master Wong Woodcraft',
      'wong_woodcraft_bio': 'Ornate timber carving specializing in traditional Malay architectural wood panels and keris handles in Perak.',

      // Skill Tree Nodes
      'novice_spinning': 'Novice Clay Spinning',
      'kiln_firing': 'Kiln Temperature Firing',
      'master_sayong': 'Master Sayong Glazing',
      'canting_motif': 'Intricate Canting Motif',
      'dye_fixation': 'Natural Dye Fixation',
      'silk_batik_master': 'Master Silk Batik Artist',

      // Quests & Passport
      'quest_completed_title': 'QUEST COMPLETED!',
      'congratulations': 'CONGRATULATIONS!',
      'exp_earned': 'EXP Earned',
      'claim_reward': 'CLAIM REWARD & STAMP PASSPORT',
      'verified_by_artisan': 'Verified by Master Artisan',

      // Master Artisan Portal
      'artisan_portal_title': 'Master Artisan Command Center',
      'preservation_metrics': 'Heritage Preservation Metrics',
      'craft_hours_preserved': 'Craft Hours Preserved',
      'students_taught': 'Students & Tourists Taught',
      'studio_status_open': '🟢 OPEN FOR EDUCATIONAL DEMOS',
      'studio_status_closed': '🔴 IN KILN SESSION (DEMOS PAUSED)',
      'manage_quests': 'Manage Quests',
      'craft_portfolio': 'Craft Portfolio',
      'live_forum_tab': 'Live Forum',
    },
    'BM': {
      // Navigation & Scaffolds
      'nav_explore': 'Terokai',
      'nav_passport': 'Pasport',
      'nav_forum': 'Forum',
      'nav_matchmaker': 'Padanan',
      'nav_settings': 'Tetapan',

      // Headers & Titles
      'app_title': 'WarisanKita',
      'discover_heritage': 'Terokai Warisan Hidup',
      'search_placeholder': 'Cari adiguru kraf, gaya seni, atau bandar...',
      'all_crafts': 'Semua Kraf',
      'clay_pottery': 'Seramik & Labu Sayong',
      'batik_wax': 'Batik Lukis Canting',
      'songket_weaving': 'Tenunan Songket Benang Emas',
      'woodcarving': 'Seni Ukiran Kayu Tradisional',
      'craft_mastery_tree': 'Pohon Penguasaan Kraf Warisan',
      'passport_stamps': 'Koleksi Cap Pasport Warisan',
      'view_profile': 'Lihat Profil Adiguru',
      'start_quest': 'MULA CABARAN',
      'audio_story_lore': 'Pemain Penceritaan Lore Audio',
      'master_artisan_bio': 'Biografi & Sejarah Adiguru Warisan',
      'accreditation': 'Akreditasi Kraftangan Malaysia',
      'materials_used': 'Bahan & Peralatan Asli Warisan',
      'quest_completion': 'Pengesahan Cabaran & Ganjaran EXP',
      'settings_title': 'Tetapan & Akaun',
      'select_language': 'Bahasa Aplikasi & Terjemahan',
      'dark_theme': 'Mod Tema Gelap',
      'push_notifications': 'Pemberitahuan Tolak',
      'geofence_alerts': 'Amaran Radar Geofens',
      'logout': 'Log Keluar',
      'edit_profile': 'Sunting Profil',
      'change_password': 'Tukar Kata Laluan',

      // Artisan Profile & Details
      'pak_mat_name': 'Studio Seramik Pak Mat',
      'pak_mat_bio': 'Adiguru Pak Mat berpengalaman lebih 25 tahun menghasilkan labu sayong dan seramik buatan tangan di Kampung Morten.',
      'siti_batik_name': 'Bengkel Kraf Batik Siti',
      'siti_batik_bio': 'Studio batik canting buatan tangan menggunakan pewarna semula jadi organik dan kain sutera di Terengganu.',
      'wan_songket_name': 'Tenunan Warisan Songket Wan',
      'wan_songket_bio': 'Tenunan songket diraja menggunakan benang emas dan perak pada alat tenun kayu di Kota Bharu.',
      'wong_woodcraft_name': 'Seni Ukir Kayu Master Wong',
      'wong_woodcraft_bio': 'Ukiran kayu halus khusus untuk panel seni bina Melayu tradisional dan hulu keris di Perak.',

      // Skill Tree Nodes
      'novice_spinning': 'Putaran Tanah Liat Asas',
      'kiln_firing': 'Pembakaran Relau Suhu Tinggi',
      'master_sayong': 'Pengilapan Labu Sayong Utama',
      'canting_motif': 'Lukisan Motif Canting Halus',
      'dye_fixation': 'Penetapan Pewarna Semula Jadi',
      'silk_batik_master': 'Adiguru Batik Sutera',

      // Quests & Passport
      'quest_completed_title': 'CABARAN SELESAI!',
      'congratulations': 'TAHNIAH!',
      'exp_earned': 'EXP Diperolehi',
      'claim_reward': 'TUNTUT GANJARAN & CAP PASPORT',
      'verified_by_artisan': 'Disahkan oleh Adiguru Kraf',

      // Master Artisan Portal
      'artisan_portal_title': 'Pusat Kawalan Adiguru Kraf',
      'preservation_metrics': 'Metrik Pemeliharaan Warisan',
      'craft_hours_preserved': 'Jam Kraf Dipelihara',
      'students_taught': 'Pelajar & Pelancong Diajar',
      'studio_status_open': '🟢 DIBUKA UNTUK DEMO PENDIDIKAN',
      'studio_status_closed': '🔴 SESI RELAU (DEMO DIBERHENTIKAN)',
      'manage_quests': 'Urus Cabaran',
      'craft_portfolio': 'Portfolio Kraf',
      'live_forum_tab': 'Forum Komuniti',
    },
    'ZH': {
      // Navigation & Scaffolds
      'nav_explore': '探索',
      'nav_passport': '护照',
      'nav_forum': '论坛',
      'nav_matchmaker': '智能匹配',
      'nav_settings': '设置',

      // Headers & Titles
      'app_title': 'WarisanKita 传统遗产',
      'discover_heritage': '探索传统手艺遗产',
      'search_placeholder': '搜索手艺大师、艺术分类或城市...',
      'all_crafts': '全部手艺',
      'clay_pottery': 'Sayong陶艺与陶瓷',
      'batik_wax': '蜡染印花画艺术',
      'songket_weaving': '宋吉金线手织',
      'woodcarving': '马来传统木雕',
      'craft_mastery_tree': '文化手艺技能树',
      'passport_stamps': '文化护照印章收集',
      'view_profile': '查看大师档案',
      'start_quest': '开启文化探索',
      'audio_story_lore': '口述历史音频播放器',
      'master_artisan_bio': '手艺大师传记与历史传承',
      'accreditation': '马来西亚国家手工艺品认证',
      'materials_used': '正统天然原料与工具',
      'quest_completion': '任务验证与EXP经验奖励',
      'settings_title': '设置与账户',
      'select_language': '应用语言与翻译',
      'dark_theme': '深色夜间模式',
      'push_notifications': '推送通知提醒',
      'geofence_alerts': '地理围栏雷达提醒',
      'logout': '退出登录',
      'edit_profile': '编辑个人资料',
      'change_password': '重置登录密码',

      // Artisan Profile & Details
      'pak_mat_name': 'Pak Mat陶艺工坊',
      'pak_mat_bio': 'Pak Mat大师在Melaka Morten村专注于手作马来Sayong黑陶容器已有超过25年历史。',
      'siti_batik_name': 'Siti蜡染艺术工坊',
      'siti_batik_bio': '位于丁加奴海岸的高级手绘canting蜡染工坊，采用天然有机染料与纯丝绸。',
      'wan_songket_name': 'Wan宋吉织锦传承馆',
      'wan_songket_bio': '位于哥打巴鲁的皇室宋吉织工，采用传统木制织布机金银线手工编制。',
      'wong_woodcraft_name': 'Wong大师木雕工坊',
      'wong_woodcraft_bio': '精美木雕大师，专门雕刻马来传统建筑木雕面板与短剑柄。',

      // Skill Tree Nodes
      'novice_spinning': '初级拉坯手作',
      'kiln_firing': '高温柴窑烧制',
      'master_sayong': 'Sayong上釉大师',
      'canting_motif': 'Canting精细蜡绘',
      'dye_fixation': '天然染料固色',
      'silk_batik_master': '丝绸蜡染大师',

      // Quests & Passport
      'quest_completed_title': '文化探索任务完成！',
      'congratulations': '恭喜您！',
      'exp_earned': '获得EXP经验值',
      'claim_reward': '领取奖励并盖章护照',
      'verified_by_artisan': '已由手艺大师亲自验证',

      // Master Artisan Portal
      'artisan_portal_title': '手艺大师控制中心',
      'preservation_metrics': '文化遗产保存指标',
      'craft_hours_preserved': '累计保存手艺学时',
      'students_taught': '累计指导学员与游客',
      'studio_status_open': '🟢 开放文化演示体验',
      'studio_status_closed': '🔴 烧窑制作中（暂停演示）',
      'manage_quests': '管理探索任务',
      'craft_portfolio': '作品展示集',
      'live_forum_tab': '实时社区论坛',
    },
    'JA': {
      // Navigation & Scaffolds
      'nav_explore': '探求',
      'nav_passport': 'パスポート',
      'nav_forum': 'フォーラム',
      'nav_matchmaker': 'マッチメイカー',
      'nav_settings': '設定',

      // Headers & Titles
      'app_title': 'WarisanKita 伝統工芸',
      'discover_heritage': '生きた伝統遺産を探求',
      'search_placeholder': '工芸マスター、技術、都市を検索...',
      'all_crafts': '全工芸',
      'clay_pottery': 'サヨン陶芸・セラミック',
      'batik_wax': 'バティックろうけつ染め',
      'songket_weaving': 'ソンケット金線織物',
      'woodcarving': '伝統木彫彫刻',
      'craft_mastery_tree': '伝統工芸スキルツリー',
      'passport_stamps': 'ヘリテージスタンプコレクション',
      'view_profile': 'マスターのプロフィールを見る',
      'start_quest': 'クエストを開始',
      'audio_story_lore': '口述歴史オーディオプレーヤー',
      'master_artisan_bio': '伝統工芸マスターの伝承と経歴',
      'accreditation': 'マレーシア政府伝統工芸認定',
      'materials_used': '本物の天然素材と工具',
      'quest_completion': 'クエスト検証とEXP報酬',
      'settings_title': '設定とアカウント',
      'select_language': 'アプリ言語設定・翻訳',
      'dark_theme': 'ダークテーマモード',
      'push_notifications': 'プッシュ通知',
      'geofence_alerts': 'ジオフェンスレーダーアラート',
      'logout': 'ログアウト',
      'edit_profile': 'プロフィール編集',
      'change_password': 'パスワード変更',

      // Artisan Profile & Details
      'pak_mat_name': 'パク・マット陶芸工房',
      'pak_mat_bio': 'マスターのパク・マット氏はカンポン・モルテンで25年以上にわたり伝統的なサヨン黒陶器を手作っています。',
      'siti_batik_name': 'シティ・バティック工房',
      'siti_batik_bio': 'トレンガヌ沿岸にある手描きチャンティン・バティック工房。有機天然染料とシルク生地を使用。',
      'wan_songket_name': 'ワン・ソンケット伝統織物',
      'wan_songket_bio': 'コタバルにある伝統的な木製織機で金銀線を使用した王室ソンケット織物。',
      'wong_woodcraft_name': 'マスター・ウォン木工芸',
      'wong_woodcraft_bio': '伝統的なマレー建築の彫刻パネルやクリス短剣の柄を専門とする精巧な木彫り。',

      // Skill Tree Nodes
      'novice_spinning': '初級ろくろ成形',
      'kiln_firing': '高温窯焼き成形',
      'master_sayong': 'サヨン施釉マスター',
      'canting_motif': 'チャンティン繊細描画',
      'dye_fixation': '天然染料色揚げ',
      'silk_batik_master': 'シルクバティック巨匠',

      // Quests & Passport
      'quest_completed_title': 'クエスト達成！',
      'congratulations': 'おめでとうございます！',
      'exp_earned': '獲得EXP点数',
      'claim_reward': '報酬を受け取りスタンプを押す',
      'verified_by_artisan': '伝統工芸マスター認定済み',

      // Master Artisan Portal
      'artisan_portal_title': '伝統工芸マスターコントロールセンター',
      'preservation_metrics': '文化遺産保存指標',
      'craft_hours_preserved': '保存工芸時間',
      'students_taught': '指導した生徒・観光客数',
      'studio_status_open': '🟢 実演見学受付中',
      'studio_status_closed': '🔴 窯焼き作業中（見学休止）',
      'manage_quests': 'クエスト管理',
      'craft_portfolio': '作品ポートフォリオ',
      'live_forum_tab': 'ライブフォーラム',
    },
  };

  void setLanguage(String code, String name) {
    _currentLanguageCode = code;
    _currentLanguageName = name;
    notifyListeners();
  }

  String translate(String key) {
    return _translations[_currentLanguageCode]?[key] ?? _translations['EN']?[key] ?? key;
  }
}
