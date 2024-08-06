import SwiftUI
import WMFData

// MARK: - WMFWatchlistView
struct WMFWatchlistView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFWatchlistViewModel
    var emptyViewModel: WMFEmptyViewModel
    weak var delegate: WMFWatchlistDelegate?
	weak var loggingDelegate: WMFWatchlistLoggingDelegate?
    weak var emptyViewDelegate: WMFEmptyViewDelegate? = nil
    weak var menuButtonDelegate: WMFSmallMenuButtonDelegate?
    
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
                WMFWatchlistContentView(viewModel: viewModel, delegate: delegate, menuButtonDelegate: menuButtonDelegate)
            } else if viewModel.sections.count == 0 && viewModel.activeFilterCount > 0 {
                WMFEmptyView(viewModel: emptyViewModel, delegate: emptyViewDelegate, type: .filter)
            } else {
                WMFEmptyView(viewModel: emptyViewModel, delegate: emptyViewDelegate, type: .noItems)
            }
        } else {
            ProgressView()
            .accessibilityHidden(true)
        }
    }
    
}

// MARK: - Private: WMFWatchlistContentView

private struct WMFWatchlistContentView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFWatchlistViewModel
    
    weak var delegate: WMFWatchlistDelegate?
    weak var menuButtonDelegate: WMFSmallMenuButtonDelegate?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.sections) { section in
                    Group {
                        Text(section.title.localizedUppercase)
                            .font(Font(WMFFont.for(.boldFootnote)))
                            .foregroundColor(Color(appEnvironment.theme.secondaryText))
                            .padding([.top, .bottom], 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(section.items) { item in
                            WMFWatchlistViewCell(itemViewModel: item, localizedStrings: viewModel.localizedStrings, menuItemConfiguration: WMFWatchlistViewCell.MenuItemConfiguration(userMenuItems: viewModel.menuButtonItems, anonOrBotMenuItems: viewModel.menuButtonItemsWithoutThank), menuButtonDelegate: menuButtonDelegate)
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

    func getAccessibilityLabelForItem(item: WMFWatchlistViewModel.ItemViewModel) -> String {
        var accessibilityString = String()
        if let project = viewModel.localizedStrings.localizedProjectNames[item.project] {
            accessibilityString = "\(project) \(item.timestampStringAccessibility). \(item.title). \(viewModel.localizedStrings.userAccessibility): \(item.username). \(viewModel.localizedStrings.summaryAccessibility): \(item.comment). \(item.bytesString(localizedStrings: viewModel.localizedStrings))"
        }
        return accessibilityString
    }

}

// MARK: - Private: WMFWatchlistViewCell

fileprivate struct WMFWatchlistViewCell: View {

	struct MenuItemConfiguration {
		let userMenuItems: [WMFSmallMenuButton.MenuItem]
		let anonOrBotMenuItems: [WMFSmallMenuButton.MenuItem]
	}

	@ObservedObject var appEnvironment = WMFAppEnvironment.current
	let itemViewModel: WMFWatchlistViewModel.ItemViewModel
	let localizedStrings: WMFWatchlistViewModel.LocalizedStrings
	let menuItemConfiguration: MenuItemConfiguration

	var menuItemsForRevisionAuthor: [WMFSmallMenuButton.MenuItem] {
		if itemViewModel.isBot || itemViewModel.isAnonymous {
			return menuItemConfiguration.anonOrBotMenuItems
		} else {
			return menuItemConfiguration.userMenuItems
		}
	}

	weak var menuButtonDelegate: WMFSmallMenuButtonDelegate?
    
    var editSummaryComment: String {
        return itemViewModel.comment.isEmpty ? localizedStrings.emptyEditSummary : itemViewModel.comment
    }
    
    var editSummaryCommentFont: UIFont {
        return itemViewModel.comment.isEmpty ? WMFFont.for(.italicFootnote) : WMFFont.for(.footnote)
    }

	var body: some View {
				ZStack {
					RoundedRectangle(cornerRadius: 8, style: .continuous)
						.stroke(Color(appEnvironment.theme.border), lineWidth: 0.5)
						.foregroundColor(.clear)
					HStack(alignment: .wmfTextBaselineAlignment) {
						VStack(alignment: .leading, spacing: 6) {
							Text(itemViewModel.timestampString)
								.font(Font(WMFFont.for(.subheadline)))
								.foregroundColor(Color(appEnvironment.theme.secondaryText))
								.frame(alignment: .topLeading)
								.alignmentGuide(.wmfTextBaselineAlignment) { context in
									context[.firstTextBaseline]
								}
                                .accessibilityHidden(true)

							Text(itemViewModel.bytesString(localizedStrings: localizedStrings))
								.font(Font(WMFFont.for(.boldFootnote)))
								.foregroundColor(Color(appEnvironment.theme[keyPath: itemViewModel.bytesTextColorKeyPath]))
								.frame(alignment: .topLeading)
						}
                        .accessibilityHidden(true)
						.frame(width: 80, alignment: .topLeading)

						VStack(alignment: .leading, spacing: 6) {
							HStack(alignment: .top) {
								Text(itemViewModel.title)
									.font(Font(WMFFont.for(.headline)))
									.foregroundColor(Color(appEnvironment.theme.text))
									.frame(maxWidth: .infinity, alignment: .topLeading)
									.alignmentGuide(.wmfTextBaselineAlignment) { context in
										context[.firstTextBaseline]
									}
                                    .accessibilityHidden(true)
								Spacer()
                                WMFProjectIconView(project: itemViewModel.project)
                                    .accessibilityHidden(true)
							}

                            Text(editSummaryComment)
                                .font(Font(editSummaryCommentFont))
                                .foregroundColor(Color(appEnvironment.theme.secondaryText))
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .accessibilityHidden(true)

							HStack {
								WMFSmallSwiftUIMenuButton(configuration: WMFSmallMenuButton.Configuration(
									title: itemViewModel.username,
									image: WMFSFSymbolIcon.for(symbol: .personFilled),
									primaryColor: \.link,
									menuItems: menuItemsForRevisionAuthor,
									metadata: [
                                    WMFWatchlistViewModel.ItemViewModel.wmfProjectMetadataKey: itemViewModel.project,
                                    WMFWatchlistViewModel.ItemViewModel.revisionIDMetadataKey: itemViewModel.revisionID,
                                    WMFWatchlistViewModel.ItemViewModel.oldRevisionIDMetadataKey: itemViewModel.oldRevisionID,
                                    WMFWatchlistViewModel.ItemViewModel.articleMetadataKey: itemViewModel.title
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

	private struct WMFTextBaselineAlignment: AlignmentID {
		static func defaultValue(in context: ViewDimensions) -> CGFloat {
			return context[VerticalAlignment.firstTextBaseline]
		}
	}

	// Allow matching text baseline alignment across `VStack`s
	static let wmfTextBaselineAlignment = VerticalAlignment(WMFTextBaselineAlignment.self)

}
