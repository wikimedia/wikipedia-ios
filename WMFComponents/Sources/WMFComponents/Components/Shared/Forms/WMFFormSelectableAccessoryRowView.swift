import SwiftUI

struct WMFFormSelectableAccessoryRowView: View {

	@ObservedObject var appEnvironment = WMFAppEnvironment.current

	var theme: WMFTheme {
		return appEnvironment.theme
	}

	@ObservedObject var viewModel: WMFFormItemSelectViewModel

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
