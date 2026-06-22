/// Why the file exists:
/// Immutable pagination query and response wrappers.
/// Allows standard pagination calculations throughout the repositories layer.
library;

class PaginationParams {
  final int page;
  final int limit;

  const PaginationParams({
    this.page = 1,
    this.limit = 20,
  });

  int get offset => (page - 1) * limit;
}

class PaginatedList<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int limit;

  const PaginatedList({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.limit,
  });

  bool get hasNextPage => (page * limit) < totalCount;
  bool get hasPreviousPage => page > 1;
}
