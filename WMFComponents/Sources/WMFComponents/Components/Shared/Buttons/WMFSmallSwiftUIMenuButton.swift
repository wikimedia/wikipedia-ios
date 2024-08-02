import SwiftUI

public struct WMFSmallSwiftUIMenuButton: View {

	@ObservedObject var appEnvironment = WMFAppEnvironment.current

	public let configuration: WMFSmallMenuButton.Configuration
	public weak var menuButtonDelegate: WMFSmallMenuButtonDelegate?

	public init(configuration: WMFSmallMenuButton.Configuration, menuButtonDelegate: WMFSmallMenuButtonDelegate?) {
		self.configuration = configuration
		self.menuButtonDelegate = menuButtonDelegate
	}

	public var body: some View {
			Menu(content: {
				ForEach(configuration.menuItems) { menuItem in
					Button(action: {
                        if UIAccessibility.isVoiceOverRunning {
                            menuButtonDelegate?.wmfSwiftUIMenuButtonUserDidTapAccessibility(configuration: configuration, item: menuItem)
                        } else {
                            menuButtonDelegate?.wmfSwiftUIMenuButtonUserDidTap(configuration: configuration, item: menuItem)
                        }
					}) {
						HStack {
							Text(menuItem.title)
								.foregroundColor(Color(appEnvironment.theme[keyPath: configuration.primaryColor]))
							Spacer()
							Image(uiImage: menuItem.image ?? UIImage())
						}
					}
				}
			}, label: {
				HStack {
					Image(uiImage: configuration.image ?? UIImage())
						.foregroundColor(Color(appEnvironment.theme[keyPath: configuration.primaryColor]))
					Spacer()
						.frame(width: 8)
					Text(configuration.title ?? "")
						.lineLimit(1)
						.foregroundColor(Color(appEnvironment.theme[keyPath: configuration.primaryColor]))
						.font(Font(WMFFont.for(.boldFootnote)))
				}
				.padding([.leading, .trailing], 8)
				.padding([.top, .bottom], 8)
				.background(Color(appEnvironment.theme[keyPath: configuration.primaryColor].withAlphaComponent(0.15)))
			})
			.highPriorityGesture(TapGesture().onEnded {
				menuButtonDelegate?.wmfSwiftUIMenuButtonUserDidTap(configuration: configuration, item: nil)
			})
			.cornerRadius(8)
	}
	
}

