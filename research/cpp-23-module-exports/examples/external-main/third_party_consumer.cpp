//
// Third-party consumer of the `core` module from the installed `demo`
// package. Verifies that an external project can:
//   - find_package(demo CONFIG)
//   - target_link_libraries(... demo::core)
//   - `import core;` and use every exported name
//   - get a private name rejected (i.e. module privacy is preserved)

import core;

#include <print>
#include <utility>   // std::move

int main() {
    // --- free functions ---
    std::println("core::add(7, 35) = {}", core::add(7, 35));
    std::println("{}", core::greet("third-party"));

    // --- variables ---
    std::println("core version: {}.{}",
                 core::kVersionMajor, core::kVersionMinor);

    // --- struct ---
    core::Point p{6.0, 8.0};
    std::println("Point({}, {}) length = {}", p.x, p.y, p.length());

    // --- class: PIMPL Widget, full API tour ---
    core::Widget w_default;
    std::println("Widget{} id = {}, label = '{}', calls = {}",
                 0, w_default.id(), w_default.label(), w_default.call_count());

    core::Widget w{99};
    w.set_label("from-tests");
    w.set_label("again");
    w.set_label("third");
    std::println("Widget id = {}, label = '{}', calls = {}",
                 w.id(), w.label(), w.call_count());

    // copy
    core::Widget w_copy{w};
    std::println("Widget copy: id = {}, calls = {}",
                 w_copy.id(), w_copy.call_count());

    // copy assignment
    core::Widget w_assigned;
    w_assigned = w;
    std::println("Widget copy-assigned: id = {}", w_assigned.id());

    // move
    core::Widget w_moved{std::move(w)};
    std::println("Widget moved: id = {}", w_moved.id());

    // move assignment
    core::Widget w_move_assigned;
    w_move_assigned = std::move(w_copy);
    std::println("Widget move-assigned: id = {}", w_move_assigned.id());

    // static
    std::println("default_label = '{}'", core::Widget::default_label());

    // --- enum ---
    std::println("Color::Blue name = {}", core::color_name(core::Color::Blue));

    return 0;
}
