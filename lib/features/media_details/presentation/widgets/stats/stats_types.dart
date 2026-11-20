import 'package:flutter/widgets.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/features/media_details/domain/entities/stats_types.dart';

export 'package:mediavore/features/media_details/domain/entities/stats_types.dart';

String statsMetricLabel(BuildContext context, StatsMetric metric) =>
    metric == StatsMetric.entries
    ? context.l10n.statsMetricLogs
    : context.l10n.statsMetricTime;
