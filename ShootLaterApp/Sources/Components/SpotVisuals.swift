import SwiftUI
import UIKit

struct SpotThumbnail: View {
    let fileName: String?
    let size: CGFloat
    private let photoStore = PhotoStore()

    var body: some View {
        Group {
            if let image = photoStore.image(for: fileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(colors: [.teal, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: size * 0.32, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: min(14, size * 0.18), style: .continuous))
    }
}

struct LocationStatusBadge: View {
    let status: LocationStatus

    var body: some View {
        Label(status.label, systemImage: status == .unavailable ? "location.slash" : "location.fill")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .glassEffect(.regular, in: Capsule())
    }
}
