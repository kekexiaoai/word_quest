# Word Quest / 词途

Word Quest（词途）是一个本地优先的背单词应用，当前面向单个孩子日常学习和家长轻量看板。应用已经接入动态关卡、真实学习记录、错词复习、本地备份和 Android 试用包构建流程。

## 当前功能

- 首页按当前孩子、当前词表、掌握比例和到期复习数动态规划今日题量。
- 关卡支持新词热身、到期复习、错词 Boss 和宝箱结算。
- 答题记录会写入本地仓库，并驱动错词、薄弱点和间隔复习。
- CSV 导入词表可立即参与关卡出题。
- 导入词表、学习记录、冒险和宠物进度支持本地持久化与备份迁移。
- 设置页支持孩子 / 家长模式切换、默认学习词表选择和数据管理。
- 家长模式首页展示孩子总览，并可进入单个孩子详情页查看趋势、错词、复习建议和词表完成情况。
- 家长详情页的错词可直接进入该孩子专属错词复习题组。

## 技术路线

- Flutter + Dart。
- Android 包名：`com.kekexiaoai.wordquest`。
- 学习核心逻辑保持纯 Dart，便于测试和多端复用。
- 数据访问通过 Repository 抽象组织，当前以本地优先为主。

## 本地运行

安装 Flutter SDK 并加入 PATH 后，在项目根目录执行：

```bash
flutter pub get
flutter test
flutter run -d chrome
```

## 本地验证

提交前建议至少运行：

```bash
flutter analyze
flutter test
```

当前已验证：

- `flutter analyze`：无问题。
- `flutter test`：72 个测试通过。

## Android APK 打包

仓库已配置 GitHub Actions：`.github/workflows/android-apk.yml`。

触发方式：

- push 到 `main` 分支自动构建。
- 在 GitHub 仓库的 Actions 页面手动运行 `Android APK` workflow。

构建流程会执行：

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

构建完成后，在 GitHub Actions 的运行详情页下载 artifact：

```text
word-quest-debug-apk
```

里面的 APK 路径是：

```text
app-debug.apk
```

手机试用时，安卓设备需要允许安装未知来源应用。当前 workflow 先产出 debug APK，适合内部快速试用；后续发布前再补 release 签名包。

## 文档

- 产品设计：`docs/superpowers/specs/2026-05-02-word-quest-design.md`
- 等级与宠物设计：`docs/superpowers/specs/2026-05-02-word-quest-level-and-pet-design.md`
