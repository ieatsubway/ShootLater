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
                drawBottomScrim(in: rect, context: cgContext)
            } else {
                drawLocationOnlyCard(in: rect, context: cgContext)
            }

            drawCardText(spot.displayLocation, in: rect, hasPhoto: photo != nil)
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

    private func drawBottomScrim(in rect: CGRect, context: CGContext) {
        let colors = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.withAlphaComponent(0.18).cgColor,
            UIColor.black.withAlphaComponent(0.62).cgColor
        ]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 0.42, 1])!
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: rect.midX, y: rect.midY - 40),
            end: CGPoint(x: rect.midX, y: rect.maxY),
            options: []
        )
    }

    private func drawLocationOnlyCard(in rect: CGRect, context: CGContext) {
        let colors = [
            UIColor(red: 0.08, green: 0.13, blue: 0.15, alpha: 1).cgColor,
            UIColor(red: 0.10, green: 0.38, blue: 0.36, alpha: 1).cgColor,
            UIColor(red: 0.82, green: 0.55, blue: 0.25, alpha: 1).cgColor
        ]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 0.72, 1])!
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: rect.width, y: rect.height), options: [])

        UIColor.white.withAlphaComponent(0.16).setStroke()
        context.setLineWidth(5)
        for inset in stride(from: CGFloat(120), through: CGFloat(420), by: CGFloat(110)) {
            context.strokeEllipse(in: rect.insetBy(dx: inset, dy: inset))
        }

        let pinRect = CGRect(x: rect.midX - 74, y: rect.midY - 130, width: 148, height: 148)
        UIColor.white.withAlphaComponent(0.94).setFill()
        context.fillEllipse(in: pinRect)

        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 68, weight: .semibold)
        let symbol = UIImage(systemName: "mappin.and.ellipse", withConfiguration: symbolConfig)?
            .withTintColor(UIColor(red: 0.08, green: 0.36, blue: 0.34, alpha: 1), renderingMode: .alwaysOriginal)
        symbol?.draw(in: pinRect.insetBy(dx: 28, dy: 28))

        drawBottomScrim(in: rect, context: context)
    }

    private func drawCardText(_ text: String, in rect: CGRect, hasPhoto: Bool) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        paragraph.lineBreakMode = .byTruncatingTail

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 28, weight: .semibold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.78),
            .paragraphStyle: paragraph
        ]
        "ShootLater".draw(
            with: CGRect(x: 72, y: hasPhoto ? 708 : 686, width: 920, height: 42),
            options: [.usesLineFragmentOrigin],
            attributes: labelAttributes,
            context: nil
        )

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fittedFontSize(for: text), weight: .semibold),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraph
        ]
        text.draw(
            with: CGRect(x: 72, y: 760, width: 920, height: 196),
            options: [.usesLineFragmentOrigin],
            attributes: attributes,
            context: nil
        )
    }

    private func fittedFontSize(for text: String) -> CGFloat {
        switch text.count {
        case 0...28: 72
        case 29...48: 60
        case 49...72: 50
        default: 42
        }
    }
}
