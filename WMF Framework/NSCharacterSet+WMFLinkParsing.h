#import <Foundation/Foundation.h>

@interface NSCharacterSet (WMFLinkParsing)

+ (NSCharacterSet *)wmf_URLPathComponentAllowedCharacterSet;

+ (NSCharacterSet *)wmf_URLQueryAllowedCharacterSet;

@end
