import SwiftUI
import Components
import WKData

struct SEATSelectionView: View {

    // MARK: - Nested Types

    enum PresentationStyle {
        case suggestion
        case preview
    }

    enum LocalizedStrings {
        static let addAltText = WMFLocalizedString("suggested-edits-alt-text-title", value: "Add alt text", comment: "Text title in alt-text task views.")
        static let learnMore = WMFLocalizedString("suggested-edits-alt-text-learn-more", value: "Learn more", comment: "Text for learn more button")
        static let feedback = WMFLocalizedString("suggested-edits-alt-text-feedback", value: "Feedback", comment: "Text for feedback button")
        static let alertTitle = WMFLocalizedString("suggested-edits-alt-text-alert-title", value: "Please help us refine the “Suggested Edits” feature!", comment: "Title for alt-text task feedback alert")
        static let sendFeedback = WMFLocalizedString("suggested-edits-alt-text-send-feedback", value: "Send feedback", comment: "Text for send feedback button")
        static let readPrivacyPolicy = WMFLocalizedString("suggested-edits-alt-text-read-privacy-policy", value: "Read privacy policy", comment: "Text for read privacy policy button")
        static let alertBody = WMFLocalizedString("suggested-edits-alt-text-alert-body", value: "We're excited to introduce our new “Suggested Edits” feature. As it's still in the testing phase, we'd absolutely love to hear from you. Your insights and suggestions will be invaluable in helping us refine, enhance, or even reconsider this feature. Dive in, explore, and let us know your thoughts. Your feedback will shape its future!", comment: "Body text for alt-text task feedback alert")
        static let suggestAltText = WMFLocalizedString("suggested-edits-alt-text-suggest-alt-text", value: "Suggest alt text for image", comment: "Text for suggest alt-text button")
        static let skipSuggestion = WMFLocalizedString("suggested-edits-alt-text-skip-suggestion", value: "Skip suggestion", comment: "Text for skip suggestion button")

        static let licenseInfo = WMFLocalizedString("suggested-edits-alt-text-license-info", value: "By publishing, you agree to the [Terms of Use](https://www.mediawiki.org/wiki/Wikimedia_Apps/Suggested_edits), and to irrevocably release your contributions under the [CC BY-SA 3.0](https://www.mediawiki.org/wiki/Wikimedia_Apps/Suggested_edits) license.", comment: "Footer text when publishing alt-text. Please do not remove the brackets or parentheses. Please do not translate or change the URL inside the parentheses.")

        static let viewImageDetails = WMFLocalizedString("suggested-edits-alt-text-view-image-details", value: "View image details →", comment: "Text for image details button in alt-text view.")

        static let readFullArticle = WMFLocalizedString("suggested-edits-alt-text-read-full-article", value: "Read full article →", comment: "Text for read more button in alt-text view.")


        static let publish = CommonStrings.publishTitle
        static let back = CommonStrings.accessibilityBackTitle
        static let cancel = CommonStrings.cancelActionTitle
        static let more = CommonStrings.moreButton

        static func markdownString(_ string: String) -> AttributedString {
            guard let attributedString = try? AttributedString(markdown: string) else {
                return AttributedString()
            }
            
            return attributedString
        }
    }

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var appEnvironment = WKAppEnvironment.current

    private var theme: WKTheme {
        appEnvironment.theme
    }

    @SwiftUI.State private var isFormPresented = false
    @SwiftUI.State private var isFeedbackAlertPresented = false

    @SwiftUI.State var taskItem: SEATItemViewModel = SEATSampleData.shared.nextTask()
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
                        Text(LocalizedStrings.addAltText)
                            .font(.headline)
                            .foregroundStyle(Color(theme.text))
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(LocalizedStrings.back, systemImage: "chevron.backward") {
                        dismiss()
                    }
                    .tint(Color(theme.text))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if presentationStyle == .suggestion {
                        Menu(LocalizedStrings.more, systemImage: "ellipsis.circle") {
                            Button(LocalizedStrings.learnMore, systemImage: "info.circle") {
                                NotificationCenter.default.post(name: .seatOnboardingDidTapLearnMore, object: nil)
                            }
                            Button(LocalizedStrings.feedback, systemImage: "exclamationmark.bubble") {
                                isFeedbackAlertPresented.toggle()
                            }
                        }
                        .tint(Color(theme.text))
                    } else {
                        Button(LocalizedStrings.publish) {
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
            .alert(LocalizedStrings.alertTitle, isPresented: $isFeedbackAlertPresented, actions: {
                Button(LocalizedStrings.sendFeedback) { }
                    .keyboardShortcut(.defaultAction)
                Button(LocalizedStrings.readPrivacyPolicy) { }
                Button(LocalizedStrings.cancel, role: .cancel) { }
            }, message: {
                Text(LocalizedStrings.alertBody)
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
                Text(LocalizedStrings.suggestAltText)
                    .font(.callout.weight(.medium))
                    .frame(maxWidth: .infinity, minHeight: 44, idealHeight: 44)
            })
            .buttonStyle(.borderedProminent)
            .tint(Color(theme.link))
            .padding()
            Button(LocalizedStrings.skipSuggestion) {
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
                Text(LocalizedStrings.markdownString(LocalizedStrings.licenseInfo))
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
                AsyncImage(url: taskItem.imageThumbnailURLs["2"], content: { image in
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
                Text(suggestedAltText ?? LocalizedStrings.viewImageDetails)
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
            Text(LocalizedStrings.readFullArticle)
                .font(.subheadline.weight(.medium))
                .tint(Color(theme.link))
        }
    }

}

#Preview {
    SEATSelectionView(taskItem: SEATSampleData.shared.nextTask())
}
