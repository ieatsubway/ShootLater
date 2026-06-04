import SwiftUI
import UIKit

enum ShootLaterTheme {
    static let maxContentWidth: CGFloat = 760
    static let wideContentWidth: CGFloat = 1120
    static let cornerRadius: CGFloat = 24
    static let compactSpacing: CGFloat = 16
    static let relaxedSpacing: CGFloat = 24

    static let teal = Color(red: 0.18, green: 0.41, blue: 0.36)
    static let ink = Color(red: 0.10, green: 0.12, blue: 0.14)
    static let amber = Color(red: 0.88, green: 0.58, blue: 0.22)
    static let mist = Color(red: 0.92, green: 0.95, blue: 0.93)
    static let slate = Color(red: 0.18, green: 0.22, blue: 0.27)
    static let backdropBase = Color(red: 0.04, green: 0.10, blue: 0.10)
    static let backdropTeal = Color(red: 0.08, green: 0.30, blue: 0.27)
    static let moss = Color(red: 0.34, green: 0.48, blue: 0.34)
    static let actionAmber = Color(red: 0.92, green: 0.56, blue: 0.20)
    static let clay = Color(red: 0.78, green: 0.34, blue: 0.25)

    static var scoutingGradient: LinearGradient {
        LinearGradient(
            colors: [backdropBase, backdropTeal, actionAmber],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct ScoutingBackdrop: View {
    var softWash: Double = 0.16

    var body: some View {
        GeometryReader { proxy in
            let longestSide = max(proxy.size.width, proxy.size.height)

            ZStack {
                LinearGradient(
                    colors: [
                        ShootLaterTheme.backdropBase,
                        ShootLaterTheme.backdropTeal,
                        ShootLaterTheme.moss.opacity(0.86),
                        ShootLaterTheme.actionAmber.opacity(0.88)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(ShootLaterTheme.actionAmber.opacity(0.62))
                    .frame(width: longestSide * 0.58, height: longestSide * 0.58)
                    .blur(radius: 76)
                    .offset(x: -proxy.size.width * 0.34, y: -proxy.size.height * 0.26)

                Circle()
                    .fill(ShootLaterTheme.backdropTeal.opacity(0.78))
                    .frame(width: longestSide * 0.74, height: longestSide * 0.74)
                    .blur(radius: 92)
                    .offset(x: proxy.size.width * 0.38, y: -proxy.size.height * 0.14)

                Circle()
                    .fill(ShootLaterTheme.clay.opacity(0.58))
                    .frame(width: longestSide * 0.56, height: longestSide * 0.56)
                    .blur(radius: 88)
                    .offset(x: proxy.size.width * 0.35, y: proxy.size.height * 0.33)

                Circle()
                    .fill(ShootLaterTheme.mist.opacity(0.42))
                    .frame(width: longestSide * 0.82, height: longestSide * 0.82)
                    .blur(radius: 110)
                    .offset(x: -proxy.size.width * 0.18, y: proxy.size.height * 0.22)

                LinearGradient(
                    colors: [
                        Color.white.opacity(softWash * 0.24),
                        Color.white.opacity(softWash),
                        Color.white.opacity(softWash * 0.34)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        }
    }
}

struct SpotThumbnail: View {
    let fileName: String?
    let size: CGFloat
    var showSourceBadge = false
    var source: SpotSource?
    private let photoStore = PhotoStore()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let image = photoStore.image(for: fileName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    LocationOnlyArtwork(size: size)
                }
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: min(22, size * 0.20), style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: min(22, size * 0.20), style: .continuous)
                    .stroke(.white.opacity(0.36), lineWidth: 1)
            }

            if showSourceBadge {
                Image(systemName: source == .cameraCapture ? "camera.fill" : "location.fill")
                    .font(.system(size: max(11, size * 0.14), weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: max(24, size * 0.24), height: max(24, size * 0.24))
                    .background(.black.opacity(0.42), in: Circle())
                    .padding(max(5, size * 0.045))
            }
        }
        .shadow(color: .black.opacity(0.12), radius: size > 100 ? 18 : 8, y: size > 100 ? 10 : 4)
        .accessibilityHidden(true)
    }
}

struct LocationStatusBadge: View {
    let status: LocationStatus

    var body: some View {
        Label(status.label, systemImage: status == .unavailable ? "location.slash" : "location.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .glassEffect(.regular, in: Capsule())
    }
}

struct LocationOnlyArtwork: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            ShootLaterTheme.scoutingGradient

            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: size * 0.30, weight: .semibold))
                .foregroundStyle(.white)

            VStack {
                Spacer()
                HStack {
                    Circle()
                        .fill(.white.opacity(0.30))
                        .frame(width: size * 0.18, height: size * 0.18)
                    Spacer()
                }
            }
            .padding(size * 0.14)
        }
    }
}

struct AppMark: View {
    var size: CGFloat = 96

    var body: some View {
        ZStack {
            Circle()
                .fill(ShootLaterTheme.scoutingGradient)
            Circle()
                .stroke(.white.opacity(0.42), lineWidth: 1)
                .padding(size * 0.13)
            Image(systemName: "camera.aperture")
                .font(.system(size: size * 0.43, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .glassEffect(.regular, in: Circle())
        .shadow(color: ShootLaterTheme.teal.opacity(0.24), radius: 24, y: 12)
        .accessibilityHidden(true)
    }
}

struct GlassPanel<Content: View>: View {
    var cornerRadius: CGFloat = ShootLaterTheme.cornerRadius
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(18)
            .background(.white.opacity(0.24), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.42), lineWidth: 1)
            }
            .shadow(color: ShootLaterTheme.backdropBase.opacity(0.16), radius: 28, y: 14)
    }
}

struct SectionHeading: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.bold))
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MetadataPill: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(.white.opacity(0.28), in: Capsule())
            .glassEffect(.regular, in: Capsule())
    }
}

struct EmptyScoutingState: View {
    let title: String
    let message: String
    var systemImage: String = "camera.viewfinder"

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 84, height: 84)
                .background(ShootLaterTheme.scoutingGradient, in: Circle())
                .glassEffect(.regular, in: Circle())

            VStack(spacing: 6) {
                Text(title)
                    .font(.title3.weight(.bold))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(28)
        .frame(maxWidth: 420)
    }
}

struct InfoTile: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(ShootLaterTheme.teal)
                .frame(width: 28, height: 28)
                .background(ShootLaterTheme.mist, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.24), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct SpotCard: View {
    let spot: ShootSpot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SpotThumbnail(fileName: spot.photoFileName, size: 168, showSourceBadge: true, source: spot.source)
                .frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 6) {
                Text(spot.bestDisplayTitle)
                    .font(.headline)
                    .lineLimit(2)
                Text(spot.displayLocation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                HStack {
                    MetadataPill(title: spot.createdAt.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(12)
        .background(.white.opacity(0.26), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.secondary.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
    }
}
