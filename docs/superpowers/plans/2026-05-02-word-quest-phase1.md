# Word Quest 第一阶段 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 创建 Word Quest Flutter 应用骨架，并实现可测试的本地学习核心雏形。

**Architecture:** 项目采用 Flutter + Dart。学习核心放在 `lib/features/*/domain` 和 `lib/features/*/application`，界面放在 `presentation`，数据访问后续通过 Repository 抽象隔离。本阶段先搭建静态首页、核心模型和每日任务生成逻辑，为后续接入本地存储、词表导入和闯关系统做准备。

**Tech Stack:** Flutter、Dart、flutter_test。后续计划引入 Riverpod、Drift / SQLite、文件导入导出插件。

---

## 文件结构

- `pubspec.yaml`：Flutter 项目配置和依赖声明。
- `analysis_options.yaml`：Dart 静态检查规则。
- `README.md`：项目目标、运行方式和当前限制。
- `lib/main.dart`：应用入口。
- `lib/app/word_quest_app.dart`：应用级 MaterialApp 配置。
- `lib/features/home/presentation/home_screen.dart`：第一版静态首页，展示两个孩子、今日任务和家长入口。
- `lib/features/child_profile/domain/child_profile.dart`：孩子档案模型。
- `lib/features/word_book/domain/word_entry.dart`：单词模型。
- `lib/features/word_book/domain/word_book.dart`：词表模型。
- `lib/features/study/domain/study_task.dart`：每日任务模型。
- `lib/features/study/domain/answer_record.dart`：答题记录模型。
- `lib/features/study/application/study_task_planner.dart`：每日任务生成逻辑。
- `test/features/study/study_task_planner_test.dart`：每日任务生成测试。

## Task 1: 项目基础文件

**Files:**
- Create: `pubspec.yaml`
- Create: `analysis_options.yaml`
- Create: `.gitignore`
- Create: `README.md`

- [ ] **Step 1: 创建 Flutter 基础配置**

写入最小 Flutter 项目配置，不引入第三方依赖，避免当前未安装 Flutter SDK 时产生锁文件不一致。

- [ ] **Step 2: 创建项目说明**

README 需要包含产品目标、当前阶段、运行命令和 Flutter SDK 未安装时的说明。

- [ ] **Step 3: 提交**

```bash
git add pubspec.yaml analysis_options.yaml .gitignore README.md
git commit -m "chore: 初始化 Flutter 项目配置"
```

## Task 2: 应用入口和静态首页

**Files:**
- Create: `lib/main.dart`
- Create: `lib/app/word_quest_app.dart`
- Create: `lib/features/home/presentation/home_screen.dart`

- [ ] **Step 1: 创建应用入口**

`main.dart` 只负责启动 `WordQuestApp`。

- [ ] **Step 2: 创建应用壳**

`WordQuestApp` 使用 `MaterialApp`，设置中文标题、主题和首页。

- [ ] **Step 3: 创建静态首页**

首页展示两个孩子档案、今日任务摘要、闯关进度和家长管理入口。第一阶段不接真实状态管理，先用静态数据表达产品结构。

- [ ] **Step 4: 提交**

```bash
git add lib/main.dart lib/app/word_quest_app.dart lib/features/home/presentation/home_screen.dart
git commit -m "feat: 添加应用入口和首页骨架"
```

## Task 3: 学习核心模型

**Files:**
- Create: `lib/features/child_profile/domain/child_profile.dart`
- Create: `lib/features/word_book/domain/word_entry.dart`
- Create: `lib/features/word_book/domain/word_book.dart`
- Create: `lib/features/study/domain/study_task.dart`
- Create: `lib/features/study/domain/answer_record.dart`

- [ ] **Step 1: 定义孩子档案**

包含 `id`、`name`、`gradeLabel`、`avatarSeed`、`createdAt`。

- [ ] **Step 2: 定义单词和词表**

单词包含拼写、释义、音标、词性、例句、标签。词表包含 id、名称、阶段和单词列表。

- [ ] **Step 3: 定义学习任务和答题记录**

任务区分新词、复习词和错词强化。答题记录需要标记题型、是否正确、耗时和错误类型。

- [ ] **Step 4: 提交**

```bash
git add lib/features/child_profile/domain lib/features/word_book/domain lib/features/study/domain
git commit -m "feat: 添加学习核心数据模型"
```

## Task 4: 每日任务生成逻辑和测试

**Files:**
- Create: `lib/features/study/application/study_task_planner.dart`
- Create: `test/features/study/study_task_planner_test.dart`

- [ ] **Step 1: 写测试**

覆盖三类任务数量：新词、复习词、错词强化。

- [ ] **Step 2: 实现任务生成**

输入候选新词、到期复习词、错词列表和每日配置，输出 `StudyTask`。

- [ ] **Step 3: 运行测试**

```bash
flutter test
```

预期：安装 Flutter SDK 后测试通过。当前环境没有 Flutter SDK 时，该命令会失败为 `command not found: flutter`。

- [ ] **Step 4: 提交**

```bash
git add lib/features/study/application/study_task_planner.dart test/features/study/study_task_planner_test.dart
git commit -m "feat: 添加每日任务生成逻辑"
```

## Task 5: 验证和后续准备

**Files:**
- Modify: `README.md`

- [ ] **Step 1: 记录本地验证结果**

如果当前环境没有 Flutter SDK，在 README 中记录需要安装 Flutter 后再运行验证。

- [ ] **Step 2: 检查 git 状态**

```bash
git status --short
```

预期：没有未提交变更，或只有明确需要继续处理的文件。

- [ ] **Step 3: 提交**

```bash
git add README.md
git commit -m "docs: 记录项目验证方式"
```
