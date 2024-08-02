import SwiftUI

struct WMFFormSelectMultiRowView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    @ObservedObject var viewModel: WMFFormItemSelectViewModel

    var body: some View {
        HStack {
            if let image = viewModel.image {
                WKRoundedRectIconView(configuration: .init(icon: image, foregroundColor: \.icon, backgroundColor: \.iconBackground))
                    .accessibilityHidden(true)
                    .padding(.trailing, 6)
            }
            WKToggleView(title: viewModel.title ?? "", isSelected: $viewModel.isSelected)
        }
    }
}
