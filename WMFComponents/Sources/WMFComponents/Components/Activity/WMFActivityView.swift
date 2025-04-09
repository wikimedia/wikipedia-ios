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
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
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
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                Spacer()
            }
            .padding()
        }
    }
    
    private var noEditsView: some View {
        VStack(alignment: .leading, spacing: 4) {
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
            VStack {
                Text(viewModel.addAnImageTitle)
                Text(viewModel.addAnImageSubtitle)
                Button(action: {
                    print("Start editing")
                }) {
                    HStack {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                        Text(viewModel.addAnImageTitle)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color(theme.link))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(theme.midBackground))
        .overlay(
            Rectangle()
                .stroke(Color(theme.text), lineWidth: 1)
        )
    }
}
