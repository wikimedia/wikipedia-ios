import SwiftUI

public struct WKSwiftUIMenuButton: View {

	@ObservedObject var appEnvironment = WKAppEnvironment.current

	public let configuration: WKMenuButton.Configuration
	public weak var menuButtonDelegate: WKMenuButtonDelegate?

	public init(configuration: WKMenuButton.Configuration, menuButtonDelegate: WKMenuButtonDelegate?) {
		self.configuration = configuration
		self.menuButtonDelegate = menuButtonDelegate
	}

	public var body: some View {
			Menu(content: {
				ForEach(configuration.menuItems) { menuItem in
					Button(action: {
						menuButtonDelegate?.wkSwiftUIMenuButtonUserDidTap(configuration: configuration, item: menuItem)
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
						.font(Font(WKFont.for(.boldFootnote)))
				}
				.padding([.leading, .trailing], 8)
				.padding([.top, .bottom], 8)
				.background(Color(appEnvironment.theme[keyPath: configuration.primaryColor].withAlphaComponent(0.15)))
			})
			.highPriorityGesture(TapGesture().onEnded {
				menuButtonDelegate?.wkSwiftUIMenuButtonUserDidTap(configuration: configuration, item: nil)
			})
			.cornerRadius(8)
	}
	
}

