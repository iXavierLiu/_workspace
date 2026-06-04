# C++ 程序员转 Rust 渐进式学习方案（12 周）

> 适用对象：有 2+ 年 C++ 经验的工程师，希望在不离开工作的前提下完成转型。  
> 核心原则：**项目驱动 + 编译期对抗 + 渐进式替换**。  
> 投入：工作日每天 1.5-2 小时 + 周末 3-4 小时。

---

## 总览

| 阶段 | 周次 | 主题 | 产出 |
|------|------|------|------|
| Phase 1 | Week 1-2 | 思维转换 + 所有权基础 | 一个能跑的命令行参数解析器 |
| Phase 2 | Week 3-4 | 借用、生命周期、错误处理 | 一个文件批量重命名工具 |
| Phase 3 | Week 5-6 | 泛型、Trait、智能指针 | 一个简单的 JSON 解析/序列化库 |
| Phase 4 | Week 7-8 | 模块化、cargo、测试、生态 | 发布到 crates.io 的小工具 |
| Phase 5 | Week 9-10 | 并发 + 异步入门 | 多线程文件下载器 |
| Phase 6 | Week 11-12 | FFI 实战 + Unsafe 边界 | Rust 包装一个你熟悉的 C++ 库 |

---

## Phase 1：思维转换（Week 1-2）

### 🎯 目标
- 理解"所有权/借用"和"指针/引用"的本质区别
- 跑通 cargo 工具链
- 完成 5-10 个 Rustlings 小练习

### 📚 必读
- The Rust Book 第 1-4 章（入门、猜数字游戏、通用编程概念、所有权）
- Rustlings 前 5 个章节：`intro`、`variables`、`functions`、`if`、`primitive_types`

### 🧠 关键思维转换

| C++ 思维 | Rust 思维 |
|---------|----------|
| 指针 + 智能指针组合 | 所有权 + 借用 |
| RAII 析构函数 | Drop trait，编译器决定调用点 |
| 拷贝构造/移动构造 | Copy trait / 显式移动 |
| 异常 + 错误码 | `Result<T, E>` + `?` |
| 引用是"不会为 null 的指针" | 引用受借用检查器约束 |
| 头文件 + 实现分离 | module + crate（cargo 管） |

### 💻 周末项目：命令行参数解析器
**C++ 起点**：用 `getopt` 或 `argparse` 写过的工具  
**Rust 实现要点**：
- 学会 `clap` 的 `derive` 宏用法
- 体验 `String` vs `&str` 的选择
- 第一次感受编译器报错信息

**验收标准**：
- [ ] 至少支持 `--help`、`--version`、必选参数、可选参数
- [ ] 错误输入有友好提示（不是 panic）
- [ ] 代码通过 `cargo clippy` 无警告

---

## Phase 2：借用、生命周期、错误处理（Week 3-4）

### 🎯 目标
- 理解借用检查器的"脾气"
- 能在简单场景下使用生命周期标注
- 抛弃"用异常/忽略错误"的 C++ 习惯

### 📚 必读
- The Rust Book 第 5-9 章（结构体、枚举与模式匹配、集合、错误处理、泛型）
- Rustlings：`strings`、`ownership`、`references`、`options`

### 🧠 关键知识点

**借用规则**（C++ 程序员最容易翻车的部分）：
```rust
let mut s = String::from("hello");
let r1 = &s;        // OK
let r2 = &s;        // OK，多个不可变借用
let r3 = &mut s;    // ❌ 已经有不可变借用了
```

**生命周期**：
- 大多数情况编译器自动推断
- 显式标注主要出现在：**结构体持有引用**、**函数返回引用**
- 早期**逃生舱**：直接返回 `String` 而非 `&str`

**错误处理**：
```rust
// C++ 习惯 → ❌ 不要用 unwrap
let f = File::open("x.txt").unwrap();

// Rust 习惯 → ✅ 用 ? 或 match
let f = File::open("x.txt")?;
```

### 💻 周末项目：文件批量重命名工具
**功能**：
- 扫描目录下所有文件
- 按规则（正则/编号/日期）批量重命名
- 支持 dry-run 模式

**涉及知识点**：
- `std::fs`、`std::path::Path`
- `regex` crate
- `Result` + `?` 透传错误
- 第一次写自己的错误类型（`thiserror`）

**验收标准**：
- [ ] 不在 main 里用 `unwrap`
- [ ] 定义自己的 `Error` 类型（用 `thiserror`）
- [ ] 重命名失败不会让整个程序崩溃
- [ ] 有简单的单元测试

---

## Phase 3：泛型、Trait、智能指针（Week 5-6）

### 🎯 目标
- 把"模板"思维转换到"trait"思维
- 理解什么时候该用 `Box`/`Rc`/`Arc`/`Mutex`
- 写出 Rust 风格的迭代器链

### 📚 必读
- The Rust Book 第 10 章（泛型、Trait、生命周期）
- Rustlings：`modules`、`traits`、`collections`、`iterators`

### 🧠 C++ vs Rust 对比

| 概念 | C++ | Rust |
|------|-----|------|
| 多态 | 虚函数 + vtable | Trait object（`dyn Trait`）|
| 模板 | `template<typename T>` | `impl Trait` + Trait bound |
| 编译期分发 | 模板 | 静态分发（默认）|
| 共享所有权 | `shared_ptr` | `Rc<T>`（单线程）/ `Arc<T>`（多线程）|
| 内部可变性 | `mutable` 成员 | `RefCell<T>` / `Mutex<T>` |

**关键警告（针对 C++ 程序员）**：
```rust
// ❌ 千万别这么写
let data = Arc::new(Mutex::new(HashMap::new()));

// ✅ 先问"真的需要共享吗"
fn process(data: &HashMap<K, V>) { ... }
```

### 💻 周末项目：简单 JSON 库
**功能**：
- 实现 `parse(str) -> Result<Value, Error>`
- 实现 `to_string(&self) -> String`
- 支持字符串、数字、布尔、null、数组、对象

**涉及知识点**：
- 递归数据结构（`Value` 枚举）
- Trait 实现（`Display`、`From`、`PartialEq`）
- 迭代器组合（解析字符串时）
- 单元测试 + 集成测试

**验收标准**：
- [ ] 不使用 `unsafe`
- [ ] 公开 API 有完整文档注释（`///`）
- [ ] 单元测试覆盖率 > 80%
- [ ] 用 `cargo test` 跑通

---

## Phase 4：模块化、Cargo 生态、发布（Week 7-8）

### 🎯 真相
Rust 的杀手锏是**工具链 + 生态**，不是语言本身。这一阶段重点不是新语法，而是把 cargo / crates.io / 测试 / 文档这套玩溜。

### 📚 必读
- The Rust Book 第 11-14 章（自动化测试、Cargo 工作空间、智能指针、闭包）
- [Cargo Book](https://doc.rust-lang.org/cargo/) 关键章节

### 🧠 必会的 cargo 命令

```bash
cargo new --lib mylib        # 创建库
cargo add tokio --features full  # 加依赖
cargo test --doc             # 跑文档测试
cargo bench                  # 跑 benchmark
cargo clippy -- -D warnings  # 把警告当错
cargo fmt --check            # 格式化检查
cargo publish --dry-run     # 模拟发布
```

### 💻 周末项目：发布一个真正的小 crate 到 crates.io

**推荐方向**（挑一个你最熟的）：
- 文件 hash 批量校验工具（用 `sha2`、`walkdir`）
- 简单的 markdown 链接检查器
- HTTP 接口健康检查器
- 你日常 C++ 项目里某个小工具的 Rust 版

**关键步骤**：
1. `cargo new --lib`
2. 写库 + 写 `examples/`
3. 写完整文档（`///` 注释能直接生成 MD）
4. 写测试（单元 + 集成 + doc test）
5. `cargo publish --dry-run` 验证
6. **真发布到 crates.io**（别怕，全球开发者都能看到）

**验收标准**：
- [ ] crate 发布成功
- [ ] README.md 完整（crates.io 会展示）
- [ ] 至少 1 个 example
- [ ] `cargo doc --no-deps --open` 能看到漂亮文档
- [ ] GitHub Action 自动跑测试

---

## Phase 5：并发 + 异步（Week 9-10）

### 🎯 目标
- 理解 Rust 并发模型和 C++ 的本质差异
- 写出第一个真正的 async Rust 程序
- 理解 `Send`/`Sync` 标记的意义

### 📚 必读
- [Rust Async Book](https://rust-lang.github.io/async-book/) 前 4 章
- [Tokio Tutorial](https://tokio.rs/tokio/tutorial) 基础章节
- The Rust Book 第 16 章（并发）

### 🧠 关键概念对比

| 场景 | C++ 方案 | Rust 方案 |
|------|---------|----------|
| 启动线程 | `std::thread::spawn` | 同上 |
| 共享状态 | `std::mutex` + `std::lock_guard` | `std::sync::Mutex` + 自动 guard |
| 跨线程发送数据 | 自己处理生命周期 | `std::sync::mpsc::channel` |
| 数据竞争 | 编译期不检查 | **编译期就拒绝** |
| 异步 | callback / coroutine / asio | `async/await` + runtime（Tokio）|

**`Send`/`Sync` 标记**（Rust 杀手锏）：
```rust
fn spawn<T: Send + 'static>(t: T) { ... }
// 任何不满足 Send 的类型，编译器拒绝你跨线程传
// 几乎消灭了整类 data race
```

### 💻 周末项目：多线程文件下载器
**功能**：
- 读 URL 列表
- 并发下载（可配置并发数）
- 显示进度条
- 失败重试

**涉及知识点**：
- `tokio::spawn` 启动任务
- `tokio::sync::Semaphore` 控制并发
- `reqwest` 异步 HTTP 客户端
- `indicatif` 进度条
- `tokio::select!` 处理超时

**验收标准**：
- [ ] 支持并发数配置
- [ ] 单个下载失败不影响其他
- [ ] 进度条实时更新
- [ ] 不使用 `unwrap`

---

## Phase 6：FFI 实战 + Unsafe 边界（Week 11-12）

### 🎯 目标
- 在 Rust 中调用 C/C++ 库
- 理解什么时候**必须**用 `unsafe`
- 学会用 Rust **包装** C++ 库，给上层提供安全 API

### 📚 必读
- [The Rustonomicon](https://doc.rust-lang.org/nomicon/) 前 4 章
- [Rust FFI 指南](https://rust-lang.github.io/nomicon/ffi.html)
- `bindgen` 文档

### 🧠 关键概念

**`unsafe` 不是"绕过检查器"，是"和编译器签合同"**：
```rust
// unsafe 块：你向编译器承诺"我保证这些不变式"
unsafe {
    let ptr = malloc(size);
    // 忘记 free → 内存泄漏（C 风格）
    // free 后使用 → UB
}
```

**C++ 程序员最容易犯的错**：
- `unsafe` 块越写越大
- 自己实现链表/树（99% 的情况 `Vec`/`BTreeMap` 更好）
- 优化"看上去可以 unsafe 加速"的地方（先 profile）

### 💻 周末项目：包装你熟悉的 C++ 库
**两种路线任选**：

**路线 A：包装纯 C 库**
- 选一个你熟悉的 C 库（SQLite、cURL、libpng、zstd）
- 用 `bindgen` 自动生成绑定
- 在 Rust 中提供更安全的封装
- 例如：把 `sqlite3_exec` 包装成返回 `Vec<Row>` 的函数

**路线 B：包装 C++ 库**
- 用 `cxx` crate（推荐）或 `autocxx`
- 暴露 C++ 类为 Rust 类型
- 在 Rust 侧提供 `Drop` 实现，确保资源释放

**验收标准**：
- [ ] unsafe 块有详细注释说明不变式
- [ ] 上层 API 全部 safe
- [ ] 有内存泄漏测试（`valgrind` 或 `miri`）
- [ ] README 写清楚 FFI 的边界

---

## 贯穿全程的几条"军规"

### 1. 🚫 暂时别碰的事
- `unsafe` —— 前 8 周零使用
- 复杂宏（`macro_rules!` 后期再看）
- Trait 高级用法（关联类型、GAT）
- 嵌入式/裸金属（学习成本高，先打基础）

### 2. ✅ 每天必做
- 写代码 30 分钟 + 看别人的 Rust 代码 30 分钟
- **推荐订阅**：This Week in Rust（周报）
- **GitHub 关注**：tokio、serde、clap 仓库的 release notes

### 3. 🔧 工具配置
```bash
# 必装
rustup update stable
rustup component add clippy rustfmt rust-analyzer
cargo install cargo-edit cargo-watch cargo-audit

# VSCode 必装插件
- rust-analyzer
- Even Better TOML
- CodeLLDB（调试）
```

### 4. 📊 进度跟踪
- 每个周末完成项目后，**写一篇短笔记**（200-500 字）
- 记录：今天学到的 / 卡住的 / 编译器教我的
- 12 周后回头看，会发现自己蜕变

### 5. 💡 心法
> **把编译器当 mentor，不是敌人。**  
> **把所有权当约束，不是负担。**  
> **用 safe Rust 写一切，unsafe 是最后的手段。**

---

## 12 周后的你

- ✅ 能独立用 Rust 写中等复杂度的应用
- ✅ 理解 Rust 生态的核心 crate（tokio/serde/clap/axum 等）
- ✅ 能在 C++ 项目里**渐进引入 Rust**（通过 FFI 或独立服务）
- ✅ 能在团队里 Review 别人的 Rust 代码
- ✅ 知道什么时候**不该**用 Rust

**下一步**（可选方向）：
- 🌐 Web 后端（axum / actix-web）
- 🖥️ 嵌入式（`embedded-hal` 生态）
- 🎮 游戏（Bevy / Fyrox）
- 🤖 AI 推理服务（`candle` / `tch-rs`）
- ⚙️ 系统工具（`ripgrep` 风格的小工具）

---

## 推荐资源汇总

| 资源 | 链接 | 适用阶段 |
|------|------|---------|
| The Rust Book | https://doc.rust-lang.org/book/ | 全程 |
| Rust by Example | https://doc.rust-lang.org/rust-by-example/ | Phase 1-2 |
| Rustlings | https://github.com/rust-lang/rustlings | Phase 1-2 |
| Programming Rust (O'Reilly) | 实体书 | Phase 3-4 |
| Zero to Production | https://www.zero-to-production.com/ | Phase 4-5 |
| Rust Async Book | https://rust-lang.github.io/async-book/ | Phase 5 |
| Tokio Tutorial | https://tokio.rs/tokio/tutorial | Phase 5 |
| The Rustonomicon | https://doc.rust-lang.org/nomicon/ | Phase 6 |
| Jon Gjengset YouTube | https://www.youtube.com/@jonhoo | 进阶全程 |
| This Week in Rust | https://this-week-in-rust.org/ | 持续订阅 |

---

> **最后一句**：12 周后，你不是"会写 Rust 的 C++ 程序员"，而是**两个都会的工程师**。这份技能组合在市场上的稀缺度，懂的都懂。开始吧 🚀
