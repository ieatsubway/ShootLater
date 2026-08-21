import SwiftUI
import UIKit

enum ShootLaterTheme {
    static let maxContentWidth: CGFloat = 760
    static let wideContentWidth: CGFloat = 1120
    static let cornerRadius: CGFloat = 24
    static let compactSpacing: CGFloat = 16
    static let relaxedSpacing: CGFloat = 24

    static let teal = adaptive(
        light: UIColor(red: 0.08, green: 0.36, blue: 0.31, alpha: 1),
        dark: UIColor(red: 0.39, green: 0.78, blue: 0.70, alpha: 1)
    )
    static let ink = Color(uiColor: .label)
    static let amber = adaptive(
        light: UIColor(red: 0.76, green: 0.38, blue: 0.08, alpha: 1),
        dark: UIColor(red: 1.00, green: 0.68, blue: 0.31, alpha: 1)
    )
    static let mist = adaptive(
        light: UIColor(red: 0.88, green: 0.94, blue: 0.91, alpha: 1),
        dark: UIColor(red: 0.10, green: 0.20, blue: 0.18, alpha: 1)
    )
    static let slate = Color(uiColor: .secondaryLabel)
    static let backdropBase = adaptive(
        light: UIColor(red: 0.96, green: 0.97, blue: 0.94, alpha: 1),
        dark: UIColor(red: 0.035, green: 0.065, blue: 0.06, alpha: 1)
    )
    static let backdropTeal = adaptive(
        light: UIColor(red: 0.85, green: 0.93, blue: 0.89, alpha: 1),
        dark: UIColor(red: 0.055, green: 0.18, blue: 0.16, alpha: 1)
    )
    static let moss = adaptive(
        light: UIColor(red: 0.76, green: 0.85, blue: 0.74, alpha: 1),
        dark: UIColor(red: 0.17, green: 0.27, blue: 0.18, alpha: 1)
    )
    static let actionAmber = amber
    static let primaryAction = adaptive(
        light: UIColor(red: 0.70, green: 0.29, blue: 0.035, alpha: 1),
        dark: UIColor(red: 0.66, green: 0.26, blue: 0.02, alpha: 1)
    )
    static let clay = adaptive(
        light: UIColor(red: 0.93, green: 0.79, blue: 0.67, alpha: 1),
        dark: UIColor(red: 0.34, green: 0.14, blue: 0.10, alpha: 1)
    )
    static let glassTint = adaptive(
        light: UIColor(red: 0.91, green: 0.95, blue: 0.92, alpha: 0.34),
        dark: UIColor(red: 0.10, green: 0.25, blue: 0.22, alpha: 0.22)
    )
    static let hairline = Color(uiColor: .separator)

    static var scoutingGradient: LinearGradient {
        LinearGradient(
            colors: [teal, Color(red: 0.08, green: 0.20, blue: 0.18), amber],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

struct ScoutingBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            let longestSide = max(proxy.size.width, proxy.size.height)

            ZStack {
                LinearGradient(
                    colors: [
                        ShootLaterTheme.backdropBase,
                        ShootLaterTheme.backdropTeal,
                        ShootLaterTheme.backdropBase
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Circle()
                    .fill(ShootLaterTheme.actionAmber.opacity(colorScheme == .dark ? 0.14 : 0.12))
                    .frame(width: longestSide * 0.62, height: longestSide * 0.62)
                    .blur(radius: 96)
                    .offset(x: -proxy.size.width * 0.42, y: -proxy.size.height * 0.38)

                Circle()
                    .fill(ShootLaterTheme.teal.opacity(colorScheme == .dark ? 0.18 : 0.10))
                    .frame(width: longestSide * 0.78, height: longestSide * 0.78)
                    .blur(radius: 118)
                    .offset(x: proxy.size.width * 0.48, y: proxy.size.height * 0.10)

                Circle()
                    .fill(ShootLaterTheme.moss.opacity(colorScheme == .dark ? 0.12 : 0.10))
                    .frame(width: longestSide * 0.70, height: longestSide * 0.70)
                    .blur(radius: 124)
                    .offset(x: -proxy.size.width * 0.30, y: proxy.size.height * 0.48)
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
                    .stroke(ShootLaterTheme.hairline.opacity(0.55), lineWidth: 0.5)
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
            .background(.thinMaterial, in: Capsule())
    }
}

struct LocationPermissionBadge: View {
    let state: LocationService.AuthorizationState

    private var label: String {
        switch state {
        case .unknown: "Location permission needed"
        case .allowed: "Location ready"
        case .denied: "Location off"
        }
    }

    private var systemImage: String {
        switch state {
        case .unknown: "location"
        case .allowed: "location.fill"
        case .denied: "location.slash"
        }
    }

    var body: some View {
        Label(label, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.thinMaterial, in: Capsule())
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
            .glassEffect(
                .regular.tint(ShootLaterTheme.glassTint),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(ShootLaterTheme.hairline.opacity(0.40), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.08), radius: 22, y: 10)
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
            .background(.thinMaterial, in: Capsule())
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
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ShootLaterTheme.hairline.opacity(0.35), lineWidth: 0.5)
        }
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(ShootLaterTheme.hairline.opacity(0.44), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
    }
}
