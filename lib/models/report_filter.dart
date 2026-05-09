import 'package:flutter/material.dart' show DateTimeRange;

enum ReportTimeRange { today, week, month, all }

class ReportFilter {
  final ReportTimeRange range;
  final String? categoryId;

  ReportFilter({this.range = ReportTimeRange.all, this.categoryId});

  DateTimeRange? get dateTimeRange {
    final now = DateTime.now();
    switch (range) {
      case ReportTimeRange.today:
        return DateTimeRange(start: DateTime(now.year, now.month, now.day), end: now);
      case ReportTimeRange.week:
        return DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
      case ReportTimeRange.month:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      case ReportTimeRange.all:
        return null;
    }
  }
}
