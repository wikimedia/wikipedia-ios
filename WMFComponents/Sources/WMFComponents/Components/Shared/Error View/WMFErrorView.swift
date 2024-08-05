import Foundation
import SwiftUI

public struct WMFErrorView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    let viewModel: WMFErrorViewModel
    let tryAgainAction: () -> Void

    public var body: some View {
        GeometryReader { geometry in

            ZStack {
                Color(appEnvironment.theme.midBackground)
                    .ignoresSafeArea()
                ScrollView {
                    VStack {
                        Spacer()
                    
                        if let image = viewModel.image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 132, height: 118)
                        }
                        
                        Text(viewModel.localizedStrings.title)
                            .font(Font(WMFFont.for(.boldCallout)))
                            .foregroundColor(Color(appEnvironment.theme.text))
                            .padding([.top], 12)
                            .padding([.bottom], 8)
                            .multilineTextAlignment(.center)
                        
                        Text(viewModel.localizedStrings.subtitle)
                            .font(Font(WMFFont.for(.footnote)))
                            .foregroundColor(Color(appEnvironment.theme.text))
                            .padding([.bottom], 12)
                            .multilineTextAlignment(.center)
                        
                        WMFLargeButton(configuration: .primary, title: viewModel.localizedStrings.buttonTitle, action: tryAgainAction)
                        
                        Spacer()
                    }
                    .frame(minHeight: geometry.size.height)
                    .padding([.leading, .trailing], 32)
                }
            }
        }
    }

}
