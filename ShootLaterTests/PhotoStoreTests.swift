import Foundation
import Testing
import UIKit
@testable import ShootLater

@Suite("PhotoStore")
struct PhotoStoreTests {
    @Test("saves and deletes app-managed image files")
    func saveAndDelete() throws {
        let root = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let store = PhotoStore(rootDirectory: root)
        let image = UIImage(systemName: "camera.fill")!

        let fileName = try store.save(image)
        #expect(FileManager.default.fileExists(atPath: store.url(for: fileName).path()))

        try store.delete(fileName: fileName)
        #expect(!FileManager.default.fileExists(atPath: store.url(for: fileName).path()))
    }
}
