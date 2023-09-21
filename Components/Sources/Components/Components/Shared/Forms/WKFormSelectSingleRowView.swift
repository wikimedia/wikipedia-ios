import SwiftUI

struct WKFormSelectSingleRowView: View {
    
    @ObservedObject var appEnvironment = WKAppEnvironment.current

    var theme: WKTheme {
        return appEnvironment.theme
    }
    
    @ObservedObject var viewModel: WKFormItemSelectViewModel
    
    var body: some View {
        Button(action: {
            // Don't allow toggling 'off'
            if !viewModel.isSelected {
                viewModel.isSelected = true
            }
        }) {
            HStack {
                if let image = viewModel.image {
                    WKRoundedRectIconView(configuration: .init(icon: image, foregroundColor: \.icon, backgroundColor: \.iconBackground))
                        .padding(.trailing, 6)
                }
                Text(viewModel.title ?? "")
                    .foregroundColor(Color(theme.text))
                Spacer()
                if viewModel.isSelected {
                    WKCheckmarkView()
                }
            }
        }
        .accessibilityAddTraits(viewModel.isSelected ? [.isSelected] : [])
    }
}
