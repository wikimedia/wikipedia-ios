#import <UIKit/UIKit.h>

#ifndef Wikipedia_WMFBlockDefinitions_h
#define Wikipedia_WMFBlockDefinitions_h

NS_ASSUME_NONNULL_BEGIN

@class MWKSearchResult;
@class WMFSearchResults;
@class HistoryFetchResults;
@class CLPlacemark;

typedef void (^WMFProgressHandler)(CGFloat progress);
typedef void (^WMFErrorHandler)(NSError *error);
typedef void (^WMFMWKSearchResultHandler)(MWKSearchResult *result);
typedef void (^WMFSearchResultsHandler)(WMFSearchResults *results);
typedef void (^WMFHistoryFetchResultsHandler)(HistoryFetchResults *results);
typedef void (^WMFArrayOfNumbersHandler)(NSArray<NSNumber *> *_Nonnull results);
typedef void (^WMFPlacemarkHandler)(CLPlacemark *result);

typedef void (^WMFSuccessHandler)(void);
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
