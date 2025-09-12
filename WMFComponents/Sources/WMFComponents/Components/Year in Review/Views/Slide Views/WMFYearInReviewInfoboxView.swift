import SwiftUI

/// Table with hard coded colors - not theme-dependent
public struct WMFYearInReviewInfoboxView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    var theme: WMFTheme { appEnvironment.theme }

    var viewModel: WMFInfoboxViewModel

    public init(viewModel: WMFInfoboxViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.tableItems.indices, id: \.self) { index in
                    let item = viewModel.tableItems[index]
                    HStack(alignment: .top, spacing: 2) {
                        Text(item.title)
                            .font(Font(WMFFont.for(.boldSubheadline)))
                            .foregroundStyle(Color(uiColor: WMFColor.black))
                            .frame(width: 140, alignment: .leading)

                        if let attr = item.attributedText {
                            Text(attr)
                                .font(Font(WMFFont.for(.subheadline)))
                                .multilineTextAlignment(.leading)
                        } else if let plain = item.text {
                            Text(plain)
                                .font(Font(WMFFont.for(.subheadline)))
                                .foregroundStyle(Color(uiColor: WMFColor.black))
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(WMFColor.gray100))
    }
}
