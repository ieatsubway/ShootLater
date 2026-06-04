import Foundation
import SwiftData

enum AppModelContainer {
    @MainActor
    static let shared: ModelContainer = {
        let schema = Schema([ShootSpot.self])
        let fileManager = FileManager.default

        let supportDirectory: URL
        if let group = fileManager.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier) {
            supportDirectory = group.appending(path: "Library/Application Support", directoryHint: .isDirectory)
        } else {
            supportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        }

        do {
            try fileManager.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
            let configuration = ModelConfiguration(
                schema: schema,
                url: supportDirectory.appending(path: "ShootLater.store")
            )
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ShootLater model container: \(error)")
        }
    }()
}
