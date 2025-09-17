import SwiftUI

/// Table with hard coded colors - not theme-dependent
public struct WMFYearInReviewInfoboxView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    var theme: WMFTheme { appEnvironment.theme }
    var viewModel: WMFInfoboxViewModel
    var isSharing: Bool

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
        VStack(alignment: .leading, spacing: 12) {
            ForEach(viewModel.tableItems.indices, id: \.self) { index in
                let item = viewModel.tableItems[index]
                HStack(alignment: .top, spacing: 8) {
                    Text(item.title)
                        .font(titleFont)
                        .foregroundStyle(Color(uiColor: WMFColor.black))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: 108, alignment: .leading)

                    if let rows = item.richRows {
                        VStack(alignment: .leading, spacing: 4) {
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
            }
        }
        .padding(8)
        .background(Color(WMFColor.gray100))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
