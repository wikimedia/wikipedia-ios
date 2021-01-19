#import "WMFArticleRevision.h"
@import WMF;

#define WMFArticleRevisionKey(key) WMF_SAFE_KEYPATH([WMFArticleRevision new], key)

typedef NS_ENUM(NSInteger, WMFArticleRevisionError) {
    WMFArticleRevisionErrorMissingRevisionId = 1
};

static NSString *const WMFArticleRevisionErrorDomain = @"WMFArticleRevisionErrorDomain";

@implementation WMFArticleRevision

- (BOOL)validate:(NSError *__autoreleasing *)error {
    if (!self.revisionId) {
        WMFSafeAssign(error, [NSError errorWithDomain:WMFArticleRevisionErrorDomain
                                                 code:WMFArticleRevisionErrorMissingRevisionId
                                             userInfo:nil]);
        return NO;
    }
    return YES;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{WMFArticleRevisionKey(revisionId): @"revid",
             WMFArticleRevisionKey(minorEdit): @"minor",
             WMFArticleRevisionKey(sizeInBytes): @"size"};
}

// No languageVariantCodePropagationSubelementKeys
// No languageVariantCodePropagationURLKeys

@end
