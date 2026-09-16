<!-- project-brain:v1 -->
# PROJECT BRAIN — DoctorFilter

> **Status:** Android 2.0 özellik-tamam; FAZ A–I kapandı (marka logosu dahil). Sırada emülatör doğrulamaları T2–T15, sonra insan gerektirenler.
> **Phase:** BUILD · **Next:** T13 · **Updated:** 2026-09-16 · **Synced@:** 230292c
> **Goal:** v1 #25377c85 · **Goal status:** CONFIRMED

## 0. PROTOCOL

Binding for every AI working in this repo. Only the user edits §0 and §1. Section headings are machine anchors: never rename them. `brain.py` = `python <project-brain skill dir>/scripts/brain.py`; if unavailable, do its checks by hand.

### 0.1 What this file is
The single source of truth for this project. Chat history is disposable; this file is not. Cycle: **read → work → verify → update this file → commit → next.** If it is not written here, the next model does not know it.

### 0.2 Run loop (never stop early)
1. Session start: read header, §0, §1, §7 → run audit **A1** (§0.4).
2. Loop without pausing: pick task (§0.5) → do it → verify and close it (§0.8) → commit → immediately pick the next one. Never stop to report after a task. Never ask "shall I continue?". Never ask the user anything.
3. A §5 section fully closed → audit **A3**. No open tasks left (ignoring `[!]`) → audit **A4**. Audits that find problems create tasks and the loop continues.
4. Stop only when: **Phase: DONE** (A4 passed), or every remaining open task is `[!]` (then list them in §7). Before any stop: update §7, commit, push.
5. Context getting long is not a reason to stop: everything needed is in this file; after each commit keep only header, §0, §7 and the current task in mind. But if the harness warns the context/session is about to end → reach the next safe point (close or wip-commit the current task, update §7, commit+push). Never lose state mid-task.
6. One active session per project. Foreign commits or a moved `Synced@` = another worker was here: reconcile via A1 deep audit; never overwrite or revert their commits without evidence.

### 0.3 Token discipline (quality is never the trade)
- Read: header, §0, §1, §7 every session; other sections only when needed. Search (grep/glob) before opening files; open line ranges of big files; never re-read what you just wrote.
- Tool output: always filtered/limited (`tail`, `grep`, quiet flags). Never pull lockfiles, logs, build output or generated code into context.
- Batch independent tool calls in parallel.
- Chat: no preamble, no restating the task, no diff recaps; ≤3 lines. Detail belongs in this file.
- This file: terse fragments, `path:symbol` references instead of pasted code, each fact in one place. Exception: task specs (§0.7), audit evidence and revision rationale are explicit, never terse.
- Never write secrets, credentials, tokens or personal data into this file (it is committed and read by future models). Reference env var names only.
- Code: reuse existing code > stdlib > installed dependency > new code. Smallest diff that fixes the root cause. No speculative abstractions.
- Deliberate in proportion to tier: `[L]` act, `[M]` plan briefly, `[H]` think fully. Audits and revisions are always `[H]`.
- Never cut: correctness, running verification, audits, security, input validation, error handling that prevents data loss.

### 0.4 Audits (trust nothing unverified, including your predecessor)
Record every audit as an `AUDIT` row in §6: which audit, what was checked, result, task IDs created. Every finding becomes a task (§0.7) with `Note: from A<n>`.

**A0 — Creation** (right after this file is created, before any build task)
1. `brain.py check` passes with no FAIL; §4 matches reality.
2. Every §3 claim names the code that proves it; open 3 of them and confirm.
3. Traceability: every part of §2 missing or partial in §3 has a `GAP:` line naming task IDs; every acceptance criterion `AC<n>` is served by at least one task.
4. Executability probe: reread the first 5 open tasks as a model with zero chat history (or ask a cheap sub-agent to list what is ambiguous without doing them). Fix every ambiguity.

**A1 — Takeover** (every session start)
1. `brain.py check`; fix FAIL lines first. Its `NEXT:` line tells you what to do.
2. Sample: the last 3 closed tasks (check prints `VERIFY:`). For each: rerun `Done when`, read its diff (`git log --grep "T<id>"` → `git show`), confirm the diff really does what the task said, tests really assert, no debug/TODO leftovers, no unrelated edits.
3. Run the project's full test suite (and build/lint if present) once.
4. **Escalate to deep audit** if any of: a sample or the suite fails · commits outside protocol · map drift · goal hash changed · no previous `AUDIT` row · last closed tasks were done by a weaker model than you on `[M]`/`[H]` work. Deep audit = step 2 for every `[x]` since the last passing A1/A3/A4, plus spot-check §3 against code.
5. Wrong `[x]` → reopen as `[ ]` with `Note: reopened by A1 — <why>`, or add a fix task if other work already builds on it.
6. `Phase: DONE` and nothing new requested → steps 1–3 only; all pass → report done in ≤3 lines and stop.

**A2 — Task close** (every task; part of §0.8)
1. Run `Done when` yourself. A sub-agent's report is not verification.
2. Self-review your full diff: matches `Do`; edge cases and error paths handled; no unrelated edits; no debug/TODO leftovers; tests fail if the code is broken.
3. Tests/lint for the touched area pass (no regressions).
4. `[H]` tasks, security-relevant tasks and tasks done by sub-agents → independent review in a fresh context (sub-agent of at least the executor's tier) if the harness allows; otherwise a second self-review after rereading the task and the relevant §2 part.

**A3 — Milestone** (a §5 section just closed)
Full test suite + build. Compare that area of §3 with §2 in code; delete resolved `GAP:` lines; findings → tasks.

**A4 — Final** (no open tasks except `[!]`) — set `Phase: AUDIT`, then:
1. Clean build, full test suite, lint/typecheck: all pass.
2. Each `AC<n>`: prove it with a command or observable behaviour; tick it in §1 only with that evidence written in the `AUDIT` row.
3. §3 equals §2: no `GAP:` lines; walk §2 component by component and confirm each in code.
4. §1 constraints respected; nothing from "Out of scope" was built.
5. Whole-change review (`git diff <first brain commit>..HEAD`, area by area, fresh context if possible): security, error handling, dead code, duplication, leftover TODO/FIXME/debug, README/docs match reality.
6. `brain.py check` prints `OK`.
Any failure → tasks, `Phase: BUILD`, continue the loop. All pass → `Phase: DONE`, `Next: none`, summary in §7, commit `chore(brain): A4 final audit passed`.

### 0.5 Choosing and doing work
- One task at a time. Next = the `[~]` task if any, else the first `[ ]` in §5 order whose `Needs:` are all `[x]`. Mark it `[~] (claimed YYYY-MM-DD)` before starting.
- Everything must serve §1 and move §3 toward §2. A task that contradicts §1/§2 → do not do it; fix the plan via §0.9.
- Needs a human (credentials, payment, product/legal decision, destructive or irreversible action such as force-push, dropping data, prod deploy) → `[!] <reason>`, continue with the next task.
- Ambiguity → choose the conservative option, log an `ASSUMPTION` row in §6, continue.
- **Goal status: DRAFT** → only goal-independent tasks (map, audit, tests, bugs, build). Never build speculative features.

### 0.6 Discoveries while working (focus rule)
- **Blocks the current task** → add sub-task `T<id>.<n>` under it and do it now.
- **Serves the goal but does not block** → write a complete task (§0.7) under the matching §5 section, then **return to the current task immediately**. Do not start it; no "while I'm here" fixes.
- **Plan itself looks wrong** → finish or safely pause the current task, then apply §0.9.
- **Outside the goal** → one `OUT-OF-SCOPE` row in §6. Not a task.

### 0.7 Task format (write for a weaker model with zero chat history)
```
- [ ] T12 [L] Add Turkish date parser
  - Where: `src/utils/date.py` (new function next to `parse_iso`)
  - Do: 1) add `parse_tr_date(s: str) -> date` for "16.09.2026"; 2) raise `ValueError` on bad input; 3) add cases to `tests/test_date.py`
  - Done when: `pytest tests/test_date.py -q` passes
  - Needs: T11
```
- IDs are permanent: never renumber or reuse. New top-level task = highest ID + 1; sub-task = `T12.1`.
- Status: `[ ]` open · `[~]` in progress · `[x]` done · `[!]` blocked (reason) · `[-]` dropped (reason, e.g. `superseded by R2`).
- Tier: `[L]` mechanical, fully specified, no judgment · `[M]` clear spec, normal engineering · `[H]` design, ambiguity, security, audits, writing specs for others.
- `Where`, `Do`, `Done when` are mandatory for open tasks. Exact paths, symbol names, commands, expected output. Forbidden vague words: "etc.", "improve", "clean up", "as discussed", "handle properly". Cannot be that precise → tag `[H]` or split.
- `Done when` must be objectively checkable and must include a test or check that fails if the work is wrong.

### 0.8 Closing a task (all steps, one commit)
1. Audit A2 (§0.4). Fails → not done; fix, or reopen with a `Note:`.
2. Mark `[x] (YYYY-MM-DD, <model name>)`. Delete its `Where`/`Do` lines; keep `Done when`; add `→ <one-line result>` if useful.
3. Behaviour, interfaces, data flow or dependencies changed → update §3 (and its `GAP:` lines). Files added/removed/moved → update §4.
4. Header: Status, Phase, Next, Updated, and `Synced@` = `git rev-parse --short HEAD` taken **before** this commit.
5. Overwrite §7 (≤5 lines).
6. Commit code + this file together: `<type>(T<id>): <summary>` (feat/fix/refactor/test/docs/chore). Push to the current branch if a remote exists. Never force-push, never skip hooks. Push fails → keep the local commit, note it in §7, continue.
- Stopping mid-task → commit `wip(T<id>): <state>`, keep `[~]`, describe exactly what remains in §7.
- A task found broken after closing → reopen per §0.9a and repair with a new commit (`git revert` or smallest fix). Never rewrite history.
- No git → skip commits and git checks; everything else still applies.
- Brain-only commits (audits, revisions, goal changes): `docs(brain): <A<n>|R<n>|G<n>> <summary>`.

### 0.9 Changing the plan
**a) Task spec wrong or incomplete** (no architecture change): open task → edit in place and add `Note: revised YYYY-MM-DD — <why>`. Closed task whose result is wrong → reopen, or add a fix task if later work depends on it.

**b) Target architecture (§2) wrong** — any model may revise it autonomously, only through this gate:
1. Evidence, not taste: show that §2 cannot meet §1, violates a §1 constraint, or is demonstrably worse against §1 (cite files, measurements, docs, failing tests). "I would design it differently" is not evidence.
2. Never changes §1.
3. Reversing an earlier `DECISION`/`REVISION` requires new evidence that the earlier row did not have; cite that row.
4. Smallest revision that fixes the problem.
5. Log a `REVISION` row `R<n>`: problem + evidence, options considered, choice, impact.
6. Impact analysis over **every** task: keep · edit · drop as `[-] superseded by R<n>` · new tasks; closed work that no longer fits → migration/removal tasks.
7. Update §2, §3 `GAP:` lines, header; commit `docs(brain): R<n> <summary>`; continue the loop.

**c) Goal (§1) changed by the user** — in chat, or detected because `brain.py check` reports the goal hash changed:
1. If told in chat, write the new goal into §1 exactly as the user stated it (fill format gaps conservatively, log `ASSUMPTION`s).
2. Log a `GOAL-CHANGE` row `G<n>`: old goal summary → new goal summary. Header: `Goal: v<n+1> #<brain.py goal-hash>`, `Goal status: CONFIRMED`, `Phase: BUILD`.
3. Redesign §2 for the new goal (a REVISION per §0.9b, citing G<n>).
4. Impact analysis over every task as in b.6, including built features the new goal no longer wants (remove only if they conflict with the new goal or its constraints).
5. Run A0 steps 3–4 on the new plan. Commit `docs(brain): G<n> goal change`. Continue the loop.

**d) Goal itself looks flawed** (contradictory, impossible, clearly harmful to the user's intent): never edit §1. Log a `GOAL-CONCERN` row with evidence. Follow the most faithful feasible interpretation (logged as `ASSUMPTION`); tasks that truly cannot be done → `[!]`. Continue everything else.

### 0.10 Keeping this file small
When this file exceeds ~500 lines: move fully completed §5 sections to `PROJECT_BRAIN.archive.md` (append, dated) and leave one line `- [x] T1–T9 <section> → archive`. Move superseded §6 rows there too. Never archive open tasks, active decisions or the latest AUDIT row.

## 1. GOAL

DoctorFilter (`com.crazypenguin.doctorfilter`): ekranın yaydığı kısa dalga (mavi) ışığı Kelvin cinsinden **doğrulanabilir renk bilimiyle** azaltan, ekranı donanım minimumunun altına karartabilen, açık kaynak (GPL-3.0), veri toplamayan, premium kalitede göz konforu uygulaması. Önce Android (2.0 mağaza sürümü), sonra iOS ve Windows. 71 dil. Gelir: kullanıcıyı rahatsız etmeyen reklam + yalnızca **ömür boyu Pro** (abonelik yok), yalnızca mağazaların kendi ödeme sistemi.

**Acceptance criteria**
- [ ] AC1 Hiçbir ayar kaybolmaz: değer o an kalıcı; ekran değiştirip dönünce ve uygulamayı kapatıp açınca aynı (`flutter test` kalıcılık testleri + emülatörde soğuk açılış).
- [ ] AC2 Çevrilmemiş metin yok: 71 dil eksiksiz (`test/core/localization`, `test/presentation/providers/native_labels_test.dart`); RTL düzen doğru; saat biçimi locale'den.
- [ ] AC3 Açık ve koyu temada okunmayan yazı yok (her ekranın iki temada emülatör ekran görüntüsü).
- [ ] AC4 Hesaplar bilimsel ve testli; uydurma yüzde yok (`test/core/math`, `test/domain/entities`).
- [ ] AC5 Reklam ilk deneyimi bozmaz, Pro'da hiç görünmez, kalkınca boşluk kalmaz (`test/domain/entities/ad_policy_test.dart` + emülatörde Pro geçişiyle banner'ın kalkması).
- [ ] AC6 Bildirim kokpiti uygulamayı açmadan gerçek kontrol sağlar (emülatörde çip/eksen/aksiyon dokunuşları).
- [ ] AC7 Zamanlayıcı cihaz yeniden başlasa bile çalışır (emülatörde `adb reboot` sonrası alarmlar kurulu).
- [ ] AC8 Çökme yok; izin reddi, servis ve mağaza hataları anlaşılır mesajla (logcat'te FATAL yok, izin geri alma senaryosu).
- [ ] AC9 Erişilebilir: ekran okuyucu etiketleri, 48dp dokunma alanı, büyük yazıda taşma yok (`test/widget_test.dart` taşma testleri + uiautomator dump).
- [ ] AC10 Play, App Store ve Microsoft Store politikalarına uygun; yasak sağlık iddiası yok (§6 "yasak iddialar" satırı).
- [ ] AC11 Ana ekranda marka logosu: solda ikon, sağda iki renkli "doctorFilter", Pro ise sonda küçük üst simge PRO, altında slogan; splash'ta ikon.

**Constraints:** Flutter 3.47 / Dart 3.13, flutter_riverpod StateNotifier, clean architecture (core/domain/data/presentation). Her commit'te `flutter analyze` temiz, `flutter test` yeşil. **Güvenlik:** `.env`, `.env.local`, `android/key.properties`, `*.jks`, `*.keystore`, `*.p12`, `google-services.json`, `GoogleService-Info.plist` asla repoya girmez; `.gitignore` zayıflatılmaz; gerçek AdMob/ürün kimliği koda yazılmaz (`lib/core/config/env_config.dart` dart-define + Google test id fallback); proje sahibinin kişisel bilgisi hiçbir dosyaya yazılmaz. `migrate_working_dir/local_archive` (eski 1.x arşivi, gitignored) **taranmaz**; yalnızca adı bilinen logo/font dosyaları kopyalanabilir. Yasak iddialar: retinaya zarar/AMD, göz yorgunluğu/kuruluğu tedavisi, kilo, herhangi bir tedavi/tanı/önleme vaadi. Ürün kimliği `doctorfilter_pro_lifetime` her mağazada aynı. Android doğrulaması yerel emülatörle yapılır ("cihaz gerekir" gerekçesi yok). Commit mesajları `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>` ile biter; push `master`.
**Out of scope:** abonelik, kendi sunucu/hesap/analitik, mağaza dışı ödeme, iOS'ta diğer uygulamaların üzerinde filtre vaadi.
**Open questions:** none

## 2. TARGET ARCHITECTURE

- **Katmanlar:** `lib/core` (Kelvin motoru, tema, yerelleştirme, env) → `lib/domain` (saf entity/politika: FilterConfig, AdPolicy, ScheduleRule, ProStatus) → `lib/data` (prefs/SQLite/kanal + repository) → `lib/presentation` (Riverpod provider, ekranlar, widget, reklam).
- **Filtre modeli:** üç eksen kelvin/density/extraDim; bileşik alfa tavanı 0.92 (native `MAX_ALPHA 235`); Dart bileşik renk+alfa hesaplar, platformlar yalnızca çizer.
- **Kalıcılık:** bellekte tek kaynak + debounce'lu tam yazma; native tarafta alarm/servis için kopya (Dart kopyası kazanır, açılışta yeniden gönderilir).
- **Android native** (`kt/` = `android/app/src/main/kotlin/com/crazypenguin/doctorfilter/`): OverlayService (FGS specialUse), RemoteViews bildirim kokpiti, Hızlı Ayarlar kutucuğu, widget, kısayollar, zamanlayıcı/boot, mola hatırlatıcı, uygulama istisnaları, ortam ışığı. Native metinler Dart'ın gönderdiği çevirilerden.
- **Gelir:** `AdPolicy` saf kurallar (grace 3 gün + 5 oturum, oturumda 1 tam ekran, app-open 4 saat arayla, ödüllü geçiş 7. günden itibaren günde 2); tüm reklam yüklemeleri onay + SDK başlatma sonrası. Pro: Play/App Store (`in_app_purchase`), Microsoft Store (C++/WinRT), eski 1.x kimlikleri geri yüklemede; yedek dışa/içe aktarma Pro.
- **Platformlar:** Android tam; iOS = sistem parlaklığı + Renk Filtreleri sihirbazı + Kısayollar + iOS 18 Control; Windows = katman pencere overlay + MSIX + Store satın alma; Linux/macOS overlaysız çalışır (vaat edilmez).
- **Marka:** tek işaret üreticisi `tool/brand/generate_icons.py`; ana ekranda `BrandLockup` (ikon + eğik iki renkli "doctor"/"Filter" Audiowide + PRO + `app_tagline`).

## 3. CURRENT ARCHITECTURE

- Kelvin motoru ve eksenler: `lib/core/math/kelvin_engine.dart`, `lib/domain/entities/filter_config.dart` (testler `test/core/math`, `test/domain/entities`).
- Kalıcılık: `lib/data/datasources/local/preferences_datasource.dart`, `lib/presentation/providers/filter_provider.dart`; zamanlama native'e açılışta yeniden gönderilir `lib/presentation/providers/schedule_provider.dart:loadSchedule` (başlatma `home_screen.dart` `ref.listen(scheduleProvider)`).
- Android native emülatörde doğrulandı (2026-09-16): overlay izni alınınca servis kendini durdurur `kt/OverlayService.kt:watchOverlayPermission`; kokpit `kt/FilterNotificationManager.kt` + `res/layout/notification_cockpit.xml` (düz `View` yok), kutucuk `kt/FilterTileService.kt:requestRefresh`, widget `kt/FilterWidgetProvider.kt`, kısayol `kt/ShortcutActivity.kt`, zamanlayıcı `kt/ScheduleReceiver.kt` (gerçek alarm tetiklendi, geçiş tavanı 180 dk). Native metinler `kt/PresetCatalog.kt:text` ← `lib/presentation/providers/notification_sync_provider.dart:nativeLabels`.
- Reklam: `lib/domain/entities/ad_policy.dart`, `lib/presentation/ads/` (`AdConsent.sdkReady`, `AppOpenAdManager`, `watchAdForProPass`), tetik `lib/main.dart:_initialiseAds`, üst çubuk hediye düğmesi `home_screen.dart:_offerProPass`; emülatörde app-open, banner, ödüllü → Pro doğrulandı.
- Pro: `lib/presentation/providers/pro_provider.dart`, `lib/data/repositories/store_purchase_repository.dart`, `lib/data/repositories/microsoft_store_purchase_repository.dart`, `windows/runner/store_purchases.cpp`. Ayar yedeği Pro'ya kilitli ve pil optimizasyonu kartı `lib/presentation/screens/settings_screen.dart`.
- Ana ekran kaydırıcı notları sabit yuvada (`home_screen.dart` `Visibility.maintain`).
- iOS: `ios/Runner/AppDelegate.swift`, `lib/core/math/ios_color_filter.dart`, `lib/presentation/screens/ios_setup_screen.dart`, `ios/DoctorFilterControl/` (hedef olarak eklenmedi). Mac'te derlenmedi.
- Windows: `windows/runner/overlay_window.cpp` (açık kaydedilmiş filtre açılışta yeniden çizilir `filter_provider.dart:_init`, doğrulandı), MSIX `pubspec.yaml:msix_config` (publisher yer tutucu); `flutter build windows` geçiyor.
- Marka ikonları: `tool/brand/generate_icons.py` → Android uyarlanabilir ikon + splash (`res/drawable/splash_logo.xml`), iOS, macOS, web, Windows ico, `assets/images/brand_mark.png`. Ana ekran başlığı `lib/presentation/widgets/brand_lockup.dart:BrandLockup` (Audiowide `assets/fonts/Audiowide-Regular.ttf`).
- Yerelleştirme: `assets/Localizations/*.json` (71), `lib/core/localization/app_localizations.dart`.

GAP: Android özellikleri için kalan emülatör doğrulamaları (paywall çipi, izin akışı, boot, tema, RTL, erişilebilirlik, tablet, sürükleme, istisnalar, mola) → T2–T12
GAP: README ekran görüntüleri yok → T13
GAP: Gerçek mağaza satın alma, eski ürün kimliği, Partner Center, iOS/macOS/Linux derleme, AB onayı → T16–T21 (insan gerekir)

## 4. FILE MAP

Every tracked path is covered: listed, or under a `dir/**` line. Two-space indent per level; `# purpose` optional.

```text
doctorfilter/
  .github/
    workflows/
      ci.yml
  android/
    app/
      src/**  # 52 files
      build.gradle.kts
      google-services.json.example
    gradle/
      wrapper/**  # 1 files
    build.gradle.kts
    gradle.properties
    key.properties.example
    settings.gradle.kts
  assets/
    fonts/
      Audiowide-Regular.ttf  # yalnızca wordmark
      Orbitron-VariableFont_wght.ttf
    images/
      brand_mark.png
      icon.png
    Localizations/**  # 71 files
  docs/
    screenshots/
      README.md
  ios/
    DoctorFilterControl/
      DoctorFilterControl.swift
      README.md
    Flutter/
      AppFrameworkInfo.plist
      Debug.xcconfig
      Release.xcconfig
    Runner/
      Assets.xcassets/**  # 21 files
      Base.lproj/**  # 2 files
      AppDelegate.swift
      GoogleService-Info.plist.example
      Info.plist
      Runner-Bridging-Header.h
      SceneDelegate.swift
    Runner.xcodeproj/
      project.xcworkspace/**  # 3 files
      xcshareddata/**  # 1 files
      project.pbxproj
    Runner.xcworkspace/
      xcshareddata/**  # 2 files
      contents.xcworkspacedata
    RunnerTests/
      RunnerTests.swift
  lib/
    core/
      config/**  # 1 files
      errors/**  # 2 files
      localization/**  # 2 files
      math/**  # 2 files
      theme/**  # 1 files
    data/
      datasources/**  # 3 files
      repositories/**  # 6 files
    domain/
      entities/**  # 8 files
      repositories/**  # 4 files
      usecases/**  # 3 files
    presentation/
      ads/**  # 6 files
      providers/**  # 13 files
      screens/**  # 12 files
      services/**  # 2 files
      widgets/**  # 7 files
    main.dart
  linux/
    flutter/
      CMakeLists.txt
      generated_plugin_registrant.cc
      generated_plugin_registrant.h
      generated_plugins.cmake
    runner/
      CMakeLists.txt
      main.cc
      my_application.cc
      my_application.h
    CMakeLists.txt
  macos/
    Flutter/
      Flutter-Debug.xcconfig
      Flutter-Release.xcconfig
      GeneratedPluginRegistrant.swift
    Runner/
      Assets.xcassets/**  # 8 files
      Base.lproj/**  # 1 files
      Configs/**  # 4 files
      AppDelegate.swift
      DebugProfile.entitlements
      Info.plist
      MainFlutterWindow.swift
      Release.entitlements
    Runner.xcodeproj/
      project.xcworkspace/**  # 1 files
      xcshareddata/**  # 1 files
      project.pbxproj
    Runner.xcworkspace/
      xcshareddata/**  # 1 files
      contents.xcworkspacedata
    RunnerTests/
      RunnerTests.swift
  test/
    core/
      localization/**  # 2 files
      math/**  # 2 files
    data/
      repositories/**  # 1 files
    domain/
      entities/**  # 6 files
    presentation/
      providers/**  # 3 files
    widget_test.dart
  tool/
    brand/
      generate_icons.py
      source_icon_192.png
  web/
    favicon.png
    index.html
    manifest.json
  windows/
    flutter/
      CMakeLists.txt
      generated_plugin_registrant.cc
      generated_plugin_registrant.h
      generated_plugins.cmake
    runner/
      resources/**  # 1 files
      CMakeLists.txt
      flutter_window.cpp
      flutter_window.h
      main.cpp
      overlay_window.cpp
      overlay_window.h
      resource.h
      runner.exe.manifest
      Runner.rc
      store_purchases.cpp
      store_purchases.h
      utils.cpp
      utils.h
      win32_window.cpp
      win32_window.h
    CMakeLists.txt
  analysis_options.yaml
  CHANGELOG.md
  LICENSE
  PROJECT_BRAIN.md  # tek doğruluk kaynağı
  AGENTS.md  # PROJECT_BRAIN.md'ye işaret
  PRIVACY.md
  pubspec.yaml
  README.md
  THIRD_PARTY_LICENSES.md
```

## 5. TASKS

### Önceki çalışma (MIMARI.md'den devralındı)
- [x] T0 [H] (2026-09-16, Claude Opus 5) FAZ A–H ve I1–I5, I7, I8 — MIMARI.md'de kapanmış (73 madde), kod ve 2026-09-16 emülatör oturumuyla doğrulandı; ayrıntı `git show 5453c2b:MIMARI.md`
  - Done when: `flutter analyze` temiz, `flutter test` 194 test yeşil

### Marka
- [x] T1 [H] (2026-09-16, Claude Opus 5) Ana ekran marka logosu (I6)
  - Done when: `flutter analyze` temiz; `flutter test` yeşil (yeni test dahil, mevcut 360dp taşma testi geçer); emülatör ekran görüntüsünde logo ve slogan okunur → `lib/presentation/widgets/brand_lockup.dart`; 2 yeni widget testi; emülatörde iki temada doğrulandı

### Android emülatör doğrulamaları
Ortak kurulum: `flutter emulators --launch flutter_emulator`; `flutter build apk --debug`; `adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk`; adb = `C:/Users/rubicon/AppData/Local/Android/Sdk/platform-tools/adb.exe`; Git Bash'te cihaz yolları için `export MSYS_NO_PATHCONV=1`; shell dışa kapalı receiver'lara yayın gönderemez (gerçek kullanıcı yolunu kullan). Bulunan her hata o görevin alt görevi olarak düzeltilir.
- [x] T2 [M] (2026-09-16, Claude Opus 5) Bildirimde kilitli çip → paywall (B3, B3.1)
  - Done when: üç senaryonun ekran görüntüsünde paywall; `logcat -d | grep FATAL` boş → arka planda, ikinci çip ve etkinlik kapalıyken (soğuk başlatma) üçü de paywall açtı; FATAL yok
- [x] T3 [M] (2026-09-16, Claude Opus 5) Overlay izni geri alma/verme ve servis yeniden başlatma (B5, B6)
  - Done when: üç adımın ekran görüntüsü/`dumpsys notification` çıktısı beklenen durumu gösterir; FATAL yok → HATA bulundu ve düzeltildi: izin alınınca sistem pencereyi gizliyor ama servis çalışmaya ve her yerde "Filtre açık" demeye devam ediyordu; `OverlayService.watchOverlayPermission` (AppOps izleme) filtreyi durdurur. İzin geri verilince kart kalktı; süreç `run-as kill -9` ile öldürülünce servis aynı değerlerle döndü
- [x] T4 [M] (2026-09-16, Claude Opus 5) Yeniden başlatma sonrası zamanlayıcı ve filtre geri yükleme (B4, AC7)
  - Done when: reboot sonrası iki zamanlama alarmı kurulu ve overlay penceresi var → reboot sonrası START/STOP alarmları kurulu, overlay var, bildirim "Filter on · 5500 K"
- [x] T5 [M] (2026-09-16, Claude Opus 5) Pil ayarı yolu ve kenardan kenara düzen (B7, B9)
  - Done when: ekran görüntülerinde çakışma yok, pil ayarı açılır, geri dönüşler doğru → EKSİK bulundu: pil köprüsü vardı ama hiçbir ekran kullanmıyordu; `settings_screen.dart:_BatteryCard` eklendi (yalnızca optimize ediliyorken, dönüşte kendini yeniler, mevcut 71 dil anahtarları). Sistem listesi açıldı, muafiyet sonrası kart kalktı; ekranlarda çakışma yok, geri dönüşler doğru
- [x] T6 [M] (2026-09-16, Claude Opus 5) İki temada görsel denetim (D1, D4, C8, AC3)
  - Done when: 14 ekran görüntüsünde her yazı okunur; `flutter test` yeşil → koyu ve açık temada ana ekran, preset, zamanlama, bilgi merkezi, ayarlar, paywall (12 görüntü) okunur; onboarding koyu temada T2'de görüldü; düzeltme gerekmedi
- [x] T7 [M] (2026-09-16, Claude Opus 5) Ana ekranda basılı tut–sürükle sıralama (D6)
  - Done when: sürükleme sonrası ve yeniden açılışta ekran görüntüsünde yeni sıra → Daylight 4. sıraya taşındı, soğuk açılışta korundu, sonra geri alındı. Not: `input draganddrop` basılı tutmadığı için çalışmaz; `input motionevent DOWN`, 1 sn, `MOVE` adımları, `UP` kullan
- [x] T8 [M] (2026-09-16, Claude Opus 5) Erişilebilirlik etiketleri ve büyük yazı (D16, AC9)
  - Done when: dump'ta tüm etkileşimli öğelerin etiketi var; 1.3 ölçekte taşma yok; ölçek 1.0'a döndü → HATALAR düzeltildi: güç anahtarı, preset kartları ve melanopik halka etiketi iki kez okunuyordu (`excludeSemantics` + `onTap` yeniden bildirildi); kaydırıcılar hangi eksen olduklarını söylemiyordu (`MergeSemantics` + eksen adı); "percent"/"kelvin" İngilizce sabitleri %/K oldu. Yeni widget testi (düzeltme geri alınınca başarısız). 1.3 yazı ölçeğinde taşma yok
- [x] T9 [M] (2026-09-16, Claude Opus 5) Tablet ve yatay düzen (D17)
  - Done when: iki düzende taşma şeridi yok; emülatör ayarları sıfırlandı → taşma yok. İyileştirme: tablette içerik ekranı boydan boya kaplıyordu; ana ekran gövdesi 720dp ile sınırlandı ve ortalandı. Yatayda banner+gezinme çubuğu içeriğin çoğunu kaplıyor ama kaydırılabilir (ASSUMPTION §6)
- [x] T10 [M] (2026-09-16, Claude Opus 5) Arapça RTL düzeni (E4, AC2)
  - Done when: ekran görüntülerinde metin sağdan sola, düzen aynalı, bildirim metinleri Arapça → düzen aynalı, bildirim Arapça. HATA düzeltildi: Kelvin değerleri RTL paragrafta "K 5500" ve "K · 15% · 0% 5500" diye ters çıkıyordu; `app_localizations.dart:ltrIsolate` (U+2066/U+2069) tüm gösterim yerlerinde ve bildirim şablonlarında. RTL widget testine iddia eklendi (düzeltme geri alınınca başarısız)
- [x] T11 [M] (2026-09-16, Claude Opus 5) Uygulama istisnaları (H1)
  - Done when: `dumpsys window windows` kamera öndeyken overlay'i görünmez (alpha 0 veya yok), çıkınca görünür gösterir; kart davranışı ekran görüntüleriyle → askıya alma pencere alfasıyla değil görünüm renginin alfasıyla yapılıyor, bu yüzden piksel ölçüldü: Kamera öndeyken üst şerit (0,172,193) = tonsuz Material cyan; istisna kapalıyken (30,180,197) tonlu. İzin kartı izin verilince kalktı, alınınca geri geldi
- [x] T12 [M] (2026-09-16, Claude Opus 5) Mola hatırlatıcısının gerçek alarmla tetiklenmesi
  - Done when: `dumpsys notification --noredact | grep android.title` mola bildirimini uygulama dilinde gösterir → açıldıktan sonra RTC alarmı (15:48 + 15 dk pencere) 15:49:56'da tetiklendi; bildirim "Time to look away" / "Every 20 minutes, look about 6 metres away for 20 seconds." (uygulama dili İngilizce)
- [ ] T13 [L] README ekran görüntüleri (F2.1)
  - Where: `docs/screenshots/README.md` (5 ekran, ayarları ve dosya adları orada), `README.md` "## Screenshots"
  - Do: `docs/screenshots/README.md` listesine göre emülatörden `adb exec-out screencap -p` ile 5 PNG çek, orada yazan dosya adlarıyla `docs/screenshots/` içine kaydet, PIL ile genişliği 540'a küçült; test reklamı görünmesin (Pro geçişi aktifken çek)
  - Done when: README'deki her `docs/screenshots/...png` bağlantısı var olan dosyaya işaret eder (`grep -o 'docs/screenshots/[^)]*png' README.md | xargs ls`)
- [x] T14 [M] (2026-09-16, Claude Opus 5) Bildirim erişilebilirlik açıklamaları uygulama dilinde
  - Done when: uygulama dili Türkçe iken bildirim gölgesinde `uiautomator dump` bu düğmelerin content-desc'ini Türkçe gösterir; `flutter build apk --debug` geçer → uygulama dili Türkçe iken dump: "Kapat", "Daha karanlık", "Daha parlak", kilitler "Tüm ön ayarlar ve kontroller için Pro'ya geçin". Ayrıca yanlış etiket düzeltildi: Kelvin/yoğunluk satırlarının −/+ düğmeleri "Brighter/Dimmer" diye okunuyordu; artık "<eksen adı> −/+"
- [x] T15 [M] (2026-09-16, Claude Opus 5) Windows overlay elle doğrulama (G2)
  - Done when: ekran görüntüleri her adımı gösterir → HATA düzeltildi: açık kaydedilmiş filtre Windows'ta yeniden açılışta çizilmiyordu ("Filtre açık" ama ton yok); `filter_provider.dart:_init` Windows'ta yeniden uygular (+2 test). Win32 ile doğrulandı: overlay layered/transparent/topmost/toolwindow/noactivate; WindowFromPoint alttaki pencereyi buluyor (tıklama geçer); ekran ortalaması 31→104,83,62 (tüm ekran tonlu); uygulama kapanınca tam 31,31,31'e döndü; en koyu ayarda (1700 K, %100/%100) ekran ortalaması 73,36,2, içerik seçilebilir. Tek monitör var (adım 4 yapılamadı, §6)
- [ ] T22 [L] Onboarding'deki eski göz simgesini marka işaretiyle değiştir
  - Where: `lib/presentation/screens/onboarding_screen.dart` (ilk sayfadaki göz ikonu)
  - Do: göz `Icon`'u yerine `Image.asset('assets/images/brand_mark.png', width: 96, height: 96)` koy; diğer sayfalara dokunma
  - Done when: `flutter analyze` temiz, `flutter test` yeşil; emülatörde `pm clear` sonrası ilk ekran görüntüsünde marka işareti
  - Note: from T2 (discovery)
- [ ] T23 [M] Soğuk açılışta "izin gerekli" kartının anlık yanıp sönmesi
  - Where: `lib/presentation/providers/filter_provider.dart` (`FilterState.hasOverlayPermission` başlangıç değeri), `lib/presentation/screens/home_screen.dart` (`!filterState.hasOverlayPermission` koşulu)
  - Do: 1) izin durumunu üç değerli yap (`bool?`, null = henüz sorulmadı) ya da ayrı `permissionChecked` bayrağı ekle; 2) ana ekranda kart yalnızca kontrol tamamlanıp izin yoksa gösterilsin; 3) `test/widget_test.dart`'a mock `checkOverlayPermission` gecikmeli true dönerken ilk karede `OverlayPermissionBanner` bulunmadığını doğrulayan test
  - Done when: yeni test ve tüm `flutter test` yeşil; emülatörde izin verilmişken soğuk açılışın ilk saniyesinde kart görünmez (açılıştan 0,5 sn sonra ekran görüntüsü)
  - Note: from T2 (discovery)
- [x] T24 [M] (2026-09-16, Claude Opus 5) Windows'ta tek örnek: ikinci açılış ikinci overlay'i üst üste bindirmesin
  - Done when: exe iki kez başlatılınca `Get-Process doctorfilter` tek süreç gösterir ve ekranda tek `DoctorFilterOverlay` penceresi vardır (T15'teki `wincheck.ps1` benzeri EnumWindows sayımı) → `main.cpp` adlı mutex; exe iki kez başlatılınca 1 süreç, 1 overlay. Pencere başlığı "doctorfilter" → "DoctorFilter" (FindWindow bununla eşleşiyor)
  - Note: from T15 (discovery: iki süreç aynı anda çalıştı, iki overlay)
- [x] T25 [M] (2026-09-16, Claude Opus 5) Windows overlay penceresi WM_CLOSE ile kapatılamasın
  - Done when: filtre açıkken overlay HWND'ye `SendMessage(WM_CLOSE)` sonrası pencere hâlâ var ve ekran tonlu; uygulama ana penceresi kapatılınca ton kalkar → `OverlayWndProc` WM_CLOSE'u yutuyor; overlay HWND'ye WM_CLOSE sonrası `IsWindow` true, ekran ortalaması 104,83,62 (tonlu) kaldı; ana pencere kapanınca 31,31,31
  - Note: from T15 (discovery: `Process.CloseMainWindow` overlay'i kapattı, uygulama "Filtre açık" demeye devam etti)

### İnsan gerektirenler
- [!] T16 [M] Play gerçek satın alma (C2) — Play Console'da `doctorfilter_pro_lifetime` ürünü ve lisanslı test hesabı gerekir (sahip)
- [!] T17 [M] Eski 1.x ürün kimliğini doğrula (C4) — `ProProduct.legacyIds` tahmini (`doctorfilter_proversion`); Play Console erişimi gerekir (sahip)
- [!] T18 [M] Microsoft Store (G2.1, G2.2) — Partner Center kaydı, Durable eklenti `doctorfilter_pro_lifetime`, `pubspec.yaml` `msix_config.publisher` gerçek değer (sahip)
- [!] T19 [H] iOS derleme ve cihaz doğrulaması (G1, G1.2, G1.3, G1.4) — macOS + Xcode gerekir; adımlar `ios/DoctorFilterControl/README.md` ve `git show 5453c2b:MIMARI.md` §12.1 G1
- [!] T20 [M] AB onay formu (C6) — AdMob hesabında UMP mesajı yayımlanmış olmalı ve AB coğrafyası (VPN veya test cihazı hash'i) gerekir (sahip)
- [!] T21 [M] Linux/macOS derleme (G3) — ilgili işletim sistemi gerekir; overlaysız çalışma vaat edilmez

## 6. DECISION LOG

Newest first. Types: DECISION · ASSUMPTION · REVISION · GOAL-CHANGE · GOAL-CONCERN · AUDIT · RECONCILE · OUT-OF-SCOPE.

| Date | Type | What | Why / evidence |
|---|---|---|---|
| 2026-09-16 | ASSUMPTION | Windows'ta ikinci monitör/çözünürlük değişimi (G2 adım 4) denenemedi: makinede tek monitör var; kod her boyamada sanal ekranı yeniden ölçüyor (`overlay_window.cpp`) | T15 |
| 2026-09-16 | ASSUMPTION | Yatay telefonda NavigationRail'e geçilmedi; ana ekran kaydırılarak kullanılabiliyor. Filtre uygulaması yatay kullanımı nadir | T9 ekran görüntüsü |
| 2026-09-16 | AUDIT | A0: `brain.py check` FAIL yok; §3 iddiaları kodda açıldı (`schedule_provider.dart:25`, `PresetCatalog.kt:51 text`, `ad_consent.dart:40 sdkReady`); her GAP görevli; AC1–AC11 görevlere/T0 testlerine bağlı; ilk 5 açık görev yeniden okundu, T2 (temiz durum) ve T3 (süreç öldürme) belirsizlikleri giderildi; `flutter test` 194 yeşil | Görev yok |
| 2026-09-16 | DECISION | MIMARI.md benimsendi ve kaldırıldı (73 bitti; 1 açık + cihaz doğrulaması bekleyen `[~]` maddeler) | Tek plan dosyası PROJECT_BRAIN.md; eski gerekçeler `git show 5453c2b:MIMARI.md` |
| 2026-09-16 | ASSUMPTION | MIMARI `[~] 🔴` maddelerinden bugün emülatörde doğrulananlar (B1, B2, B8, C7, D10→I5) T0'a kapatıldı; emülatörde doğrulanabilenler T2–T15, doğrulanamayanlar `[!]` T16–T21 oldu | 2026-09-16 emülatör oturumu (commit 1861618, d46040e, f793ec6, 5453c2b) |
| 2026-09-16 | DECISION | iOS sınırları: bildirim kokpiti yok, Kısayollar hue değiştiremez, Night Shift programlanamaz, diğer uygulamaların üzerine filtre yok — uygulama ve mağaza metni bunları vaat etmez | Public API yok (eski MIMARI §7.2.4) |
| 2026-09-16 | DECISION | Android doğrulaması yerel emülatörle; "cihaz gerekir" gerekçesi kullanılmaz | Sahibin açık talimatı |
| 2026-09-16 | DECISION | Yedek dışa/içe aktarma yalnızca Pro; app-open reklam 3 gün + 5 oturum sonra, 4 saat arayla; ödüllü geçiş 7. günden; hediye düğmesi üst çubukta | Sahibin 2. tur geri bildirimi (I2–I4) |
| 2026-09-16 | DECISION | Yasak iddialar: mavi ışık retinaya zarar/AMD, göz yorgunluğu/kuruluğu tedavisi, kilo, herhangi tedavi/tanı/önleme. Söylenebilecek: akşam melanopik dozu düşürme, karartma konforu, 20-20-20 | Cochrane (Singh 2023), Chang 2015, Brown 2022, Nagare 2019 |
| 2026-09-16 | DECISION | Project brain created | Single source of truth for multi-session, multi-model work |

## 7. HANDOFF

T15 bitti. AÇIK İŞ (commit edilmedi, çalışma ağacında): T12 [~] mola alarmı bekleniyor (emülatör saatiyle 15:48–16:03 penceresi; bildirim `dumpsys notification` ile aranıyor); T14 Kotlin değişikliği (`FilterNotificationManager.kt` contentDescription) derleniyor ama emülatörde doğrulanmadı; T22 onboarding marka işareti + test hazır, emülatörde doğrulanmadı. T12 bitmeden APK yeniden kurulmamalı (kurulum alarmları sıfırlar).
