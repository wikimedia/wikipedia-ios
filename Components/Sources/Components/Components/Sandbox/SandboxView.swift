import SwiftUI
import WKData

struct SandboxView: View {
    @ObservedObject var appEnvironment = WKAppEnvironment.current
    
    @State var titles: [String] = []
    let username: String

    var body: some View {
        
        List(titles, id: \.self) { title in
            SandboxViewCell(sandboxTitle: title)
        }
        .listStyle(.inset)
        .refreshable {
            fetchData()
        }
        .onAppear {
            fetchData()
        }
    }
    
    private func fetchData() {
        let dataController = WKSandboxDataController()
        let testLanguage = WKLanguage(languageCode: "test", languageVariantCode: nil)
        dataController.fetchSandboxArticles(project: WKProject.wikipedia(testLanguage), username: username) { result in
            switch result {
            case .success(let titles):
                self.titles = titles
            case .failure(let error):
                print(error)
            }
        }
    }
}


struct SandboxViewCell: View {
    @ObservedObject var appEnvironment = WKAppEnvironment.current
    var sandboxTitle: String
    // var sandboxTopic: String

    var body: some View {
        Text(sandboxTitle)
            .font(Font(WKFont.for(.boldCallout)))
            .foregroundColor(Color(appEnvironment.theme.text))

//        Text(sandboxTopic)
//            .font(Font(WKFont.for(.callout)))
//            .foregroundColor(Color(appEnvironment.theme.secondaryText))

    }
}
