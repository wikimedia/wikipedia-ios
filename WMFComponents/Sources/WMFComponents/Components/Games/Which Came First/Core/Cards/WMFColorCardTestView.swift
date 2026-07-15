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

// MARK: Original samples

private let originalArticles: [SampleArticle] = [
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
    ),
]

// MARK: Light / transparent background samples
// These images have white, near-white, or transparent backgrounds. The color
// sampler must not produce a near-white card background that fails contrast.

private let lightBackgroundArticles: [SampleArticle] = [
    SampleArticle(
        title: "Apple Inc.",
        subtitle: "Light / transparent background",
        description: "The Apple logo on a white background — a common case for articles about tech companies, whose press assets are often logo-on-white.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/f/fa/Apple_logo_black.svg")
    ),
    SampleArticle(
        title: "Wrist",
        subtitle: "Light / transparent background",
        description: "Album art for the Logic song \"Wrist\" — a mostly white infobox image that exercises the minimum-luminance floor.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/en/6/63/WristLogic.jpg")
    ),
    SampleArticle(
        title: "Gospodin Savršeni",
        subtitle: "Light / transparent background",
        description: "Logo of a Croatian TV series on a white background — representative of infobox artwork across entertainment articles.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/en/c/c6/Gospodin_Savrseni_logo.png")
    ),
    SampleArticle(
        title: "4th Line Road",
        subtitle: "Light / transparent background",
        description: "A road-sign photograph against a pale sky — low-saturation, high-brightness scene that challenges the darkening loop.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/2/25/4th_Line_Road.png")
    ),
    SampleArticle(
        title: "Poland–Russia relations",
        subtitle: "Light / transparent background",
        description: "A locator map with a white background — typical of geopolitical and country-relation article thumbnails.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/1/12/Poland_Russia_Locator.svg/960px-Poland_Russia_Locator.svg.png")
    ),
]

// MARK: Portrait samples
// Portraits may produce awkward crops in a 4:3 or wider image section;
// these also test whether facial-area colors drive the sampler.

private let portraitArticles: [SampleArticle] = [
    SampleArticle(
        title: "Robert Mamątow",
        subtitle: "Portrait crop test",
        description: "A close-cropped official portrait — tests whether skin tones in the lower third produce a readable card background.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/8/81/Robert_Mam%C4%85tow_Kancelaria_Senatu_2015.jpg/960px-Robert_Mam%C4%85tow_Kancelaria_Senatu_2015.jpg")
    ),
    SampleArticle(
        title: "Lauren Bennett",
        subtitle: "Portrait crop test",
        description: "A performer portrait with a relatively uniform background — checks that bright, saturated clothing doesn't break the sampler.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/6/65/Lauren_Bennett_2013.jpg")
    ),
    SampleArticle(
        title: "Carmelo Cedrún",
        subtitle: "Portrait crop test",
        description: "An athlete portrait against a club-colored background — warm midtones common in sports biographies.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/2/29/Carmelo_Cedrun_Atletico_Bilbao.png")
    ),
]

// MARK: Diagram / illustration / scientific samples
// These images are typically flat vector art, charts, microscopy, or medical
// diagrams — often low-detail with limited color ranges.

private let diagramArticles: [SampleArticle] = [
    SampleArticle(
        title: "Pythagorean Theorem",
        subtitle: "Diagram / illustration",
        description: "A classic geometric diagram with flat color fills on a white background — representative of mathematics and science articles.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d2/Pythagorean.svg/960px-Pythagorean.svg.png")
    ),
    SampleArticle(
        title: "Common Logarithm",
        subtitle: "Diagram / illustration",
        description: "A graph plotted on a white background — a pure data visualization with almost no photographic content.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/7/7f/Graph_of_common_logarithm.svg")
    ),
    SampleArticle(
        title: "Transmission Electron Microscopy (lens)",
        subtitle: "Diagram / illustration",
        description: "A schematic cross-section of a TEM column — line art on white, extremely low average luminance variance.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/5/50/TEM-lens.svg")
    ),
    SampleArticle(
        title: "Poliovirus (TEM)",
        subtitle: "Scientific / microscopy",
        description: "A transmission electron micrograph of poliovirus — near-monochrome scientific imagery with very low saturation.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/7/77/Polio_EM_PHIL_1875_lores.PNG")
    ),
    SampleArticle(
        title: "Heart",
        subtitle: "Scientific / medical",
        description: "An anterior exterior view of the human heart — medical photography with deep reds and dark shadows.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/1/1b/Heart_anterior_exterior_view.png")
    ),
    SampleArticle(
        title: "Chimp Brain",
        subtitle: "Scientific / medical",
        description: "A chimpanzee brain preserved in a jar — pale, desaturated medical specimen photography.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/1/14/Chimp_Brain_in_a_jar.jpg")
    ),
]

// MARK: Violence / disaster / unpleasant content samples
// The color algorithm is content-agnostic, but these edge-case images (dark
// scenes, news photography, crime-scene stills) should still produce accessible
// cards regardless of their emotional content.

private let sensitiveContentArticles: [SampleArticle] = [
    SampleArticle(
        title: "Murder of Henry Nowak",
        subtitle: "Potentially unpleasant content",
        description: "A photograph associated with a violent crime — dark, desaturated news photography that should still yield a readable card.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/1/14/Henry_Nowak.png")
    ),
    SampleArticle(
        title: "Pulse Nightclub Shooting",
        subtitle: "Potentially unpleasant content",
        description: "A news photograph from the Pulse shooting aftermath — outdoor scene, likely bright, exercises the darkening loop on a high-key image.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/03/Orange_Avenue_closed_during_Pulse_shooting_%28cropped2%29.jpg/960px-Orange_Avenue_closed_during_Pulse_shooting_%28cropped2%29.jpg")
    ),
    SampleArticle(
        title: "1968 Meckering Earthquake",
        subtitle: "Potentially unpleasant content",
        description: "Earthquake damage at a rural homestead — warm-toned Australian landscape with structural debris in the foreground.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/Salisbury_homestead_gnangarra-44.jpg/960px-Salisbury_homestead_gnangarra-44.jpg")
    ),
]

// MARK: Saturation edge-case samples
// High-saturation, low-saturation, and monochromatic images push the color math
// in different directions; each should still pass WCAG AA.

private let saturationArticles: [SampleArticle] = [
    SampleArticle(
        title: "Mars Night Sky",
        subtitle: "Monochromatic / near-black",
        description: "Spirit Rover photograph of the Martian night sky — almost pure black with faint stars; the darkest possible average sample.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/4/4d/Spirit_Rover-Mars_Night_Sky.jpg")
    ),
    SampleArticle(
        title: "Tektite I (saturation diving)",
        subtitle: "Low-saturation / desaturated",
        description: "Exterior of the Tektite I habitat — muted olive and grey tones typical of low-contrast underwater or industrial photography.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/a/a2/Tektite_I_exterior.jpg")
    ),
    SampleArticle(
        title: "Fotothek archival photo",
        subtitle: "Monochromatic / greyscale",
        description: "A historical black-and-white archival photograph — greyscale pixel data with no chroma information at all.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/e/e8/Fotothek_df_n-08_0000820.jpg")
    ),
    SampleArticle(
        title: "Gentlemen Prefer Blondes",
        subtitle: "High-saturation / Technicolor",
        description: "A Technicolor film still with heavily boosted, vivid primary hues — the highest-saturation stress test in the suite.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/b/b6/Gentlemen_Prefer_Blondes_Movie_Trailer_Screenshot_%2834%29.jpg")
    ),
    SampleArticle(
        title: "Woodside LIRR Blue Lights",
        subtitle: "High-saturation / monochromatic hue",
        description: "A platform bathed in intense blue LED lighting — monochromatic-hue scene that exercises the hue-preservation behaviour of the darkening loop.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/d/dc/Woodside_LIRR_Blue_Lights_on_platform_.jpg")
    ),
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
    /// Optional binding so a parent container can mirror the dominant color
    /// (e.g. for a matching full-screen background in previews).
    var dominantColorBinding: Binding<Color>? = nil
    /// When true the card fills all available space (no fixed image height,
    /// no rounded corners) for the full-screen paged preview.
    var fullScreen: Bool = false
    @State private var loadedImage: UIImage? = nil
    @State private var dominantColor: Color = Color(white: 0.22)

    var body: some View {
        if fullScreen {
            fullScreenBody
        } else {
            cardBody
        }
    }

    // Standard card layout (used in WMFColorCardTestView scroll list)
    private var cardBody: some View {
        VStack(spacing: 0) {
            fixedImageSection
            textSection
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .task { await loadImage() }
    }

    // Full-screen layout (used in paged preview)
    private var fullScreenBody: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                // Background color fills any gaps the image doesn't cover
                dominantColor

                // Image fills the full frame, cropping overflow
                if let image = loadedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                } else if article.imageURL != nil {
                    ProgressView()
                }

                // Scrim fading into solid dominant color
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: dominantColor.opacity(0.5), location: 0.45),
                        .init(color: dominantColor, location: 0.72)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: proxy.size.width, height: proxy.size.height)

                // Text pinned to bottom, inside safe area
                VStack(alignment: .leading, spacing: 6) {
                    Text(article.title)
                        .font(.system(size: 32, weight: .light))
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
                        .lineLimit(3)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, proxy.safeAreaInsets.bottom + 32)
                .frame(width: proxy.size.width, alignment: .leading)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .task { await loadImage() }
    }

    private var fixedImageSection: some View {
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
                dominantColorBinding?.wrappedValue = color
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

// MARK: - Section header

private struct SectionHeader: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }
}

// MARK: - Test view

public struct WMFColorCardTestView: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeader(
                    title: "Original samples",
                    detail: "Baseline photographic images used during initial development."
                )
                ForEach(originalArticles.indices, id: \.self) { i in
                    ColorSampledCard(article: originalArticles[i])
                }

                SectionHeader(
                    title: "Light / transparent backgrounds",
                    detail: "Logos, maps, and artwork on white or near-white backgrounds — the sampler must not produce a near-white card that fails contrast."
                )
                ForEach(lightBackgroundArticles.indices, id: \.self) { i in
                    ColorSampledCard(article: lightBackgroundArticles[i])
                }

                SectionHeader(
                    title: "Portraits",
                    detail: "Close-cropped faces and headshots. Also exercises awkward vertical crop composition in the fixed-height image section."
                )
                ForEach(portraitArticles.indices, id: \.self) { i in
                    ColorSampledCard(article: portraitArticles[i])
                }

                SectionHeader(
                    title: "Diagrams, illustrations, and scientific imagery",
                    detail: "Flat vector art, charts, microscopy, and medical photography. Often low-saturation or mostly-white with sparse detail."
                )
                ForEach(diagramArticles.indices, id: \.self) { i in
                    ColorSampledCard(article: diagramArticles[i])
                }

                SectionHeader(
                    title: "Violence, disasters, and potentially unpleasant content",
                    detail: "The algorithm is content-agnostic, but dark or high-key news photography still needs to produce accessible cards."
                )
                ForEach(sensitiveContentArticles.indices, id: \.self) { i in
                    ColorSampledCard(article: sensitiveContentArticles[i])
                }

                SectionHeader(
                    title: "Saturation edge cases",
                    detail: "Near-black, greyscale, desaturated, highly saturated, and monochromatic-hue images that stress-test the darkening loop from both extremes."
                )
                ForEach(saturationArticles.indices, id: \.self) { i in
                    ColorSampledCard(article: saturationArticles[i])
                }
            }
            .padding()
        }
    }
}

// MARK: - Paged full-screen preview
// Swipe up/down to snap between full-screen cards.

private let allPreviewArticles: [SampleArticle] =
    originalArticles +
    lightBackgroundArticles +
    portraitArticles +
    diagramArticles +
    sensitiveContentArticles +
    saturationArticles

private struct PagedCardPreview: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(allPreviewArticles.indices, id: \.self) { i in
                    ColorSampledCard(article: allPreviewArticles[i], fullScreen: true)
                        .containerRelativeFrame([.horizontal, .vertical])
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .ignoresSafeArea()
    }
}

// MARK: - Previews

#Preview("Full-screen paged") {
    PagedCardPreview()
}

#Preview("Scroll list") {
    WMFColorCardTestView()
}
