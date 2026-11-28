import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/app_language.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_segmented.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/pages/tmdb_credential_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mediavore/features/settings/presentation/utils/data_import_flow.dart';
import 'package:provider/provider.dart';

/// Multi-step onboarding flow shown on first launch, or in [reviewOnly] mode
/// from Settings ("Review introduction") to replay the Welcome & Tour steps.
class OnboardingPage extends StatefulWidget {
  /// When `true`, only shows Welcome and Tour without touching the TMDB key
  /// or backup import steps.
  final bool reviewOnly;

  /// Overridable for tests; passed through to [TmdbCredentialPage].
  final UrlOpener? openUrl;

  const OnboardingPage({super.key, this.reviewOnly = false, this.openUrl});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const int _tourCardCount = 3;

  int _step = 0;
  int _tourPage = 0;
  bool _isReadingBackup = false;
  late final PageController _tourController;

  @override
  void initState() {
    super.initState();
    _tourController = PageController();
  }

  @override
  void dispose() {
    _tourController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    if (!widget.reviewOnly) {
      await context.read<SettingsProvider>().setOnboardingCompleted(true);
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _handleBack() {
    if (_step == 1 && _tourPage > 0) {
      _tourController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  Future<void> _handleTourNext() async {
    if (_tourPage < _tourCardCount - 1) {
      await _tourController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }
    if (widget.reviewOnly) {
      await _finishOnboarding();
    } else {
      setState(() => _step = 2);
    }
  }

  Future<void> _handleImport() async {
    final imported = await importBackupWithPreview(
      context,
      context.read<SearchProvider>(),
      onReadingChanged: (reading) {
        if (mounted) setState(() => _isReadingBackup = reading);
      },
    );
    if (imported && mounted) {
      await _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final totalSteps = widget.reviewOnly ? 2 : 4;

    return PopScope(
      canPop: widget.reviewOnly,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: _step > 0
              ? IconButton(
                  key: const Key('onboarding_back'),
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _handleBack,
                )
              : null,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < totalSteps; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == _step ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i <= _step
                        ? colors.primary
                        : colors.text2.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ],
          ),
          centerTitle: true,
          actions: [
            TextButton(
              key: const Key('onboarding_skip'),
              onPressed: _isReadingBackup ? null : _finishOnboarding,
              child: Text(l10n.onboardingSkip),
            ),
          ],
        ),
        body: switch (_step) {
          0 => _WelcomeStep(
            key: const Key('onboarding_step_welcome'),
            onStart: () => setState(() => _step = 1),
          ),
          1 => _TourStep(
            key: const Key('onboarding_step_tour'),
            controller: _tourController,
            currentPage: _tourPage,
            isLastActionDone: widget.reviewOnly,
            onPageChanged: (page) => setState(() => _tourPage = page),
            onNext: _handleTourNext,
          ),
          2 => TmdbCredentialPage(
            key: const Key('onboarding_step_tmdb'),
            onboarding: true,
            embedded: true,
            openUrl: widget.openUrl ?? const TmdbCredentialPage().openUrl,
            onDone: (_) {
              if (mounted) setState(() => _step = 3);
            },
          ),
          _ => _ImportStep(
            key: const Key('onboarding_step_import'),
            isReading: _isReadingBackup,
            onImport: _handleImport,
            onSkip: _finishOnboarding,
          ),
        },
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  final VoidCallback onStart;

  const _WelcomeStep({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: colors.primary.withValues(alpha: 0.12),
                      child: Icon(
                        Icons.movie_filter_outlined,
                        size: 44,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.onboardingWelcomeTitle,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.onboardingWelcomeBody,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.text2,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      l10n.settingsLanguage,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.text2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppSegmented<AppLanguage?>(
                      key: const Key('onboarding_language_selector'),
                      segments: [
                        AppSegment(
                          value: null,
                          label: l10n.settingsLanguageSystem,
                        ),
                        for (final language in supportedAppLanguages)
                          AppSegment(
                            value: language,
                            label: language.nativeName,
                          ),
                      ],
                      selected: settings.appLanguageOverride,
                      onChanged: settings.setAppLanguage,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('onboarding_start'),
                onPressed: onStart,
                child: Text(l10n.onboardingStart),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TourStep extends StatelessWidget {
  final PageController controller;
  final int currentPage;
  final bool isLastActionDone;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onNext;

  const _TourStep({
    super.key,
    required this.controller,
    required this.currentPage,
    required this.isLastActionDone,
    required this.onPageChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final cards = [
      (
        icon: Icons.explore_outlined,
        title: l10n.onboardingTourDiscoverTitle,
        body: l10n.onboardingTourDiscoverBody,
      ),
      (
        icon: Icons.collections_bookmark_outlined,
        title: l10n.onboardingTourLibraryTitle,
        body: l10n.onboardingTourLibraryBody,
      ),
      (
        icon: Icons.person_outline,
        title: l10n.onboardingTourMeTitle,
        body: l10n.onboardingTourMeBody,
      ),
    ];

    final isLastCard = currentPage == cards.length - 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                key: const Key('onboarding_tour_pageview'),
                controller: controller,
                itemCount: cards.length,
                onPageChanged: onPageChanged,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return _TourCard(
                    icon: card.icon,
                    title: card.title,
                    body: card.body,
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == currentPage
                          ? colors.primary
                          : colors.text2.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('onboarding_tour_next'),
                onPressed: onNext,
                child: Text(
                  isLastCard && isLastActionDone
                      ? l10n.onboardingDone
                      : l10n.onboardingNext,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _TourCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        child: Card(
          elevation: 0,
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: colors.primary.withValues(alpha: 0.12),
                  child: Icon(icon, size: 36, color: colors.primary),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.text2,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImportStep extends StatelessWidget {
  final bool isReading;
  final VoidCallback onImport;
  final VoidCallback onSkip;

  const _ImportStep({
    super.key,
    required this.isReading,
    required this.onImport,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: colors.primary.withValues(alpha: 0.12),
                        child: Icon(
                          Icons.restore,
                          size: 40,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.onboardingImportTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.text,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.onboardingImportBody,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.text2,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('onboarding_import_button'),
                icon: isReading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.file_open_outlined),
                label: Text(l10n.onboardingImportButton),
                onPressed: isReading ? null : onImport,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                key: const Key('onboarding_import_skip'),
                onPressed: isReading ? null : onSkip,
                child: Text(l10n.onboardingImportSkip),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
