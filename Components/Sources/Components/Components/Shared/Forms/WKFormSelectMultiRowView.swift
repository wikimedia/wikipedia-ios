import SwiftUI

struct WKFormSelectMultiRowView: View {

    @ObservedObject var appEnvironment = WKAppEnvironment.current

    var theme: WKTheme {
        return appEnvironment.theme
    }

    @ObservedObject var viewModel: WKFormItemSelectViewModel

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
