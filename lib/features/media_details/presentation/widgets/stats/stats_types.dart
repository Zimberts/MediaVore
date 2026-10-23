import 'package:flutter/widgets.dart';
import 'package:mediavore/core/l10n/l10n.dart';

enum StatsMetric { entries, runtime }

enum StatsScope { allTime, specificYear, specificMonth }

String statsMetricLabel(BuildContext context, StatsMetric metric) =>
    metric == StatsMetric.entries
    ? context.l10n.statsMetricLogs
    : context.l10n.statsMetricTime;
