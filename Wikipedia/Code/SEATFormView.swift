import SwiftUI
import Components

struct SEATFormView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var appEnvironment = WKAppEnvironment.current

    private var theme: WKTheme {
        appEnvironment.theme
    }

    private var appTheme: Theme {
        switch theme {
        case .black:
            return .black
        case .dark:
            return .dark
        case .sepia:
            return .sepia
        default:
            return .light
        }
    }

    @SwiftUI.State var altText: String = ""
    var taskItem: SEATTaskItem

    // MARK: - Public

    var body: some View {
        ScrollView {
            VStack {
                header
                Divider()
                    .foregroundColor(Color(theme.border))
                form
            }
        }
        .navigationTitle("Add alt text")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .tint(Color(theme.text))
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink("Next", destination: {
                    SEATSelectionView(taskItem: taskItem, presentationStyle: .preview, suggestedAltText: altText)
                })
                .tint(Color(theme.text))
                .disabled(altText.isEmpty)
            }
        }
    }

    var header: some View {
        HStack(alignment: .top) {
            AsyncImage(url: URL(string: taskItem.imageURL), content: { image in
                Rectangle()
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        image
                            .resizable()
                            .scaledToFill()
                    )
                    .clipShape(Rectangle())
            }, placeholder: {
                ProgressView()
            })
            .frame(width: 100, height: 100)

            VStack(alignment: .leading) {
                Text("Image")
                    .foregroundStyle(Color(theme.secondaryText))
                Text(taskItem.imageFilename)
                    .foregroundStyle(Color(theme.link))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }

    var form: some View {
        VStack(alignment: .leading) {
            Text("Alternative Text")
            TextView(placeholder: "Describe this image", theme: appTheme, text: $altText)
                .frame(maxWidth: .infinity, minHeight: 44)
            Divider()
            Text("Text description for readers who cannot see the image")
            Text("Guidance")
            Text("• Describe main point")
            Text("• Under 125 characters")
            Text("• Context-aware")
            Text("• State function if needed")
            Text("• Highlight key parts")

            Button(action: { }, label: {
                HStack {
                    Image(systemName: "arrow.up.right.square")
                    Text("View Examples")
                }
            })

        }
        .padding()
    }

}

#Preview {
    SEATFormView(taskItem: SEATSampleData.shared.availableTasks.randomElement()!)
}
