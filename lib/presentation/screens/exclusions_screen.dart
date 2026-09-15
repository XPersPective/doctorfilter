import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctorfilter/core/localization/app_localizations.dart';
import 'package:doctorfilter/core/theme/app_theme.dart';
import 'package:doctorfilter/presentation/providers/exclusion_provider.dart';

/// Picks the apps the filter should get out of the way for.
///
/// Watches the app lifecycle: usage access is granted in system settings, which
/// means leaving and coming back, and a permission prompt still sitting there
/// after the user has already granted it is the same defect the overlay banner
/// had.
class ExclusionsScreen extends ConsumerStatefulWidget {
  const ExclusionsScreen({super.key});

  @override
  ConsumerState<ExclusionsScreen> createState() => _ExclusionsScreenState();
}

class _ExclusionsScreenState extends ConsumerState<ExclusionsScreen>
    with WidgetsBindingObserver {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      ref.read(exclusionProvider.notifier).refreshPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final state = ref.watch(exclusionProvider);
    final notifier = ref.read(exclusionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('exclusions_title') ?? 'Pause in these apps'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              loc?.translate('exclusions_intro') ??
                  'The filter lifts itself while one of these apps is in front, '
                      'and comes back when you leave.',
              style: context.texts.bodyMedium,
            ),
          ),

          if (!state.hasPermission)
            _PermissionCard(onGrant: notifier.requestPermission)
          else ...[
            SwitchListTile(
              secondary: Icon(
                Icons.pause_circle_outline_rounded,
                color: context.colours.primary,
              ),
              title: Text(
                loc?.translate('exclusions_enable') ?? 'Pause automatically',
              ),
              value: state.isEnabled,
              onChanged: notifier.setEnabled,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: loc?.translate('exclusions_search') ?? 'Search apps',
                ),
                onChanged: (value) => setState(() => _query = value.toLowerCase()),
              ),
            ),
            Expanded(child: _AppList(query: _query, selected: state.packages)),
          ],
        ],
      ),
    );
  }
}

class _AppList extends ConsumerWidget {
  const _AppList({required this.query, required this.selected});

  final String query;
  final Set<String> selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(installedAppsProvider);

    return apps.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Text(
          AppLocalizations.of(context)?.translate('exclusions_list_failed') ??
              'The app list could not be read.',
        ),
      ),
      data: (installed) {
        final visible = query.isEmpty
            ? installed
            : installed
                .where((app) => app.label.toLowerCase().contains(query))
                .toList();

        return ListView.builder(
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final app = visible[index];
            return CheckboxListTile(
              value: selected.contains(app.packageName),
              onChanged: (_) =>
                  ref.read(exclusionProvider.notifier).toggle(app.packageName),
              title: Text(app.label, maxLines: 1, overflow: TextOverflow.ellipsis),
              secondary: SizedBox(
                width: 40,
                height: 40,
                child: app.icon == null
                    ? Icon(Icons.android_rounded, color: context.colours.outline)
                    : Image.memory(app.icon!, filterQuality: FilterQuality.medium),
              ),
            );
          },
        );
      },
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.onGrant});

  final Future<void> Function() onGrant;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc?.translate('exclusions_permission_title') ?? 'One permission first',
              style: context.texts.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              // Says exactly what is read and what is not. A permission screen
              // that explains itself is the difference between being granted
              // and being uninstalled.
              loc?.translate('exclusions_permission_body') ??
                  'To step aside for your camera, the app needs to know which '
                      'app is in front. Android calls this usage access and you '
                      'grant it in system settings. DoctorFilter only reads the '
                      'name of the app currently open, never your history, and '
                      'nothing leaves your phone.',
              style: context.texts.bodyMedium,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                onPressed: onGrant,
                child: Text(
                  loc?.translate('exclusions_permission_action') ?? 'Open settings',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
