//
// Module implementation unit for partition `lib:functions`.
// Definitions of the free functions declared in functions.cppm.
module;

#include <string>
#include <string_view>

module core;
import :functions;

namespace core {

auto add(int a, int b) -> int {
    return a + b;
}

auto greet(std::string_view name) -> std::string {
    return "Hello, " + std::string{name} + "!";
}

} // namespace core
