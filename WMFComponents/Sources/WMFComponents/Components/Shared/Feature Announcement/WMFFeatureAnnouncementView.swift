import SwiftUI

struct WMFFeatureAnnouncementView: View {

    private enum Constants {

        // Vertical spacing between the main stack's elements
        static let spacingHeightMultiplier: CGFloat = 0.04
        static let minimumSpacing: CGFloat = 8

        // Inner spacing of the title/body text block
        static let textBlockSpacing: CGFloat = 6

        // Padding
        static let contentHorizontalPadding: CGFloat = 22
        static let containerHorizontalPadding: CGFloat = 10
        static let contentTopPadding: CGFloat = 10

        // Foreground (icon) image
        static let foregroundImageWidth: CGFloat = 132
        static let foregroundImageHeight: CGFloat = 118

        // Background image (height is derived from the foreground icon height)
        static let backgroundImageHeightRatio: CGFloat = 1.5
        static let imageCornerRadius: CGFloat = 8
        static let imageHorizontalInset: CGFloat = 64
        static let minimumImageWidth: CGFloat = 100

        // GIF image
        static let gifAspectRatio: CGFloat = 1.5
        static let gifMaximumHeight: CGFloat = 220

        // Extra height reported to the presenter to account for sheet chrome
        // Adds Top Padding = 10 and Close Button Height = 44
        static let reportedContentHeightPadding: CGFloat = 54
    }

    private struct ContentSizePreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0

        static func reduce(value: inout Value, nextValue: () -> Value) {
            value = max(value, nextValue())
        }
    }

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    let viewModel: WMFFeatureAnnouncementViewModel

    var imageColor: Color? {
        Color(uiColor: appEnvironment.theme.link)
    }

    var closeImage: Image? {
        if let uiImage = WMFSFSymbolIcon.for(symbol: .closeCircleFill, font: .title1) {
            return Image(uiImage: uiImage)
        }
        return nil
    }

    func spacingForAvailableHeight(_ height: CGFloat) -> CGFloat {
        return max(height * Constants.spacingHeightMultiplier, Constants.minimumSpacing)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(appEnvironment.theme.popoverBackground)
                    .ignoresSafeArea()
                ScrollView(.vertical) {
                    VStack(spacing: spacingForAvailableHeight(geometry.size.height)) {
                        VStack(alignment: .leading, spacing: Constants.textBlockSpacing) {
                            HStack {
                                WMFLargeCloseButton(imageType: .plainX) {
                                    viewModel.closeButtonAction?()
                                }
                                Spacer()
                            }
                            Text(viewModel.title)
                                .font(Font(WMFFont.for(.boldTitle3)))
                                .foregroundColor(Color(appEnvironment.theme.text))
                                .padding([.leading, .trailing], Constants.contentHorizontalPadding)
                            Text(viewModel.body)
                                .font(Font(WMFFont.for(.callout)))
                                .foregroundColor(Color(appEnvironment.theme.text))
                                .padding([.leading, .trailing], Constants.contentHorizontalPadding)
                        }

                        if let gifName = viewModel.gifName, let altText = viewModel.altText {
                            ZStack {
                                Image(gifName, bundle: .module)
                                    .resizable()
                                    .aspectRatio(Constants.gifAspectRatio, contentMode: .fill)
                                    .frame(maxHeight: Constants.gifMaximumHeight)
                                    .frame(maxWidth: geometry.size.width - Constants.imageHorizontalInset)
                                    .cornerRadius(Constants.imageCornerRadius)
                                WMFGIFImageView(gifName)
                                    .aspectRatio(Constants.gifAspectRatio, contentMode: .fill)
                                    .frame(maxHeight: Constants.gifMaximumHeight)
                                    .frame(maxWidth: geometry.size.width - Constants.imageHorizontalInset)
                                    .cornerRadius(Constants.imageCornerRadius)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(altText)
                            .padding([.leading, .trailing], Constants.contentHorizontalPadding)
                        } else if let image = viewModel.image {
                            ZStack(alignment: .center) {
                                if let backgroundImage = viewModel.backgroundImage {
                                    Image(uiImage: backgroundImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: Constants.backgroundImageHeightRatio * Constants.foregroundImageHeight)
                                        .frame(maxWidth: max(geometry.size.width - Constants.imageHorizontalInset, Constants.minimumImageWidth))
                                        .cornerRadius(Constants.imageCornerRadius)
                                        .clipped()
                                }
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: Constants.foregroundImageWidth, height: Constants.foregroundImageHeight)
                                    .foregroundColor(imageColor)
                            }
                            .frame(maxWidth: max(geometry.size.width - Constants.imageHorizontalInset, Constants.minimumImageWidth))
                            .padding([.leading, .trailing], Constants.contentHorizontalPadding)
                        }

                        WMFLargeButton(style: .primary, title: viewModel.primaryButtonTitle, action: viewModel.primaryButtonAction)
                            .padding([.leading, .trailing], Constants.contentHorizontalPadding)
                    }
                    .padding([.leading, .trailing], Constants.containerHorizontalPadding)
                    .padding(.top, Constants.contentTopPadding)
                }
                .background {
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: ContentSizePreferenceKey.self,
                            value: proxy.size.height
                        )
                    }
                }
                .ignoresSafeArea(.container, edges: .bottom)
                .fixedSize(horizontal: false, vertical: true)
            }
            .onPreferenceChange(ContentSizePreferenceKey.self) { height in
                guard height > 0 else { return }
                viewModel.contentHeightChanged?(height + Constants.reportedContentHeightPadding)
            }

        }
    }
}

 #Preview {
    WMFFeatureAnnouncementView(viewModel: WMFFeatureAnnouncementViewModel(title: "Try 'Add an image'", body: "Decide if an image gets added to a Wikipedia article. You can find the ‘Add an image’ card in your ‘Explore feed’.", primaryButtonTitle: "Try now", image:  WMFIcon.addPhoto, primaryButtonAction: {}, closeButtonAction: {}))
 }
