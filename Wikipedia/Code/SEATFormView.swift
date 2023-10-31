import SwiftUI
import Components
import WKData
import WMF

struct SEATFormView: View {

    // MARK: - Nested Types

    enum LocalizedStrings {
        static let addAltText = SEATSelectionView.LocalizedStrings.addAltText
        static let cancel = CommonStrings.cancelActionTitle
        static let next = CommonStrings.nextTitle

        static let image = WMFLocalizedString("suggested-edits-alt-text-form-image", value: "Image", comment: "Title for image section in alt-text form view.")
        static let alternativeText = WMFLocalizedString("suggested-edits-alt-text-form-alternative-text", value: "Alternative text", comment: "Title for header in alt-text form view.")
        static let altTextPlaceholder = WMFLocalizedString("suggested-edits-alt-text-form-alt-text-placeholder", value: "Describe this image", comment: "Placeholder for textfield in alt-text form view.")
        static let altTextTextfieldFooter = WMFLocalizedString("suggested-edits-alt-text-form-textfield-footer", value: "Text description for readers who cannot see the image", comment: "Description for textfield in alt-text form view.")
        static let altTextGuidance = WMFLocalizedString("suggested-edits-alt-text-form-guidance", value: "Guidance for writing alt-text", comment: "Header for guidance section in alt-text form view.")
        static let altTextGuidance1 = WMFLocalizedString("suggested-edits-alt-text-form-guidance-1", value: "• Describe main point", comment: "Guidance point in alt-text form view.")
        static let altTextGuidance2 = WMFLocalizedString("suggested-edits-alt-text-form-guidance-2", value: "• Under 125 characters", comment: "Guidance point in alt-text form view.")
        static let altTextGuidance3 = WMFLocalizedString("suggested-edits-alt-text-form-guidance-3", value: "• Context-aware", comment: "Guidance point in alt-text form view.")
        static let altTextGuidance4 = WMFLocalizedString("suggested-edits-alt-text-form-guidance-4", value: "• State function if needed", comment: "Guidance point in alt-text form view.")
        static let altTextGuidance5 = WMFLocalizedString("suggested-edits-alt-text-form-guidance-5", value: "• Highlight key parts", comment: "Guidance point in alt-text form view.")
        static let viewExamples = WMFLocalizedString("suggested-edits-alt-text-form-view-examples", value: "View examples", comment: "Title for view examples button in alt-text form view.")
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

    var taskItem: SEATItemViewModel
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
                    header
                        .foregroundColor(Color(theme.text))
                }
                Divider()
                    .foregroundColor(Color(theme.border))
                form
                    .foregroundColor(Color(theme.text))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Text(LocalizedStrings.addAltText)
                        .font(.headline)
                        .foregroundStyle(Color(theme.text))
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button(LocalizedStrings.cancel) {
                    dismiss()
                }
                .tint(Color(theme.text))
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(LocalizedStrings.next, destination: {
                    SEATSelectionView(taskItem: taskItem, presentationStyle: .preview, suggestedAltText: altText) { suggestedAltText in
                        parentDismissAction?(suggestedAltText)
                        dismiss()
                    }
                })
                .simultaneousGesture(TapGesture().onEnded {
                    SEATFunnel.shared.logSEATFormViewDidTapNext(articleTitle: taskItem.articleTitle, commonsFileName: taskItem.imageCommonsFilename)
                })
                .font(.body.weight(.medium))
                .tint(Color(theme.link))
                .disabled(altText.isEmpty)
            }
        }
        .background(
            Color(theme.paperBackground)
                .ignoresSafeArea()
        )
        .onAppear {
            SEATFunnel.shared.logSEATFormViewDidAppear(articleTitle: taskItem.articleTitle, commonsFileName: taskItem.imageCommonsFilename)
        }
    }

    var header: some View {
        HStack(alignment: .top) {
            AsyncImage(url: taskItem.imageThumbnailURLs["2"], content: { image in
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

            VStack(alignment: .leading, spacing: 6) {
                Text(LocalizedStrings.image)
                    .font(.callout)
                    .foregroundStyle(Color(theme.secondaryText))
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
                    Text(taskItem.imageWikitextFilename)
                        .font(.body)
                        .foregroundStyle(Color(theme.link))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding()
    }

    @ViewBuilder
    var formTextField: some View {
        if #available(iOS 16.0, *) {
            ZStack {
                TextEditor(text: Binding<String>.init(get: { return LocalizedStrings.altTextPlaceholder}, set: { _ in }))
                    .foregroundColor(Color(uiColor: theme.secondaryText))
                    .disabled(true)
                    .opacity(altText.isEmpty ? 1 : 0)
                    .padding([.leading, .trailing], -5)
                    .accessibilityHidden(true)
                TextEditor(text: $altText)
                    .foregroundColor(Color(uiColor: theme.text))
                    .opacity(altText.isEmpty ? 0.5 : 1)
                    .padding([.leading, .trailing], -5)
            }
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .clear))
        } else {
            ZStack {
                TextEditor(text: Binding<String>.init(get: { return LocalizedStrings.altTextPlaceholder}, set: { _ in }))
                    .disabled(true)
                    .opacity(altText.isEmpty ? 1 : 0)
                    .foregroundColor(.black)
                    .padding([.leading, .trailing], -5)
                    .accessibilityHidden(true)
                TextEditor(text: $altText)
                    .opacity(altText.isEmpty ? 0.5 : 1)
                    .foregroundColor(.black)
                    .padding([.leading, .trailing], -5)
            }
        }
    }

    var form: some View {
        VStack(alignment: .leading) {
            Text(LocalizedStrings.alternativeText)
                .font(.callout)
                .foregroundStyle(Color(theme.secondaryText))
            formTextField
                .padding(0)
                .frame(minHeight: 38)
            Divider()
            Text(LocalizedStrings.altTextTextfieldFooter)
                .font(.caption)
                .foregroundStyle(Color(theme.secondaryText))
            Spacer()
                .frame(height: 24)
            Text(LocalizedStrings.altTextGuidance)
                .font(.callout.weight(.medium))
            Spacer()
                .frame(height: 8)
            VStack(alignment: .leading, spacing: 6) {
                Text(LocalizedStrings.altTextGuidance1)
                Text(LocalizedStrings.altTextGuidance2)
                Text(LocalizedStrings.altTextGuidance3)
                Text(LocalizedStrings.altTextGuidance4)
                Text(LocalizedStrings.altTextGuidance5)
                Spacer()
                    .frame(height: 4)
                Button(action: {
                    SEATFunnel.shared.logSEATFormViewDidTapViewExamples(articleTitle: taskItem.articleTitle, commonsFileName: taskItem.imageCommonsFilename)
                    NotificationCenter.default.post(name: .seatOnboardingDidTapLearnMore, object: nil)
                }) {
                    HStack {
                        Image("mini-external")
                            .renderingMode(.template)
                        Text(LocalizedStrings.viewExamples)
                    }
                    .foregroundColor(Color(theme.link))
                }
            }
            .foregroundStyle(Color(theme.text))
            .font(.callout)
            .padding([.leading], 8)
        }
        .padding()
    }

}

// #Preview {
//    SEATFormView(taskItem: SEATSampleData.shared.availableTasks.randomElement()!)
// }
