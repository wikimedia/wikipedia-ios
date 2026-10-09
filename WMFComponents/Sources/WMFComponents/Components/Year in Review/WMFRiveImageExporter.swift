import Metal
import RiveRuntime
import UIKit

/// SPIKE (not compiled yet): draws one Year in Review slide to a still image, from its own copy of
/// the Rive artboard, then adds the Wikipedia logo and a caption. It does not touch the slide that
/// is on screen.
///
/// How it works:
/// 1. Loads a second copy of the slide's artboard with the same text, numbers, images and text
///    fitting as the live slide (`WMFRiveAnimationViewModel`).
/// 2. Moves the animation forward to `poseTime`, in small steps.
/// 3. Draws the artboard into a Metal texture that this file owns, then reads the pixels back.
/// 4. Draws the logo and the caption on top, with native drawing.
///
/// Rive's iOS 6.28.0 renderer draws into any Metal texture (`Rive.makeRenderer()`), so no on-screen
/// view is needed.
@MainActor
public enum WMFRiveImageExporter {

    public enum ExportError: LocalizedError {
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
    public static let defaultSize = CGSize(width: 1080, height: 1920)

    /// The animation moves forward in steps of this length, so that each state change has a
    /// chance to run. One large step could skip a change.
    private static let stepInterval: TimeInterval = 1.0 / 60.0

    // MARK: - Footer layout
    // PLACEHOLDERS. Take the real values from the Figma frame.

    /// The footer is laid out as on a phone this many points wide, then scaled up to the image.
    /// The same width is used by `WMFWhichCameFirstShareView`.
    private static let referenceWidth: CGFloat = 393

    /// The asset in `Assets.xcassets` of WMFComponents. Confirm against Figma that this is the logo it shows.
    private static let logoAssetName = "W-share-logo"
    private static let logoHeight: CGFloat = 28
    private static let logoToCaptionSpacing: CGFloat = 8
    private static let bottomMargin: CGFloat = 32
    private static let sideMargin: CGFloat = 24

    /// - Parameters:
    ///   - slide: The slide to export. Its text, numbers, thumbnails and text fits are used.
    ///   - poseTime: Seconds to move the animation forward. Ask design when the artwork reaches its resting pose.
    ///   - caption: The localized line under the logo, for example "Created with the Wikipedia app".
    ///   - size: The size of the image in pixels.
    ///   - fit: How the artboard fills the image. The live slide uses `.layout`, but Rive does not let
    ///     an app resize the artboard, so the export uses a fit that scales the artboard instead.
    public static func image(
        for slide: WMFYearInReviewSlideViewModel,
        poseTime: TimeInterval,
        caption: String,
        size: CGSize = defaultSize,
        fit: RiveRuntime.Fit = .cover(alignment: .center)
    ) async throws -> UIImage {
        guard let animation = slide.animation else {
            throw ExportError.noAnimation
        }

        let thumbnailLoader = WMFYearInReviewThumbnailLoader()
        await thumbnailLoader.load(slide.articleThumbnails)

        // Images are bound below, where this code can wait for them. The view model does not wait.
        let viewModel = WMFRiveAnimationViewModel(
            animation: animation,
            text: slide.text,
            numbers: slide.numbers,
            readBool: slide.lightContentFlag,
            textFits: slide.textFits
        )
        await viewModel.load()
        defer { viewModel.unload() }

        guard viewModel.loadState.isLoaded, let rive = viewModel.rive else {
            throw ExportError.loadFailed
        }

        // The artwork says whether it is light or dark. Without the flag, use the style of the slide.
        let prefersLight = viewModel.readBoolValue ?? slide.prefersLightContent
        let style: WMFYearInReviewSlideViewModel.ContentStyle = prefersLight ? .light : .dark

        await bind(images: thumbnailLoader.images, to: rive, animation: animation)

        rive.fit = fit
        advance(rive, by: poseTime)

        let artwork = try await render(rive, size: size)
        return addFooter(to: artwork, caption: caption, style: style)
    }

    // MARK: - Images

    private static func bind(images: [WMFRiveImage: Data], to rive: Rive, animation: WMFRiveAnimation) async {
        guard let instance = rive.viewModelInstance else { return }
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

        // Rive asks for this pixel format, and for a texture that it can render into.
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
                onDraw: { commandBuffer in
                    commandBuffer.addCompletedHandler { finished in
                        if let error = finished.error {
                            once.resume(throwing: error)
                        } else {
                            once.resume()
                        }
                    }
                },
                onSkipped: {
                    once.resume(throwing: ExportError.drawSkipped)
                },
                onError: { error in
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

        // BGRA with the alpha already multiplied in. This is an assumption about Rive's output.
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

    // MARK: - Footer

    /// Draws the logo and the caption at the bottom center, in the color of the artwork's style.
    private static func addFooter(to artwork: UIImage, caption: String, style: WMFYearInReviewSlideViewModel.ContentStyle) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false

        let pixelSize = artwork.size
        let renderer = UIGraphicsImageRenderer(size: pixelSize, format: format)

        return renderer.image { context in
            artwork.draw(in: CGRect(origin: .zero, size: pixelSize))

            // From here, draw in points of a phone that is `referenceWidth` wide.
            let scale = pixelSize.width / referenceWidth
            context.cgContext.scaleBy(x: scale, y: scale)
            let canvas = CGSize(width: referenceWidth, height: pixelSize.height / scale)

            let color = WMFColor.red600

            // A fixed text size, so the image does not depend on the Dynamic Type setting of the reader.
            let traits = UITraitCollection(preferredContentSizeCategory: .large)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let attributes: [NSAttributedString.Key: Any] = [
                .font: WMFFont.for(.caption1, compatibleWith: traits),
                .foregroundColor: color,
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
                y: canvas.height - bottomMargin - captionHeight,
                width: maximumWidth,
                height: captionHeight
            )
            (caption as NSString).draw(with: captionRect, options: [.usesLineFragmentOrigin], attributes: attributes, context: nil)

            guard let logo = UIImage(named: logoAssetName, in: .module, compatibleWith: traits)?
                .withTintColor(color, renderingMode: .alwaysOriginal),
                  logo.size.height > 0 else {
                return
            }
            let logoWidth = logoHeight * logo.size.width / logo.size.height
            let logoRect = CGRect(
                x: (canvas.width - logoWidth) / 2,
                y: captionRect.minY - logoToCaptionSpacing - logoHeight,
                width: logoWidth,
                height: logoHeight
            )
            logo.draw(in: logoRect)
        }
    }
}

/// Rive can call back on a background thread, and more than one of its callbacks can fire.
/// This makes sure the continuation resumes once.
private final class ResumeOnce: @unchecked Sendable {

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
