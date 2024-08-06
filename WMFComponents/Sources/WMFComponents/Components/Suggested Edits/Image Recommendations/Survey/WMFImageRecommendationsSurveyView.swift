import SwiftUI

struct WMFImageRecommendationsSurveyView: View {

	// MARK: - Properties

	@ObservedObject var appEnvironment = WMFAppEnvironment.current

	private var theme: WMFTheme {
		return appEnvironment.theme
	}

	private var userHasSelectedReasons: Bool {
		return !selectedReasons.isEmpty || !otherReasonText.isEmpty
	}

	@FocusState var otherReasonTextFieldSelected: Bool

	@State var otherReasonText = ""
	@State var selectedReasons: Set<WMFImageRecommendationsSurveyViewModel.Reason> = []

	let viewModel: WMFImageRecommendationsSurveyViewModel

	var cancelAction: (() -> Void)?
	var submitAction: (([WMFImageRecommendationsSurveyViewModel.Reason]) -> Void)?

	// MARK: - View

	var body: some View {
		NavigationView {
			List {
				Section {
					VStack(alignment: .leading) {
						Text(viewModel.localizedStrings.improveSuggestions)
							.font(Font(WMFFont.for(.callout)))
						Text(viewModel.localizedStrings.selectOptions)
							.font(Font(WMFFont.for(.italicCallout)))
					}
				}
				.foregroundColor(Color(theme.secondaryText))
				.listRowBackground(Color.clear)
				.listRowSeparator(.hidden)
				.listCustomSectionSpacing(0)

				Section {
					ForEach(viewModel.presetReasons) { reason in
						HStack {
							Text(reason.localizedPlaceholder(from: viewModel.localizedStrings))
								.foregroundStyle(Color(theme.text))
							Spacer()
							WMFCheckmarkView(isSelected: selectedReasons.contains(reason), configuration: WMFCheckmarkView.Configuration(style: .default))
						}
						.contentShape(Rectangle())
						.onTapGesture {
							otherReasonTextFieldSelected = false
							if selectedReasons.contains(reason) {
								selectedReasons.remove(reason)
							} else {
								selectedReasons.insert(reason)
							}
						}
					}
					.listRowBackground(Color(theme.paperBackground))
					.listRowSeparatorTint(Color(theme.newBorder))
				}
				.listSectionSeparator(.hidden)

				Section {
					HStack {
						TextField(viewModel.localizedStrings.other, text: $otherReasonText)
							.focused($otherReasonTextFieldSelected)
							.foregroundStyle(Color(theme.text))
						Spacer()
						WMFCheckmarkView(isSelected: !otherReasonText.isEmpty, configuration: WMFCheckmarkView.Configuration(style: .default))
					}
					.listRowBackground(Color(theme.paperBackground))
				}
				.listCustomSectionSpacing(16)
				.listRowSeparator(.hidden)
			}
			.listBackgroundColor(Color(theme.midBackground))
			.listStyle(.plain)
			.navigationTitle(viewModel.localizedStrings.reason)
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					Button(viewModel.localizedStrings.cancel) {
						cancelAction?()
					}
					.foregroundStyle(Color(theme.link))
				}

				ToolbarItem(placement: .topBarTrailing) {
					Button(viewModel.localizedStrings.submit) {
						if !otherReasonText.isEmpty {
							let otherReason = WMFImageRecommendationsSurveyViewModel.Reason.other(reason: otherReasonText)
							selectedReasons.insert(otherReason)
						}
						submitAction?(Array(selectedReasons))
					}
					.disabled(!userHasSelectedReasons)
					.foregroundStyle(Color(userHasSelectedReasons ? theme.link : theme.secondaryText))
				}
			}
		}
		.navigationViewStyle(.stack)
		.environment(\.colorScheme, theme.preferredColorScheme)
	}
	
}

#Preview {
	WMFImageRecommendationsSurveyView(viewModel: WMFImageRecommendationsSurveyViewModel(localizedStrings: .init(reason: "Reason", cancel: "Cancel", submit: "Submit", improveSuggestions: "Improve", selectOptions: "Select", imageNotRelevant: "Image not relevant", notEnoughInformation: "Not enough info", imageIsOffensive: "Image is offensive", imageIsLowQuality: "Image is low quality", dontKnowSubject: "Dont know subject", other: "Other")))
}
