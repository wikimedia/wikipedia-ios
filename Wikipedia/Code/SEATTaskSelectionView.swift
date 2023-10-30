import SwiftUI
import Components
import WKData
import WMF

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
        static let alertBody = WMFLocalizedString("suggested-edits-alt-text-alert-body", value: "We're excited to introduce our new “Suggested Edits” feature. We'd love to hear from you as it's still in the testing phase. Your insights and suggestions will be invaluable in helping us refine and enhance this feature. Thanks!", comment: "Body text for alt-text task feedback alert")
        static let suggestAltText = WMFLocalizedString("suggested-edits-alt-text-suggest-alt-text", value: "Suggest alt text for image", comment: "Text for suggest alt-text button")
        static let skipSuggestion = WMFLocalizedString("suggested-edits-alt-text-skip-suggestion", value: "Skip suggestion", comment: "Text for skip suggestion button")

        static let licenseInfo = WMFLocalizedString("suggested-edits-alt-text-license-info", value: "By publishing, you agree to the [Terms of Use](https://foundation.m.wikimedia.org/wiki/Policy:Terms_of_Use), and to irrevocably release your contributions under the [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/4.0/) license.", comment: "Footer text when publishing alt-text. Please do not remove the brackets or parentheses. Please do not translate or change the URL inside the parentheses.")

        static let viewImageDetails = WMFLocalizedString("suggested-edits-alt-text-view-image-details", value: "View image details →", comment: "Text for image details button in alt-text view.")

        static let readFullArticle = WMFLocalizedString("suggested-edits-alt-text-read-full-article", value: "Read full article →", comment: "Text for read more button in alt-text view.")

        static let submitted = WMFLocalizedString("suggested-edits-alt-text-submitted-toast", value: "Submitted!", comment: "Text for submit toast in alt-text view.")

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

    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var appEnvironment = WKAppEnvironment.current

    private var theme: WKTheme {
        appEnvironment.theme
    }

    @SwiftUI.State private var isFormPresented = false
    @SwiftUI.State private var isFeedbackAlertPresented = false

    @SwiftUI.State var taskItem: SEATItemViewModel = SEATSampleData.shared.nextTask()
    @SwiftUI.State var presentationStyle: PresentationStyle = .suggestion

    @SwiftUI.State var isPresentingPublishedToast = false
    private let publishedToastAnimationStyle = Animation.easeInOut

    var suggestedAltText: String? = nil
    var parentDismissAction: ((String) -> Void)? = nil

    var onboardingModalAction: (() -> Void)?

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

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            HStack {
                Text(LocalizedStrings.addAltText)
                    .font(.headline)
                    .foregroundStyle(Color(theme.text))
            }
        }
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
                if presentationStyle == .preview {
                    SEATFunnel.shared.logSEATPreviewViewDidTapBack(articleTitle: taskItem.articleTitle, commonsFileName: taskItem.imageCommonsFilename)
                }
                dismiss()
            }, label: {
                Image(systemName: "chevron.backward")
            })
            .tint(Color(theme.text))
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            if presentationStyle == .suggestion {
                Menu(content: {
                    Button(action: {
                        SEATFunnel.shared.logSEATTaskSelectionDidTapMoreButtonLearnMore()
                        onboardingModalAction?()
                    }, label: {
                        HStack {
                            Text(LocalizedStrings.learnMore)
                            Spacer()
                            Image(systemName: "info.circle")
                        }
                    })

                    Button(action: {
                        SEATFunnel.shared.logSEATTaskSelectionDidTapMoreButtonSendFeedback()
                        isFeedbackAlertPresented.toggle()
                    }, label: {
                        HStack {
                            Text(LocalizedStrings.feedback)
                            Spacer()
                            Image(systemName: "exclamationmark.bubble")
                        }
                    })

                }, label: {
                    Image(systemName: "ellipsis.circle")
                })
                .tint(Color(theme.text))
            } else {
                Button(LocalizedStrings.publish) {
                    SEATFunnel.shared.logSEATPreviewViewDidTapSubmit(articleTitle: taskItem.articleTitle, commonsFileName: taskItem.imageCommonsFilename)
                    if let suggestedAltText = suggestedAltText {
                        parentDismissAction?(suggestedAltText)
                    }
                }
                .font(.body.weight(.medium))
                .tint(Color(theme.link))
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
                toolbarContent
            }
            .onAppear {
                if presentationStyle == .preview {
                    SEATFunnel.shared.logSEATPreviewViewImpression(articleTitle: taskItem.articleTitle, commonsFileName: taskItem.imageCommonsFilename)
                }
            }
            .overlay(alignment: .bottom) {
                toastView
                    .offset(y: isPresentingPublishedToast ? 0 : 200) // not ideal :(
            }
            .fullScreenCover(isPresented: $isFormPresented) {
                NavigationView {
                    SEATFormView(taskItem: taskItem) { suggestedAltText in
                        SEATFunnel.shared.logSEATPreviewViewDidDidTriggerSubmittedToast(articleTitle: taskItem.articleTitle, commonsFileName: taskItem.imageCommonsFilename, altText: suggestedAltText)
                        withAnimation {
                            taskItem = SEATSampleData.shared.nextTask()
                            animateToast(visible: true)
                        }
                    }
                }
                .accentColor(Color(theme.text))
            }
            .alert(LocalizedStrings.alertTitle, isPresented: $isFeedbackAlertPresented, actions: {
                Button(LocalizedStrings.sendFeedback) {
                    SEATFunnel.shared.logSEATTaskSelectionFeedbackAlertDidTapSendFeedback()
                    guard let url = URL(string: SEATSampleData.shared.surveyURL.rawValue) else {
                        return
                    }
                    
                    openURL(url)
                }
                    .keyboardShortcut(.defaultAction)
                Button(LocalizedStrings.readPrivacyPolicy) {
                    SEATFunnel.shared.logSEATTaskSelectionFeedbackAlertDidTapPrivacyPolicy()
                    guard let url = URL(string: SEATSampleData.shared.privacyURL.rawValue) else {
                        return
                    }

                    openURL(url)
                }
                Button(LocalizedStrings.cancel, role: .cancel) {
                    SEATFunnel.shared.logSEATTaskSelectionFeedbackAlertDidTapCancel()
                }
            }, message: {
                Text(LocalizedStrings.alertBody)
            })
            .animation(publishedToastAnimationStyle, value: isPresentingPublishedToast)
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
                SEATFunnel.shared.logSEATTaskSelectionDidTapSuggestButton(articleTitle: taskItem.articleTitle, commonsFileName: taskItem.imageCommonsFilename)
                isFormPresented.toggle()
            }, label: {
                Text(LocalizedStrings.suggestAltText)
                    .font(.callout.weight(.medium))
                    .frame(maxWidth: .infinity, minHeight: 31, idealHeight: 31)
            })
            .buttonStyle(.borderedProminent)
            .tint(Color(theme.link))
            .padding([.leading, .trailing, .bottom])
            Button(LocalizedStrings.skipSuggestion) {
                SEATFunnel.shared.logSEATTaskSelectionDidTapSkipButton(articleTitle: taskItem.articleTitle, commonsFileName: taskItem.imageCommonsFilename)
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
                    .font(.footnote)
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
                    .frame(height: 2)
                articleViewLink
                    .frame(height: 44)
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
                .onAppear {
                    SEATFunnel.shared.logSEATTaskSelectionCommonsWebViewImpression(articleTitle: taskItem.articleTitle, commonsFileName: taskItem.imageCommonsFilename)
                }
        } label: {
            HStack(alignment: .center) {
                Text(suggestedAltText ?? LocalizedStrings.viewImageDetails)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                if presentationStyle == .preview {
                    Image(systemName: "accessibility")
                    Image(systemName: "speaker.wave.2.circle")
                } else {
                    Image("wikimedia-project-commons", bundle: .main)
                }                
            }
            .foregroundStyle(Color.white)
            .padding([.leading, .trailing])
            .padding([.top, .bottom], 4)
            .frame(maxWidth: .infinity, minHeight: 44, idealHeight: 44)
            .background(Color.black.opacity(0.7))
        }
        .simultaneousGesture(TapGesture().onEnded {
            if presentationStyle == .suggestion {
                SEATFunnel.shared.logSEATTaskSelectionDidTapImageDetails(articleTitle: taskItem.articleTitle, commonsFileName: taskItem.imageCommonsFilename)
            }
        })
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
                .onAppear {
                    SEATFunnel.shared.logSEATTaskSelectionArticleViewImpression(articleTitle: taskItem.articleTitle, commonsFileName: taskItem.imageCommonsFilename)
                }
        } label: {
            Text(LocalizedStrings.readFullArticle)
                .font(.subheadline.weight(.medium))
                .tint(Color(theme.link))
        }
        .simultaneousGesture(TapGesture().onEnded {
            SEATFunnel.shared.logSEATTaskSelectionDidTapReadArticle(articleTitle: taskItem.articleTitle, commonsFileName: taskItem.imageCommonsFilename)
        })
    }

    var toastView: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(uiColor: theme.link))
            Text(LocalizedStrings.submitted)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(uiColor: theme.text))
            Spacer()
            Button {
                isPresentingPublishedToast.toggle()
            } label: {
                Image(systemName: "xmark")
            }
            .tint(Color(uiColor: theme.secondaryText))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            Color(uiColor: theme.paperBackground)
                .shadow(color: Color.black.opacity(0.25), radius: 10)
                .ignoresSafeArea()
        )
        .ignoresSafeArea()
    }

    func animateToast(visible: Bool) {
        if visible {
            isPresentingPublishedToast = true
            Task {
                try await Task.sleep(nanoseconds:3_000_000_000)
                await MainActor.run {
                    if isPresentingPublishedToast {
                        isPresentingPublishedToast = false
                    }
                }
            }
        } else {
            isPresentingPublishedToast = false
        }
    }

}

// #Preview {
//    SEATSelectionView(taskItem: SEATSampleData.shared.nextTask())
// }
