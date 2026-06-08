//
// Module partition: struct declaration.
module;

export module core:structs;

export namespace core {

struct Point {
    double x = 0.0;
    double y = 0.0;

    auto length() const -> double;
};

} // namespace core
