#import "SavedArticlesFetcher.h"

@class MWKImageInfoFetcher;

@interface SavedArticlesFetcher ()

@property(nonatomic, strong, readonly) dispatch_queue_t accessQueue;

- (instancetype)initWithSavedPageList:(MWKSavedPageList *)savedPageList
                       articleFetcher:(WMFArticleFetcher *)articleFetcher
                      imageController:(WMFImageController *)imageController
                     imageInfoFetcher:(MWKImageInfoFetcher *)imageInfoFetcher NS_DESIGNATED_INITIALIZER;

@end
