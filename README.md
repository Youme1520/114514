# 影像技术刷题宝 —— 云端打包 APK 完整指南

> 本项目源码已完整交付。由于你的电脑上没有安装 Flutter / Android SDK，本指南教你用 **GitHub Actions 云端免费打包**，把代码变成可直接安装到安卓手机的 APK 文件。

---

## 一、准备工作（只需做一次）

1. **注册 GitHub 账号**：<https://github.com> （免费）
2. **安装 Git**：你电脑上已有 Git（版本 2.55.0），无需再装。

---

## 二、把代码推送到你自己的 GitHub 仓库

打开终端（Git Bash 或 CMD），先在浏览器里打开 GitHub 网页，点击右上角 **「+」→「New repository」** 创建一个**空的**仓库（仓库名随意，比如 `yingxiang-tiku-app`）。**不要勾选** "Add a README"（保持空仓库）。

然后回到终端，**一次性按顺序**执行以下命令（把 `<你的用户名>/<仓库名>` 换成你自己的仓库地址）：

```bash
# 1. 进入项目目录
cd D:/MC/yingxiang-tiku-app

# 2. 初始化 Git 仓库（已初始化过会提示已存在，可忽略）
git init

# 3. 添加所有文件并提交（必须先有提交，才能推送）
git add .
git commit -m "影像技术刷题宝：完整 Flutter 源码 + 云端打包工作流"

# 4. 把当前分支改名为 main
git branch -M main

# 5. 关联远程仓库：set-url 会自动覆盖已存在的 origin，不会报 "already exists"
git remote set-url origin https://github.com/Youme1520/114514.git

# 6. 推送代码
git push -u origin main
```

> **为什么用 `set-url` 而不是 `add`？**  
> `git remote add origin` 在重复执行或之前已添加过远程时，会报 `remote origin already exists`。改用 `git remote set-url origin ...` 会在 origin 已存在时自动覆盖为正确地址、不存在时自动创建，两种情况下都不会报错。

推送时会弹出 GitHub 登录窗口，用浏览器授权登录即可。

---

## 三、在 GitHub Actions 页面触发构建

1. 打开你的仓库页面，点击顶部 **「Actions」** 标签。
2. 左侧列表里应该能看到 **「Build Android APK」** 工作流（推送后会自动触发一次）。
   - 如果它还没自动跑，点击右侧 **「Run workflow」** 按钮手动触发。
3. 点击进入运行中的任务，你会看到 8 个步骤依次执行：
   - Checkout 代码 → 配置 Java 17 → 配置 Flutter → 生成 Android 工程 → 安装依赖 → 配置应用名/权限 → 构建 APK → 上传产物。
4. 整个过程约 **5～10 分钟**，等绿色对勾出现即表示成功。

---

## 四、下载 APK 文件

1. 构建成功后，回到该任务的页面底部，找到 **「Artifacts」**（构建产物）区域。
2. 你会看到两个产物：
   - `yingxiang-tiku-apk`：完整 APK（`app-release.apk`，通用，兼容所有安卓手机）
   - `yingxiang-tiku-apk-split`：按 CPU 架构拆分的 APK（体积更小）
3. 点击 **`yingxiang-tiku-apk`** 下载，解压后得到 `app-release.apk`。
4. 把这个 `.apk` 文件传到你的安卓手机上，点击安装即可。
   - 安装时如提示"未知来源"，请在手机设置中允许「安装未知来源应用」。

---

## 五、App 首次使用提示

1. **内置内容**：5 套试卷（135 题）+ 25 章知识卡片（102 张），开箱即用。
2. **AI 深度解析 / 主观题批改**：进入「我的」→「AI 设置」，填入你的免费接口：
   - 方案 A（推荐，永久免费）：注册智谱 AI（open.bigmodel.cn），选 `glm-4-flash`，填入 API Key。
   - 方案 B：注册硅基流动（cloud.siliconflow.cn），模型填 `Qwen/Qwen3-8B`，填入 API Key。
   - 两个接口都是 OpenAI 兼容格式，App 里已内置一键填入预设。
3. **自定义题库**：首页「导入题库」支持 JSON / CSV 文件（格式说明在导入页内）。

---

## 六、常见问题

| 问题                                    | 解决办法                                                                                                     |
| ------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| 推送时卡在登录                               | 换用 Personal Access Token 登录，或用 `gh auth login` 命令                                                        |
| Actions 构建报错                          | 点开红色步骤查看日志，把报错信息发给我，我帮你定位                                                                                |
| 想改应用名/图标                              | 告诉我，我帮你调整配置                                                                                              |
| 手机安装失败                                | 确认是 arm64 或通用 APK；旧手机用 split 包里的 `arm64-v8a` 版本                                                          |
| `remote origin already exists`        | 远程已添加过，改用 `git remote set-url origin <你的仓库地址>` 覆盖即可                                                      |
| `src refspec main does not match any` | 还没提交或分支名不是 main。先 `git add .` → `git commit -m "..."` → `git branch -M main`，再 `git push -u origin main` |

---

## 七、项目结构速览

```
yingxiang-tiku-app/
├── .github/workflows/build_apk.yml   # 云端打包工作流
├── lib/
│   ├── main.dart / app.dart          # 入口
│   ├── models/                       # 数据模型（题目/试卷/知识卡/AI配置）
│   ├── data/                         # 内置题库（5套试卷+知识卡片）
│   ├── services/                     # 数据库/导入/AI/设置服务
│   ├── providers/                    # 状态管理
│   ├── screens/                      # 各页面（首页/刷题/背诵/导入/我的）
│   ├── widgets/                      # 通用组件
│   └── theme.dart                    # 亮/暗主题
├── test/                             # 单元测试（4个文件）
└── pubspec.yaml                      # 依赖配置
```
