import SwiftUI

struct WKFeatureAnnouncementView: View {
    
    var appEnvironment = WKAppEnvironment.current
    
    let viewModel: WKFeatureAnnouncementViewModel
    
    var imageColor: Color? {
        Color(uiColor: appEnvironment.theme.link)
    }
    
    var closeImage: Image? {
        if let uiImage = WKSFSymbolIcon.for(symbol: .closeCircleFill, font: .title1) {
            return Image(uiImage: uiImage)
        }
        
        return nil
    }
    
    var body: some View {
        ZStack {
            Color(appEnvironment.theme.paperBackground)
                .ignoresSafeArea()
            VStack(spacing: 52) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Spacer()
                        Button(
                            action: { viewModel.closeButtonAction?() },
                            label: {
                            closeImage
                        })
                        .foregroundColor(Color(uiColor: appEnvironment.theme.icon))
                    }
                    Text(viewModel.title)
                        .font(Font(WKFont.for(.boldTitle3)))
                        .foregroundColor(Color(appEnvironment.theme.text))
                    Text(viewModel.body)
                        .font(Font(WKFont.for(.body)))
                        .foregroundColor(Color(appEnvironment.theme.text))
                }
                if let image = viewModel.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 132, height: 118)
                        .foregroundColor(imageColor)
                }
                WKLargeButton(configuration: .primary, title: viewModel.primaryButtonTitle, action: viewModel.primaryButtonAction)
            }
        }
        .padding(.leading)
        .padding(.trailing)
        .padding(.bottom)
    }
}

#Preview {
    WKFeatureAnnouncementView(viewModel: WKFeatureAnnouncementViewModel(title: "Try 'Add an image'", body: "Decide if an image gets added to a Wikipedia article. You can find the ‘Add an image’ card in your ‘Explore feed’.", primaryButtonTitle: "Try now", image:  WKIcon.checkPhoto, primaryButtonAction: {}, closeButtonAction: {}))
}
