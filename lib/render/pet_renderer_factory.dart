/// Selects the concrete [PetRenderer] for the active [PetRendererBackend].
///
/// Kept separate from `pet_renderer.dart` so the interface file stays free of
/// the `rive` dependency; only this factory (and its callers) pull Rive in.
library;

import '../core/app_config.dart';
import 'pet_renderer.dart';
import 'rive_pet_renderer.dart';

/// Builds the renderer for [backend]. [riveAsset] is the commissioned `.riv`
/// rig path (null until P2 — the Rive seam then paints its native-free stand-in).
PetRenderer createPetRenderer(
  PetRendererBackend backend, {
  String? riveAsset,
}) {
  switch (backend) {
    case PetRendererBackend.rive:
      return RivePetRenderer(assetPath: riveAsset);
    case PetRendererBackend.placeholder:
      return const PlaceholderPetRenderer();
  }
}
