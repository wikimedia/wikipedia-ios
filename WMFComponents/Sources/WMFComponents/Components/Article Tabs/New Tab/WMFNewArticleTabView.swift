import SwiftUI

public struct WMFNewArticleTabView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    public init() {}

    public var body: some View {
        ZStack {
            Spacer()
        }
        .background(Color(theme.paperBackground))
    }
}
