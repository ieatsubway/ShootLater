import Foundation
import SwiftUI
import UIKit

struct SharePayload {
    var image: UIImage
    var text: String
    var mapsURL: URL?

    var activityItems: [Any] {
        var items: [Any] = [image, text]
        if let mapsURL {
            items.append(mapsURL)
        }
        return items
    }
}

struct ShareCardRenderer {
    func appleMapsURL(for spot: ShootSpot) -> URL? {
        guard let latitude = spot.latitude, let longitude = spot.longitude else { return nil }
        var components = URLComponents(string: "https://maps.apple.com/")
        components?.queryItems = [
            URLQueryItem(name: "ll", value: String(format: "%.6f,%.6f", latitude, longitude)),
            URLQueryItem(name: "q", value: spot.locationDisplayName ?? spot.bestDisplayTitle)
        ]
        return components?.url
    }

    func shareText(for spot: ShootSpot) -> String {
        var parts: [String] = []
        if let title = spot.title?.trimmedNilIfEmpty {
            parts.append(title)
        }
        if let notes = spot.notes?.trimmedNilIfEmpty {
            parts.append(notes)
        }
        if parts.isEmpty {
            return spot.displayLocation
        }
        return parts.joined(separator: "\n")
    }

    @MainActor
    func payload(for spot: ShootSpot, photo: UIImage?) -> SharePayload {
        let image = renderCard(for: spot, photo: photo)
        return SharePayload(image: image, text: shareText(for: spot), mapsURL: appleMapsURL(for: spot))
    }

    @MainActor
    func renderCard(for spot: ShootSpot, photo: UIImage?) -> UIImage {
        let size = CGSize(width: 1_080, height: 1_080)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let cgContext = context.cgContext

            if let photo {
                drawImage(photo, in: rect)
                UIColor.black.withAlphaComponent(0.36).setFill()
                cgContext.fill(rect)
            } else {
                let colors = [UIColor.systemTeal.cgColor, UIColor.systemIndigo.cgColor]
                let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])!
                cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
                UIColor.white.withAlphaComponent(0.18).setStroke()
                cgContext.setLineWidth(6)
                cgContext.strokeEllipse(in: rect.insetBy(dx: 220, dy: 220))
            }

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .left
            paragraph.lineBreakMode = .byWordWrapping
            let text = spot.displayLocation
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 72, weight: .semibold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraph
            ]
            let textRect = CGRect(x: 72, y: 760, width: 920, height: 220)
            text.draw(with: textRect, options: [.usesLineFragmentOrigin], attributes: attributes, context: nil)
        }
    }

    private func drawImage(_ image: UIImage, in rect: CGRect) {
        let imageSize = image.size
        let scale = max(rect.width / imageSize.width, rect.height / imageSize.height)
        let scaled = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let drawRect = CGRect(
            x: rect.midX - scaled.width / 2,
            y: rect.midY - scaled.height / 2,
            width: scaled.width,
            height: scaled.height
        )
        image.draw(in: drawRect)
    }
}
