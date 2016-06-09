//Thanks to https://www.cocoanetics.com/2012/03/reading-and-writing-extended-file-attributes/

#import "NSFileManager+WMFExtendedFileAttributes.h"
#import <sys/xattr.h>

NSString* const WMFExtendedFileAttributesErrorDomain = @"org.wikimedia.WMFExtendedFileAttributesError";

@implementation NSFileManager (WMFExtendedFileAttributes)

- (BOOL)wmf_setValue:(NSString*)value forExtendedFileAttributeNamed:(NSString*)attributeName forFileAtPath:(NSString*)path error:(NSError**)error {
    const char* attributeNamePtr = [attributeName UTF8String];
    const char* pathPtr          = [path fileSystemRepresentation];

    const char* valuePtr = [value UTF8String];

    int result = setxattr(pathPtr, attributeNamePtr, valuePtr, strlen(valuePtr), 0, 0);

    BOOL validResult = result != -1;

    if (!validResult && error) {
        int err                    = errno;
        NSString* errorDescription = @"An unexpected error has occurred.";
        switch (err) {
            case EEXIST:
                errorDescription = @"Options contains XATTR_CREATE and the named attribute already exists.";
            case ENOATTR:
                errorDescription = @"Options is set to XATTR_REPLACE and the named attribute does not exist.";
            case ENOTSUP:
                errorDescription = @"The file system does not support extended attributes or has them disabled.";
            case EROFS:
                errorDescription = @"The file system is mounted read-only.";
            case ERANGE:
                errorDescription = @"The data size of the attribute is out of range (some attributes have size restric-tions).";
            case EPERM:
                errorDescription = @"Attributes cannot be associated with this type of object. For example, attributes are not allowed for resource forks.";
            case EINVAL:
                errorDescription = @"Name or options is invalid. Name must be valid UTF-8 and options must make sense.";
            case ENOTDIR:
                errorDescription = @"A component of path is not a directory.";
            case ENAMETOOLONG:
                errorDescription = @"Name exceeded XATTR_MAXNAMELEN UTF-8 bytes, or a component of path exceeded NAME_MAX characters, or the entire path exceeded PATH_MAX characters.";
            case EACCES:
                errorDescription = @"Search permission is denied for a component of path or permission to set the attribute is denied.";
            case ELOOP:
                errorDescription = @"Too many symbolic links were encountered resolving path.";
            case EFAULT:
                errorDescription = @"Path or name points to an invalid address.";
            case EIO:
                errorDescription = @"An I/O error occurred while reading from or writing to the file system.";
            case E2BIG:
                errorDescription = @"The data size of the extended attribute is too large.";
            case ENOSPC:
                errorDescription = @"Not enough space left on the file system.";
        }
        NSDictionary* userInfo = @{NSLocalizedDescriptionKey: errorDescription};
        *error = [NSError errorWithDomain:WMFExtendedFileAttributesErrorDomain code:err userInfo:userInfo];
    }
    return result == 0;
}

- (NSString*)wmf_valueForExtendedFileAttributeNamed:(NSString*)attributeName forFileAtPath:(NSString*)path {
    const char* attributeNamePtr = [attributeName UTF8String];
    const char* pathPtr          = [path fileSystemRepresentation];

    ssize_t bufferLength = getxattr(pathPtr, attributeNamePtr, NULL, 0, 0, 0);

    NSString* result = nil;

    if (bufferLength != -1) { //-1 indicates an error
        char* buffer = malloc(bufferLength);

        ssize_t readLen = getxattr(pathPtr, attributeNamePtr, buffer, bufferLength, 0, 0);

        result = [[NSString alloc] initWithBytes:buffer length:readLen encoding:NSUTF8StringEncoding];

        free(buffer);
    }

    return result;
}

@end
