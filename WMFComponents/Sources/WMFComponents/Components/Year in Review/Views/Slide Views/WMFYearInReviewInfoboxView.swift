import SwiftUI

/// Table with hard coded colors - not theme-dependent
public struct WMFYearInReviewInfoboxView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    var theme: WMFTheme { appEnvironment.theme }
    var viewModel: WMFInfoboxViewModel
    var isSharing: Bool
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

    public init(viewModel: WMFInfoboxViewModel, isSharing: Bool) {
        self.viewModel = viewModel
        self.isSharing = isSharing
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(viewModel.tableItems.indices, id: \.self) { index in
                let item = viewModel.tableItems[index]
                HStack(alignment: .top, spacing: 8) {
                    Text(item.title)
                        .font(titleFont)
                        .foregroundStyle(Color(uiColor: WMFColor.black))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: ((containerWidth ?? 540) / 5) * 2, alignment: .leading)

                    if let rows = item.richRows {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(rows) { row in
                                HStack(alignment: .top, spacing: 4) {
                                    Text(row.numberText)
                                        .font(rowFont)

                                    Text(row.titleText)
                                        .font(rowFont)
                                        .multilineTextAlignment(.leading)
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
