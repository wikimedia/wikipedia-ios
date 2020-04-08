
import Foundation

extension FileManager {
    func getValueForExtendedFileAttributeNamed(_ attributeName: String, forFileAtPath path: String) -> String? {
        let name = (attributeName as NSString).utf8String
        let path = (path as NSString).fileSystemRepresentation

        let bufferLength = getxattr(path, name, nil, 0, 0, 0)

        guard bufferLength != -1, let buffer = malloc(bufferLength) else {
            return nil
        }

        let readLen = getxattr(path, name, buffer, bufferLength, 0, 0)
        return String(bytesNoCopy: buffer, length: readLen, encoding: .utf8, freeWhenDone: true)
    }
}
