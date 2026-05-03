import '../domain/word_book.dart';
import '../domain/word_book_repository.dart';
import '../domain/word_entry.dart';

class InMemoryWordBookRepository implements WordBookRepository {
  const InMemoryWordBookRepository({
    List<WordBook>? importedWordBooks,
  }) : _importedWordBooks = importedWordBooks;

  static final List<WordBook> _sharedImportedWordBooks = [];

  final List<WordBook>? _importedWordBooks;

  List<WordBook> get _activeImportedWordBooks {
    return _importedWordBooks ?? _sharedImportedWordBooks;
  }

  @override
  List<WordBook> loadWordBooks() {
    return [
      ...loadBuiltInWordBooks(),
      ..._activeImportedWordBooks,
    ];
  }

  @override
  List<WordBook> loadBuiltInWordBooks() {
    return [
      WordBook(
        id: 'primary-basic',
        name: '小学高年级基础词表',
        stageLabel: '小学高年级词表',
        isBuiltIn: true,
        words: _words('primary-basic', 6),
      ),
      WordBook(
        id: 'beijing-primary-grade-3',
        name: '北京版英语三年级词表',
        stageLabel: '小学三年级词表',
        description: '北京出版社北京版（新）三年级上下册 Word List 词库',
        isBuiltIn: true,
        words: _beijingEditionGrade3Words(),
      ),
      WordBook(
        id: 'middle-core',
        name: '初中核心词表',
        stageLabel: '初中词表',
        isBuiltIn: true,
        words: _words('middle-core', 6),
      ),
      WordBook(
        id: 'high-core',
        name: '高中核心词表',
        stageLabel: '高中核心词表',
        isBuiltIn: true,
        words: _words('high-core', 6),
      ),
    ];
  }

  @override
  List<WordBook> loadImportedWordBooks() {
    return List<WordBook>.of(_activeImportedWordBooks);
  }

  @override
  void saveImportedWordBook(WordBook wordBook) {
    _activeImportedWordBooks.removeWhere((book) => book.id == wordBook.id);
    _activeImportedWordBooks.add(wordBook);
  }

  @override
  void replaceImportedWordBooks(List<WordBook> wordBooks) {
    _activeImportedWordBooks
      ..clear()
      ..addAll(wordBooks);
  }

  List<WordEntry> _words(String prefix, int count) {
    const demoWords = [
      WordEntry(id: 'library', spelling: 'library', meanings: ['图书馆']),
      WordEntry(id: 'neighbor', spelling: 'neighbor', meanings: ['邻居']),
      WordEntry(id: 'through', spelling: 'through', meanings: ['穿过']),
    ];
    final generatedWords = List.generate(
      count - demoWords.length,
      (index) {
        final displayIndex = index + demoWords.length;
        return WordEntry(
          id: '$prefix-$displayIndex',
          spelling: '$prefix-$displayIndex',
          meanings: ['释义 $displayIndex'],
        );
      },
    );

    return [
      ...demoWords,
      ...generatedWords,
    ];
  }

  List<WordEntry> _beijingEditionGrade3Words() {
    return [
      for (final (index, row) in _beijingEditionGrade3WordRows.indexed)
        _beijingEditionGrade3Word(index, row),
    ];
  }

  WordEntry _beijingEditionGrade3Word(int index, String row) {
    final columns = row.split('|');
    final termTags = columns[2].split('/');
    return WordEntry(
      id: 'beijing-primary-grade-3-${index + 1}',
      spelling: columns[0],
      meanings: [columns[1]],
      tags: ['北京版', '三年级', ...termTags],
      source: '北京出版社北京版（新）三年级英语 Word List',
    );
  }
}

const _beijingEditionGrade3WordRows = [
  "hello|你好（问候语）|三上",
  "hi|你好（问候语）|三上",
  "what|什么|三上",
  "your|你的；你们的|三上",
  "name|名字|三上",
  "nice|令人愉快的，令人高兴的|三上",
  "meet|见到，看到|三上",
  "from|来自，从……来|三上",
  "you|你；你们（主格或宾格）|三上",
  "this|这，这个|三上",
  "he|他（主格）|三上",
  "good|好的|三上",
  "morning|早晨，上午|三上",
  "Miss|小姐，女士，年轻未婚女士|三上",
  "how|多么；多少；如何|三上",
  "fine|好的；令人愉快的|三上",
  "afternoon|下午|三上",
  "Mr|先生|三上",
  "friend|朋友|三上",
  "help|帮助|三上",
  "evening|傍晚|三上",
  "night|夜晚|三上",
  "new|新的|三上",
  "many|许多；许多的|三上",
  "class|课|三上",
  "one|一|三上",
  "two|二|三上",
  "three|三|三上",
  "six|六|三上",
  "pencil|铅笔|三上",
  "old|年老的；古老的|三上",
  "seven|七|三上",
  "eight|八|三上",
  "nine|九|三上",
  "yes|是；同意|三上",
  "sit|坐|三上",
  "four|四|三上",
  "five|五|三上",
  "there|在那里，在那边|三上",
  "basketball|篮球|三上",
  "ten|十|三上",
  "eleven|十一|三上",
  "twelve|十二|三上",
  "star|星星|三上",
  "thirteen|十三|三上",
  "fourteen|十四|三上",
  "great|非凡的，绝妙的，了不起的|三上",
  "fifteen|十五|三上",
  "panda|熊猫|三上",
  "family|家庭|三上",
  "duck|鸭子|三上",
  "hen|母鸡|三上",
  "cow|奶牛|三上",
  "horse|马|三上",
  "sheep|绵羊（复数 sheep）|三上",
  "cute|可爱的|三上",
  "that|那，那个|三上",
  "big|大的|三上",
  "elephant|大象|三上",
  "ear|耳朵|三上",
  "long|长的|三上",
  "nose|鼻子|三上",
  "lion|狮子|三上",
  "tiger|老虎|三上",
  "cat|猫|三上",
  "a|一（个）；每一（个）|三上",
  "an|一（个）；每一（个）|三上",
  "bird|鸟|三上",
  "take care of|照顾|三上",
  "pet|宠物|三上",
  "tail|尾巴|三上",
  "beautiful|漂亮的|三上",
  "goodbye|再见|三上",
  "tall|高的|三上",
  "neck|脖子|三上",
  "arm|手臂，胳膊|三上",
  "wing|翅膀|三上",
  "school|学校|三上",
  "show|演出；展出；显示|三上",
  "can|可以；能够|三上",
  "do|做，干；从事|三上",
  "dance|舞蹈；跳舞|三上",
  "play|参加（体育运动或比赛）；演奏（乐器等）；玩耍|三上",
  "piano|钢琴|三上",
  "sing|唱（歌）|三上",
  "we|我们（主格）|三上",
  "ping-pong|乒乓球|三上",
  "let|让；使|三上",
  "jump|跳跃|三上",
  "rope|绳，绳索|三上",
  "no|不；没有；不是|三上",
  "easy|容易的|三上",
  "child|儿童（复数 children）|三上",
  "our|我们的|三上",
  "clean|清理干净|三上",
  "put|放；移动；安置|三上",
  "sweep|打扫|三上",
  "and|和，与|三上",
  "aunt|舅母；婶母；姨母；姑母|三上",
  "bear|熊|三上",
  "bed|床|三上",
  "bee|蜜蜂|三上",
  "black|黑色；黑色的|三上",
  "blackboard|黑板|三上",
  "blue|蓝色；蓝色的|三上",
  "book|书|三上",
  "boy|男孩|三上",
  "brother|兄弟|三上",
  "brown|棕色；棕色的|三上",
  "butterfly|蝴蝶|三上",
  "colour|颜色|三上",
  "cook|厨师|三上",
  "cousin|堂（表）兄弟；堂（表）姐妹|三上",
  "dad|爸爸（father）|三上",
  "dish|盘，碟|三上",
  "doctor|医生|三上",
  "driver|司机，驾驶员|三上",
  "everywhere|处处，到处|三上",
  "eye|眼睛|三上",
  "floor|层；地板|三上",
  "flower|花|三上",
  "girl|女孩|三上",
  "grape|葡萄|三上",
  "green|绿色；绿色的|三上",
  "hair|头发|三上",
  "indigo|靛蓝色；靛蓝色的|三上",
  "kind|和蔼的|三上",
  "like|喜欢；想|三上",
  "look|看|三上",
  "love|爱|三上",
  "magic|魔法；不可思议的；有魔力的|三上",
  "make|做，制作|三上",
  "man|男人；人|三上",
  "me|我（宾格）|三上",
  "mix|使混合；配置|三上",
  "mum|妈妈（mother 美式 mom）|三上",
  "where|哪里；在哪里|三下",
  "in|在……内，在……中|三下",
  "box|盒子，箱子|三下",
  "cap|帽子|三下",
  "on|在……上|三下",
  "next to|旁边，在……近旁|三下",
  "schoolbag|书包|三下",
  "ruler|尺子|三下",
  "the|指已提到或正在谈到的人或物|三下",
  "my|我的|三下",
  "under|在……之下|三下",
  "English|英文的；英语|三下",
  "desk|书桌|三下",
  "clothes|衣服，衣物|三下",
  "in order|整齐；秩序井然|三下",
  "these|这些|三下",
  "trousers|裤子，长裤|三下",
  "sock|短袜|三下",
  "shorts|短裤|三下",
  "behind|在……之后|三下",
  "pen|钢笔|三下",
  "doll|洋娃娃；玩偶|三下",
  "Chinese|中国的；中文；中国人|三下",
  "tidy|整理，收拾|三下",
  "weather|天气|三下",
  "rainy|下雨的；多雨的|三下",
  "snowy|下雪的|三下",
  "windy|有风的|三下",
  "cold|冷的|三下",
  "snow|雪；下雪|三下",
  "sunny|晴朗的|三下",
  "hot|热的|三下",
  "swim|游泳|三下",
  "sea|海，海洋|三下",
  "get up|起床|三下",
  "park|公园|三下",
  "OK|好的；行；很好|三下",
  "rain|雨；下雨|三下",
  "kite|风筝|三下",
  "umbrella|雨伞|三下",
  "be|是（am/is/are）|三下",
  "wear|穿；戴；佩戴|三下",
  "coat|上衣，外套|三下",
  "cloudy|多云的|三下",
  "raincoat|雨衣|三下",
  "spring|春天；春季|三下",
  "summer|夏天；夏季|三下",
  "autumn|秋天；秋季|三下",
  "winter|冬天；冬季|三下",
  "season|季节|三下",
  "year|年|三下",
  "warm|温暖的|三下",
  "cool|凉爽的；冷静的|三下",
  "mountain|山，山脉|三下",
  "sweater|毛衣，线衣|三下",
  "skirt|裙子|三下",
  "golden|金色的；黄金般的|三下",
  "leaf|树叶（复数 leaves）|三下",
  "shirt|衬衫，衬衣|三下",
  "row|划船|三下",
  "boat|小船|三下",
  "walk|散步，步行|三下",
  "ice|冰|三下",
  "ice-skating|滑冰|三下",
  "for|为，为了；给；对于；因为|三下",
  "climb|爬，攀登|三下",
  "tree|树|三下",
  "river|河；江|三下",
  "fish|鱼|三下",
  "lot|许多|三下",
  "sleep|睡；睡觉|三下",
  "time|时间|三下",
  "o'clock|……点钟|三下",
  "up|向上；起来；在……之上|三下",
  "kid|小孩|三下",
  "classroom|教室|三下",
  "twenty|二十|三下",
  "at|在；于；向|三下",
  "thirty|三十|三下",
  "draw|画；绘画|三下",
  "art|艺术；美术|三下",
  "forty|四十|三下",
  "hurry|匆忙，急忙|三下",
  "half|半；一半|三下",
  "past|过去的；过去|三下",
  "go|走；去|三下",
  "birthday|生日|三下",
  "about|关于；大约|三下",
  "also|也|三下",
  "always|总是，一直|三下",
  "Beijing opera|京剧|三下",
  "bread|面包|三下",
  "breakfast|早餐|三下",
  "candy|糖果|三下",
  "chicken|鸡肉|三下",
  "day|一天；一日|三下",
  "dinner|晚餐；正餐|三下",
  "drink|饮料|三下",
  "egg|鸡蛋|三下",
  "favourite|最喜爱的|三下",
  "film|电影|三下",
  "food|食物|三下",
  "football|足球|三下",
  "forty-five|四十五|三下",
  "Friday|星期五|三下",
  "fruit|水果|三下",
  "hand|指针；手|三下",
  "happy|高兴的|三下",
  "healthy|健康的|三下",
  "home|家，住宅|三下",
  "hot dog|热狗|三下",
  "hungry|饥饿的|三下",
  "juice|果汁|三下",
  "library|图书馆|三下",
  "lovely|可爱的；令人愉快的|三下",
  "lunch|午餐|三下",
  "meat|肉|三下",
  "milk|牛奶|三下",
  "Monday|星期一|三下",
  "museum|博物馆|三下",
  "noodles|面条|三下",
  "not|不|三下",
  "often|常常，时常|三下",
  "opera|歌剧|三下",
  "party|聚会；派对|三下",
];
