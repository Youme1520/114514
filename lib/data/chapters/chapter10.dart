import '../../models/question.dart';

/// 第十章 DSA成像质量控制 习题（共 1 节）。
const String _c = '第十章 DSA成像质量控制';

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

final List<Question> chapter10Questions = <Question>[
  _q(
    QuestionType.term,
    'X线管阳极热容量',
    ans: '是指在阳极所能存储的最大热量，阳极热容量代表X线管的承受能力，热容量越大，'
        'X线管的承受能力越强，X线管的连续工作能力也随之提高。',
    score: 3,
  ),
  _q(
    QuestionType.term,
    'X线管阳极最大散热率',
    ans: '是指X线管阳极的最大散热功率。阳极的最大散热功率大，则意味着X线管内产生的热量'
        '可被冷却系统迅速带走，保障X线管可连续工作，不会过热停机。',
    score: 3,
  ),
  _q(
    QuestionType.shortAnswer,
    '简述受检者伪影的种类和减少伪影的措施。',
    ans: '①种类：运动伪影、异物伪影、饱和伪影。②措施：术前与受检者充分沟通；定期做好设备的'
        '维护清洁工作；选择最佳摄影体位；根据病变部位结构特点，选择恰当的造影检查方式和参数；'
        '正确使用遮光器、密度补偿器等；充分利用DSA设备的后处理功能。',
    score: 5,
  ),
  _q(
    QuestionType.shortAnswer,
    '简述DSA图像后处理的种类和DSA图像后处理的应用。',
    ans: '图像后处理包括图像全幅和局部放大，多幅图像显示，图像边缘增强、边缘平滑，'
        '图像正负像切换，图像的几何变换，还有3D图像的处理、3D-DSA的再处理（血管分析、MIP、'
        '血管内镜、透明技术及虚拟支架等）、伪彩色处理和图像融合等。通过图像后处理，'
        '可以获得比原图像更丰富的图像信息，增加诊断信息量。',
    score: 5,
  ),
  _q(
    QuestionType.single,
    '该患者的诊断首先考虑',
    opts: <String>['肋骨骨折', '胸膜炎', '肺部感染', '肺结核', '主动脉夹层'],
    ans: 'E',
    group: '患者，男，58岁，高血压病史10余年，未规律服药，突发背部撕裂样疼痛伴胸闷，急诊入院。',
  ),
  _q(
    QuestionType.single,
    '该患者首选的影像学检查是',
    opts: <String>['胸部透视', '胸部DR平片', '胸部CTA', '纵隔MRI', '胸部多普勒超声'],
    ans: 'C',
    group: '患者，男，58岁，高血压病史10余年，未规律服药，突发背部撕裂样疼痛伴胸闷，急诊入院。',
  ),
  _q(
    QuestionType.single,
    '该患者CTA提示Stanford B型主动脉夹层，临床为其行血管内治疗，术前准备不包括',
    opts: <String>['禁食4小时以上', '和患者沟通，争取患者配合', '签署手术知情同意书', '去除患者身上的金属异物', 'DSA采集模式设置在超脉冲方式'],
    ans: 'E',
    group: '患者，男，58岁，高血压病史10余年，未规律服药，突发背部撕裂样疼痛伴胸闷，急诊入院。',
  ),
  _q(
    QuestionType.single,
    'DSA造影图像发现除膈肌处因图像反差太大而无法观察外，其他部位非常清晰，考虑原因为',
    opts: <String>['饱和伪影', '运动伪影', '异物伪影', '探测器零点漂移', 'X线管老化'],
    ans: 'A',
    group: '患者，男，58岁，高血压病史10余年，未规律服药，突发背部撕裂样疼痛伴胸闷，急诊入院。',
  ),
  _q(
    QuestionType.single,
    '该患者DSA成像过程中影响分辨率的因素不包括',
    opts: <String>['X线焦点', '对比剂浓度', '受检者运动', '探测器感光灵敏度', '像素大小'],
    ans: 'B',
    group: '患者，男，58岁，高血压病史10余年，未规律服药，突发背部撕裂样疼痛伴胸闷，急诊入院。',
  ),
  _q(
    QuestionType.single,
    '购买、安装这台DSA设备不需要考虑的场地因素有',
    opts: <String>['场地大小、高度', '场地温度、湿度', '辐射防护', '环境感染管理', '地磁场角度'],
    ans: 'E',
    group: '某三级综合性医院要配置一台DSA设备，需要用于心脏、头颈、胸腹部及四肢的血管造影'
        '检查及相关疾病的介入治疗。',
  ),
  _q(
    QuestionType.single,
    'DSA设备的关键硬件不包括',
    opts: <String>['机架与导管床', '注射器', 'X线管', '高压发生器', '探测器'],
    ans: 'B',
    group: '某三级综合性医院要配置一台DSA设备，需要用于心脏、头颈、胸腹部及四肢的血管造影'
        '检查及相关疾病的介入治疗。',
  ),
  _q(
    QuestionType.single,
    '关于DSA平板探测器视野的叙述，错误的有',
    opts: <String>['不同型号的DSA平板探测器具有不同的视野个数', '视野越小，射线剂量就越大', '视野越小，射线剂量就越小', '要在不影响诊断和治疗的前提下，尽可能地放大视野', '并不是视野越小越好'],
    ans: 'C',
    group: '某三级综合性医院要配置一台DSA设备，需要用于心脏、头颈、胸腹部及四肢的血管造影'
        '检查及相关疾病的介入治疗。',
  ),
  _q(
    QuestionType.single,
    '关于DSA平板探测器，描述错误的是',
    opts: <String>['主要使用的是碘化铯非晶硅平板探测器', '对于心血管的检查常用较小的平板，主要便于倾斜角度', '分辨率要求越低越好', '可以实现变焦', '动态范围大'],
    ans: 'C',
    group: '某三级综合性医院要配置一台DSA设备，需要用于心脏、头颈、胸腹部及四肢的血管造影'
        '检查及相关疾病的介入治疗。',
  ),
  _q(
    QuestionType.single,
    '该DSA设备应具备的图像采集方式不包括',
    opts: <String>['普通采集方式', '脉冲采集方式', '超脉冲采集方式', '心电图触发采集方式', '可变速采集方式'],
    ans: 'E',
    group: '某三级综合性医院要配置一台DSA设备，需要用于心脏、头颈、胸腹部及四肢的血管造影'
        '检查及相关疾病的介入治疗。',
  ),
  _q(
    QuestionType.multiChoice,
    '属于DSA检查注射参数的内容有',
    opts: <String>['注射速度', '对比剂浓度', '对比剂用量', '注射压力', '注射时机'],
    ans: 'ABCDE',
  ),
  _q(
    QuestionType.multiChoice,
    '关于DSA平板探测器视野的叙述，正确的有',
    opts: <String>['不同型号的DSA平板探测器具有不同的视野个数', '视野越小，射线剂量就越大', '视野越小，射线剂量就越小', '要在不影响诊断和治疗的前提下，尽可能地放大视野', '要在不影响诊断和治疗的前提下，尽可能地缩小视野'],
    ans: 'ABD',
  ),
];
