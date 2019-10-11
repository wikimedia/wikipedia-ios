
import Foundation

class DiffController {
    
    func fetchDiff(completion: ((Result<DiffResponse, Error>) -> Void)? = nil) {
        
        do {

             let url = Bundle.main.url(forResource: "ObamaTest", withExtension: "json")!
             let data = try Data(contentsOf: url)
             let result = try JSONDecoder().decode(DiffResponse.self, from: data)
            
            //let viewModels: [DiffListGroupViewModel] = viewModels(from networkResponse: DiffResponse)
            completion?(.success(result))
        }
        catch (let error) {
            completion?(.failure(error))
        }
    }
}
