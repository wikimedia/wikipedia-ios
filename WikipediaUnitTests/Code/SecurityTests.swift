import XCTest

class SecurityTests: XCTestCase {
    
    func testFileProtection() {
        let fileURL: URL = MWKDataStore.shared().containerURL
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: fileURL, includingPropertiesForKeys: [URLResourceKey.fileProtectionKey], options: [], errorHandler: { url, error in
            XCTAssert(false, "Enumerator error")
            return false
        }) else {
            XCTAssert(false, "Enumerator error")
            return
        }
        for item in enumerator {
            guard
                let fileURL = item as? URL,
                let values = try? fileURL.resourceValues(forKeys: [URLResourceKey.isDirectoryKey, URLResourceKey.fileProtectionKey]),
                let isDirectory = values.isDirectory
                else {
                    XCTAssert(false, "Unable to get isDirectory value")
                    return
            }
            guard !isDirectory else {
                continue
            }
            guard let fileProtection = values.fileProtection else {
                XCTAssert(false, "Unable to get fileProtection value")
                return
            }
            XCTAssert(fileProtection == .completeUntilFirstUserAuthentication)
        }
       
    }
    
}
    

