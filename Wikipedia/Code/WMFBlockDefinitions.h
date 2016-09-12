@import UIKit;

#ifndef Wikipedia_WMFBlockDefinitions_h
#define Wikipedia_WMFBlockDefinitions_h

NS_ASSUME_NONNULL_BEGIN

@class MWKArticle;
@class MWKSearchResult;

typedef void (^WMFArticleHandler)(MWKArticle *article);
typedef void (^WMFProgressHandler)(CGFloat progress);
typedef void (^WMFErrorHandler)(NSError *error);
typedef void (^WMFSearchResultHandler)(MWKSearchResult *result);
typedef void (^WMFArrayOfNumbersHandler)(NSArray <NSNumber *> * _Nonnull results);

typedef void (^WMFSuccessHandler)();
typedef void (^WMFSuccessIdHandler)(id object);
typedef void (^WMFSuccessUIImageHandler)(UIImage *image);
typedef void (^WMFSuccessNSValueHandler)(NSValue *value);
typedef void (^WMFSuccessNSArrayHandler)(NSArray *value);
typedef void (^WMFSuccessBoolHandler)(BOOL value);

static WMFErrorHandler WMFIgnoreErrorHandler = ^(NSError *error) {
};
static WMFSuccessHandler WMFIgnoreSuccessHandler = ^() {
};

NS_ASSUME_NONNULL_END

#endif
