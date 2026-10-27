import Metal
import RiveRuntime
import SwiftUI
import UIKit

/// Draws one Year in Review slide to a still image for sharing, from its own copy of the Rive
/// artboard, then adds the Wikipedia wordmark and a caption. The slide on screen does not change.
///
/// 1. Loads a second copy of the artboard with the same text, numbers, booleans, images and text
///    fits as the slide on screen.
/// 2. Moves the animation forward to `poseTime` in small steps.
/// 3. Draws the artboard into a Metal texture and reads the pixels back.
/// 4. Draws the wordmark at the top and the caption at the bottom.
@MainActor
public enum WMFYearInReviewSlideImageExporter {

    public nonisolated enum ExportError: LocalizedError {
        case noAnimation
        case loadFailed
        case noMetalDevice
        case noTexture
        case drawSkipped
        case noImage

        public var errorDescription: String? {
            switch self {
            case .noAnimation:
                return "The slide has no Rive animation to export."
            case .loadFailed:
                return "The Rive file for the export did not load."
            case .noMetalDevice:
                return "There is no Metal device."
            case .noTexture:
                return "Could not make the texture to draw into."
            case .drawSkipped:
                return "Rive skipped the draw."
            case .noImage:
                return "Could not make an image from the pixels."
            }
        }
    }

    /// 9:16, in pixels.
    public static let imageSize = CGSize(width: 1080, height: 1920)

    /// Design: every frame rests at 7 seconds.
    public static let poseTime: TimeInterval = 7

    /// The artboards are 360 wide, so 3 fills the 1080 pixel width.
    private static let layoutScale: Float = 3

    /// The animation moves forward in steps of this length, so that each state change can run.
    private static let stepInterval: TimeInterval = 1.0 / 60.0

    // MARK: - Wordmark and caption
    // From the Figma frame of the share image (T437468).

    /// The wordmark and the caption are laid out as on a phone this many points wide, then scaled up to the image. The
    /// same width as `WMFWhichCameFirstShareView`.
    private static let referenceWidth: CGFloat = 360
    private static let wordmarkAssetName = "wikipedia"
    private static let wordmarkHeight: CGFloat = 22
    private static let wordmarkTopMargin: CGFloat = 24
    private static let captionBottomMargin: CGFloat = 18
    /// The letter spacing of Caption2 in Figma.
    private static let captionKerning: CGFloat = 0.06
    private static let sideMargin: CGFloat = 24

    /// - Parameters:
    ///   - caption: The localized line at the bottom, "Created with the Wikipedia app".
    ///   - layoutDirection: The direction of the app language, for the frames that mirror.
    public static func image(
        for slide: WMFYearInReviewSlideViewModel,
        caption: String,
        layoutDirection: LayoutDirection
    ) async throws -> UIImage {
        guard let animation = slide.animation else {
            throw ExportError.noAnimation
        }

        let thumbnailLoader = WMFYearInReviewThumbnailLoader()
        await thumbnailLoader.load(slide.articleThumbnails)
        let images = slide.images.merging(thumbnailLoader.images) { _, loaded in loaded }
        var bools = slide.bools
        for (image, flag) in slide.missingImageFlags {
            bools[flag] = images[image] == nil
        }

        // Images are bound below, where the export can wait for them.
        let viewModel = WMFRiveAnimationViewModel(
            animation: animation,
            text: slide.text,
            numbers: slide.numbers,
            bools: bools,
            textFits: slide.textFits
        )
        if let property = slide.layoutDirection {
            viewModel.update(enums: [property.property: property.value(for: layoutDirection)])
        }
        await viewModel.load()
        defer { viewModel.unload() }

        guard viewModel.loadState.isLoaded,
              let rive = viewModel.rive,
              let instance = viewModel.boundInstance else {
            throw ExportError.loadFailed
        }

        await bind(images: images, to: instance, animation: animation)

        rive.fit = .layout(scaleFactor: .explicit(layoutScale))
        advance(rive, by: poseTime)

        let artwork = try await render(rive, size: imageSize)
        return addWordmarkAndCaption(to: artwork, caption: caption)
    }

    // MARK: - Images

    private static func bind(images: [WMFRiveImage: Data], to instance: ViewModelInstance, animation: WMFRiveAnimation) async {
        for (property, data) in images {
            do {
                let image = try await WMFRiveWorkerProvider.decodeImage(from: data)
                instance.setValue(of: ImageProperty(path: property.path), to: image)
            } catch {
                WMFRiveLogger.log(WMFRiveFailure(animation: animation, stage: .binding, reason: "Could not decode the image for \"\(property.path)\" in the export: \(error.localizedDescription)"))
            }
        }
    }

    // MARK: - Pose

    private static func advance(_ rive: Rive, by time: TimeInterval) {
        let steps = max(1, Int((time / stepInterval).rounded(.up)))
        for _ in 0..<steps {
            rive.stateMachine.advance(by: stepInterval)
        }
    }

    // MARK: - Drawing

    private static func render(_ rive: Rive, size: CGSize) async throws -> UIImage {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw ExportError.noMetalDevice
        }

        let width = Int(size.width)
        let height = Int(size.height)

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .shared

        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw ExportError.noTexture
        }

        let configuration = RiveUIRendererConfiguration(rive: rive, drawableSize: size)
        let renderer = rive.makeRenderer()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let once = ResumeOnce(continuation)
            renderer.draw(
                configuration,
                to: texture,
                from: device,
                // Rive and Metal call these off the main actor.
                onDraw: { @Sendable commandBuffer in
                    commandBuffer.addCompletedHandler { @Sendable finished in
                        if let error = finished.error {
                            once.resume(throwing: error)
                        } else {
                            once.resume()
                        }
                    }
                },
                onSkipped: { @Sendable in
                    once.resume(throwing: ExportError.drawSkipped)
                },
                onError: { @Sendable error in
                    once.resume(throwing: error)
                }
            )
        }

        return try makeImage(from: texture, width: width, height: height)
    }

    private static func makeImage(from texture: MTLTexture, width: Int, height: Int) throws -> UIImage {
        let bytesPerRow = width * 4
        var pixels = [UInt8](repeating: 0, count: bytesPerRow * height)
        texture.getBytes(
            &pixels,
            bytesPerRow: bytesPerRow,
            from: MTLRegionMake2D(0, 0, width, height),
            mipmapLevel: 0
        )

        // BGRA, with the alpha multiplied in.
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
            .union(.byteOrder32Little)

        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let cgImage = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo,
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              ) else {
            throw ExportError.noImage
        }

        return UIImage(cgImage: cgImage, scale: 1, orientation: .up)
    }

    // MARK: - Drawing the wordmark and the caption

    /// Draws the wordmark at the top center and the caption at the bottom center. The image is
    /// opaque, so a part of the artwork that is transparent shows the chrome color, as on screen.
    private static func addWordmarkAndCaption(to artwork: UIImage, caption: String) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let pixelSize = artwork.size
        let renderer = UIGraphicsImageRenderer(size: pixelSize, format: format)

        return renderer.image { context in
            WMFYearInReviewViewModel.chromeBackgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: pixelSize))
            artwork.draw(in: CGRect(origin: .zero, size: pixelSize))

            // Black, as in Figma, or white on dark artwork. `isUIWhite` describes only the top of the
            // artwork, so each one takes its color from the artwork behind it.
            let scale = pixelSize.width / referenceWidth
            let wordmarkArea = CGRect(x: 0, y: 0, width: pixelSize.width, height: (wordmarkTopMargin + wordmarkHeight + 8) * scale)
            let captionArea = CGRect(x: 0, y: pixelSize.height - (captionBottomMargin + 24) * scale, width: pixelSize.width, height: (captionBottomMargin + 24) * scale)
            let wordmarkColor = isDark(context.cgContext, in: wordmarkArea) ? WMFColor.white : WMFColor.black
            let captionColor = isDark(context.cgContext, in: captionArea) ? WMFColor.white : WMFColor.black

            // From here, draw in points of a phone that is `referenceWidth` wide.
            context.cgContext.scaleBy(x: scale, y: scale)
            let canvas = CGSize(width: referenceWidth, height: pixelSize.height / scale)

            // A fixed text size, so the image does not depend on the Dynamic Type setting of the reader.
            let traits = UITraitCollection(preferredContentSizeCategory: .large)

            if let wordmark = UIImage(named: wordmarkAssetName, in: .module, compatibleWith: traits)?
                .withTintColor(wordmarkColor, renderingMode: .alwaysOriginal),
               wordmark.size.height > 0 {
                let wordmarkWidth = wordmarkHeight * wordmark.size.width / wordmark.size.height
                wordmark.draw(in: CGRect(
                    x: (canvas.width - wordmarkWidth) / 2,
                    y: wordmarkTopMargin,
                    width: wordmarkWidth,
                    height: wordmarkHeight
                ))
            }

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let attributes: [NSAttributedString.Key: Any] = [
                .font: WMFFont.for(.caption2, compatibleWith: traits),
                .kern: captionKerning,
                .foregroundColor: captionColor,
                .paragraphStyle: paragraphStyle
            ]

            let maximumWidth = canvas.width - 2 * sideMargin
            let captionBounds = (caption as NSString).boundingRect(
                with: CGSize(width: maximumWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin],
                attributes: attributes,
                context: nil
            )
            let captionHeight = ceil(captionBounds.height)
            let captionRect = CGRect(
                x: sideMargin,
                y: canvas.height - captionBottomMargin - captionHeight,
                width: maximumWidth,
                height: captionHeight
            )
            (caption as NSString).draw(with: captionRect, options: [.usesLineFragmentOrigin], attributes: attributes, context: nil)
        }
    }
}

extension WMFYearInReviewSlideImageExporter {

    /// True if the average brightness of the area is below the middle. `area` is in pixels.
    fileprivate static func isDark(_ context: CGContext, in area: CGRect) -> Bool {
        guard let image = context.makeImage()?.cropping(to: area) else {
            return false
        }
        var pixel = [UInt8](repeating: 0, count: 4)
        guard let averaging = CGContext(
            data: &pixel,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return false
        }
        averaging.interpolationQuality = .medium
        averaging.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        let luminance = 0.2126 * Double(pixel[0]) + 0.7152 * Double(pixel[1]) + 0.0722 * Double(pixel[2])
        return luminance < 128
    }
}

/// Rive can call back on a background thread, and more than one of its callbacks can fire.
/// This makes sure the continuation resumes once.
nonisolated private final class ResumeOnce: @unchecked Sendable {

    private let lock = NSLock()
    private var continuation: CheckedContinuation<Void, Error>?

    init(_ continuation: CheckedContinuation<Void, Error>) {
        self.continuation = continuation
    }

    func resume() {
        take()?.resume()
    }

    func resume(throwing error: Error) {
        take()?.resume(throwing: error)
    }

    private func take() -> CheckedContinuation<Void, Error>? {
        lock.lock()
        defer { lock.unlock() }
        let taken = continuation
        continuation = nil
        return taken
    }
}
