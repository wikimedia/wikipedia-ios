import SwiftUI

struct WMFFeatureAnnouncementView: View {
    
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
        return max(height * 0.04, 8)
    }

    /// Calculate the background image height so all other content fits without scrolling.
    func backgroundImageHeight(for geometry: GeometryProxy) -> CGFloat {
        let topPadding: CGFloat = 14
        let closeButtonHeight: CGFloat = 44
        let textBlockHeight: CGFloat = 150
        let buttonHeight: CGFloat = 50
        let bottomPadding: CGFloat = 12
        let spacing = spacingForAvailableHeight(geometry.size.height)
        let spacingsTotal = spacing * 3

        let foregroundImageHeight: CGFloat = 118
        let minimumBackgroundImageHeight = foregroundImageHeight + 40

        let reserved = topPadding + closeButtonHeight + textBlockHeight + buttonHeight + bottomPadding + spacingsTotal
        return max(geometry.size.height - reserved, minimumBackgroundImageHeight)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(appEnvironment.theme.popoverBackground)
                    .ignoresSafeArea()
                ScrollView(.vertical) {
                    VStack(spacing: spacingForAvailableHeight(geometry.size.height)) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                WMFLargeCloseButton(imageType: .plainX) {
                                    viewModel.closeButtonAction?()
                                }
                                Spacer()
                            }
                            Text(viewModel.title)
                                .font(Font(WMFFont.for(.boldTitle3)))
                                .foregroundColor(Color(appEnvironment.theme.text))
                                .padding([.leading, .trailing], 22)
                            Text(viewModel.body)
                                .font(Font(WMFFont.for(.callout)))
                                .foregroundColor(Color(appEnvironment.theme.text))
                                .padding([.leading, .trailing], 22)
                        }
                        
                        if let gifName = viewModel.gifName, let altText = viewModel.altText {
                            ZStack {
                                Image(gifName, bundle: .module)
                                    .resizable()
                                    .aspectRatio(1.5, contentMode: .fill)
                                    .frame(maxHeight: 220)
                                    .frame(maxWidth: geometry.size.width - 64)
                                    .cornerRadius(8)
                                WMFGIFImageView(gifName)
                                    .aspectRatio(1.5, contentMode: .fill)
                                    .frame(maxHeight: 220)
                                    .frame(maxWidth: geometry.size.width - 64)
                                    .cornerRadius(8)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(altText)
                            .padding([.leading, .trailing], 22)
                        } else if let image = viewModel.image {
                            ZStack(alignment: .center) {
                                if let backgroundImage = viewModel.backgroundImage {
                                    Image(uiImage: backgroundImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: backgroundImageHeight(for: geometry))
                                        .frame(maxWidth: max(geometry.size.width - 64, 100))
                                        .cornerRadius(8)
                                        .clipped()
                                }
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 132, height: 118)
                                    .foregroundColor(imageColor)
                            }
                            .frame(maxWidth: max(geometry.size.width - 64, 100))
                            .padding([.leading, .trailing], 22)
                        }

                        WMFLargeButton(style: .primary, title: viewModel.primaryButtonTitle, action: viewModel.primaryButtonAction)
                            .padding([.leading, .trailing], 22)
                    }
                    .padding([.leading, .trailing], 32)
                    .padding(.top, 14)
                    .padding(.bottom, 12)
                }
                .ignoresSafeArea(.container, edges: .bottom)
            }
        }
    }
}

 #Preview {
    WMFFeatureAnnouncementView(viewModel: WMFFeatureAnnouncementViewModel(title: "Try 'Add an image'", body: "Decide if an image gets added to a Wikipedia article. You can find the ‘Add an image’ card in your ‘Explore feed’.", primaryButtonTitle: "Try now", image:  WMFIcon.addPhoto, primaryButtonAction: {}, closeButtonAction: {}))
 }
