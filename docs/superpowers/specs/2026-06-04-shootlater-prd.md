# ShootLater PRD

## Summary

ShootLater is a local-first iPhone app for solo photographers who notice a location they may want to shoot later. The app helps them quickly save a scouting spot with as little friction as possible: take an in-app photo or save the current location, automatically attach private location data, derive a human-readable place name, and revisit the spot through a map, searchable list, widgets, and quick controls.

The v1 product should feel modern, quiet, and native to iOS 26. It should target iOS 26 and above only, with SwiftUI, SwiftData, WidgetKit, App Intents, Core Location, MapKit, and native Liquid Glass APIs as core product requirements.

## Product Goals

- Let a solo photographer save a potential shoot location in seconds.
- Support both photo-based spots and location-only spots.
- Automatically capture exact coordinates privately and derive a human-readable/general location for display.
- Provide map and searchable list views for rediscovering saved spots.
- Share a polished visual card plus an Apple Maps link.
- Offer fast system entry points through widgets, controls, and App Intents.
- Keep v1 local-first with no accounts, sync, teams, or cloud dependency.

## Non-Goals For V1

- iCloud sync or account support.
- Team collaboration or shared workspaces.
- Importing existing photos from the photo library.
- Map-link-only sharing.
- Advanced shoot planning metadata such as weather, golden hour, gear, model/client info, reminders, ratings, or categories.
- Cloud backend, web dashboard, or cross-platform support.
- Fallback UI for iOS versions earlier than iOS 26.

## Target User

The v1 user is a solo photographer scouting for future photo shoots. They may be walking, driving, traveling, or working between shoots when they notice a potentially useful location. The app should optimize for capture speed and later rediscovery, not heavy planning.

## Core User Jobs

- "I saw a place I might want to photograph later, so I want to save it quickly."
- "I want to take a quick reference photo and have the location remembered automatically."
- "I want to save my current location even when I do not have or want a photo."
- "I want to browse all my scouting spots on a map."
- "I want to search my saved spots by location, title, or notes."
- "I want to share a spot with a polished image and an Apple Maps link."

## App Structure

ShootLater should be a SwiftUI tab bar app with these primary tabs:

- **Capture:** The primary entry point for snapping a new scouting photo.
- **Map:** A map of saved spots with compact previews.
- **Spots:** A chronological, searchable list of saved spots.
- **Settings:** Permissions, privacy explanation, app preferences, and destructive actions such as data deletion.

The tab bar and any floating controls should use native iOS 26 styling. Liquid Glass is a defining visual and interaction language for the app, especially for tab/navigation surfaces, floating map preview cards, compact capture/edit sheets, share affordances, and primary action buttons.

## First Launch And Permissions

On first launch, ShootLater should present a brief onboarding or permission explanation screen before requesting location permission. The copy should explain that ShootLater uses location to remember where scouting spots were captured.

Recommended permission behavior:

- Request location permission early on first launch to get setup out of the way.
- Use Core Location for both photo spots and location-only spots.
- Continue to function if location is denied.
- Allow photo or note-only saves when location is unavailable.
- Clearly mark missing or approximate location states in the UI.

Camera permission should be requested when the user first enters the capture flow.

## Capture Experience

The Capture tab should prioritize speed. The photographer should be able to open the app, take a photo, and save the spot without typing anything.

Photo capture flow:

1. User opens Capture.
2. App presents in-app camera.
3. User takes a photo.
4. App captures current device location and uses available photo capture metadata or EXIF location metadata to seed or validate the spot location.
5. App reverse-geocodes the coordinate into a human-readable/general location.
6. App presents a lightweight confirmation/edit sheet.
7. User can optionally add a title or notes.
8. User saves the spot.

No field should be mandatory. Title and notes are optional. If the user does not enter a title, the app should use a fallback display name derived from the general location and date.

## Location-Only Capture

ShootLater must support saving a spot without a photo. This is required for the "Save Current Location" control/action and may also be available inside the app.

Location-only flow:

1. User invokes Save Current Location from a control, widget, shortcut, or app UI.
2. App captures the current device coordinate through Core Location.
3. App reverse-geocodes the coordinate into a human-readable/general location.
4. App saves a new Shoot Spot with no photo attached.
5. If needed, app can show a compact confirmation state or open an optional edit screen for title/notes.

The product model should treat photos as optional enrichment. A saved item is a Shoot Spot, not a photo record.

## Map Experience

The Map tab should show all saved spots with valid coordinates. Spots can be represented as pins, photo markers, or a hybrid marker style.

Map interactions:

- Tapping a marker opens a compact preview first, not the full detail screen.
- The preview should use a native-feeling Liquid Glass surface.
- The preview should show the square photo if available, a location-only placeholder if not, the human-readable location, optional title, and saved date.
- The preview should include a clear way to open the full detail screen.
- Location-only spots should appear on the map just like photo spots, but use a distinct placeholder/marker treatment.

The map should preserve the user's browsing context when opening and closing previews.

## Spots List And Search

The Spots tab should show a chronological list of saved spots, newest first.

Each list row should show:

- Thumbnail if a photo exists.
- Location-only placeholder if no photo exists.
- Best display title.
- Human-readable/general location.
- Saved date.

Search should be available in the list view and match:

- Optional title.
- Optional notes.
- Human-readable/general location.

Search does not need advanced filters in v1.

## Spot Detail

The detail screen should show:

- Large photo if available.
- Location-only visual treatment if no photo exists.
- Human-readable/general location.
- Optional title.
- Optional notes.
- Created date.
- Share action.
- Edit action.
- Delete action.

The exact coordinate should not be emphasized as primary UI, but it may be used for map display and Apple Maps link generation.

## Sharing

When the user shares a saved spot, ShootLater should generate a square visual card.

Share card requirements:

- Square format.
- Rounded corners.
- Uses the scouting photo when available.
- Overlays the human-readable/general location on top of the image.
- If the spot is location-only, generate a tasteful location card placeholder using the general location and app styling.
- The card should look polished enough to send through iMessage or Mail.

Share payload requirements:

- Include the generated square image card.
- Include an Apple Maps link when an exact coordinate is available.
- Include optional title and notes text only if the user entered them.

The share card itself should show only the human-readable/general location. The Apple Maps link may encode the precise coordinate so recipients can open or navigate to the spot in Apple Maps.

## Data Model

Use SwiftData for local persistence.

Recommended model: `ShootSpot`

- `id`: Stable unique identifier.
- `photoFileName`: Optional app-managed local photo file reference.
- `latitude`: Optional exact latitude.
- `longitude`: Optional exact longitude.
- `locationDisplayName`: Optional human-readable/general location.
- `title`: Optional user-entered title.
- `notes`: Optional user-entered notes.
- `createdAt`: Creation timestamp.
- `updatedAt`: Last edited timestamp.
- `source`: Enum, either `cameraCapture` or `locationOnly`.
- `locationStatus`: Enum, such as `captured`, `approximate`, `unavailable`, or `pendingReverseGeocode`.

Photo files should be stored in app-managed local storage. SwiftData records should store file references rather than raw image blobs.

## Location Handling

Use Core Location for device location capture, with photo capture metadata or EXIF location metadata used when available for photo spots. Use reverse geocoding to derive a human-readable/general location. The app should store exact coordinates locally and privately, while using general location strings for display and share card overlays.

Location behavior:

- A spot may be saved without coordinates.
- A coordinate may exist while reverse geocoding is still pending.
- Reverse geocoding failures should not block saving.
- If location is denied or unavailable, the UI should explain the missing location state without making the user feel stuck.

## Platform Integrations

ShootLater v1 should target iOS 26 and above only. Implementation agents should not spend v1 effort on backwards-compatible UI fallbacks for earlier iOS versions.

Use App Intents as the system-facing layer for the smallest useful set of actions.

Recommended v1 intents:

- **Capture New Spot:** Opens ShootLater directly into camera capture.
- **Save Current Location:** Captures the current location without requiring a photo.
- **Open Spot:** Opens a saved spot detail when invoked from a widget or system surface.

WidgetKit:

- Provide a recent spots widget.
- Show photo thumbnails when available.
- Show location-only placeholders when no photo exists.
- Allow quick access to recent spot detail.

Controls:

- Provide a Capture New Spot control.
- Provide a Save Current Location control.
- Reuse App Intents where possible.

## Visual And Interaction Guidelines

- Use SwiftUI as the UI framework.
- Treat Liquid Glass as a core part of the ShootLater product identity, not an optional accent.
- Use native Liquid Glass APIs for iOS 26 UI treatment throughout the primary app surfaces.
- Prefer standard system components over custom recreation.
- Use `glassEffect` and `GlassEffectContainer` for custom Liquid Glass surfaces when needed.
- Use glass button styles for primary and secondary actions when they fit the surface.
- Use interactive glass only for tappable/focusable elements.
- Keep glass usage polished and functional, especially around previews, controls, floating actions, and share surfaces.
- Do not implement earlier-iOS fallback styling in v1.

The app should feel like a native Apple ecosystem app: lightweight, calm, spatial, and fast.

## Success Criteria

- A user can save a photo spot without entering any text.
- A user can save a location-only spot without taking a photo.
- Saved spots persist locally through app restarts.
- Saved spots with coordinates appear on the map.
- Tapping a map marker opens a compact preview before detail.
- The list view can search title, notes, and general location.
- Sharing produces a square visual card and includes an Apple Maps link when coordinates exist.
- Widgets and controls expose quick access to Capture New Spot and Save Current Location.
- Denied or unavailable location does not block saving a spot.

## Open Implementation Choices

These choices can be made by implementation agents, as long as they preserve the PRD behavior:

- Whether the camera implementation uses `UIImagePickerController`, `AVFoundation`, or another native camera approach appropriate for the target OS.
- Exact marker visual design for map pins/photo markers.
- Exact placeholder visual treatment for location-only spots.
- Whether location-only Save Current Location completes fully in the background or opens the app for confirmation when required by platform constraints.

## Official Platform References

- Apple SwiftUI Liquid Glass: https://developer.apple.com/documentation/swiftui/glass
- Apple `glassEffect(_:in:)`: https://developer.apple.com/documentation/swiftui/view/glasseffect%28_%3Ain%3A%29
- Apple App Intents: https://developer.apple.com/documentation/AppIntents/app-intents
- Apple widgets, Live Activities, and controls with App Intents: https://developer.apple.com/documentation/appintents/widgets-and-live-activities
