# cpp-module-test

一个用于验证 **C++23 modules** 各种细节的小型演示项目。
重点验证以下内容:

- 模块的**导入 / 导出**机制
- 声明与实现的**分离**
- 导出代码与私有代码的**可见性隔离**(四层粒度:命名空间 / 类型 / 类成员 / **PIMPL 完全不可见**)
- 一个标准 C++23 module 项目的**目录结构 + CMake 安装 + 第三方消费**完整工作流

> **关于"完全不可见"**:本项目用 **PIMPL** 模式(`Widget::Impl` 前向声明 +
> `std::unique_ptr<Impl>`)做到让 [`Widget`](main/src/main.cpp ) 类的所有实现细节——
> 字段、私有方法、辅助类(`InternalLogger`)、甚至类型本身(`Widget::Impl`)——
> 对 `import core;` 的消费者**完全不可见**。详见
> [层 4:PIMPL](#层-4pimpl完全不可见模式) 章节。

---

## 目录结构

```
cpp-module-test/                            # 项目根 (CMake project `demo`)
├── CMakeLists.txt                          # 根:project + install + 2 个子目录
├── CMakePresets.json                       # 根 preset 定义
├── CMakeUserPresets.json.example           # 用户自定义 preset 模板
├── .gitignore
├── cmake/
│   └── demoConfig.cmake.in                 # find_package(demo) 的模板
│
├── src/                                    # ✅ 计入根项目:`core` 库
│   ├── CMakeLists.txt                      # 库定义 + install
│   ├── core.cppm                           # 主接口(只做 export import 转发)
│   ├── functions.cppm      / functions-impl.cpp
│   ├── variables.cppm      / variables.cpp
│   ├── classes.cppm        / classes-impl.cpp
│   ├── structs.cppm        / structs-impl.cpp
│   ├── enums.cppm          / enums-impl.cpp
│   └── impl.cpp                              # 私有模块辅助
│
└── examples/
    ├── internal-main/                      # ✅ 计入根项目:自带 demo 程序
    │   ├── CMakeLists.txt
    │   └── main.cpp                          # import core;
    │
    └── external-main/                      # ❌ 不计入根项目:独立第三方消费者
        ├── CMakeLists.txt                    # find_package(demo)
        ├── CMakePresets.json                 # include 根 preset
        └── third_party_consumer.cpp          # import core;
```

**核心理念**:`src/` 暴露 `core` 模块;`internal-main` 用它做自带示例;
`external-main` 模拟一个**完全外部的下游项目**,只能通过 install + find_package 消费 `core`。

---

## 模块设计

### 命名约定

| 层 | 名字 |
|---|---|
| **CMake 项目** | `demo` |
| **命名模块** | `core` |
| **CMake 链接目标** | `demo::core`(在 `core` 命名空间下) |
| **C++ 命名空间** | `core`(与模块名一致) |
| **C++ 导入** | `import core;` |
| **CMake 消费** | `target_link_libraries(... demo::core)` |

> **设计选择**:模块名和 C++ 命名空间都叫 `core`,保持一致。
> 二者在 C++20 标准里是独立的,但**保持同名能让 import 后的代码更直观**
> (`import core;` + `core::add(...)`)。

### 文件分层

```
core.cppm                 # 主接口(export module core;)
                          #   只做: export import :xxx;
                          #   聚合所有分区的导出

functions.cppm            # 分区接口(export module core:functions;)
                          #   声明: free function
functions-impl.cpp        # 分区实现(module core; + import :functions;)
                          #   定义: free function
                          #   可以包含私有实体(不可见)

classes.cppm              # 分区接口(export module core:classes;)
classes-impl.cpp          # 分区实现 + 私有 class Logger

structs.cppm              # 分区接口(export module core:structs;)
structs-impl.cpp          # 分区实现 + 私有 struct InternalState

enums.cppm                # 分区接口(export module core:enums;)
enums-impl.cpp            # 分区实现 + 私有 enum InternalCode

variables.cppm            # 分区接口(导出常量,内联定义)
variables.cpp             # 私有变量 kPi / call_count

impl.cpp                  # 私有辅助:core::detail::to_upper 等
```

### 主接口的"瘦身"模式

`src/core.cppm` **不**包含任何实际声明,只做聚合:

```cpp
module;

#include <string>
#include <string_view>

export module core;

export import :functions;
export import :variables;
export import :classes;
export import :structs;
export import :enums;
```

> **好处**:`core.cppm` 永远不会膨胀,新增模块只需新建一个 `<name>.cppm` +
> `<name>-impl.cpp` + 在主接口加一行 `export import :<name>;`。

---

## 可见性矩阵(本项目验证的核心)

模块的可见性是**编译时由 `export` 关键字决定的**,与命名空间无关。
`import core;` 只能看到**主接口 `export module core;` 的导出符号 + 所有被
`export import :xxx;` 引入的分区的导出符号**。

### 导出(消费者可见)

| 类别 | 符号 | 声明位置 | 定义位置 |
|---|---|---|---|
| 函数 | `core::add(int, int) -> int` | `functions.cppm` | `functions-impl.cpp` |
| 函数 | `core::greet(string_view) -> string` | `functions.cppm` | `functions-impl.cpp` |
| 变量 | `core::kVersionMajor` | `variables.cppm`(inline) | — |
| 变量 | `core::kVersionMinor` | `variables.cppm`(inline) | — |
| 类 | `core::Widget` | `classes.cppm` | `classes-impl.cpp` |
| 结构体 | `core::Point` | `structs.cppm` | `structs-impl.cpp` |
| 枚举 | `core::Color` | `enums.cppm` | — |
| 函数 | `core::color_name(Color) -> string_view` | `enums.cppm` | `enums-impl.cpp` |

### 私有(消费者**不可**见)

下面这些符号**虽然定义在模块的 `.cpp` 文件里**(且通过 `module core;` 归属于 `core`),
但**没有在任何 `export` 上下文里声明**,所以对 `import core;` 的消费者隐藏。

| 符号 | 类型 | 位置 |
|---|---|---|
| `core::Widget::Impl` | class (PIMPL) | `classes-impl.cpp`(匿名命名空间) |
| `core::Widget::InternalLogger` | class (PIMPL 内部) | `classes-impl.cpp`(匿名命名空间) |
| `core::Widget::Impl::id`、`label_`、`call_history`、`secret_token`、`cached_value` | 字段 | `classes-impl.cpp` |
| `core::InternalState` | struct | `structs-impl.cpp` |
| `core::InternalCode` | enum | `enums-impl.cpp` |
| `core::detail::to_upper` | function | `impl.cpp` |
| `core::detail::kInternalMagic` | variable | `impl.cpp` |
| `kPi`, `call_count` | variable | `variables.cpp` |
| `internal_counter` | function | `functions-impl.cpp` 中的匿名命名空间 |

> **`Widget` 的 PIMPL 模式**:`Widget` 公开 API(构造函数、`id()`、`label()`、
> `set_label()`、`call_count()`)对消费者**可见**;但所有字段、所有私有方法、
> `Widget::Impl`、`Widget::InternalLogger` 都被 `Widget::Impl` 前向声明 +
> `std::unique_ptr<Impl>` 封装,**对消费者完全不可见**。详见下文层 4。

### 层 4:PIMPL——"完全不可见"模式

**目标**:导出 [`Widget`](main/src/main.cpp ) 这个类(类名 + 公开 API 可见),
但**所有实现细节**(字段、私有方法、辅助类)对消费者**完全不可见**——
连名字都写不出来。

**做法**:

1. **接口文件** [`classes.cppm`](src/classes.cppm )**只暴露公开 API**,
   用 `Impl` 前向声明 + `std::unique_ptr` 持有:

   ```cpp
   export class Widget {
   public:
       Widget();
       explicit Widget(int id);
       ~Widget();

       Widget(Widget const&);
       auto operator=(Widget const&) -> Widget&;

       Widget(Widget&&) noexcept;
       auto operator=(Widget&&) noexcept -> Widget&;

       auto id() const -> int;
       auto label() const -> std::string_view;
       auto set_label(std::string_view) -> void;
       auto call_count() const -> int;

       static auto default_label() -> std::string_view;

   private:
       struct Impl;                       // ← 前向声明,**不导出**
       std::unique_ptr<Impl> impl_;       // ← 8 字节,消费者看不到
   };
   ```

2. **实现文件** [`classes-impl.cpp`](src/classes-impl.cpp )**定义完整 `Impl`**
   (在匿名命名空间里)+ 实现 [`Widget`](main/src/main.cpp ) 方法,全部委托给 `impl_`:

   ```cpp
   namespace {
   struct Widget::Impl {
       int id = 0;
       std::string label;
       int call_count = 0;
       std::vector<std::string> call_history;
       std::array<char, 32> secret_token{};
       double cached_value = 0.0;
   };

   class InternalLogger { /* 完整定义,消费者完全不可见 */ };
   } // namespace

   Widget::Widget() : impl_(std::make_unique<Impl>()) {
       impl_->label = default_label();
   }
   // ...其他方法全部委托给 impl_->xxx
   ```

**消费者看到什么**:

```cpp
import core;

core::Widget w{42};          // ✅ OK
w.set_label("hello");        // ✅ OK
w.id(); w.label();           // ✅ OK
w.call_count();              // ✅ OK

// 全部 ❌ 编译失败
core::Widget::Impl* p;       // ❌ 'Impl' is not a member of 'Widget'
w.impl_;                     // ❌ 'impl_' is private
core::Widget::InternalLogger logger;  // ❌ 'InternalLogger' is not a member
```

**为什么"完全不可见"**:

| 层 | 消费者能"看到"吗? | 证据 |
|---|---|---|
| **C++ 源码** | ❌ 名字写不出 | 上面编译错误 |
| **模块 BMI** `core.pcm` | ❌ 导出符号表里**完全没有** `Widget::Impl` / `InternalLogger` | `strings core.pcm` / `nm` 都查不到 |
| **消费者 IR** | ❌ 看不到 | LTO 友好,跨 TU 完全独立 |
| **`libcore.a` 静态库** | ⚠️ ELF 符号**有** | 因为 [`Widget`](main/src/main.cpp ) 内部确实用了 `Impl` 方法,必须生成代码段 |

**最后一条限制**是 C++ 的物理事实:**任何被实际执行的代码都会有对应的机器码和符号**。
要想连 `libcore.a` 里都不出现 `Widget::Impl`,只能让 [`Widget`](main/src/main.cpp ) **不引用 `Impl`**——但这等于不用 PIMPL,回到了导出全部实现细节的境地。

**PIMPL 真正的价值**:

1. **ABI 稳定**:`Widget` 大小固定为 8 字节(一个指针)。改 `Impl` 内部(加字段、改算法)**不需要重编消费者**——只要公开 API 不变。
2. **编译防火墙**:改 `Impl` 实现,只有 [`classes-impl.cpp`](src/classes-impl.cpp ) 需要重编。
3. **二进制优化**:`Widget` 的所有内层调用都成为跨 TU 调用,优化器**仍能**在 LTO 时把它们全部内联回去——等价于"没有 PIMPL 时的最优性能",但源码层完全隔离。

### 验证可见性

`examples/external-main/third_party_consumer.cpp` 是这个项目的**核心验证程序**。
它能成功编译并运行,证明:

```cpp
import core;        // 导入 core 模块

core::add(7, 35);       // ✅ 可见:导出函数
core::greet("hi");      // ✅ 可见
core::kVersionMajor;    // ✅ 可见
core::Widget{99};       // ✅ 可见:PIMPL 类的公开 API
core::Point{1, 2};      // ✅ 可见
core::Color::Blue;      // ✅ 可见
core::color_name(...);  // ✅ 可见
```

而下面这些**如果**取消注释,**编译会失败**,证明它们对消费者不可见:

```cpp
core::Logger::instance().log("...");           // ❌ no member named 'Logger'
core::InternalState s{};                       // ❌ no type named 'InternalState'
auto x = core::detail::kInternalMagic;         // ❌ no member named 'detail'

// PIMPL 内部细节(层 4 "完全不可见")
core::Widget::Impl* p = ...;                   // ❌ no member 'Impl' in 'Widget'
w.impl_;                                       // ❌ member 'impl_' is private
```

---

## 关键设计要点

### 1. 全局模块片段(Global Module Fragment)

任何带 `module X;` 声明的翻译单元,如果要 `#include` 标准库头文件,**必须**用全局片段:

```cpp
module;                                   // ← 开始全局片段

#include <string>                         // ← 在这里 #include
#include <string_view>

module core;                              // ← 然后才是模块声明
```

否则 Clang 会把 `<string>` 等附加到命名模块,产生 ODR 冲突。

### 2. 声明与实现分离

**不要**把函数体写在 `core.cppm` 或 `*.cppm` 分区接口里。原因是:

- **多 TU 编译**:`.cpp` 实现单元是独立翻译单元,改实现不必重编所有 importer
- **可见性清晰**:接口文件只看得到声明,实现文件单独看

模式:

```cpp
// functions.cppm (接口)
export module core:functions;
export namespace lib {
    auto add(int, int) -> int;     // ← 只有声明
}

// functions-impl.cpp (实现)
module core;                       // ← 不写 export
import :functions;                 // ← 拉入分区的导出
namespace lib {
    auto add(int a, int b) -> int {  // ← 定义
        return a + b;
    }
}
```

### 3. 分区实现单元的"小技巧"

如果分区实现写成 `module core:functions;`,会和分区的 `.cppm` 冲突(两者都产出
`lib-functions.pcm`)。所以**实现单元用普通 `module core;` + `import :functions;`**:

```cpp
// 推荐:用 module core; + import :functions;
module core;
import :functions;
namespace lib {
    auto add(int, int) -> int { ... }
}

// 不推荐:用 module core:functions;  ← 与 functions.cppm 冲突
```

这样既能看到分区的导出声明,又不会触发 CMake 的 BMI 冲突。

### 4. CMake 模块注册

```cmake
target_sources(core PUBLIC
    FILE_SET CXX_MODULES
    BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}    # 包含根(模块扫描用)
    FILES
        core.cppm
        functions.cppm
        variables.cppm
        classes.cppm
        structs.cppm
        enums.cppm
)

target_sources(core PRIVATE
    impl.cpp
    variables.cpp
    functions-impl.cpp
    classes-impl.cpp
    structs-impl.cpp
    enums-impl.cpp
)
```

> **关键**:`FILE_SET CXX_MODULES` 只需要列**接口**文件(`.cppm`),
> `.cpp` 实现单元作为普通源文件添加。CMake 自动按 BMI 依赖排序编译。

### 5. install 时不复制 `.cpp`

`include/` 目录是给**公共头文件**用的,模块项目里 `include/demo/core/` 里
**只放 `.cppm`**,实现 `.cpp` **不安装**(它们已链入 `libcore.a`)。

```cmake
install(TARGETS core
    EXPORT demo-targets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}/demo
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}/demo
    FILE_SET CXX_MODULES
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/demo/core
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/demo
)
```

---

## 构建

需要 **CMake ≥ 3.30** 和 **Ninja**。

### 快速开始(根项目)

```bash
# 系统已有 ninja + clang
cmake --workflow clang-debug     # configure + build 一行搞定
./build/bin/main
```

### 列出所有 preset

```bash
cmake --list-presets=all
```

| Preset | 用途 |
|---|---|
| `default` | 默认(Ninja, Release, 系统编译器) |
| `clang-debug` | **推荐开发配置** |
| `clang-release` | **推荐发布配置** |
| `clang-relwithdebinfo` | 带调试符号的 release |
| `gcc-debug` / `gcc-release` | GCC 变体 |
| `external-main` | 第三方消费者配置 |

### 手工 build

```bash
cmake -S . -B build -G Ninja -DCMAKE_CXX_COMPILER=clang++
cmake --build build
./build/bin/main
```

---

## 安装

```bash
cmake --install build --prefix ./install
```

安装布局:

```
install/
├── bin/main                              # 可执行
├── include/demo/core/                    # 模块源(.cppm)
│   ├── core.cppm
│   ├── functions.cppm
│   └── ...
└── lib64/
    ├── demo/libcore.a                    # 静态库
    └── cmake/demo/                       # CMake 包配置
        ├── demoConfig.cmake
        ├── demo-config-version.cmake
        └── demo-targets.cmake
```

---

## 第三方消费(验证 install 可用性)

`examples/external-main/` 是**完全独立**的下游项目,不通过根 `add_subdirectory()`,
只能 `find_package(demo)` 拿到 `demo::core` 目标。

```bash
# 1. 先 install 根项目
cmake --install build --prefix ./install

# 2. 独立配置 + 构建第三方消费者
cd examples/external-main
cmake --preset external-main              # 自动指向 ../../install
cmake --build --preset external-main
./build/third_party_consumer
```

预期输出:

```
core::add(7, 35) = 42
Hello, third-party!
core version: 1.0
Point(6, 8) length = 10
Widget id = 99, label = from-tests
```

如果想验证**私有 entity 真的不可见**,在该文件的注释中取消任何一行 `core::Logger` /
`core::InternalState` / `core::detail::*` 的注释,重新编译会失败:

```
error: no member named 'Logger' in namespace 'core'
error: no type named 'InternalState' in namespace 'core'
error: no member named 'detail' in namespace 'core'
```

---

## 已知坑点(本项目踩过的)

### 1. `Unix Makefiles` 不支持 C++23 modules

CMake 报错:

> `The target named "core" has C++ sources that may use modules, but modules
> are not supported by this generator: Unix Makefiles`

**解决**:必须用 **Ninja** 生成器。

### 2. `#include` 必须在 `import` 之前

```cpp
// 错误
import core;
#include <print>     // ❌ 警告:include attaches to module

// 正确
import core;          // 或者:#include <print> 在 import 之前
```

### 3. `<string_view>` / `<string>` 等需要全局模块片段

带 `module X;` 的翻译单元如果 `#include <string>`,必须用全局片段:

```cpp
module;                  // ← 必须
#include <string>         // ← 这样 OK
module core;
```

### 4. `libstdc++` 没有 `import std;`

**当前日期 2026-06,libstdc++ 仍未提供 `std` 模块**。本项目用 `#include <print>` 代替
`import std;`。如果想用 `import std;`,需要切到 **libc++**:

```bash
sudo dnf install libcxx-devel libcxxabi-devel
```

然后在 CMake 中加:

```cmake
target_compile_options(core PUBLIC -stdlib=libc++)
target_link_options(core    PUBLIC -stdlib=libc++)
```

### 5. 命名空间与模块名可以独立

本项目目前让两者**保持一致**(都叫 `core`),是为了 `import core;` + `core::add(...)` 的写法更直观。
但二者在 C++20 标准里是**完全独立**的两件事:

- 模块名决定 `import X;` 时的名字
- C++ 命名空间决定符号 `core::Y` / `lib::Y` 的归属

你可以让一个叫 `core` 的模块把代码放在 `namespace lib { ... }` 里(之前的版本就是这样),这完全合法。

---

## 编译器与工具版本

| 工具 | 要求 |
|---|---|
| CMake | ≥ 3.30(本项目 `cmake_minimum_required(VERSION 3.30)`) |
| Ninja | 任意较新版本 |
| Clang | ≥ 19(完整 C++23 modules 支持) |
| GCC | ≥ 15(部分支持) |
| 标准库 | libc++ ≥ 19(用 `import std;` 时) / libstdc++ 任意(用 `#include` 时) |

本项目在以下环境验证通过:

- AlmaLinux 10 / Clang 21.1.8 / libstdc++ 15 / CMake 3.31.8 / Ninja 1.11
