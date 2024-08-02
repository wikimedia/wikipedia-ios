import SwiftUI

struct WKFormSelectableAccessoryRowView: View {

	@ObservedObject var appEnvironment = WKAppEnvironment.current

	var theme: WKTheme {
		return appEnvironment.theme
	}

	@ObservedObject var viewModel: WKFormItemSelectViewModel

	var body: some View {
		Button(action: {
			viewModel.accessoryRowSelectionAction?()
		}, label: {
			if let title = viewModel.title {
				Text(title)
					.foregroundColor(Color(theme.link))
			}
		})
	}
	
}
