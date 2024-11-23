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

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(appEnvironment.theme.popoverBackground)
                    .ignoresSafeArea()
                ScrollView(.vertical) {
                    VStack(spacing: spacingForAvailableHeight(geometry.size.height)) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Spacer()
                                Button(
                                    action: {
                                        viewModel.closeButtonAction?()
                                    },
                                    label: {
                                        closeImage
                                    })
                                .foregroundColor(Color(uiColor: appEnvironment.theme.icon))
                            }
                            Text(viewModel.title)
                                .font(Font(WMFFont.for(.boldTitle3)))
                                .foregroundColor(Color(appEnvironment.theme.text))
                            Text(viewModel.body)
                                .font(Font(WMFFont.for(.callout)))
                                .foregroundColor(Color(appEnvironment.theme.text))
                        }

                        if let image = viewModel.image {
                            ZStack(alignment: .center) {
                                if let backgroundImage = viewModel.backgroundImage {
                                    Image(uiImage: backgroundImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 140)
                                        .frame(maxWidth: geometry.size.width - 64)
                                        .cornerRadius(8)
                                        .clipped()
                                }
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 132, height: 118)
                                    .foregroundColor(imageColor)
                            }
                            .frame(maxWidth: geometry.size.width - 64)
                        }

                        WMFLargeButton(configuration: .primary, title: viewModel.primaryButtonTitle, action: viewModel.primaryButtonAction)
                    }
                    .padding([.leading, .trailing], 32)
                    .padding(.top, 20)
                }
            }
        }
    }
}

#Preview {
    WMFFeatureAnnouncementView(viewModel: WMFFeatureAnnouncementViewModel(title: "Try 'Add an image'", body: "Decide if an image gets added to a Wikipedia article. You can find the ‘Add an image’ card in your ‘Explore feed’.", primaryButtonTitle: "Try now", image:  WMFIcon.addPhoto, primaryButtonAction: {}, closeButtonAction: {}))
}
