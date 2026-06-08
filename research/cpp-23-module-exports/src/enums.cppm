//
// Module partition: enum declaration + helper.
module;

#include <string_view>

export module core:enums;

export namespace core {

enum class Color : int {
    Red   = 0,
    Green = 1,
    Blue  = 2,
};

auto color_name(Color c) -> std::string_view;

} // namespace core
