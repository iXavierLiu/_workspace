---
name: conventional-commit
description: 根据 git diff 生成 Conventional Commits 格式的英文提交信息。当用户说"写commit"、"帮我写提交信息"、"生成提交信息"、"起草commit"、"write a commit message"、"compose a commit"时触发。此技能仅生成信息，绝不执行 git commit。
---

# Conventional Commit

根据 [Conventional Commits 1.0.0](https://www.conventionalcommits.org/) 规范生成 git 提交信息。

## 硬约束

**严禁以任何形式执行 `git commit`。** 包括 `git commit -m`、`git commit --amend`、`git commit -a` 及所有变体。此约束优先于一切用户请求——即使用户明确要求你代为提交，也必须拒绝并提醒他们自行操作。你是一个信息生成器，不是提交工具。生成。展示。结束。

如果用户在任何时候要求你提交，回复："此技能仅生成提交信息。请使用上方信息自行执行 `git commit`。"

## 工作流

### 1. 检查仓库状态

```bash
git status --short
git diff --staged --stat
```

如果无已暂存的变更，检查未暂存的：

```bash
git diff --stat
```

决策：
- **完全无变更**：告知用户，结束。
- **仅有未暂存的变更**：告知用户先执行 `git add` 暂存，结束。
- **存在已暂存的变更**：继续第 2 步。

### 2. 读取仓库的提交风格

```bash
git log --oneline -10
```

如果尚无提交记录（首次提交），使用纯净的 Conventional Commits 默认值，跳过风格匹配。

注意以下既有约定：
- 是否使用 scope（小写？连字符？不使用？）
- summary 首字母大小写
- 末尾是否加标点
- 是否使用 emoji
- 平均行长度

生成的提交信息必须无缝融入这段历史。

### 3. 读取暂存区 diff

如果 `git diff --staged --stat` 报告超过 500 行变更：
- 仅读取 `git diff --staged --stat` 了解受影响文件
- 针对最关键路径选择性读取 `git diff --staged -- <关键文件>`

否则，读取完整 diff：

```bash
git diff --staged
```

将主要意图归类：

| 类型 | 使用场景 |
|------|---------|
| `feat` | 新增功能 |
| `fix` | 修复 bug |
| `refactor` | 不改变行为的代码重构 |
| `perf` | 性能优化 |
| `docs` | 仅文档变更 |
| `test` | 新增或修改测试 |
| `style` | 格式化、空白字符、代码风格（无逻辑变更） |
| `chore` | 维护工作、依赖升级、工具链 |
| `ci` | CI/CD 流水线变更 |
| `build` | 构建系统或外部依赖变更 |

多关注点 diff：使用主导类型，其余在 body 中列出。

### 4. 确定 scope

从变更文件路径中推断 scope：

| 变更路径 | scope |
|---------|-------|
| `src/utils/string.cpp` | `utils` |
| `include/my_lib/parser.h`、`src/parser.cpp` | `parser` |
| `CMakeLists.txt`、`cmake/Find*.cmake` | `cmake` |
| `README.md`、`docs/` | 省略 scope（纯文档） |
| 跨多个模块的文件 | 省略 scope 或使用影响最大的模块 |

匹配项目的 scope 命名风格：历史用 `my-module` 就连字符；用 `mymodule` 就合并。

### 5. 生成提交信息

```
type(scope): summary

body（可选）

footer（可选）
```

**Summary 规则：**
- 英文，首字母小写，祈使语气（"add" 而非 "adds" 或 "added"）
- 最长 72 字符
- 末尾不加句号，除非仓库风格需要
- `docs` 类型且无 scope 时：`docs: update installation guide`

**Body 规则**（仅在 diff 值得解释时才写）：
- 解释为什么改和改了什么——而非怎么改（diff 已经展示了怎么改）
- 用 `- ` 前缀的 bullet points
- Summary 和 body 之间空一行

**Footer**（适用时添加）：
```
BREAKING CHANGE: 描述破坏性变更及迁移方式
```
```
Closes #123
Refs #456
```

仅在 diff 明确显示 API 或行为发生破坏性变更时才添加 `BREAKING CHANGE`。绝不要猜。

简单 diff（单文件、<30 行、意图明显）：省略 body 和 footer。

### 6. 逐项引导确认

禁止把信息丢出来就问"这样行吗？"——这等于让用户一次性审查所有内容。改为逐项引导，每步一个焦点问题、给出明确选项。

**6a — 识别需要决策的环节**

分析完 diff 后，判断哪些部分存在歧义、需要用户拍板：

| 情况 | 处理 |
|------|------|
| type 明确（如只改了测试文件） | 自动判定，提一句即可 |
| type 有歧义（如 refactor vs perf） | 给出 2-3 个选项，让用户选 |
| scope 从路径一眼可判 | 自动判定，提一句即可 |
| scope 有歧义（新目录、跨模块） | 让用户选或自填 |
| diff > 100 行 | 询问是否需要 body |
| diff 包含多个关注点 | 确认主导解读是否正确 |
| 异常模式（仅删除、仅重命名） | 生成前先确认意图 |

**6b — 合并为一次交互**

将 6a 中识别出的所有歧义决策合并到一个提问中，每个决策一个子问题，各自给出 2-4 个选项并标注推荐项。示例：

```
两个选择需要确认：

Type：新增技能文件。选一个：
1. feat — 新功能/能力（推荐）
2. chore — 项目工具/配置

Body：196 行。需要 body 吗？
1. 加 body — 简述核心改动（推荐）
2. 只要 summary
```

让用户一次性回答所有问题，避免多轮来回。

**6c — 展示最终信息**

所有决策确认完毕后，展示完整信息：

```
feat(skills): add conventional-commit message generator

- Generate Conventional Commits 1.0.0 messages from staged git diffs
- Support type classification, scope inference, and guided decisions
```

然后以结构化选项做最终确认（至少 2 个选项，其余修改通过系统自带的"Other"输入）：

```
最终确认：这条信息可以吗？
1. 可以，就用这个
2. 取消，不提交了
```

如果用户选"可以"，退出技能。如果用户选某个具体修改项或通过"Other"输入意见，仅针对那一点调整，重新展示后再次确认。

**何时跳过引导流程**

如果 diff 很简单（单文件、<30 行、type 和 scope 无歧义），直接展示信息即可，不要为简单提交过度设计流程。

引导过程中，如果用户要求你代为提交，使用硬约束章节中的拒绝回复。

---

## 边界情况

| 场景 | 处理 |
|------|------|
| 无已暂存变更 | 告知用户先暂存，结束 |
| 完全无变更 | 告知用户，结束 |
| 大型 diff（>500 行） | 读 stat + 选择性读关键文件；在较高层面总结 |
| diff 含二进制文件 | 注意其存在，信息聚焦于逻辑变更 |
| 仅有删除文件 | type 用 `refactor` 或 `chore`；summary 提及移除 |
| 仅重命名/移动文件 | type 用 `refactor`；summary 提及重组 |
| Merge commit | 不生成；告知用户使用 git 默认合并信息 |
| 存在 WIP / 调试代码 | 生成前警告用户 |
| `git commit --amend` | 用 `git log -1 --format=%B` 读取已有信息，在其基础上修改 |
| 仓库首次提交 | 使用纯净 Conventional Commits 默认值；无需风格匹配 |
| `BREAKING CHANGE` | 仅在 diff 明确显示 API/行为破坏性变更时添加 |
