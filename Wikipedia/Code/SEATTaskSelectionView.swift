import SwiftUI
import Components

struct SEATSelectionView: View {

    // MARK: - Nested Types

    enum PresentationStyle {
        case suggestion
        case preview
    }

    enum LocalizedStrings {
         
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
    var parentDismissAction: ((String) -> Void)? = nil

    // MARK: - Public

    var content: some View {
        VStack {
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

    var rootContent: some View {
        content
            .background(
                Color(theme.paperBackground)
                    .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(presentationStyle == .preview)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("Add alt text")
                            .font(.headline)
                            .foregroundStyle(Color(theme.text))
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back", systemImage: "chevron.backward") {
                        dismiss()
                    }
                    .tint(Color(theme.text))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if presentationStyle == .suggestion {
                        Menu("More", systemImage: "ellipsis.circle") {
                            Button("Learn more", systemImage: "info.circle") {
                                NotificationCenter.default.post(name: .seatOnboardingDidTapLearnMore, object: nil)
                            }
                            Button("Feedback", systemImage: "exclamationmark.bubble") {
                                isFeedbackAlertPresented.toggle()
                            }
                        }
                        .tint(Color(theme.text))
                    } else {
                        Button("Publish") {
                            if let suggestedAltText = suggestedAltText {
                                parentDismissAction?(suggestedAltText)
                            }
                        }
                        .font(.body.weight(.medium))
                        .tint(Color(theme.link))
                    }
                }
            }
            .fullScreenCover(isPresented: $isFormPresented) {
                NavigationView {
                    SEATFormView(taskItem: taskItem) { suggestedAltText in
                        // Present toast
                        withAnimation {
                            taskItem = SEATSampleData.shared.nextTask()
                            print(suggestedAltText)
                        }
                    }
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

    var body: some View {
        if #available(iOS 16.0, *) {
            rootContent
                .toolbarBackground(Color(theme.paperBackground), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        } else {
            rootContent
        }
    }

    var buttonStack: some View {
        VStack(alignment: .center, spacing: 4) {
            Button(action: {
                isFormPresented.toggle()
            }, label: {
                Text("Suggest alt text for image")
                    .font(.callout.weight(.medium))
                    .frame(maxWidth: .infinity, minHeight: 44, idealHeight: 44)
            })
            .buttonStyle(.borderedProminent)
            .tint(Color(theme.link))
            .padding()
            Button("Skip suggestion") {
                withAnimation {
                    taskItem = SEATSampleData.shared.nextTask()
                }
            }
            .font(.callout.weight(.medium))
            .tint(Color(theme.link))
        }
    }

    var footer: some View {
        VStack {
            Divider()
            HStack {
                Image("license-cc")
                    .renderingMode(.template)
                Text("By publishing, you agree to the [Terms of Use](https://www.mediawiki.org/wiki/Wikimedia_Apps/Suggested_edits), and to irrevocably release your contributions under the [CC BY-SA 3.0](https://www.mediawiki.org/wiki/Wikimedia_Apps/Suggested_edits) license.")
                    .font(.caption)
                    .lineSpacing(10)
                    .accentColor(Color(theme.link))
            }
            .foregroundColor(Color(theme.inputAccessoryButtonTint))
            .padding([.leading, .trailing])
            .padding([.top, .bottom], 4)
        }
    }

    var imagePreview: some View {
        GeometryReader { proxy in
            ZStack {
                Color(theme.baseBackground)
                AsyncImage(url: taskItem.imageURL, content: { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }, placeholder: {
                    ProgressView()
                })
            }
            .overlay(alignment: .bottom, content: {
                imageCommonsLink
            })
        }
    }
    
    var articlePreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Spacer()
                .frame(height: 12)
            Text(taskItem.articleTitle)
                .foregroundStyle(Color(theme.text))
                .font(.custom("Georgia", size: 28, relativeTo: .headline))
            if let articleDescription = taskItem.articleDescription {
                Text(articleDescription)
                    .font(.footnote)
                    .foregroundStyle(Color(theme.secondaryText))
            }
            Spacer()
                .frame(height: 2)
            HStack {
                Rectangle()
                    .foregroundStyle(Color(theme.secondaryText))
                    .frame(width: 60, height: 0.5)
                Spacer()
            }
            Spacer()
                .frame(height: 2)
            Text(taskItem.articleSummary)
                .font(.callout)
                .lineLimit(nil)
                .foregroundStyle(Color(theme.text))
                .lineSpacing(8)
            if presentationStyle == .suggestion {
                Spacer()
                    .frame(height: 4)
                articleViewLink
            }
        }
        .padding([.leading, .trailing, .bottom])
    }
    
    var imageCommonsLink: some View {
        NavigationLink {
            SEATImageCommonsView(commonsURL: taskItem.commonsURL)
                .background(
                    Color(theme.paperBackground)
                        .ignoresSafeArea()
                )
        } label: {
            HStack(alignment: .center) {
                Text(suggestedAltText ?? "View image details →")
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Image("wikimedia-project-commons", bundle: .main)
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.black.opacity(0.7))
        }
        .disabled(presentationStyle == .preview)
    }
    
    var articleViewLink: some View {
        NavigationLink {
            SEATArticleView(articleURL: taskItem.articleURL)
                .ignoresSafeArea(edges:.bottom)
                .background(
                    Color(theme.paperBackground)
                        .ignoresSafeArea()
                )
        } label: {
            Text("Read full article →")
                .font(.subheadline.weight(.medium))
                .tint(Color(theme.link))
        }
    }

}

#Preview {
    SEATSelectionView(taskItem: SEATSampleData.shared.nextTask())
}
