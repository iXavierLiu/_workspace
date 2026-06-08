//
// Primary module interface for `core`.
// This file's only job is to aggregate and re-export the partitions
// that make up the public API. All actual declarations live in
// `src/<name>.cppm` partition files.
export module core;

// Re-export each partition. Importers of `core` see the union of all
// `export`ed names from these partitions.
export import :functions;
export import :variables;
export import :classes;
export import :structs;
export import :enums;
