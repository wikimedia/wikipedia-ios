#import "NSURL+WMFMainPage.h"
#import "WMFAssetsFile.h"
#import "NSURL+WMFLinkParsing.h"

@implementation NSURL (WMFMainPage)

+ (WMFAssetsFile *)mainPages {
    static WMFAssetsFile *mainPages;
    if (!mainPages) {
        mainPages = [[WMFAssetsFile alloc] initWithFileType:WMFAssetsFileTypeMainPages];
    }
    return mainPages;
}

+ (nullable NSURL *)wmf_mainPageURLForLanguage:(nonnull NSString *)language {
    NSString *titleText = [self mainPages].dictionary[language];
    if (!titleText) {
        return nil;
    }
    return [NSURL wmf_URLWithDomain:WMFDefaultSiteDomain language:language title:titleText fragment:nil];
}

- (BOOL)wmf_isMainPage {
    if (self.wmf_isNonStandardURL) {
        return NO;
    }
    NSURL *mainArticleURL = [NSURL wmf_mainPageURLForLanguage:self.wmf_language];
    return ([self isEqual:mainArticleURL]);
}

@end
