import SwiftUI

/// Table with hard coded colors - not theme-dependent
public struct WMFYearInReviewInfoTableView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        appEnvironment.theme
    }

    var viewModel: WMFInfoTableViewModel

    init(viewModel: WMFInfoTableViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.tableItems.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 8) {
                        // TODO: add helvetica
                        Text(viewModel.tableItems[index].title)
                            .font(Font(WMFFont.for(.boldSubheadline)))
                            .foregroundStyle(Color(uiColor: WMFColor.black))
                            .frame(width: 140, alignment: .leading)
                        Text(viewModel.tableItems[index].text)// TODO: format link color
                        // TODO: Limit lines to 2 and truncate on iPhone and sharing, not iPad
                            .font(Font(WMFFont.for(.subheadline)))
                            .foregroundStyle(Color(uiColor: WMFColor.black))
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .padding(16)
            
        }
        .background(Color(WMFColor.gray100))
    }
}
