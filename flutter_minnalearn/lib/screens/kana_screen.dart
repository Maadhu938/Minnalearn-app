import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class KanaChar {
  final String kana;
  final String romaji;

  const KanaChar(this.kana, this.romaji);
}

class KanaGroup {
  final String title;
  final String subtitle;
  final List<KanaChar> hiragana;
  final List<KanaChar> katakana;

  const KanaGroup({
    required this.title,
    required this.subtitle,
    required this.hiragana,
    required this.katakana,
  });
}

const _kanaGroups = [
  KanaGroup(
    title: 'Basic',
    subtitle: 'Core gojuon sounds',
    hiragana: [
      KanaChar('あ', 'a'),
      KanaChar('い', 'i'),
      KanaChar('う', 'u'),
      KanaChar('え', 'e'),
      KanaChar('お', 'o'),
      KanaChar('か', 'ka'),
      KanaChar('き', 'ki'),
      KanaChar('く', 'ku'),
      KanaChar('け', 'ke'),
      KanaChar('こ', 'ko'),
      KanaChar('さ', 'sa'),
      KanaChar('し', 'shi'),
      KanaChar('す', 'su'),
      KanaChar('せ', 'se'),
      KanaChar('そ', 'so'),
      KanaChar('た', 'ta'),
      KanaChar('ち', 'chi'),
      KanaChar('つ', 'tsu'),
      KanaChar('て', 'te'),
      KanaChar('と', 'to'),
      KanaChar('な', 'na'),
      KanaChar('に', 'ni'),
      KanaChar('ぬ', 'nu'),
      KanaChar('ね', 'ne'),
      KanaChar('の', 'no'),
      KanaChar('は', 'ha'),
      KanaChar('ひ', 'hi'),
      KanaChar('ふ', 'fu'),
      KanaChar('へ', 'he'),
      KanaChar('ほ', 'ho'),
      KanaChar('ま', 'ma'),
      KanaChar('み', 'mi'),
      KanaChar('む', 'mu'),
      KanaChar('め', 'me'),
      KanaChar('も', 'mo'),
      KanaChar('や', 'ya'),
      KanaChar('ゆ', 'yu'),
      KanaChar('よ', 'yo'),
      KanaChar('ら', 'ra'),
      KanaChar('り', 'ri'),
      KanaChar('る', 'ru'),
      KanaChar('れ', 're'),
      KanaChar('ろ', 'ro'),
      KanaChar('わ', 'wa'),
      KanaChar('を', 'wo'),
      KanaChar('ん', 'n'),
    ],
    katakana: [
      KanaChar('ア', 'a'),
      KanaChar('イ', 'i'),
      KanaChar('ウ', 'u'),
      KanaChar('エ', 'e'),
      KanaChar('オ', 'o'),
      KanaChar('カ', 'ka'),
      KanaChar('キ', 'ki'),
      KanaChar('ク', 'ku'),
      KanaChar('ケ', 'ke'),
      KanaChar('コ', 'ko'),
      KanaChar('サ', 'sa'),
      KanaChar('シ', 'shi'),
      KanaChar('ス', 'su'),
      KanaChar('セ', 'se'),
      KanaChar('ソ', 'so'),
      KanaChar('タ', 'ta'),
      KanaChar('チ', 'chi'),
      KanaChar('ツ', 'tsu'),
      KanaChar('テ', 'te'),
      KanaChar('ト', 'to'),
      KanaChar('ナ', 'na'),
      KanaChar('ニ', 'ni'),
      KanaChar('ヌ', 'nu'),
      KanaChar('ネ', 'ne'),
      KanaChar('ノ', 'no'),
      KanaChar('ハ', 'ha'),
      KanaChar('ヒ', 'hi'),
      KanaChar('フ', 'fu'),
      KanaChar('ヘ', 'he'),
      KanaChar('ホ', 'ho'),
      KanaChar('マ', 'ma'),
      KanaChar('ミ', 'mi'),
      KanaChar('ム', 'mu'),
      KanaChar('メ', 'me'),
      KanaChar('モ', 'mo'),
      KanaChar('ヤ', 'ya'),
      KanaChar('ユ', 'yu'),
      KanaChar('ヨ', 'yo'),
      KanaChar('ラ', 'ra'),
      KanaChar('リ', 'ri'),
      KanaChar('ル', 'ru'),
      KanaChar('レ', 're'),
      KanaChar('ロ', 'ro'),
      KanaChar('ワ', 'wa'),
      KanaChar('ヲ', 'wo'),
      KanaChar('ン', 'n'),
    ],
  ),
  KanaGroup(
    title: 'Dakuten',
    subtitle: 'Voiced and p-sounds',
    hiragana: [
      KanaChar('が', 'ga'),
      KanaChar('ぎ', 'gi'),
      KanaChar('ぐ', 'gu'),
      KanaChar('げ', 'ge'),
      KanaChar('ご', 'go'),
      KanaChar('ざ', 'za'),
      KanaChar('じ', 'ji'),
      KanaChar('ず', 'zu'),
      KanaChar('ぜ', 'ze'),
      KanaChar('ぞ', 'zo'),
      KanaChar('だ', 'da'),
      KanaChar('ぢ', 'ji'),
      KanaChar('づ', 'zu'),
      KanaChar('で', 'de'),
      KanaChar('ど', 'do'),
      KanaChar('ば', 'ba'),
      KanaChar('び', 'bi'),
      KanaChar('ぶ', 'bu'),
      KanaChar('べ', 'be'),
      KanaChar('ぼ', 'bo'),
      KanaChar('ぱ', 'pa'),
      KanaChar('ぴ', 'pi'),
      KanaChar('ぷ', 'pu'),
      KanaChar('ぺ', 'pe'),
      KanaChar('ぽ', 'po'),
    ],
    katakana: [
      KanaChar('ガ', 'ga'),
      KanaChar('ギ', 'gi'),
      KanaChar('グ', 'gu'),
      KanaChar('ゲ', 'ge'),
      KanaChar('ゴ', 'go'),
      KanaChar('ザ', 'za'),
      KanaChar('ジ', 'ji'),
      KanaChar('ズ', 'zu'),
      KanaChar('ゼ', 'ze'),
      KanaChar('ゾ', 'zo'),
      KanaChar('ダ', 'da'),
      KanaChar('ヂ', 'ji'),
      KanaChar('ヅ', 'zu'),
      KanaChar('デ', 'de'),
      KanaChar('ド', 'do'),
      KanaChar('バ', 'ba'),
      KanaChar('ビ', 'bi'),
      KanaChar('ブ', 'bu'),
      KanaChar('ベ', 'be'),
      KanaChar('ボ', 'bo'),
      KanaChar('パ', 'pa'),
      KanaChar('ピ', 'pi'),
      KanaChar('プ', 'pu'),
      KanaChar('ペ', 'pe'),
      KanaChar('ポ', 'po'),
    ],
  ),
  KanaGroup(
    title: 'Combos',
    subtitle: 'Small ya, yu, yo sounds',
    hiragana: [
      KanaChar('きゃ', 'kya'),
      KanaChar('きゅ', 'kyu'),
      KanaChar('きょ', 'kyo'),
      KanaChar('ぎゃ', 'gya'),
      KanaChar('ぎゅ', 'gyu'),
      KanaChar('ぎょ', 'gyo'),
      KanaChar('しゃ', 'sha'),
      KanaChar('しゅ', 'shu'),
      KanaChar('しょ', 'sho'),
      KanaChar('じゃ', 'ja'),
      KanaChar('じゅ', 'ju'),
      KanaChar('じょ', 'jo'),
      KanaChar('ちゃ', 'cha'),
      KanaChar('ちゅ', 'chu'),
      KanaChar('ちょ', 'cho'),
      KanaChar('にゃ', 'nya'),
      KanaChar('にゅ', 'nyu'),
      KanaChar('にょ', 'nyo'),
      KanaChar('ひゃ', 'hya'),
      KanaChar('ひゅ', 'hyu'),
      KanaChar('ひょ', 'hyo'),
      KanaChar('びゃ', 'bya'),
      KanaChar('びゅ', 'byu'),
      KanaChar('びょ', 'byo'),
      KanaChar('ぴゃ', 'pya'),
      KanaChar('ぴゅ', 'pyu'),
      KanaChar('ぴょ', 'pyo'),
      KanaChar('みゃ', 'mya'),
      KanaChar('みゅ', 'myu'),
      KanaChar('みょ', 'myo'),
      KanaChar('りゃ', 'rya'),
      KanaChar('りゅ', 'ryu'),
      KanaChar('りょ', 'ryo'),
    ],
    katakana: [
      KanaChar('キャ', 'kya'),
      KanaChar('キュ', 'kyu'),
      KanaChar('キョ', 'kyo'),
      KanaChar('ギャ', 'gya'),
      KanaChar('ギュ', 'gyu'),
      KanaChar('ギョ', 'gyo'),
      KanaChar('シャ', 'sha'),
      KanaChar('シュ', 'shu'),
      KanaChar('ショ', 'sho'),
      KanaChar('ジャ', 'ja'),
      KanaChar('ジュ', 'ju'),
      KanaChar('ジョ', 'jo'),
      KanaChar('チャ', 'cha'),
      KanaChar('チュ', 'chu'),
      KanaChar('チョ', 'cho'),
      KanaChar('ニャ', 'nya'),
      KanaChar('ニュ', 'nyu'),
      KanaChar('ニョ', 'nyo'),
      KanaChar('ヒャ', 'hya'),
      KanaChar('ヒュ', 'hyu'),
      KanaChar('ヒョ', 'hyo'),
      KanaChar('ビャ', 'bya'),
      KanaChar('ビュ', 'byu'),
      KanaChar('ビョ', 'byo'),
      KanaChar('ピャ', 'pya'),
      KanaChar('ピュ', 'pyu'),
      KanaChar('ピョ', 'pyo'),
      KanaChar('ミャ', 'mya'),
      KanaChar('ミュ', 'myu'),
      KanaChar('ミョ', 'myo'),
      KanaChar('リャ', 'rya'),
      KanaChar('リュ', 'ryu'),
      KanaChar('リョ', 'ryo'),
    ],
  ),
];

class KanaScreen extends StatefulWidget {
  const KanaScreen({Key? key}) : super(key: key);

  @override
  State<KanaScreen> createState() => _KanaScreenState();
}

class _KanaScreenState extends State<KanaScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final FlutterTts _tts;

  int _groupIndex = 0;
  final Set<String> _revealed = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tts = FlutterTts();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ja-JP');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFF472B6),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildKanaPage(isHiragana: true),
                  _buildKanaPage(isHiragana: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF472B6),
            Color(0xFFEC4899),
            Color(0xFFE11D48),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.arrowLeft,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kana Chart',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hiragana, katakana, and sound practice',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.88),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: const Color(0xFFBE185D),
              unselectedLabelColor: Colors.white,
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Hiragana  あ'),
                Tab(text: 'Katakana  ア'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanaPage({required bool isHiragana}) {
    final group = _kanaGroups[_groupIndex];
    final chars = isHiragana ? group.hiragana : group.katakana;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: List.generate(_kanaGroups.length, (index) {
                final g = _kanaGroups[index];
                final isSelected = _groupIndex == index;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == _kanaGroups.length - 1 ? 0 : 8,
                    ),
                    child: GestureDetector(
                      onTap: () => setState(() => _groupIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFEC4899) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFEC4899) : const Color(0xFFE5E7EB),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isSelected ? 0.08 : 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          g.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: isSelected ? Colors.white : const Color(0xFF374151),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            10,
            4,
            10,
            MediaQuery.of(context).padding.bottom + 24,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 640 ? 7 : 4,
              childAspectRatio: 0.85,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildKanaTile(
                  chars[index],
                  keyId: '${isHiragana ? 'h' : 'k'}-$_groupIndex-$index',
                );
              },
              childCount: chars.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKanaTile(KanaChar char, {required String keyId}) {
    final isRevealed = _revealed.contains(keyId);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_revealed.contains(keyId)) {
            _revealed.remove(keyId);
          } else {
            _revealed.add(keyId);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRevealed ? const Color(0xFFF9A8D4) : const Color(0xFFE5E7EB),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEC4899).withOpacity(isRevealed ? 0.12 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    char.kana,
                    style: GoogleFonts.notoSansJp(
                      color: const Color(0xFFBE185D),
                      fontSize: char.kana.length > 1 ? 44 : 52,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: isRevealed ? 1 : 0,
              duration: const Duration(milliseconds: 140),
              child: Text(
                char.romaji,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 34,
              height: 34,
              child: IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: () => _speak(char.kana),
                icon: const Icon(
                  LucideIcons.volume2,
                  color: Color(0xFFF97316),
                  size: 17,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
