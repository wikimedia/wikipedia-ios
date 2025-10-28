import SwiftUI

/// Table with hard coded colors - not theme-dependent
public struct WMFYearInReviewInfoboxView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    var theme: WMFTheme { appEnvironment.theme }
    var viewModel: WMFInfoboxViewModel
    var isSharing: Bool
    private let needsAdaptiveTitleColumnWidth: Bool
    private let defaultTitleColumnWidth = 108.0
    @State private var containerWidth: CGFloat?

    private var fontTraitOverride: UITraitCollection? {
        isSharing ? UITraitCollection(preferredContentSizeCategory: .medium) : nil
    }

    private var titleFont: Font {
        Font(WMFFont.for(.helveticaBodyBold, compatibleWith: fontTraitOverride ?? appEnvironment.traitCollection))
    }
    private var rowFont: Font {
        Font(WMFFont.for(.helveticaBody, compatibleWith: fontTraitOverride ?? appEnvironment.traitCollection))
    }

    private var hashtagFont: Font {
        Font(WMFFont.for(.helveticaLargeHeadline, compatibleWith: fontTraitOverride ?? appEnvironment.traitCollection))
    }

    private var logoFont: Font {
        Font(WMFFont.for(.helveticaCaption1, compatibleWith: fontTraitOverride ?? appEnvironment.traitCollection))
    }

    private var adaptiveTitleColumnWidth: CGFloat {
        // Aiming for title column width = 2/5 of infobox width
        return ((containerWidth ?? (defaultTitleColumnWidth * 5)) / 5) * 2
    }

    public init(viewModel: WMFInfoboxViewModel, isSharing: Bool, needsAdaptiveTitleColumnWidth: Bool = false) {
        self.viewModel = viewModel
        self.isSharing = isSharing
        self.needsAdaptiveTitleColumnWidth = needsAdaptiveTitleColumnWidth
    }

    public var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text("#WikipediaYearInReview")
                .font(hashtagFont)
                .foregroundStyle(Color(uiColor: WMFColor.black))
                .multilineTextAlignment(.center)
            VStack(spacing: 8) {
                Image("globe_yir", bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 166, height: 166)
                    .accessibilityHidden(true)

                Text(viewModel.logoCaption)
                    .font(logoFont)
                    .foregroundStyle(Color(WMFColor.black))
                    .multilineTextAlignment(.center)

            }
            ForEach(viewModel.tableItems.indices, id: \.self) { index in
                let item = viewModel.tableItems[index]
                HStack(alignment: .top, spacing: 8) {
                    Text(item.title)
                        .font(titleFont)
                        .lineSpacing(3)
                        .foregroundStyle(Color(uiColor: WMFColor.black))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: needsAdaptiveTitleColumnWidth ? adaptiveTitleColumnWidth : defaultTitleColumnWidth, alignment: .leading)

                    if let rows = item.richRows {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(rows) { row in
                                HStack(alignment: .top, spacing: 4) {
                                    Text(row.numberText)
                                        .font(rowFont)

                                    Text(row.titleText)
                                        .font(rowFont)
                                        .multilineTextAlignment(.leading)
                                        .lineSpacing(3)
                                        .lineLimit(3)
                                        .truncationMode(.tail)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    } else if let plain = item.text {
                        Text(plain)
                            .font(rowFont)
                            .foregroundStyle(Color(uiColor: WMFColor.black))
                            .multilineTextAlignment(.leading)
                            .lineSpacing(3)
                            .lineLimit(3)
                            .truncationMode(.tail)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: WidthKey.self, value: geo.size.width)
                    }
                )
                .onPreferenceChange(WidthKey.self) { width in
                    containerWidth = width
                }
            }
        }
        .padding(8)
        .background(Color(WMFColor.gray100))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        // Keep the largest reported width (or sum, or whatever logic you need)
        value = max(value, nextValue())
    }
}
