#import "SavedArticlesFetcher.h"

@class MWKImageInfoFetcher;

@interface SavedArticlesFetcher (WMFTesting)

@property(nonatomic, strong, readonly) dispatch_queue_t accessQueue;

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore
                    savedPageList:(MWKSavedPageList *)savedPageList
                   articleFetcher:(WMFArticleFetcher *)articleFetcher
                  imageController:(WMFImageController *)imageController
                 imageInfoFetcher:(MWKImageInfoFetcher *)imageInfoFetcher;

@end
