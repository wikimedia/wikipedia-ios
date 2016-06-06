#import <Foundation/Foundation.h>

@interface NSURLComponents (WMFLinkParsing)

+ (NSURLComponents*)wmf_componentsWithDomain:(NSString*)domain language:(NSString*)language;
+ (NSURLComponents*)wmf_componentsWithDomain:(NSString*)domain language:(NSString*)language isMobile:(BOOL)isMobile;

@end
