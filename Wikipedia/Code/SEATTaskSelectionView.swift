import SwiftUI
import Components

struct SEATSelectionView: View {

    // MARK: - Nested Types

    enum PresentationStyle {
        case suggestion
        case preview
    }

    struct LocalizedStrings {
         
    }

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var appEnvironment = WKAppEnvironment.current

    private var theme: WKTheme {
        appEnvironment.theme
    }

    @SwiftUI.State private var isFormPresented = false
    @SwiftUI.State private var isFeedbackAlertPresented = false

    @SwiftUI.State var taskItem: SEATTaskItem = SEATSampleData.shared.nextTask()
    @SwiftUI.State var presentationStyle: PresentationStyle = .suggestion

    var suggestedAltText: String? = nil

    // MARK: - Public

    var content: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack {
                    imagePreview
                        .frame(height: 300)
                    articlePreview
                }
            }
            if presentationStyle == .suggestion {
                buttonStack
            } else {
                footer
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
                    if presentationStyle == .suggestion {
                        Button("Back", systemImage: "chevron.backward") {
                            dismiss()
                        }
                        .tint(Color(theme.text))

                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if presentationStyle == .suggestion {
                        Menu("More", systemImage: "ellipsis.circle") {
                            Button("Learn more", systemImage: "info.circle") { }
                            Button("Feedback", systemImage: "exclamationmark.bubble") {
                                isFeedbackAlertPresented.toggle()
                            }
                        }
                        .tint(Color(theme.text))
                    } else {
                        Button("Publish") {
                            dismiss()
                        }
                        .tint(Color(theme.link))
                    }
                }
            }
            .fullScreenCover(isPresented: $isFormPresented) {
                NavigationView {
                    SEATFormView(taskItem: taskItem)
                }
            }
            .alert("Please help us refine the “Suggested Edits” feature!", isPresented: $isFeedbackAlertPresented, actions: {
                Button("Send Feedback") { }
                    .keyboardShortcut(.defaultAction)
                Button("Read Privacy Policy") { }
                Button("Cancel", role: .cancel) { }
            }, message: {
                Text("We're excited to introduce our new “Suggested Edits” feature. As it's still in the testing phase, we'd absolutely love to hear from you. Your insights and suggestions will be invaluable in helping us refine, enhance, or even reconsider this feature. Dive in, explore, and let us know your thoughts. Your feedback will shape its future!")
            })

    }

    var buttonStack: some View {
        VStack(alignment: .center, spacing: 8) {
            Button(action: {
                isFormPresented.toggle()
            }, label: {
                Text("Suggest alt text for image")
                    .frame(maxWidth: .infinity, minHeight: 44)
            })
            .buttonStyle(.borderedProminent)
            .tint(Color(theme.link))
            .padding()

            Button("Skip suggestion") {
                withAnimation {
                    taskItem = SEATSampleData.shared.nextTask()
                }
            }
            .tint(Color(theme.link))
        }
    }

    var footer: some View {
        VStack {
            Divider()
            Text("By publishing, you agree to the Terms of Use, and to irrevocably release your contributions under the CC BY-SA 3.0 license.")
        }
    }

    var imagePreview: some View {
        ZStack {
            Color(theme.baseBackground)
            AsyncImage(url: URL(string: taskItem.imageURL), content: { image in
                image
                    .resizable()
                    .scaledToFit()
            }, placeholder: {
                ProgressView()
            })
        }
        .overlay(alignment: .bottom, content: {
            Button(action: {

            }, label: {
                HStack(alignment: .center) {
                    Text(suggestedAltText ?? "View image details →")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    Image("wikimedia-project-commons", bundle: .main)
                }
            })
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.black.opacity(0.7))
        })
    }

    var articlePreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(taskItem.articleTitle)
                .foregroundStyle(Color(theme.text))
                .font(.custom("Georgia", size: 28, relativeTo: .headline))
            if let articleDescription = taskItem.articleDescription {
                Text(articleDescription)
                    .foregroundStyle(Color(theme.secondaryText))
            }
            HStack {
                Rectangle()
                    .foregroundStyle(Color(theme.secondaryText))
                    .frame(width: 60, height: 0.5)
                Spacer()
            }
            Text(taskItem.articleSummary)
                .lineLimit(nil)
                .foregroundStyle(Color(theme.text))
            if presentationStyle == .suggestion {
                Button("Read full article →") {

                }
                .tint(Color(theme.link))
            }
        }
        .padding([.leading, .trailing, .bottom])
    }

}

#Preview {
    SEATSelectionView(taskItem: SEATSampleData.shared.nextTask())
}
