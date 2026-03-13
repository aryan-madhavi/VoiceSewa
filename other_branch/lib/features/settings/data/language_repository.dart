import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/language_settings.dart';
import '../../auth/data/auth_repository.dart';

const _kLangKey = 'user_lang';

class LanguageRepository {
  LanguageRepository(this._prefs, this._authRepo);

  final SharedPreferences _prefs;
  final AuthRepository _authRepo;

  LanguageSettings load() {
    final lang = _prefs.getString(_kLangKey) ?? 'en-US';
    return LanguageSettings(lang: lang);
  }

  Future<void> save(LanguageSettings settings, {String? uid}) async {
    await _prefs.setString(_kLangKey, settings.lang);
    // Sync to Firestore if signed in
    if (uid != null) {
      await _authRepo.updateLang(uid, settings.lang);
    }
  }
}

// ── Providers ──────────────────────────────────────────────────────────────────

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in ProviderScope with SharedPreferences.getInstance()');
});

final languageRepositoryProvider = Provider<LanguageRepository>((ref) {
  return LanguageRepository(
    ref.watch(sharedPreferencesProvider),
    ref.watch(authRepositoryProvider),
  );
});

class LanguageSettingsNotifier extends AsyncNotifier<LanguageSettings> {
  @override
  Future<LanguageSettings> build() async {
    return ref.watch(languageRepositoryProvider).load();
  }

  Future<void> setLang(String langCode) async {
    final repo = ref.read(languageRepositoryProvider);
    final user = await ref.read(currentUserProvider.future);
    final updated = LanguageSettings(lang: langCode);
    await repo.save(updated, uid: user?.uid);
    state = AsyncData(updated);
  }
}

final languageSettingsProvider =
    AsyncNotifierProvider<LanguageSettingsNotifier, LanguageSettings>(
  LanguageSettingsNotifier.new,
);
