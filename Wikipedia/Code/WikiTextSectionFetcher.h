#import <WMF/WMFLegacyFetcher.h>

NS_ASSUME_NONNULL_BEGIN

@class MWKSection;

typedef NS_ENUM(NSInteger, WikiTextFetcherErrorType) {
    WikiTextFetcherErrorTypeUnknown = 0,
    WikiTextFetcherErrorTypeAPI = 1,
    WikiTextFetcherErrorTypeIncomplete = 2
};

extern NSString *const WikiTextSectionFetcherErrorDomain;

@interface WikiTextSectionFetcher : WMFLegacyFetcher

- (void)fetchSection:(MWKSection *)section completion:(void (^)(NSDictionary *_Nullable result, NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
