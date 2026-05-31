---
name: conventional-commit
description: Generate Conventional Commits 1.0.0 compliant commit messages by analyzing Git staged changes (git diff --cached). Use when user asks to generate a commit message, write a git commit, or mentions "conventional commit", "commit message", "提交信息".
---

# Conventional Commit 消息生成

## 流程

1. **读取暂存区** — 运行 `git diff --cached` 查看所有暂存的变更
2. **分析变更** — 判断变更类型、范围和影响
3. **生成消息** — 只输出最终消息，不执行 `git commit`

## 类型判断指南

| 变更内容 | 类型 |
|---|---|
| 新功能、新接口、新端点 | `feat` |
| Bug 修复 | `fix` |
| 文档（README、注释、文档文件） | `docs` |
| 代码重构（不改变行为） | `refactor` |
| 性能优化 | `perf` |
| 测试（添加/修改测试） | `test` |
| 样式格式化（缩进、空格，非语义变更） | `style` |
| 构建/依赖/CI/CD | `build` \| `ci` |
| 杂项（配置、工具等） | `chore` |

## 生成规则

### 格式

```
<type>(<scope>): <简短描述>

<可选正文>

<可选脚注>
```

### 范围 (scope)

从变更文件的路径/模块推断。例如 `src/routes/auth.ts` 变更 → `scope: auth`。

### 描述 (description)

- 祈使句，首字母小写，句末无句号
- 简洁（< 72 字符优先）

### 破坏性变更

- 如果 API 或行为向后不兼容，在类型后加 `!`：`feat!:` 或 `feat(api)!:`
- 脚注中添加 `BREAKING CHANGE: <描述>`

### 正文 (body)

- 需要额外上下文时添加（描述 why 而非 what）
- 空行分隔描述和正文

### 脚注 (footer)

- `BREAKING CHANGE:` 用于破坏性变更
- `Refs: #123` 引用 issue/PR
- `Reviewed-by: name` 等

## 输出规则

- **只输出 commit message 本身**，不要额外的解释、不要确认、不要 Markdown 包裹
- 如果暂存区为空，返回 `暂存区没有变更，无法生成提交信息`
- 如果变更包含破坏性 API 修改，务必标记 `!` 或 `BREAKING CHANGE`
