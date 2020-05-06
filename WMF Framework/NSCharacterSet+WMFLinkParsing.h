#import <Foundation/Foundation.h>

@interface NSCharacterSet (WMFLinkParsing)

+ (NSCharacterSet *)wmf_encodeURIComponentAllowedCharacterSet;
+ (NSCharacterSet *)wmf_relativePathAndFragmentAllowedCharacterSet;

@end
