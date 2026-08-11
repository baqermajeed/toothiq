class PaginatedResult<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int total;

  const PaginatedResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  bool get hasNextPage => page * limit < total;
}
