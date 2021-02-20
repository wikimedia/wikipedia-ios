
import Foundation

extension Bundle {
    
    enum DecodableError: Error {
        case unableToCreatePath
    }
    
    func objectFromContentsOfOFile<T: Decodable>(fileName: String, fileType: String, objectType: T.Type) throws -> T {
        guard let path = self.path(forResource: fileName, ofType: fileType, inDirectory: "Fixtures") else {
            throw DecodableError.unableToCreatePath
        }
        
        let url = URL(fileURLWithPath: path)
        
        let data = try Data(contentsOf: url)
        let object = try JSONDecoder().decode(T.self, from: data)
        return object
    }
}
