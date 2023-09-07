import SwiftUI

// MARK: - WKWatchlistView
struct WKWatchlistView: View {

	@ObservedObject var appEnvironment = WKAppEnvironment.current
 	@ObservedObject var viewModel: WKWatchlistViewModel
	weak var delegate: WKWatchlistDelegate?

	// MARK: - Lifecycle

	var body: some View {
		ZStack {
			Color(appEnvironment.theme.paperBackground)
				.ignoresSafeArea()
			WKWatchlistContentView(viewModel: viewModel, delegate: delegate)
		}
	}

}

// MARK: - Private: WKWatchlistContentView

private struct WKWatchlistContentView: View {

	@ObservedObject var appEnvironment = WKAppEnvironment.current
	@ObservedObject var viewModel: WKWatchlistViewModel
	weak var delegate: WKWatchlistDelegate?

	var body: some View {
		ScrollView {
			LazyVStack(spacing: 0) {
				ForEach(viewModel.sections) { section in
					Group {
						Text(section.title.localizedUppercase)
							.font(Font(WKFont.for(.boldFootnote)))
							.foregroundColor(Color(appEnvironment.theme.secondaryText))
							.padding([.top, .bottom], 6)
							.frame(maxWidth: .infinity, alignment: .leading)
						ForEach(section.items) { item in
							WKWatchlistViewCell(itemViewModel: item, localizedStrings: viewModel.localizedStrings)
						}
						.padding([.top, .bottom], 6)
						Spacer()
							.frame(height: 14)
					}
				}
			}
			.padding([.leading, .trailing], 16)
			.padding([.top], 12)
		}
	}

}

// MARK: - Private: WKWatchlistViewCell

private struct WKWatchlistViewCell: View {

	@ObservedObject var appEnvironment = WKAppEnvironment.current
	let itemViewModel: WKWatchlistViewModel.ItemViewModel
	let localizedStrings: WKWatchlistViewModel.LocalizedStrings

	var body: some View {
			if #available(iOS 15.0, *) {
				ZStack {
					RoundedRectangle(cornerRadius: 8, style: .continuous)
						.stroke(Color(appEnvironment.theme.border), lineWidth: 0.5)
						.foregroundColor(.clear)
					HStack(alignment: .wkTextBaselineAlignment) {
						VStack(alignment: .leading, spacing: 6) {
							Text(itemViewModel.timestampString)
								.font(Font(WKFont.for(.subheadline)))
								.foregroundColor(Color(appEnvironment.theme.secondaryText))
								.frame(alignment: .topLeading)
								.alignmentGuide(.wkTextBaselineAlignment) { context in
									context[.firstTextBaseline]
								}
							Text(itemViewModel.bytesString(localizedStrings: localizedStrings))
								.font(Font(WKFont.for(.boldFootnote)))
								.foregroundColor(Color(appEnvironment.theme[keyPath: itemViewModel.bytesTextColorKeyPath]))
								.frame(alignment: .topLeading)
						}
						.frame(width: 80, alignment: .topLeading)

						VStack(alignment: .leading, spacing: 6) {
							HStack(alignment: .top) {
								Text(itemViewModel.title)
									.font(Font(WKFont.for(.headline)))
									.foregroundColor(Color(appEnvironment.theme.text))
									.frame(maxWidth: .infinity, alignment: .topLeading)
									.alignmentGuide(.wkTextBaselineAlignment) { context in
										context[.firstTextBaseline]
									}
								Spacer()
                                WKProjectIconView(project: itemViewModel.project)
							}

							if !itemViewModel.comment.isEmpty {
								Text(itemViewModel.comment)
									.font(Font(WKFont.for(.smallBody)))
									.foregroundColor(Color(appEnvironment.theme.secondaryText))
									.frame(maxWidth: .infinity, alignment: .topLeading)
							}

							// TODO: Replace with user button
							Menu(itemViewModel.username) {
								Button("User page", action: { })
								Button("User talk page", action: { })
								Button("User contributions", action: { })
								Button("Thank", action: { })
							}
							.font(Font(WKFont.for(.boldFootnote)))
							.foregroundColor(Color(appEnvironment.theme.link))
						}
					}
					.padding([.top, .bottom], 12)
					.padding([.leading, .trailing], 16)
				}
			} else {
				// TODO: Remove enclosing version check when minimum target is iOS 15
				fatalError()
			}
	}

}

// MARK: - Private: VerticalAlignment extension

fileprivate extension VerticalAlignment {

	private struct WKTextBaselineAlignment: AlignmentID {
		static func defaultValue(in context: ViewDimensions) -> CGFloat {
			return context[VerticalAlignment.firstTextBaseline]
		}
	}

	// Allow matching text baseline alignment across `VStack`s
	static let wkTextBaselineAlignment = VerticalAlignment(WKTextBaselineAlignment.self)

}
