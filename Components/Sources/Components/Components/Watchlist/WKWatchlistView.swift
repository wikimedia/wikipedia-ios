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
    weak var menuButtonDelegate: WKSmallMenuButtonDelegate?
    
    // MARK: - Lifecycle
    
    var body: some View {
        ZStack {
            Color(appEnvironment.theme.paperBackground)
                .ignoresSafeArea()
            contentView
        }.onAppear {
           viewModel.fetchWatchlist {
                let items = viewModel.sections.flatMap { $0.items }
                loggingDelegate?.logWatchlistDidLoad(itemCount: items.count)
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
            .accessibilityHidden(true)
        }
    }
    
}

// MARK: - Private: WKWatchlistContentView

private struct WKWatchlistContentView: View {
    
    @ObservedObject var appEnvironment = WKAppEnvironment.current
    @ObservedObject var viewModel: WKWatchlistViewModel
    
    weak var delegate: WKWatchlistDelegate?
    weak var menuButtonDelegate: WKSmallMenuButtonDelegate?
    
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
                                .accessibilityLabel(getAccessibilityLabelForItem(item: item))
                                .accessibilityElement(children: .combine)
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

    func getAccessibilityLabelForItem(item: WKWatchlistViewModel.ItemViewModel) -> String {
        var accessibilityString = String()
        if let project = viewModel.localizedStrings.localizedProjectNames[item.project] {
            accessibilityString = "\(project) \(item.timestampStringAccessibility). \(item.title). \(viewModel.localizedStrings.userAccessibility): \(item.username). \(viewModel.localizedStrings.summaryAccessibility): \(item.comment). \(item.bytesString(localizedStrings: viewModel.localizedStrings))"
        }
        return accessibilityString
    }

}

// MARK: - Private: WKWatchlistViewCell

fileprivate struct WKWatchlistViewCell: View {

	struct MenuItemConfiguration {
		let userMenuItems: [WKSmallMenuButton.MenuItem]
		let anonOrBotMenuItems: [WKSmallMenuButton.MenuItem]
	}

	@ObservedObject var appEnvironment = WKAppEnvironment.current
	let itemViewModel: WKWatchlistViewModel.ItemViewModel
	let localizedStrings: WKWatchlistViewModel.LocalizedStrings
	let menuItemConfiguration: MenuItemConfiguration

	var menuItemsForRevisionAuthor: [WKSmallMenuButton.MenuItem] {
		if itemViewModel.isBot || itemViewModel.isAnonymous {
			return menuItemConfiguration.anonOrBotMenuItems
		} else {
			return menuItemConfiguration.userMenuItems
		}
	}

	weak var menuButtonDelegate: WKSmallMenuButtonDelegate?
    
    var editSummaryComment: String {
        return itemViewModel.comment.isEmpty ? localizedStrings.emptyEditSummary : itemViewModel.comment
    }
    
    var editSummaryCommentFont: UIFont {
        return itemViewModel.comment.isEmpty ? WKFont.for(.smallItalicsBody) : WKFont.for(.smallBody)
    }

	var body: some View {
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
                                .accessibilityHidden(true)

							Text(itemViewModel.bytesString(localizedStrings: localizedStrings))
								.font(Font(WKFont.for(.boldFootnote)))
								.foregroundColor(Color(appEnvironment.theme[keyPath: itemViewModel.bytesTextColorKeyPath]))
								.frame(alignment: .topLeading)
						}
                        .accessibilityHidden(true)
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
                                    .accessibilityHidden(true)
								Spacer()
                                WKProjectIconView(project: itemViewModel.project)
                                    .accessibilityHidden(true)
							}

                            Text(editSummaryComment)
                                .font(Font(editSummaryCommentFont))
                                .foregroundColor(Color(appEnvironment.theme.secondaryText))
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .accessibilityHidden(true)

							HStack {
								WKSmallSwiftUIMenuButton(configuration: WKSmallMenuButton.Configuration(
									title: itemViewModel.username,
									image: WKSFSymbolIcon.for(symbol: .personFilled),
									primaryColor: \.link,
									menuItems: menuItemsForRevisionAuthor,
									metadata: [
										WKWatchlistViewModel.ItemViewModel.wkProjectMetadataKey: itemViewModel.project,
										WKWatchlistViewModel.ItemViewModel.revisionIDMetadataKey: itemViewModel.revisionID,
                                        WKWatchlistViewModel.ItemViewModel.oldRevisionIDMetadataKey: itemViewModel.oldRevisionID,
                                        WKWatchlistViewModel.ItemViewModel.articleMetadataKey: itemViewModel.title
									]
                                ), menuButtonDelegate: menuButtonDelegate)
                                .accessibilityAddTraits(.isButton)
								Spacer()
							}
						}
					}
					.padding([.top, .bottom], 12)
					.padding([.leading, .trailing], 16)
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
