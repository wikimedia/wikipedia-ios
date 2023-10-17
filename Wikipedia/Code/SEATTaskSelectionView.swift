import SwiftUI
import Components

struct SEATSelectionView: View {

    // MARK: - Nested Types

    enum PresentationStyle {
        case task
        case preview
    }

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var appEnvironment = WKAppEnvironment.current

    private var theme: WKTheme {
        appEnvironment.theme
    }

    @SwiftUI.State private var isFormPresented = false
    
    @SwiftUI.State var taskItem: SEATTaskItem = SEATSampleData.shared.nextTask()

    // MARK: - Public

    var content: some View {
        ScrollView {
            VStack {
                imagePreview
                    .frame(height: 300)
                articlePreview
                buttonStack
            }
        }
    }

    var body: some View {
        content
            .background(
                Color(theme.paperBackground)
                    .ignoresSafeArea()
            )
            .navigationTitle("Add alt text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back", systemImage: "chevron.backward") {
                        dismiss()
                    }
                    .tint(Color(theme.text))
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu("More", systemImage: "ellipsis.circle") {
                        Button("Learn more (onboarding)") { }
                        Button("Feedback (form link)") { }
                    }
                    .tint(Color(theme.text))
                }
            }
            .fullScreenCover(isPresented: $isFormPresented) {
                NavigationView {
                    SEATFormView(taskItem: taskItem)
                }
            }

    }

    var buttonStack: some View {
        VStack(alignment: .center) {
            Button("Suggest alt text for image") {
                isFormPresented.toggle()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(theme.link))
            Button("Skip suggestion") {
                withAnimation {
                    taskItem = SEATSampleData.shared.nextTask()
                }
            }
            .tint(Color(theme.link))
        }
    }

    var imagePreview: some View {
        Color(theme.baseBackground)
    }

    var articlePreview: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(taskItem.articleTitle)
                .foregroundStyle(Color(theme.text))
                .font(.custom("Georgia", size: 28, relativeTo: .headline))
            if let articleDescription = taskItem.articleDescription {
                Text(articleDescription)
                    .foregroundStyle(Color(theme.secondaryText))
            }
            Divider()
                .foregroundStyle(Color(theme.secondaryText))
            Text(taskItem.articleSummary)
                .lineLimit(nil)
                .foregroundStyle(Color(theme.text))
            Button("Read full article →") {

            }
            .tint(Color(theme.link))
        }
        .padding()
    }

}

#Preview {
    SEATSelectionView(taskItem: SEATSampleData.shared.nextTask())
}
