#import <Foundation/Foundation.h>

extern NSString *const WMFExtendedFileAttributesErrorDomain;

@interface NSFileManager (WMFExtendedFileAttributes)

- (BOOL)wmf_setValue:(NSString *)value forExtendedFileAttributeNamed:(NSString *)attributeName forFileAtPath:(NSString *)path error:(NSError **)error;
- (NSString *)wmf_valueForExtendedFileAttributeNamed:(NSString *)attributeName forFileAtPath:(NSString *)path;

@end
