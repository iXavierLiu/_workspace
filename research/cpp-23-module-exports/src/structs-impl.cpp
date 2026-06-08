//
// Module implementation unit for partition `lib:structs`.
// Member function definition for `Point`, plus a fully private struct
// `InternalState`.
module;

#include <cmath>

module core;
import :structs;

namespace core {

// ---- exported Point: declaration in structs.cppm ----
auto Point::length() const -> double {
    return std::hypot(x, y);
}

// ---- private struct: not visible to importers of `core` ----
struct InternalState {
    int counter = 0;
    double last_value = 0.0;
};

} // namespace core
