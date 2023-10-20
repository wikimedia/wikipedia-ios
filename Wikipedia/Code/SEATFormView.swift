import SwiftUI
import Components

struct SEATFormView: View {

    // MARK: - Nested Types

    enum LocalizedStrings {
        
    }

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
    var parentDismissAction: ((String) -> Void)? = nil

    // MARK: - Public

    var body: some View {
        if #available(iOS 16.0, *) {
            content
                .toolbarBackground(Color(theme.paperBackground), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        } else {
            content
        }
    }

    var content: some View {
        ScrollView {
            VStack {
                header
                    .foregroundColor(Color(theme.text))
                Divider()
                    .foregroundColor(Color(theme.border))
                form
                    .foregroundColor(Color(theme.text))
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
                    SEATSelectionView(taskItem: taskItem, presentationStyle: .preview, suggestedAltText: altText) { suggestedAltText in
                        parentDismissAction?(suggestedAltText)
                        dismiss()
                    }
                })
                .tint(Color(theme.link))
                .disabled(altText.isEmpty)
            }
        }
        .background(
            Color(theme.paperBackground)
                .ignoresSafeArea()
        )
    }

    var header: some View {
        HStack(alignment: .top) {
            AsyncImage(url: taskItem.imageURL, content: { image in
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
                    Image("mini-external")
                        .renderingMode(.template)
                    Text("View Examples")
                }
            })
            .foregroundColor(Color(theme.link))

        }
        .padding()
    }

}

 #Preview {
    SEATFormView(taskItem: SEATSampleData.shared.availableTasks.randomElement()!)
 }
