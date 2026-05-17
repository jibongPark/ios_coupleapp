import Foundation
import UIKit

public struct CanvasSnapshotStrokeInput: Equatable, Sendable {
    public let sequence: Int
    public let toolRawValue: String
    public let colorHex: String
    public let lineWidth: Double
    public let points: [CanvasSnapshotPointInput]

    public init(sequence: Int, toolRawValue: String, colorHex: String, lineWidth: Double, points: [CanvasSnapshotPointInput]) {
        self.sequence = sequence
        self.toolRawValue = toolRawValue
        self.colorHex = colorHex
        self.lineWidth = lineWidth
        self.points = points
    }
}

public struct CanvasSnapshotPointInput: Equatable, Sendable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = min(max(x, 0), 1)
        self.y = min(max(y, 0), 1)
    }
}

public enum CanvasSnapshotRenderer {
    public static func render(
        strokes: [CanvasSnapshotStrokeInput],
        size: CGSize = CGSize(width: 800, height: 800),
        backgroundColor: UIColor = UIColor(red: 0.98, green: 0.93, blue: 0.86, alpha: 1)
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            for stroke in strokes.sorted(by: { $0.sequence < $1.sequence }) {
                draw(stroke: stroke, in: context.cgContext, size: size, backgroundColor: backgroundColor)
            }
        }
    }

    public static func writePNG(
        strokes: [CanvasSnapshotStrokeInput],
        to url: URL,
        size: CGSize = CGSize(width: 800, height: 800)
    ) throws -> URL {
        let image = render(strokes: strokes, size: size)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try image.pngData()?.write(to: url, options: [.atomic])
        return url
    }

    private static func draw(stroke: CanvasSnapshotStrokeInput, in cgContext: CGContext, size: CGSize, backgroundColor: UIColor) {
        guard stroke.points.count > 1 else { return }
        cgContext.setLineCap(.round)
        cgContext.setLineJoin(.round)
        cgContext.setLineWidth(CGFloat(stroke.lineWidth))
        cgContext.setStrokeColor(stroke.toolRawValue == "eraser" ? backgroundColor.cgColor : UIColor(hex: stroke.colorHex).cgColor)
        let first = stroke.points[0]
        cgContext.beginPath()
        cgContext.move(to: CGPoint(x: first.x * size.width, y: first.y * size.height))
        for point in stroke.points.dropFirst() {
            cgContext.addLine(to: CGPoint(x: point.x * size.width, y: point.y * size.height))
        }
        cgContext.strokePath()
    }
}

private extension UIColor {
    convenience init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r, g, b: UInt64
        switch cleaned.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xff, (int >> 8) & 0xff, int & 0xff)
        default:
            (r, g, b) = (61, 44, 46)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
    }
}
