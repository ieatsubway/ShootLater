# ShootLater Modern Responsive Redesign

## Goal

Redesign ShootLater into a polished, modern, native iOS 26 scouting app that feels fast, calm, and useful on compact iPhones, large iPhones, and regular-width iPad layouts. The redesign should keep the PRD's local-first photographer workflow intact: capture quickly, rediscover on a map or list, inspect details, share, and manage privacy.

## Design Team Loop

- Visual design critic: checks identity, hierarchy, color, typography, glass usage, and screen-level polish.
- Adaptive layout reviewer: checks compact and regular size classes, landscape, iPad split layouts, Dynamic Type, and safe-area behavior.
- QA/accessibility reviewer: checks empty states, navigation, controls, destructive actions, permissions, share/edit flows, and simulator evidence.

Feedback from these passes becomes an implementation queue. The main thread owns edits and verification.

## Visual Direction

ShootLater should look like a quiet field notebook for photographers rather than a generic utility. The visual system should use:

- Neutral content backgrounds with camera-inspired dark text, cool teal accents, and small warm amber highlights.
- Big photography/location visuals where they help recognition, especially capture, detail, cards, and empty states.
- Liquid Glass on functional chrome: primary buttons, floating map controls, preview surfaces, status chips, and bottom action bars.
- Standard SwiftUI containers where content should stay readable. Glass should not be sprayed across every row.
- Rounded geometry that is consistent and moderate: tighter rows, softer media, and larger glass action surfaces.

## Screen Designs

### Onboarding

Use a first-viewport product signal: app name, camera/location mark, privacy promise, and a single location setup action. It should feel premium and centered on the app's private local storage promise.

### Capture

Capture remains the primary tab and must optimize for fast saving. Compact width uses a focused vertical layout with a large camera mark, primary capture action, secondary location-only action, and a small status chip. Regular width splits into an editorial intro panel and an action panel, making iPad feel intentional instead of stretched.

### Map

The map should feel like the scouting surface. Use photo/location markers, a small floating count/status surface, a polished empty state when no coordinates exist, and a bounded bottom preview that does not sprawl on iPad.

### Spots

Compact width keeps a searchable chronological list but upgrades row hierarchy and visual states. Regular width uses a responsive card grid so iPad and wide layouts are not just a stretched list. Empty search and empty collection states should be distinct.

### Detail

Compact width stacks visual, title/location, notes, metadata, and actions. Regular width uses a two-column layout: visual on one side, detail and actions on the other. Share/edit remain top actions, delete remains visually separated and destructive.

### Settings

Settings should read as privacy and device-state controls, not a raw form. Use a summary header, clear permission state, local privacy copy, and a distinct destructive zone.

## Adaptive Rules

- Constrain readable content width on all screens.
- Use two-column or grid layouts only in regular horizontal size class or very wide geometry.
- Avoid fixed `UIScreen.main.bounds` sizing for primary content.
- Support Dynamic Type by allowing vertical growth, multiline labels, and minimum touch target sizes.
- Keep floating glass surfaces clear of tab bars, home indicator, and map controls.
- Ensure iPad layouts have intentional whitespace and do not create oversized rows or edge-to-edge text.

## QA Gates

- Build and unit tests must pass.
- Simulator screenshot evidence should cover compact portrait and at least one wider/adaptive viewport when available.
- Inspect for clipped text, overlapping safe-area content, empty states, unbounded media, unreadable map overlays, and awkward iPad stretching.
- Verify core interactions: capture button opens camera flow, location-only save disables while saving, map marker opens preview, spot row/card navigates to detail, edit sheet opens, share sheet action is reachable, delete remains separated.
- Run a final design critique pass after implementation and iterate on concrete issues.
