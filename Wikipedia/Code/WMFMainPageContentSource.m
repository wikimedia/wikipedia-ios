#import "WMFMainPageContentSource.h"
#import "MWKSiteInfoFetcher.h"
#import "WMFArticlePreviewFetcher.h"
#import "MWKSiteInfo.h"
#import "MWKSearchResult.h"

@interface WMFMainPageContentSource ()

@property (readwrite, nonatomic, strong) NSURL *siteURL;

@property (nonatomic, strong) MWKSiteInfoFetcher *siteInfoFetcher;
@property (nonatomic, strong) WMFArticlePreviewFetcher *previewFetcher;

@end

@implementation WMFMainPageContentSource

- (instancetype)initWithSiteURL:(NSURL *)siteURL  {
    NSParameterAssert(siteURL);
    self = [super init];
    if (self) {
        self.siteURL = siteURL;
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
    [self fetchAndSaveMainPageForSiteURL:self.siteURL intoManagedObjectContext:moc completion:completion];
}

- (void)removeAllContentInManagedObjectContext:(nonnull NSManagedObjectContext *)moc {
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindMainPage];
}

#pragma mark - Add / Remove Sections

- (void)cleanupOldSectionsInManagedObjectContext:(NSManagedObjectContext *)moc {
    __block BOOL foundTodaysSection = NO;
    
    [moc enumerateContentGroupsOfKind:WMFContentGroupKindMainPage
                                          withBlock:^(WMFContentGroup *_Nonnull section, BOOL *_Nonnull stop) {
                                              BOOL isForToday = section.isForToday;
                                              if (!isForToday || foundTodaysSection) {
                                                  [moc removeContentGroup:section];
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
        WMFContentGroup *section = [moc contentGroupForURL:groupURL];
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
                                                                                                      [moc performBlock:^{
                                                                                                          WMFContentGroup *section = [moc fetchOrCreateGroupForURL:groupURL ofKind:WMFContentGroupKindMainPage forDate:[NSDate date] withSiteURL:siteURL associatedContent:nil customizationBlock:NULL];
                                                                                                          [moc fetchOrCreateArticleWithURL:data.mainPageURL updatedWithSearchResult:[results firstObject]];
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
