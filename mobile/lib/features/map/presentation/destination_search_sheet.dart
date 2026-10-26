import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianroute/core/config/maps_config.dart';
import 'package:guardianroute/features/map/data/places_autocomplete_service.dart';
import 'package:guardianroute/features/map/presentation/map_providers.dart';

Future<void> showDestinationSearchSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const _DestinationSearchSheet(),
  );
}

class _DestinationSearchSheet extends ConsumerStatefulWidget {
  const _DestinationSearchSheet();

  @override
  ConsumerState<_DestinationSearchSheet> createState() =>
      _DestinationSearchSheetState();
}

class _DestinationSearchSheetState extends ConsumerState<_DestinationSearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = const [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!MapsConfig.hasPlacesApiKey) {
        setState(() {
          _error = 'Add GOOGLE_MAPS_API_KEY via --dart-define for search.';
          _suggestions = const [];
        });
        return;
      }

      setState(() {
        _loading = true;
        _error = null;
      });

      try {
        final service = ref.read(placesAutocompleteServiceProvider);
        final results = await service.autocomplete(value);
        if (mounted) {
          setState(() {
            _suggestions = results;
            _loading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'Search failed. Check your connection.';
          });
        }
      }
    });
  }

  Future<void> _select(PlaceSuggestion suggestion) async {
    setState(() => _loading = true);
    final service = ref.read(placesAutocompleteServiceProvider);
    final destination = await service.resolvePlace(suggestion);
    if (!mounted) return;

    if (destination == null) {
      setState(() {
        _loading = false;
        _error = 'Could not resolve that place.';
      });
      return;
    }

    ref.read(selectedDestinationProvider.notifier).set(destination);
    await ref.read(mapControllerHolderProvider.notifier).animateTo(
          destination.location,
          zoom: 14,
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Where are you going?',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search destination in Uganda',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _onQueryChanged,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          ],
          if (_loading) const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final item = _suggestions[index];
                return ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(item.description),
                  onTap: () => _select(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
