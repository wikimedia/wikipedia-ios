#import <Foundation/Foundation.h>

@interface NSURLComponents (WMFLinkParsing)

+ (NSURLComponents* __nonnull)wmf_componentsWithDomain:(NSString* __nonnull)domain
                                              language:(NSString* __nullable)language;

+ (NSURLComponents* __nonnull)wmf_componentsWithDomain:(NSString* __nonnull)domain
                                              language:(NSString* __nullable)language
                                              isMobile:(BOOL)isMobile;

+ (NSURLComponents* __nonnull)wmf_componentsWithDomain:(NSString* __nonnull)domain
                                              language:(NSString* __nullable)language
                                                 title:(NSString* __nullable)title;

+ (NSURLComponents* __nonnull)wmf_componentsWithDomain:(NSString* __nonnull)domain
                                              language:(NSString* __nullable)language
                                                 title:(NSString* __nullable)title
                                              fragment:(NSString* __nullable)fragment;

+ (NSURLComponents* __nonnull)wmf_componentsWithDomain:(NSString* __nonnull)domain
                                              language:(NSString* __nullable)language
                                                 title:(NSString* __nullable)title
                                              fragment:(NSString* __nullable)fragment
                                              isMobile:(BOOL)isMobile;

+ (NSString* __nonnull)wmf_hostWithDomain:(NSString* __nonnull)domain
                                 language:(NSString* __nullable)language
                                 isMobile:(BOOL)isMobile;

@property (nonatomic, copy, nullable) NSString* wmf_title;
@property (nullable, copy) NSString* wmf_fragment;

@end
