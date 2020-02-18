
import Foundation

final class CacheFileWriterHelper {
    static func fileURL(for key: String) -> URL {
        return CacheController.cacheURL.appendingPathComponent(key, isDirectory: false)
    }
    
    static func moveFile(from fileURL: URL, toNewFileWithKey key: String, mimeType: String?, completion: @escaping (FileSaveResult) -> Void) {
        do {
            let newFileURL = self.fileURL(for: key)
            try FileManager.default.moveItem(at: fileURL, to: newFileURL)
            if let mimeType = mimeType {
                FileManager.default.setValue(mimeType, forExtendedFileAttributeNamed: WMFExtendedFileAttributeNameMIMEType, forFileAtPath: newFileURL.path)
            }
            completion(.success)
        } catch let error as NSError {
            if error.domain == NSCocoaErrorDomain, error.code == NSFileWriteFileExistsError {
                completion(.exists)
            } else {
                completion(.failure(error))
            }
        } catch let error {
            completion(.failure(error))
        }
    }
    
    static func saveResponseHeader(urlResponse: HTTPURLResponse, toNewFileName fileName: String, completion: @escaping (FileSaveResult) -> Void) {
        
        let contentData: Data = NSKeyedArchiver.archivedData(withRootObject: urlResponse.allHeaderFields)
        
        do {
            let newFileURL = self.fileURL(for: fileName)
            try contentData.write(to: newFileURL)
            completion(.success)
        } catch let error as NSError {
            if error.domain == NSCocoaErrorDomain, error.code == NSFileWriteFileExistsError {
                completion(.exists)
            } else {
                completion(.failure(error))
            }
        } catch let error {
            completion(.failure(error))
        }
    }
    
    static func saveContent(_ content: String, toNewFileName fileName: String, mimeType: String?, completion: @escaping (FileSaveResult) -> Void) {
        
        do {
            let newFileURL = self.fileURL(for: fileName)
            try content.write(to: newFileURL, atomically: true, encoding: .utf8)
            if let mimeType = mimeType {
                FileManager.default.setValue(mimeType, forExtendedFileAttributeNamed: WMFExtendedFileAttributeNameMIMEType, forFileAtPath: newFileURL.path)
            }
            completion(.success)
        } catch let error as NSError {
            if error.domain == NSCocoaErrorDomain, error.code == NSFileWriteFileExistsError {
                completion(.exists)
            } else {
                completion(.failure(error))
            }
        } catch let error {
            completion(.failure(error))
        }
    }
}

enum FileSaveResult {
    case exists
    case success
    case failure(Error)
}
