import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// TMDB page where a user creates their API key / read access token.
final Uri tmdbApiSettingsUri = Uri.parse(
  'https://www.themoviedb.org/settings/api',
);

/// Opens [uri] outside the app; returns whether it worked.
typedef UrlOpener = Future<bool> Function(Uri uri);

Future<bool> _openExternally(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('[TmdbCredentialPage] launchUrl failed: $e');
    return false;
  }
}

/// Lets the user get, paste and verify a TMDB credential before saving it.
///
/// With [onboarding] it is the first-launch screen (explanation, "Skip for
/// now"); otherwise it is the Settings editor. Pops `true` once a credential
/// was saved (or removed), `false`/`null` when the user left without saving.
class TmdbCredentialPage extends StatefulWidget {
  final bool onboarding;

  /// Overridable for tests; defaults to `url_launcher`.
  final UrlOpener openUrl;

  const TmdbCredentialPage({
    super.key,
    this.onboarding = false,
    this.openUrl = _openExternally,
  });

  @override
  State<TmdbCredentialPage> createState() => _TmdbCredentialPageState();
}

class _TmdbCredentialPageState extends State<TmdbCredentialPage> {
  late final TextEditingController _controller;
  bool _obscure = true;
  bool _verifying = false;

  /// Why the last check failed; `null` before any check.
  SearchErrorType? _checkError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<SettingsProvider>().tmdbApiKey,
    )..addListener(_onTextChanged);
    _lastText = _controller.text;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _lastText = '';

  void _onTextChanged() {
    // Selection-only changes also notify; react to text edits only.
    if (_controller.text == _lastText) return;
    _lastText = _controller.text;
    // Rebuild for the button state; a stale error must not stick to a new key.
    setState(() => _checkError = null);
  }

  Future<void> _openTmdb() async {
    final opened = await widget.openUrl(tmdbApiSettingsUri);
    if (opened || !mounted) return;
    final url = tmdbApiSettingsUri.toString();
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.tmdbCredentialLinkCopied(url))),
    );
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _verifyAndSave() async {
    final credential = _controller.text.trim();
    if (credential.isEmpty || _verifying) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _verifying = true;
      _checkError = null;
    });
    final error = await context.read<SearchProvider>().validateTmdbCredential(
      credential,
    );
    if (!mounted) return;
    setState(() {
      _verifying = false;
      _checkError = error;
    });
    if (error == null) await _save(credential, verified: true);
  }

  Future<void> _save(String credential, {required bool verified}) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l10n = context.l10n;
    await context.read<SettingsProvider>().setTmdbApiKey(credential);
    if (verified) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.tmdbCredentialSaved)));
    }
    if (mounted) navigator.pop(true);
  }

  /// Message shown under the field for [_checkError].
  String? _errorText(AppLocalizations l10n) {
    final error = _checkError;
    if (error == null) return null;
    if (error == SearchErrorType.invalidApiKey ||
        error == SearchErrorType.missingApiKey) {
      return l10n.tmdbCredentialInvalid;
    }
    return l10n.tmdbCredentialCheckFailed(searchErrorMessage(error, l10n));
  }

  /// TMDB couldn't be reached, so the key is neither good nor bad.
  bool get _checkInconclusive =>
      _checkError != null &&
      _checkError != SearchErrorType.invalidApiKey &&
      _checkError != SearchErrorType.missingApiKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final hasText = _controller.text.trim().isNotEmpty;
    final hasStoredKey = context.select<SettingsProvider, bool>(
      (s) => s.tmdbApiKey.isNotEmpty,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.onboarding
              ? l10n.tmdbOnboardingTitle
              : l10n.settingsTmdbCredential,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(l10n.tmdbOnboardingWhy, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            Text(l10n.tmdbOnboardingStepGetKey),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const Key('tmdb_open_api_page'),
                icon: const Icon(Icons.open_in_new),
                label: Text(l10n.tmdbOnboardingOpenTmdb),
                onPressed: _openTmdb,
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.tmdbOnboardingStepPaste),
            const SizedBox(height: 12),
            TextField(
              key: const Key('tmdb_credential_field'),
              controller: _controller,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              enabled: !_verifying,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _verifyAndSave(),
              decoration: InputDecoration(
                hintText: l10n.tmdbCredentialHint,
                border: const OutlineInputBorder(),
                errorText: _errorText(l10n),
                errorMaxLines: 3,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: const Key('tmdb_credential_visibility'),
                      tooltip: _obscure
                          ? l10n.tmdbCredentialShow
                          : l10n.tmdbCredentialHide,
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    IconButton(
                      key: const Key('tmdb_credential_paste'),
                      tooltip: l10n.tmdbCredentialPaste,
                      icon: const Icon(Icons.content_paste),
                      onPressed: _verifying ? null : _paste,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('tmdb_credential_verify'),
              icon: _verifying
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(
                _verifying
                    ? l10n.tmdbCredentialVerifying
                    : l10n.tmdbCredentialVerifyAndSave,
              ),
              onPressed: hasText && !_verifying ? _verifyAndSave : null,
            ),
            if (_checkInconclusive && hasText)
              TextButton(
                key: const Key('tmdb_credential_save_anyway'),
                onPressed: () =>
                    _save(_controller.text.trim(), verified: false),
                child: Text(l10n.tmdbCredentialSaveAnyway),
              ),
            if (widget.onboarding)
              TextButton(
                key: const Key('tmdb_credential_skip'),
                onPressed: _verifying
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: Text(l10n.tmdbCredentialSkip),
              )
            else if (hasStoredKey)
              TextButton(
                key: const Key('tmdb_credential_remove'),
                onPressed: _verifying ? null : () => _save('', verified: false),
                child: Text(l10n.tmdbCredentialRemove),
              ),
          ],
        ),
      ),
    );
  }
}
