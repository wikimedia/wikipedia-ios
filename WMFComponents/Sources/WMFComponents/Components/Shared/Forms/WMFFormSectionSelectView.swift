import SwiftUI

struct WMFFormSectionSelectView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    let viewModel: WMFFormSectionSelectViewModel

    var body: some View {
        Section {
            ForEach(viewModel.items) { item in
                switch viewModel.selectType {
                case .multi:
                    WMFFormSelectMultiRowView(viewModel: item)
                case .multiWithAccessoryRows:
					if item.isAccessoryRow {
						WMFFormSelectableAccessoryRowView(viewModel: item)
					} else {
						WMFFormSelectMultiRowView(viewModel: item)
					}
                case .single:
                    WMFFormSelectSingleRowView(viewModel: item)
                }
            }
        } header: {
            if let header = viewModel.header {
                Text(header)
            }
        } footer: {
            if let footer = viewModel.footer {
                Text(footer)
            }
        }
    }
}
