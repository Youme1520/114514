import '../../models/question.dart';

/// 第一章 绪论 习题（共 25 题）。
const String _c = '第一章 绪论';

Question _q(
  String type,
  String stem, {
  List<String> opts = const <String>[],
  String ans = '',
  String? group,
  String analysis = '',
  double score = 1,
}) =>
    Question(
      paperSet: 0,
      type: type,
      chapter: _c,
      stem: stem,
      groupStem: group,
      options: opts,
      answer: ans,
      analysis: analysis,
      score: score,
    );

final List<Question> chapter01Questions = <Question>[
  // （一）名词解释
  _q(
    QuestionType.term,
    'CR',
    ans: '即计算机X线摄影（computed radiography），是计算机和X线摄影的结合产物。'
        '它利用成像板取代传统的屏-片系统，利用荧光体的光激励发光（PSL）特性，'
        '通过激光扫描读取信息后，再经模/数转换器转换成数字信号，在显示器上显示图像。',
    score: 3,
  ),
  _q(
    QuestionType.term,
    'CT的能量成像',
    ans: '目前有双X线球管同步扫描、单X线球管的千伏瞬间切换和单X线球管的双层探测器'
        '三种类型的CT能量成像。它是指在同一次扫描中，CT机产生不同能量的射线进行数据采样，'
        '探测器接收后进行单能量重建，除产生传统混合能量图像外，还能产生单能量图像、'
        '基物质（水、碘、钙等）图像、能谱曲线以及有效原子序数等，并能进行物质分解和组织定性。',
    score: 3,
  ),
  _q(
    QuestionType.term,
    '分子影像学',
    ans: '指借助于分子探针和超顺磁性MR对比剂，运用影像技术来显示组织水平、细胞和'
        '亚细胞水平的特定分子，反映活体状态下分子水平变化，通过影像学对其生物学行为'
        '进行定性和定量研究的科学。',
    score: 3,
  ),

  // （二）简答题
  _q(
    QuestionType.shortAnswer,
    '简述医学影像检查技术的发展历程。',
    ans: '医学影像技术的应用与发展，从最初的模拟X线检查技术发展到数字X线检查技术，'
        '从唯一的普通X线检查技术发展到目前X线、CT、MR、核医学、超声等多种数字化的'
        '检查方式并存、互相补充，而且新技术日新月异、层出不穷，给医学诊断和治疗带来'
        '许多根本的改变。',
    score: 5,
  ),
  _q(
    QuestionType.shortAnswer,
    '简述MR的主要成像特点。',
    ans: '磁共振成像的特点主要有：①多参数成像；②多方位成像；③软组织分辨力高；'
        '④无电离辐射；⑤有多种成像技术；⑥可进行功能性成像；⑦可以进行MR介入；'
        '⑧可以进行分子水平成像。',
    score: 5,
  ),

  // （三）选择题 A3型题（1~5 题共用题干）
  _q(
    QuestionType.single,
    '发现X射线的物理学家是',
    opts: <String>['伦琴', '贝克勒尔', '居里夫人', 'Hounsfield', '洛克'],
    ans: 'A',
    group: '医学影像技术学是临床医学的支撑学科，主要包括X线摄影、CT、MR、DSA和核医学技术。',
  ),
  _q(
    QuestionType.single,
    '磁共振的物理现象及理论建立的时间是',
    opts: <String>['1895年', '1940年', '1946年', '1952年', '1971年'],
    ans: 'C',
    group: '医学影像技术学是临床医学的支撑学科，主要包括X线摄影、CT、MR、DSA和核医学技术。',
  ),
  _q(
    QuestionType.single,
    '以下设备和其英文缩写对应错误的是',
    opts: <String>[
      '计算机X线摄影——CR',
      '数字X线摄影——DR',
      '计算机X线断层扫描——ST',
      '数字减影血管造影——DSA',
      '磁共振成像——MR',
    ],
    ans: 'C',
    group: '医学影像技术学是临床医学的支撑学科，主要包括X线摄影、CT、MR、DSA和核医学技术。',
  ),
  _q(
    QuestionType.single,
    'CT的发明者是',
    opts: <String>['Cormack', 'Ambrose', 'Hounsfield', 'Ledley', 'Roentgen'],
    ans: 'C',
    group: '医学影像技术学是临床医学的支撑学科，主要包括X线摄影、CT、MR、DSA和核医学技术。',
  ),
  _q(
    QuestionType.single,
    '实施影像的全面质量管理，应该运用的循环方法是',
    opts: <String>['APCD', 'CPDA', 'DCAP', 'PDCA', 'PADC'],
    ans: 'D',
    group: '医学影像技术学是临床医学的支撑学科，主要包括X线摄影、CT、MR、DSA和核医学技术。',
  ),

  // （三）选择题 A3型题（6~10 题共用题干）
  _q(
    QuestionType.single,
    '以下关于理想对比剂的说法不正确的是',
    opts: <String>['显影效果好', '具有水溶性', '有生物活性', '易于排泄', '久存不变质'],
    ans: 'C',
    group: '用人工的方法将高密度或低密度物质通过某种途径引入体内，使器官或组织的图像'
        '与其周围结构或组织的图像产生密度差别，以显示成像区域内组织器官的形态和功能，'
        '这种被引入的物质称为对比剂（contrast media）。',
  ),
  _q(
    QuestionType.single,
    '以下不属于阴性对比剂的是',
    opts: <String>['水', '碘普罗胺', '空气', '氧气', '二氧化碳'],
    ans: 'B',
    group: '用人工的方法将高密度或低密度物质通过某种途径引入体内，使器官或组织的图像'
        '与其周围结构或组织的图像产生密度差别，以显示成像区域内组织器官的形态和功能，'
        '这种被引入的物质称为对比剂（contrast media）。',
  ),
  _q(
    QuestionType.single,
    '阳性对比剂为原子序数较高的物质，不包括',
    opts: <String>[
      '难溶性固体对比剂',
      '主要经肾脏排泄的对比剂',
      '排泄性胆道对比剂',
      '气体类对比剂',
      '油脂类对比剂',
    ],
    ans: 'D',
    group: '用人工的方法将高密度或低密度物质通过某种途径引入体内，使器官或组织的图像'
        '与其周围结构或组织的图像产生密度差别，以显示成像区域内组织器官的形态和功能，'
        '这种被引入的物质称为对比剂（contrast media）。',
  ),
  _q(
    QuestionType.single,
    '以下不属于阳性对比剂的是',
    opts: <String>['硫酸钡', '无机碘化物', '有机碘化物', '碘化油', '二氧化碳'],
    ans: 'E',
    group: '用人工的方法将高密度或低密度物质通过某种途径引入体内，使器官或组织的图像'
        '与其周围结构或组织的图像产生密度差别，以显示成像区域内组织器官的形态和功能，'
        '这种被引入的物质称为对比剂（contrast media）。',
  ),
  _q(
    QuestionType.single,
    'X线对比剂根据使用途径分类不包括',
    opts: <String>[
      '离子型对比剂',
      '胃肠使用对比剂',
      '血管内注射对比剂',
      '椎管内注射对比剂',
      '胆系对比剂',
    ],
    ans: 'A',
    group: '用人工的方法将高密度或低密度物质通过某种途径引入体内，使器官或组织的图像'
        '与其周围结构或组织的图像产生密度差别，以显示成像区域内组织器官的形态和功能，'
        '这种被引入的物质称为对比剂（contrast media）。',
  ),

  // （三）X型题
  _q(
    QuestionType.multiChoice,
    '下列叙述中正确的是',
    opts: <String>[
      'CT图像是数字图像',
      'CT成像使用X线',
      'CT是多参数成像',
      'CT可以进行薄层扫描',
      'CT可以得到容积数据',
    ],
    ans: 'ABDE',
  ),
  _q(
    QuestionType.multiChoice,
    '以下可作为成像探测器的是',
    opts: <String>['屏-片系统', 'IP', 'FPD', 'CCD', '稀土陶瓷'],
    ans: 'ABCDE',
  ),
  _q(
    QuestionType.multiChoice,
    'DR相比CR，描述正确的是',
    opts: <String>['成像时间短', 'X线利用率高', 'DQE高', '系统成本高', '使用IP'],
    ans: 'ABCD',
  ),
  _q(
    QuestionType.multiChoice,
    '下列关于MRI优势的描述正确的是',
    opts: <String>[
      '不使用X线，避免了电离辐射损伤',
      '对骨骼、钙化和胃肠道的显示效果好',
      '多方位成像',
      '对软组织的显示能力好',
      '多参数成像',
    ],
    ans: 'ACDE',
  ),
  _q(
    QuestionType.multiChoice,
    '关于X线对比剂的描述，正确的是',
    opts: <String>[
      '可分为高密度和低密度两大类',
      '离子型对比剂的理化性能优于非离子型对比剂',
      'CO₂是低密度对比剂',
      '双聚体对比剂又称为等渗对比剂',
      '离子型和非离子型水溶性对比剂在化学结构上都是三碘苯环的衍生物',
    ],
    ans: 'ACDE',
  ),

  // （四）案例分析题（1~5 题共用题干）
  _q(
    QuestionType.multiChoice,
    '目前CT双能成像临床应用的主流方式有',
    opts: <String>[
      '双球管双探测器双能成像',
      '单球管高低能瞬切能谱成像',
      '单球管高低能两次扫描成像',
      '单球管双层探测器双能成像',
      'Sn滤过高低能成像',
      'Cu滤过高低能成像',
    ],
    ans: 'ABD',
    group: '从1895年伦琴发现X线以来，X线检查技术从传统模拟X线摄影到现在的DR、CT、DSA，'
        '新的方法和检查技术不断涌现。',
  ),
  _q(
    QuestionType.multiChoice,
    '磁共振设备硬件发展的方向包括',
    opts: <String>[
      '高场强',
      '长磁体',
      '零液氦技术',
      '单源射频发射系统',
      '可穿戴柔性表面线圈',
      '小孔径',
    ],
    ans: 'ACE',
    group: '从1895年伦琴发现X线以来，X线检查技术从传统模拟X线摄影到现在的DR、CT、DSA，'
        '新的方法和检查技术不断涌现。',
  ),
  _q(
    QuestionType.multiChoice,
    'CT设备硬件发展的方向包括',
    opts: <String>[
      '更高的球管热容量',
      '更高的散热速率',
      '更高的机架转速',
      '更宽的探测器覆盖',
      '更大的探测器单元',
      '“0”发热球管技术',
    ],
    ans: 'ABCD',
    group: '从1895年伦琴发现X线以来，X线检查技术从传统模拟X线摄影到现在的DR、CT、DSA，'
        '新的方法和检查技术不断涌现。',
  ),
  _q(
    QuestionType.multiChoice,
    '普通乳腺X线检查的特点包括',
    opts: <String>[
      '密度分辨力高',
      '组织结构前后重叠',
      '成像质量受乳腺组织结构、发育情况、生理期和受检者年龄等诸多因素的影响',
      '空间分辨力高',
      '对钙化病变敏感',
      '软组织分辨力高',
    ],
    ans: 'BCDE',
    group: '从1895年伦琴发现X线以来，X线检查技术从传统模拟X线摄影到现在的DR、CT、DSA，'
        '新的方法和检查技术不断涌现。',
  ),
  _q(
    QuestionType.multiChoice,
    'DSA作为介入治疗的影像导引，较传统的心血管造影具有较大的优势，其中包括',
    opts: <String>[
      '能消除造影血管以外的结构，仅留下造影的血管影像，图像清晰且分辨力高',
      '成像速度快、时间分辨力高',
      '能作动态性能研究，如血流储备分数（FFR）等',
      'DSA是无创的检查',
      'DSA可以显示成像区域解剖结构',
      'DSA成像无需对比剂',
    ],
    ans: 'ABC',
    group: '从1895年伦琴发现X线以来，X线检查技术从传统模拟X线摄影到现在的DR、CT、DSA，'
        '新的方法和检查技术不断涌现。',
  ),
];
