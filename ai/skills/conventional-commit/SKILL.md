---
name: conventional-commit
description: 根据暂存区变更生成 Conventional Commits 1.0.0 提交信息，同时输出英文原文和中文翻译；不执行 git commit。当用户要求生成 commit message、写提交信息，或提到 conventional commit / 提交信息 时使用。
---

# Conventional Commit 消息生成

规范：[references/conventional-commits-v1.0.0.md](references/conventional-commits-v1.0.0.md)，细节存疑时查阅。

## 流程

1. 运行 `git diff --cached` 读取暂存变更。
2. 按规范生成英文 commit message，并翻译一份中文版。
3. 只输出两份消息，不执行 `git commit`。

## 输出

- 依次输出两份消息，各用 markdown 代码块包裹：先英文原文，后中文翻译；两份消息之间用 `---` 分隔。
- 中文版保留 `type(scope)`、`!`、`BREAKING CHANGE:` 等规范关键字，只翻译描述、正文和脚注内容。
- 正文使用 `- ` 列表项，每项一行。
- 暂存区为空时，仅返回：`暂存区没有变更，无法生成提交信息`

```markdown
feat(auth): add password reset via email

- Send a time-limited reset link instead of a temporary password.

BREAKING CHANGE: `POST /login` no longer accepts the `temp_password` field.
```

---

```markdown
feat(auth): 支持通过邮件重置密码

- 使用有时效的重置链接替代临时密码。

BREAKING CHANGE: `POST /login` 不再接受 `temp_password` 字段。
```
