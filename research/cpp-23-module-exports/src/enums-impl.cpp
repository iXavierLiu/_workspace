//
// Module implementation unit for partition `lib:enums`.
// Definition of `color_name` plus a fully private enum `InternalCode`.
module;

#include <string_view>

module core;
import :enums;

namespace core {

auto color_name(Color c) -> std::string_view {
    switch (c) {
        case Color::Red:   return "red";
        case Color::Green: return "green";
        case Color::Blue:  return "blue";
    }
    return "unknown";
}

// ---- private enum: not visible to importers of `core` ----
enum class InternalCode : int {
    Ok      = 0,
    Pending = 1,
    Failed  = 2,
};

} // namespace core
