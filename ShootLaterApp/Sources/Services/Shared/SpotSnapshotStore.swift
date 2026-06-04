import Foundation

struct SpotSnapshot: Codable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var location: String
    var createdAt: Date
    var photoFileName: String?
    var isLocationOnly: Bool
}

struct SpotSnapshotStore {
    private let fileManager: FileManager
    private let directory: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let group = fileManager.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier) {
            self.directory = group
        } else {
            self.directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        }
    }

    var snapshotsURL: URL {
        directory.appending(path: "recent-spots.json")
    }

    func loadRecent(limit: Int = 5) -> [SpotSnapshot] {
        guard
            let data = try? Data(contentsOf: snapshotsURL),
            let snapshots = try? JSONDecoder().decode([SpotSnapshot].self, from: data)
        else {
            return []
        }
        return Array(snapshots.prefix(limit))
    }

    func save(_ snapshots: [SpotSnapshot]) throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(Array(snapshots.prefix(10)))
        try data.write(to: snapshotsURL, options: [.atomic])
    }
}
