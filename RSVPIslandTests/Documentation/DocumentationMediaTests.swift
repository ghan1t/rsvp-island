import CoreGraphics
import ImageIO
import SwiftUI
import UniformTypeIdentifiers
import XCTest
@testable import RSVPIsland

@MainActor
final class DocumentationMediaTests: XCTestCase {
    private let canvasSize = CGSize(width: 640, height: 200)

    func testDocumentationMediaIsCurrent() throws {
        let media = try generatedMedia()
        let outputDirectory = repositoryRoot
            .appendingPathComponent("docs/media", isDirectory: true)
        let shouldUpdate = FileManager.default.fileExists(
            atPath: repositoryRoot.appendingPathComponent(".build/update-documentation-media").path
        )

        if shouldUpdate {
            try FileManager.default.createDirectory(
                at: outputDirectory,
                withIntermediateDirectories: true
            )
            for (filename, data) in media {
                try data.write(to: outputDirectory.appendingPathComponent(filename), options: .atomic)
            }
            return
        }

        for (filename, expectedData) in media {
            let url = outputDirectory.appendingPathComponent(filename)
            guard let committedData = try? Data(contentsOf: url) else {
                XCTFail("Missing \(filename). Run ./generate-documentation-media.sh")
                continue
            }
            if filename.hasSuffix(".gif") {
                XCTAssertTrue(
                    visuallyEquivalentGIFs(committedData, expectedData),
                    "\(filename) is stale. Run ./generate-documentation-media.sh"
                )
            } else {
                XCTAssertEqual(
                    committedData,
                    expectedData,
                    "\(filename) is stale. Run ./generate-documentation-media.sh"
                )
            }
        }
    }

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func generatedMedia() throws -> [String: Data] {
        let tokenizer = RSVPTokenizer()
        let tokens = tokenizer.tokenize(
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
                + "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. "
                + "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris."
        )
        let animationFrameRate = 24.0
        let animationSteps = 12
        let openingFrames = (0...animationSteps).map { step in
            readerState(
                step == 0 ? .hidden : .expanding,
                token: nil,
                expansionProgress: easeOut(Double(step) / Double(animationSteps))
            )
        }
        let readingFrames = tokens.map { readerState(.playing, token: $0) }
        let closingFrames = (0...animationSteps).map { step in
            readerState(
                step == animationSteps ? .hidden : .collapsing,
                token: nil,
                expansionProgress: easeIn(1 - Double(step) / Double(animationSteps))
            )
        }

        let gifFrames = openingFrames + readingFrames + closingFrames
        let gifImages = try gifFrames.map { state in
            try render(
                documentationCanvas(ReaderSurfaceView(state: state)),
                size: canvasSize,
                scale: 1
            )
        }
        let animationDelays = Array(repeating: 1 / animationFrameRate, count: animationSteps + 1)
        let readingDelays = tokens.map { token in
            60 / 350 * token.delayMultiplier
        }
        var delays = animationDelays + readingDelays + animationDelays
        delays[delays.count - 1] = 0.7

        return [
            "island-in-action.gif": try encodeGIF(gifImages, delays: delays),
            "menu-options.png": try encodePNG(
                try render(menuSnapshot, size: CGSize(width: 390, height: 340), scale: 2)
            )
        ]
    }

    private func readerState(
        _ presentationState: ReaderPresentationState,
        token: RSVPToken?,
        expansionProgress: Double? = nil
    ) -> ReaderSurfaceState {
        ReaderSurfaceState(
            presentationState: presentationState,
            token: token,
            wordsPerMinute: 350,
            expandedWidth: 600,
            closedSize: CGSize(width: 185, height: 32),
            fallbackHiddenOffset: 0,
            sourceLabel: "Selection",
            sourceIconName: "laptopcomputer",
            expansionProgressOverride: expansionProgress.map { CGFloat($0) }
        )
    }

    private func easeOut(_ value: Double) -> Double {
        1 - pow(1 - value, 3)
    }

    private func easeIn(_ value: Double) -> Double {
        pow(value, 3)
    }

    private func documentationCanvas<Content: View>(_ content: Content) -> some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.16, blue: 0.28), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            content
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
    }

    private var menuSnapshot: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
            SettingsMenuContent(
                wordsPerMinute: .constant(350),
                firstWordPauseSeconds: .constant(1),
                sentenceSkipWindowSeconds: .constant(0.5),
                launchAtLogin: .constant(false),
                accessibilityEnabled: true,
                loginError: nil,
                showsShortcutRecorder: false,
                usesStaticControls: true,
                requestAccess: {},
                readClipboard: {},
                showAbout: {},
                quit: {}
            )
        }
        .frame(width: 390, height: 340)
        .environment(\.colorScheme, .dark)
    }

    private func render<Content: View>(
        _ content: Content,
        size: CGSize,
        scale: CGFloat
    ) throws -> CGImage {
        let renderer = ImageRenderer(
            content: content.frame(width: size.width, height: size.height)
        )
        renderer.proposedSize = ProposedViewSize(size)
        renderer.scale = scale
        guard let image = renderer.cgImage else {
            throw MediaError.renderFailed
        }
        return image
    }

    private func encodePNG(_ image: CGImage) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw MediaError.destinationCreationFailed
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw MediaError.encodingFailed
        }
        return data as Data
    }

    private func encodeGIF(_ images: [CGImage], delays: [Double]) throws -> Data {
        precondition(images.count == delays.count)
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.gif.identifier as CFString,
            images.count,
            nil
        ) else {
            throw MediaError.destinationCreationFailed
        }
        CGImageDestinationSetProperties(destination, [
            kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]
        ] as CFDictionary)
        for (image, delay) in zip(images, delays) {
            CGImageDestinationAddImage(destination, image, [
                kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: delay]
            ] as CFDictionary)
        }
        guard CGImageDestinationFinalize(destination) else {
            throw MediaError.encodingFailed
        }
        return data as Data
    }

    private func visuallyEquivalentGIFs(_ lhs: Data, _ rhs: Data) -> Bool {
        guard let lhsSource = CGImageSourceCreateWithData(lhs as CFData, nil),
              let rhsSource = CGImageSourceCreateWithData(rhs as CFData, nil),
              CGImageSourceGetCount(lhsSource) == CGImageSourceGetCount(rhsSource) else {
            return false
        }

        for index in 0..<CGImageSourceGetCount(lhsSource) {
            let lhsDelay = gifDelay(source: lhsSource, index: index)
            let rhsDelay = gifDelay(source: rhsSource, index: index)
            guard delaysAreEquivalent(lhsDelay, rhsDelay),
                  let lhsImage = CGImageSourceCreateImageAtIndex(lhsSource, index, nil),
                  let rhsImage = CGImageSourceCreateImageAtIndex(rhsSource, index, nil),
                  lhsImage.width == rhsImage.width,
                  lhsImage.height == rhsImage.height else {
                return false
            }
            let lhsPixels = rgbaPixels(lhsImage)
            let rhsPixels = rgbaPixels(rhsImage)
            guard lhsPixels.count == rhsPixels.count else { return false }

            var totalDifference = 0
            var comparedBytes = 0
            for offset in stride(from: 0, to: lhsPixels.count, by: 40) {
                totalDifference += abs(Int(lhsPixels[offset]) - Int(rhsPixels[offset]))
                comparedBytes += 1
            }
            guard comparedBytes > 0, Double(totalDifference) / Double(comparedBytes) < 1 else {
                return false
            }
        }
        return true
    }

    private func delaysAreEquivalent(_ lhs: Double?, _ rhs: Double?) -> Bool {
        switch (lhs, rhs) {
        case let (.some(lhs), .some(rhs)): abs(lhs - rhs) < 0.005
        case (nil, nil): true
        default: false
        }
    }

    private func gifDelay(source: CGImageSource, index: Int) -> Double? {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gif = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
            return nil
        }
        return gif[kCGImagePropertyGIFDelayTime] as? Double
    }

    private func rgbaPixels(_ image: CGImage) -> [UInt8] {
        var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
        pixels.withUnsafeMutableBytes { buffer in
            let context = CGContext(
                data: buffer.baseAddress,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: image.width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
            context?.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        return pixels
    }

    private enum MediaError: Error {
        case renderFailed
        case destinationCreationFailed
        case encodingFailed
    }
}
