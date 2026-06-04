import AppIntents
import SwiftUI
import WidgetKit

@main
struct ShootLaterWidgetsBundle: WidgetBundle {
    var body: some Widget {
        RecentSpotsWidget()
        CaptureControlWidget()
        SaveLocationControlWidget()
    }
}

struct RecentSpotEntry: TimelineEntry {
    let date: Date
    let snapshots: [SpotSnapshot]
}

struct RecentSpotsProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecentSpotEntry {
        RecentSpotEntry(date: .now, snapshots: [
            SpotSnapshot(id: UUID(), title: "Neon alley", location: "Mission District", createdAt: .now, photoFileName: nil, isLocationOnly: false)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (RecentSpotEntry) -> Void) {
        completion(RecentSpotEntry(date: .now, snapshots: SpotSnapshotStore().loadRecent(limit: 3)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecentSpotEntry>) -> Void) {
        let entry = RecentSpotEntry(date: .now, snapshots: SpotSnapshotStore().loadRecent(limit: 3))
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(30 * 60))))
    }
}

struct RecentSpotsWidget: Widget {
    let kind = "RecentSpotsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecentSpotsProvider()) { entry in
            RecentSpotsWidgetView(entry: entry)
        }
        .configurationDisplayName("Recent Spots")
        .description("Jump back to your latest scouting spots.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct RecentSpotsWidgetView: View {
    let entry: RecentSpotEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ShootLater")
                .font(.headline)
            if entry.snapshots.isEmpty {
                Text("No spots yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(entry.snapshots.prefix(3)) { snapshot in
                    Link(destination: URL(string: "shootlater://spot/\(snapshot.id.uuidString)")!) {
                        HStack(spacing: 8) {
                            Image(systemName: snapshot.isLocationOnly ? "location.fill" : "camera.fill")
                                .foregroundStyle(.teal)
                                .frame(width: 22)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(snapshot.title)
                                    .lineLimit(1)
                                    .font(.caption.bold())
                                Text(snapshot.location)
                                    .lineLimit(1)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .containerBackground(.background, for: .widget)
    }
}

struct CaptureControlWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "CaptureControlWidget") {
            ControlWidgetButton(action: CaptureNewSpotIntent()) {
                Label("Capture", systemImage: "camera.fill")
            }
        }
        .displayName("Capture Spot")
        .description("Open ShootLater directly into capture.")
    }
}

struct SaveLocationControlWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "SaveLocationControlWidget") {
            ControlWidgetButton(action: SaveCurrentLocationIntent()) {
                Label("Save Location", systemImage: "location.fill")
            }
        }
        .displayName("Save Location")
        .description("Start a location-only ShootLater spot.")
    }
}
