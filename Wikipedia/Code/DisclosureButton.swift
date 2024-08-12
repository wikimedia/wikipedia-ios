import WMFComponents
import SwiftUI

struct DisclosureButton<Element: CustomStringConvertible>: View {

    let item: Element
    let action: (Element) -> Void
    
    @EnvironmentObject var observableTheme: ObservableTheme

    var body: some View {
        Button(action: { action(item) }) {
            VStack(spacing: 0) {
                HStack {
                    Text(item.description)
                        .foregroundColor(Color(observableTheme.theme.colors.primaryText))
                        .font(Font(WMFFont.for(.callout)))
                        .fontWeight(.semibold)
                    Spacer(minLength: 12)
                    Image(systemName: "chevron.right").font(Font(WMFFont.for(.mediumFootnote)))
                        .foregroundColor(Color(observableTheme.theme.colors.secondaryText))
                }
                .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                Divider()
                    .frame(height: 1)
                    .background(Color(observableTheme.theme.colors.midBackground))
            }
        }
        .buttonStyle(BackgroundHighlightingButtonStyle())
    }
}
