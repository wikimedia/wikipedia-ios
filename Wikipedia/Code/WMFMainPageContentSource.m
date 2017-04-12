#import "WMFMainPageContentSource.h"
#import "MWKSiteInfoFetcher.h"
#import "WMFArticlePreviewFetcher.h"
#import "MWKSiteInfo.h"
#import "MWKSearchResult.h"

@interface WMFMainPageContentSource ()

@property (readwrite, nonatomic, strong) WMFContentGroupDataStore *contentStore;
@property (readwrite, nonatomic, strong) WMFArticleDataStore *previewStore;

@property (readwrite, nonatomic, strong) NSURL *siteURL;

@property (nonatomic, strong) MWKSiteInfoFetcher *siteInfoFetcher;
@property (nonatomic, strong) WMFArticlePreviewFetcher *previewFetcher;

@end

@implementation WMFMainPageContentSource

- (instancetype)initWithSiteURL:(NSURL *)siteURL contentGroupDataStore:(WMFContentGroupDataStore *)contentStore articlePreviewDataStore:(WMFArticleDataStore *)previewStore {
    NSParameterAssert(contentStore);
    NSParameterAssert(previewStore);
    NSParameterAssert(siteURL);
    self = [super init];
    if (self) {
        self.siteURL = siteURL;
        self.contentStore = contentStore;
        self.previewStore = previewStore;
    }
    return self;
}

#pragma mark - Accessors

- (MWKSiteInfoFetcher *)siteInfoFetcher {
    if (_siteInfoFetcher == nil) {
        _siteInfoFetcher = [[MWKSiteInfoFetcher alloc] init];
    }
    return _siteInfoFetcher;
}

- (WMFArticlePreviewFetcher *)previewFetcher {
    if (_previewFetcher == nil) {
        _previewFetcher = [[WMFArticlePreviewFetcher alloc] init];
    }
    return _previewFetcher;
}

#pragma mark - WMFContentSource

- (void)loadNewContentInManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(dispatch_block_t)completion {
    [self fetchAndSaveMainPageForSiteURL:self.siteURL completion:completion];
}

- (void)removeAllContentInManagedObjectContext:(nonnull NSManagedObjectContext *)moc {
    [self.contentStore removeAllContentGroupsOfKind:WMFContentGroupKindMainPage inManagedObjectContext:moc];
}

#pragma mark - Add / Remove Sections

- (void)cleanupOldSectionsInManagedObjectContext:(NSManagedObjectContext *)moc {
    __block BOOL foundTodaysSection = NO;
    
    [self.contentStore enumerateContentGroupsOfKind:WMFContentGroupKindMainPage
                             inManagedObjectContext:moc
                                          withBlock:^(WMFContentGroup *_Nonnull section, BOOL *_Nonnull stop) {
                                              BOOL isForToday = section.isForToday;
                                              if (!isForToday || foundTodaysSection) {
                                                  [self.contentStore removeContentGroup:section inManagedObjectContext:moc];
                                              }
                                              if (!foundTodaysSection) {
                                                  foundTodaysSection = isForToday;
                                              }
                                          }];
}

#pragma mark - Fetch

- (void)fetchAndSaveMainPageForSiteURL:(NSURL *)siteURL intoManagedObjectContext:(NSManagedObjectContext *)moc completion:(nullable dispatch_block_t)completion {
    [moc performBlock:^{
        NSURL *groupURL = [WMFContentGroup mainPageURLForSiteURL:siteURL];
        WMFContentGroup *section = [WMFContentGroup contentGroupForURL:groupURL inManagedObjectContext:moc];
        if (section.isForToday && section.content != nil) {
            if (completion) {
                completion();
            }
            return;
        }
        [self.siteInfoFetcher fetchSiteInfoForSiteURL:self.siteURL
                                           completion:^(MWKSiteInfo *_Nonnull data) {
                                               if (data.mainPageURL == nil) {
                                                   if (completion) {
                                                       completion();
                                                   }
                                                   return;
                                               }
                                               
                                               [self.previewFetcher fetchArticlePreviewResultsForArticleURLs:@[data.mainPageURL]
                                                                                                     siteURL:self.siteURL
                                                                                                  completion:^(NSArray<MWKSearchResult *> *_Nonnull results) {
                                                                                                      if ([results count] == 0) {
                                                                                                          if (completion) {
                                                                                                              completion();
                                                                                                          }
                                                                                                          return;
                                                                                                      }
                                                                                                      [cs performBlockOnImportContext:^(NSManagedObjectContext * _Nonnull moc) {
                                                                                                          WMFContentGroup *section = [self.contentStore fetchOrCreateGroupForURL:groupURL ofKind:WMFContentGroupKindMainPage forDate:[NSDate date] withSiteURL:siteURL associatedContent:nil inManagedObjectContext:moc customizationBlock:NULL];
                                                                                                          [self.previewStore addPreviewWithURL:data.mainPageURL updatedWithSearchResult:[results firstObject] inManagedObjectContext:moc];
                                                                                                          section.content = @[data.mainPageURL];
                                                                                                          [self cleanupOldSectionsInManagedObjectContext:moc];
                                                                                                          
                                                                                                          if (completion) {
                                                                                                              completion();
                                                                                                          }
                                                                                                      }];
                                                                                                  }
                                                                                                     failure:^(NSError *_Nonnull error) {
                                                                                                         //TODO??
                                                                                                         if (completion) {
                                                                                                             completion();
                                                                                                         }
                                                                                                         
                                                                                                     }];
                                               
                                           }
                                              failure:^(NSError *_Nonnull error) {
                                                  //TODO??
                                                  if (completion) {
                                                      completion();
                                                  }
                                              }];
    }];
}

@end
