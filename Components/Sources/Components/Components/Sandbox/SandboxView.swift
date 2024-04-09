import SwiftUI
import WKData

struct SandboxView: View {
    
    @State var titles: [String] = []
    let username: String
    weak var delegate: WKSandboxListDelegate?
    
    var body: some View {
        
        List(titles, id: \.self) { title in
            SandboxViewCell(sandboxTitle: title)
                .onTapGesture {
                    delegate?.didTapSandboxTitle(title: title)
                }
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
    var sandboxTitle: String
    // var sandboxTopic: String

    var body: some View {
        Text(sandboxTitle)

        // Text(sandboxTopic)

    }
}
