import SwiftUI
import WKData

// MARK: - WKWatchlistView
struct WKWatchlistView: View {

	@ObservedObject var appEnvironment = WKAppEnvironment.current
 	@ObservedObject var viewModel: WKWatchlistViewModel
    var emptyViewModel: WKEmptyViewModel
	weak var delegate: WKWatchlistDelegate?
    weak var loggingDelegate: WKWatchlistLoggingDelegate?
    weak var emptyViewDelegate: WKEmptyViewDelegate? = nil
	weak var menuButtonDelegate: WKMenuButtonDelegate?

	// MARK: - Lifecycle

	var body: some View {
		ZStack {
			Color(appEnvironment.theme.paperBackground)
				.ignoresSafeArea()
			contentView
		}.onAppear {
            viewModel.fetchWatchlist {
                let items = viewModel.sections.flatMap { $0.items }
                loggingDelegate?.logWatchlistLoaded(itemCount: items.count)
            }
		}
	}

	@ViewBuilder
	var contentView: some View {
		if viewModel.hasPerformedInitialFetch {
			if viewModel.sections.count > 0 {
				WKWatchlistContentView(viewModel: viewModel, delegate: delegate, menuButtonDelegate: menuButtonDelegate)
			} else if viewModel.sections.count == 0 && viewModel.activeFilterCount > 0 {
				WKEmptyView(viewModel: emptyViewModel, delegate: emptyViewDelegate, type: .filter)
			} else {
				WKEmptyView(viewModel: emptyViewModel, delegate: emptyViewDelegate, type: .noItems)
			}
		} else {
			ProgressView()
		}
	}

}

// MARK: - Private: WKWatchlistContentView

private struct WKWatchlistContentView: View {

	@ObservedObject var appEnvironment = WKAppEnvironment.current
	@ObservedObject var viewModel: WKWatchlistViewModel

	weak var delegate: WKWatchlistDelegate?
	weak var menuButtonDelegate: WKMenuButtonDelegate?

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
							WKWatchlistViewCell(itemViewModel: item, localizedStrings: viewModel.localizedStrings, menuItemConfiguration: WKWatchlistViewCell.MenuItemConfiguration(userMenuItems: viewModel.menuButtonItems, anonOrBotMenuItems: viewModel.menuButtonItemsWithoutThank), menuButtonDelegate: menuButtonDelegate)
								.contentShape(Rectangle())
								.onTapGesture {
									delegate?.watchlistUserDidTapDiff(project: item.project, title: item.title, revisionID: item.revisionID, oldRevisionID: item.oldRevisionID)
								}
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

fileprivate struct WKWatchlistViewCell: View {

	struct MenuItemConfiguration {
		let userMenuItems: [WKMenuButton.MenuItem]
		let anonOrBotMenuItems: [WKMenuButton.MenuItem]
	}

	@ObservedObject var appEnvironment = WKAppEnvironment.current
	let itemViewModel: WKWatchlistViewModel.ItemViewModel
	let localizedStrings: WKWatchlistViewModel.LocalizedStrings
	let menuItemConfiguration: MenuItemConfiguration

	var menuItemsForRevisionAuthor: [WKMenuButton.MenuItem] {
		if itemViewModel.isBot || itemViewModel.isAnonymous {
			return menuItemConfiguration.anonOrBotMenuItems
		} else {
			return menuItemConfiguration.userMenuItems
		}
	}

	weak var menuButtonDelegate: WKMenuButtonDelegate?

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

							HStack {
								WKSwiftUIMenuButton(configuration: WKMenuButton.Configuration(
									title: itemViewModel.username,
									image: WKSFSymbolIcon.for(symbol: .personFilled),
									primaryColor: \.link,
									menuItems: menuItemsForRevisionAuthor,
									metadata: [
										WKWatchlistViewModel.ItemViewModel.wkProjectMetadataKey: itemViewModel.project,
										WKWatchlistViewModel.ItemViewModel.revisionIDMetadataKey: itemViewModel.revisionID
									]
								), menuButtonDelegate: menuButtonDelegate)
								Spacer()
							}
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
