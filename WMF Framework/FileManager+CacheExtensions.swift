
import Foundation

extension FileManager {
    /// DEPRECATED: This should only be used for migrating legacy data to the new cache format. The app should no longer need to store information in extended file attributes. Previously, this was used to store the MIME type of a cached file so the approrpriate Content-Type could be set when serving it as a cached response. Now, the response headers are cached in a separate file, removing the need to attach MIME type (or any other info) to the file itself. This function can be removed when the corresponding migration is removed.
    /// - Parameter attributeName: Extended file attribute name
    /// - Parameter path: Path of the file
    /// - Returns: the attribute value for the given attributeName or nil if no such attribute exists on the file
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
