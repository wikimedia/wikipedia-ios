#import <Foundation/Foundation.h>

@interface NSURLComponents (WMFLinkParsing)

+ (NSURLComponents*)wmf_componentsWithDomain:(NSString*)domain
                                    language:(NSString*)language;

+ (NSURLComponents*)wmf_componentsWithDomain:(NSString*)domain
                                    language:(NSString*)language
                                    isMobile:(BOOL)isMobile;

+ (NSURLComponents*)wmf_componentsWithDomain:(NSString*)domain
                                    language:(NSString*)language
                                       title:(NSString*)title;

+ (NSURLComponents*)wmf_componentsWithDomain:(NSString*)domain
                                    language:(NSString*)language
                                       title:(NSString*)title
                                    fragment:(NSString*)fragment;

+ (NSURLComponents*)wmf_componentsWithDomain:(NSString*)domain
                                    language:(NSString*)language
                                       title:(NSString*)title
                                    fragment:(NSString*)fragment
                                    isMobile:(BOOL)isMobile;

+ (NSString*)wmf_hostWithDomain:(NSString*)domain
                       language:(NSString*)language
                       isMobile:(BOOL)isMobile;
@end
