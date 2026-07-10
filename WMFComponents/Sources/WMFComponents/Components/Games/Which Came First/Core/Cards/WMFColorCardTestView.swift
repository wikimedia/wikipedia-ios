//
//  WMFColorCardTestView.swift
//  WMFComponents
//
//  Created by Grey Olson on 7/9/26.
//

import SwiftUI

// MARK: - Test data

private struct SampleArticle {
    let title: String
    let subtitle: String
    let description: String
    let imageURL: URL?
}

private let sampleArticles: [SampleArticle] = [
    SampleArticle(
        title: "Black Hole",
        subtitle: "Compact astronomical body",
        description: "A black hole is an astronomical body so compact that its gravity prevents anything from escaping, including light.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/5/5e/Artist%E2%80%99s_impression_of_the_black_hole_inside_NGC_300_X-1_%28ESO_1004a%29.jpg")
    ),
    SampleArticle(
        title: "Amazon River",
        subtitle: "River in South America",
        description: "The Amazon River is the largest river by discharge volume of water in the world and the disputed longest river in the world.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/1/15/Amazon_River%2C_Sentinel-2.jpg")
    ),
    SampleArticle(
        title: "Aurora Borealis",
        subtitle: "Natural light display",
        description: "A natural light display in Earth's sky, predominantly seen in high-latitude regions, caused by disturbances in the magnetosphere.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/8/86/Lofoten%2C_Norway_%28Unsplash%29.jpg")
    ),
    SampleArticle(
        title: "Sahara Desert",
        subtitle: "Largest hot desert on Earth",
        description: "The Sahara is a hot desert located in the northern part of Africa. It is the largest hot desert in the world.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/3/3e/Gourara_Monument_%28Timimoun%29_01.jpg")
    ),
    SampleArticle(
        title: "Paper Ball",
        subtitle: "Worst-case brightness test",
        description: "A crumpled white paper ball — nearly white average color, the hardest case for contrast enforcement against white text.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/e/ea/Paperball_2.jpeg")
    ),
    SampleArticle(
        title: "No Image",
        subtitle: "Fallback state",
        description: "This card has no image URL, demonstrating the fallback appearance when thumbnail data is unavailable.",
        imageURL: nil
    )
]

// MARK: - WCAG contrast helpers

/// Linearises an sRGB channel value (0–1) for relative luminance calculation.
private func linearise(_ c: CGFloat) -> CGFloat {
    c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
}

/// Relative luminance of an RGB color (channels in 0–1 range), per WCAG 2.1.
private func relativeLuminance(r: CGFloat, g: CGFloat, b: CGFloat) -> CGFloat {
    0.2126 * linearise(r) + 0.7152 * linearise(g) + 0.0722 * linearise(b)
}

/// WCAG 2.1 contrast ratio between two luminances.
private func contrastRatio(l1: CGFloat, l2: CGFloat) -> CGFloat {
    let lighter = max(l1, l2)
    let darker  = min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)
}

/// Darkens an RGB color (channels 0–1) by multiplying each channel by `step`
/// repeatedly until the contrast ratio against white reaches `targetRatio`.
/// Returns the darkened RGB triple.
private func darkenToMeetContrast(
    r: CGFloat, g: CGFloat, b: CGFloat,
    targetRatio: CGFloat = 4.5,
    step: CGFloat = 0.95
) -> (CGFloat, CGFloat, CGFloat) {
    let whiteLuminance: CGFloat = 1.0
    var r = r, g = g, b = b

    while true {
        let L = relativeLuminance(r: r, g: g, b: b)
        let ratio = contrastRatio(l1: whiteLuminance, l2: L)
        if ratio >= targetRatio { break }
        r *= step
        g *= step
        b *= step
        // Safety floor — pure black always passes
        if r < 0.001 && g < 0.001 && b < 0.001 { break }
    }

    return (r, g, b)
}

// MARK: - Card view

private struct ColorSampledCard: View {
    let article: SampleArticle
    @State private var loadedImage: UIImage? = nil
    @State private var dominantColor: Color = Color(white: 0.22)

    var body: some View {
        VStack(spacing: 0) {
            imageSection
            textSection
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .task { await loadImage() }
    }

    private var imageSection: some View {
        ZStack(alignment: .bottom) {
            Group {
                if let image = loadedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else if article.imageURL != nil {
                    Rectangle()
                        .fill(Color(uiColor: .systemGray5))
                        .overlay(ProgressView())
                } else {
                    Rectangle()
                        .fill(dominantColor.opacity(0.4))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 240)
            .clipped()

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: dominantColor.opacity(0.6), location: 0.65),
                    .init(color: dominantColor, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 240)
        }
    }

    private var textSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(article.title)
                .font(.system(size: 26, weight: .light))
                .foregroundColor(.white)

            Text(article.subtitle)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))

            Rectangle()
                .fill(Color.white.opacity(0.35))
                .frame(width: 36, height: 1)
                .padding(.vertical, 4)

            Text(article.description)
                .font(.callout)
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(dominantColor)
    }

    private func loadImage() async {
        guard let url = article.imageURL else { return }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data) else { return }
        loadedImage = image
        if let color = accessibleSampledColor(from: image) {
            withAnimation(.easeInOut(duration: 0.3)) {
                dominantColor = color
            }
        }
    }

    /// Averages the bottom third of the image, then iteratively darkens the result
    /// until it achieves at least WCAG AA contrast (4.5:1) against white text.
    private func accessibleSampledColor(from image: UIImage) -> Color? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return nil }

        let sampleStartY = (height * 2) / 3
        let sampleHeight = height - sampleStartY

        guard let cropped = cgImage.cropping(
            to: CGRect(x: 0, y: sampleStartY, width: width, height: sampleHeight)
        ) else { return nil }

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var rawData = [UInt8](repeating: 0, count: sampleHeight * bytesPerRow)

        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: sampleHeight,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cropped, in: CGRect(x: 0, y: 0, width: width, height: sampleHeight))

        var totalR: CGFloat = 0
        var totalG: CGFloat = 0
        var totalB: CGFloat = 0
        let pixelCount = CGFloat(width * sampleHeight)

        for i in stride(from: 0, to: rawData.count, by: bytesPerPixel) {
            totalR += CGFloat(rawData[i])
            totalG += CGFloat(rawData[i + 1])
            totalB += CGFloat(rawData[i + 2])
        }

        // Average, normalised to 0–1
        var r = totalR / pixelCount / 255
        var g = totalG / pixelCount / 255
        var b = totalB / pixelCount / 255

        // Darken iteratively until white text passes WCAG AA (4.5:1)
        (r, g, b) = darkenToMeetContrast(r: r, g: g, b: b, targetRatio: 4.5)

        return Color(red: r, green: g, blue: b)
    }
}

// MARK: - Test view

public struct WMFColorCardTestView: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Color card test")
                        .font(.title2.bold())
                    Text("Each card samples its image and darkens iteratively until white text passes WCAG AA (4.5:1).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach(sampleArticles.indices, id: \.self) { index in
                    ColorSampledCard(article: sampleArticles[index])
                }
            }
            .padding()
        }
    }
}

// MARK: - Previews

#Preview("All cards") {
    WMFColorCardTestView()
}

#Preview("Single — dark image") {
    ColorSampledCard(article: sampleArticles[0])
        .padding()
}

#Preview("Single — green image") {
    ColorSampledCard(article: sampleArticles[1])
        .padding()
}

#Preview("Single — paper ball (bright)") {
    ColorSampledCard(article: sampleArticles[4])
        .padding()
}

#Preview("Single — no image") {
    ColorSampledCard(article: sampleArticles[5])
        .padding()
}
