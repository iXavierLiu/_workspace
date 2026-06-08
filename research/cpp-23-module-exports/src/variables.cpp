//
// Module implementation unit: a fully private variable.
// (Exported constants are defined inline in variables.cppm.)
module core;

namespace core {

// ---- private: not declared in lib.cppm, not visible to importers ----
inline constexpr double kPi = 3.141592653589793;

inline int call_count = 0;  // private mutable state

} // namespace core
