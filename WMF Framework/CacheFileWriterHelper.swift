import Foundation

enum CacheFileWriterHelperError: Error {
    case unexpectedHeaderFieldsType
}

final class CacheFileWriterHelper {
    static func fileURL(for key: String) -> URL {
        return CacheController.cacheURL.appendingPathComponent(key, isDirectory: false)
    }
    
    static func saveData(data: Data, toNewFileWithKey key: String, completion: @escaping (FileSaveResult) -> Void) {
        do {
            let newFileURL = self.fileURL(for: key)
            try data.write(to: newFileURL)
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
    
    static func copyFile(from fileURL: URL, toNewFileWithKey key: String, completion: @escaping (FileSaveResult) -> Void) {
        do {
            let newFileURL = self.fileURL(for: key)
            try FileManager.default.copyItem(at: fileURL, to: newFileURL)
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
    
    static func saveResponseHeader(httpUrlResponse: HTTPURLResponse, toNewFileName fileName: String, completion: @escaping (FileSaveResult) -> Void) {
        
        guard let headerFields = httpUrlResponse.allHeaderFields as? [String: String] else {
            completion(.failure(CacheFileWriterHelperError.unexpectedHeaderFieldsType))
            return
        }
            
        saveResponseHeader(headerFields: headerFields, toNewFileName: fileName, completion: completion)
    }
    
    static func saveResponseHeader(headerFields: [String: String], toNewFileName fileName: String, completion: (FileSaveResult) -> Void) {
        do {
            let contentData: Data = try NSKeyedArchiver.archivedData(withRootObject: headerFields, requiringSecureCoding: false)
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
    
    static func replaceResponseHeaderWithURLResponse(_ httpUrlResponse: HTTPURLResponse, atFileName fileName: String, completion: @escaping (FileSaveResult) -> Void) {
        
        guard let headerFields = httpUrlResponse.allHeaderFields as? [String: String] else {
            completion(.failure(CacheFileWriterHelperError.unexpectedHeaderFieldsType))
            return
        }
        
        replaceResponseHeaderWithHeaderFields(headerFields, atFileName: fileName, completion: completion)
    }
    
    static func replaceResponseHeaderWithHeaderFields(_ headerFields:[String: String], atFileName fileName: String, completion: @escaping (FileSaveResult) -> Void) {
        do {
            let headerData: Data = try NSKeyedArchiver.archivedData(withRootObject: headerFields, requiringSecureCoding:false)
            replaceFileWithData(headerData, fileName: fileName, completion: completion)
        } catch let error {
            completion(.failure(error))
        }
    }
    
    static func replaceFileWithData(_ data: Data, fileName: String, completion: @escaping (FileSaveResult) -> Void) {
        let destinationURL = fileURL(for: fileName)
        do {
            let temporaryDirectoryURL = try FileManager.default.url(for: .itemReplacementDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: destinationURL,
                                    create: true)
            
            let temporaryFileName = UUID().uuidString
            
            let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(temporaryFileName)
            
            try data.write(to: temporaryFileURL,
            options: .atomic)
            
            _ = try FileManager.default.replaceItemAt(destinationURL, withItemAt: temporaryFileURL)
            
            try FileManager.default.removeItem(at: temporaryDirectoryURL)
            
            completion(.success)
            
        } catch let error {
            completion(.failure(error))
        }
    }

    
    static func saveContent(_ content: String, toNewFileName fileName: String, completion: @escaping (FileSaveResult) -> Void) {
        
        do {
            let newFileURL = self.fileURL(for: fileName)
            try content.write(to: newFileURL, atomically: true, encoding: .utf8)
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
