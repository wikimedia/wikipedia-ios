import SwiftUI

public struct WMFInfoTableView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        appEnvironment.theme
    }

    var viewModel: WMFInfoTableViewModel

    init(viewModel: WMFInfoTableViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading) {
            ForEach(viewModel.tableItems.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 12) {
                    //waiting on fonts
                    Text(viewModel.tableItems[index].title)
                        .font(Font(WMFFont.for(.boldSubheadline)))
                        .foregroundStyle(Color(uiColor: theme.text))
                        .frame(width: 140, alignment: .leading) // get width for several devices, ipad
                    Text(viewModel.tableItems[index].text)// check here if we can format the link color OR i need to separate each item and apply theme
                        .font(Font(WMFFont.for(.subheadline)))
                        .foregroundStyle(Color(uiColor: theme.text)) // check theme re: link color
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding()
    }
}
