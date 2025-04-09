import SwiftUI

public struct WMFActivityView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    @ObservedObject var viewModel: WMFActivityViewModel

    public init(viewModel: WMFActivityViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack {
            Text("ACTIVITY VIEW ")
            if viewModel.hasNoEdits {
                noEditsView
                if viewModel.shouldShowStartEditing {
                    startEditingButton
                } else if viewModel.shouldShowAddAnImage {
                    addAnImageButton
                }
            } else if viewModel.shouldShowAddAnImage {
                Text(viewModel.suggestedEdits)
                addAnImageButton // TODO: add editing activity item above
            }
            if let activityItems = viewModel.activityItems {
                ForEach(activityItems, id: \.title) { item in
                    WMFActivityComponentView(activityItem: item)
                }
            }
        }
    }
    
    private var noEditsView: some View {
        VStack {
            Text(viewModel.noEditsTitle)
                .font(Font(WMFFont.for(.boldSubheadline)))
            Text(viewModel.noEditsSubtitle)
                .font(Font(WMFFont.for(.subheadline)))
        }
    }
    
    private var startEditingButton: some View {
        Button(viewModel.noEditsButtonTitle) {
            print("Start editing")
        }
    }
    
    private var addAnImageButton: some View {
        HStack {
            Image("abc")
            VStack {
                Text(viewModel.addAnImageTitle)
                Text(viewModel.addAnImageSubtitle)
                Button(viewModel.addAnImageButtonTitle) {
                    print("Start adding images")
                }
            }
        }
        .background(Color(theme.midBackground))
    }
}
