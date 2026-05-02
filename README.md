# Word Quest

Word Quest 是一个给两个孩子使用的本地优先背单词应用。第一版采用“每日任务 + 闯关反馈”的产品形态，支持多孩子档案、基础题型、少量听音题、家长轻量看板和备份导入导出。

## 当前阶段

当前仓库处于项目骨架阶段：

- 已记录产品设计文档。
- 已记录第一阶段实施计划。
- 正在搭建 Flutter 项目结构和核心学习模型。

## 技术路线

- Flutter + Dart。
- 第一阶段优先 Flutter Web / PWA。
- 后续打包 Android、iOS、macOS、Windows。
- 学习核心逻辑保持纯 Dart，便于测试和多端复用。
- 数据访问通过 Repository 抽象预留云同步。

## 本地运行

当前机器尚未安装 Flutter SDK，因此本轮无法直接运行 Flutter 命令。安装 Flutter 后，在本目录执行：

```bash
flutter pub get
flutter test
flutter run -d chrome
```

## 当前验证记录

- `flutter --version`：未通过，当前环境提示 `command not found: flutter`。
- `flutter test`：未通过，当前环境提示 `command not found: flutter`。
- 安装 Flutter SDK 后，优先运行 `flutter pub get` 和 `flutter test`。

## 文档

- 产品设计：`docs/superpowers/specs/2026-05-02-word-quest-design.md`
- 第一阶段计划：`docs/superpowers/plans/2026-05-02-word-quest-phase1.md`
