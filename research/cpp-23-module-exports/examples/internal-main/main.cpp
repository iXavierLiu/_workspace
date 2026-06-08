//
// Internal demo program. Part of the `demo` project's build.
// Exercises every public API of the `core` module, including the
// PIMPL "fully invisible" Widget (copy / move / call_count).

import core;

#include <print>
#include <utility>   // std::move

int main() {
    // --- free functions ---
    std::println("add(1, 2) = {}", core::add(1, 2));
    std::println("{}", core::greet("world"));

    // --- exported variables ---
    std::println("core version: {}.{}",
                 core::kVersionMajor, core::kVersionMinor);

    // --- exported struct ---
    core::Point p{3.0, 4.0};
    std::println("Point({}, {}) length = {}", p.x, p.y, p.length());

    // --- exported class: PIMPL Widget ---
    // 1. default constructor
    core::Widget w0;
    std::println("Widget{} id = {}, label = '{}', calls = {}",
                 0, w0.id(), w0.label(), w0.call_count());

    // 2. converting constructor
    core::Widget w{42};
    w.set_label("hello");
    std::println("Widget id = {}, label = '{}', calls = {}",
                 w.id(), w.label(), w.call_count());

    // 3. set_label triggers a tracked call -- call_count() goes up
    w.set_label("again");
    w.set_label("third");
    std::println("Widget after 3 set_label calls: calls = {}", w.call_count());

    // 4. copy constructor
    core::Widget w_copy{w};
    std::println("Widget copy: id = {}, label = '{}', calls = {}",
                 w_copy.id(), w_copy.label(), w_copy.call_count());

    // 5. copy assignment
    core::Widget w_assigned;
    w_assigned = w;
    std::println("Widget copy-assigned: id = {}", w_assigned.id());

    // 6. move constructor
    core::Widget w_moved{std::move(w)};
    std::println("Widget moved: id = {}, label = '{}'",
                 w_moved.id(), w_moved.label());

    // 7. move assignment
    core::Widget w_move_assigned;
    w_move_assigned = std::move(w_copy);
    std::println("Widget move-assigned: id = {}", w_move_assigned.id());

    // 8. static method
    std::println("default_label = '{}'", core::Widget::default_label());

    // --- exported enum ---
    std::println("Color::Red name = {}", core::color_name(core::Color::Red));

    return 0;
}
