#import "WMFArticleFetcher.h"
#import <WMF/WMF-Swift.h>

#if WMF_TWEAKS_ENABLED
#import <Tweaks/FBTweakInline.h>
#endif
//Tried not to do it, but we need it for the useageReports BOOL
//Plan to refactor settings into an another object, then we can remove this.
#import <WMF/SessionSingleton.h>

#import <WMF/MWNetworkActivityIndicatorManager.h>

// Revisions
#import "WMFArticleRevisionFetcher.h"
#import "WMFArticleRevision.h"
#import "WMFRevisionQueryResults.h"

#import "Wikipedia-Swift.h"

//Models
#import <WMF/MWKSectionList.h>
#import <WMF/MWKSection.h>

NS_ASSUME_NONNULL_BEGIN

NSString *const WMFArticleFetcherErrorDomain = @"WMFArticleFetcherErrorDomain";

NSString *const WMFArticleFetcherErrorCachedFallbackArticleKey = @"WMFArticleFetcherErrorCachedFallbackArticleKey";

@interface WMFArticleFetcher ()

@property (nonatomic, strong) dispatch_queue_t operationsQueue;

@property (nonatomic, strong, readwrite) MWKDataStore *dataStore;
@property (nonatomic, strong) WMFArticleRevisionFetcher *revisionFetcher;
@property (nonatomic, strong) WMFArticleSummaryFetcher *summaryFetcher;

@end

@implementation WMFArticleFetcher

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore {
    NSParameterAssert(dataStore);
    self = [super init];
    if (self) {

        self.dataStore = dataStore;
        NSString *queueID = [NSString stringWithFormat:@"org.wikipedia.articlefetcher.accessQueue.%@", [[NSUUID UUID] UUIDString]];
        self.operationsQueue = dispatch_queue_create([queueID cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_SERIAL);
        self.revisionFetcher = [[WMFArticleRevisionFetcher alloc] init];
        self.summaryFetcher = [[WMFArticleSummaryFetcher alloc] initWithSession:self.session configuration:self.configuration];
    }
    return self;
}

#pragma mark - Fetching

- (nullable NSURLSessionTask *)fetchArticleForURL:(NSURL *)articleURL
                                       saveToDisk:(BOOL)saveToDisk
                                         priority:(float)priority
                                          failure:(WMFErrorHandler)failure
                                          success:(WMFArticleHandler)success {
    NSString *title = articleURL.wmf_titleWithUnderscores;
    if (!title) {
        failure([WMFFetcher invalidParametersError]);
        return nil;
    }

    WMFTaskGroup *taskGroup = [WMFTaskGroup new];
    [[MWNetworkActivityIndicatorManager sharedManager] push];

    __block WMFArticleSummary *summaryResponse = nil;
    [taskGroup enter];
    [self.summaryFetcher fetchSummaryFor:articleURL priority:priority completion:^(WMFArticleSummary * _Nullable summary, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        summaryResponse = summary;
        [taskGroup leave];
    }];

    __block id articleResponse = nil;
    __block NSError *articleError = nil;
    [taskGroup enter];

    NSNumber *thumbnailWidth = [[UIScreen mainScreen] wmf_leadImageWidthForScale];
    if (!thumbnailWidth) {
        DDLogError(@"Missing thumbnail width for article request serialization: %@", articleURL);
        thumbnailWidth = @640;
    }

    NSDictionary *params = @{
        @"format": @"json",
        @"action": @"mobileview",
        @"sectionprop": WMFJoinedPropertyParameters(@[@"toclevel", @"line", @"anchor", @"level", @"number",
                                                      @"fromtitle", @"index"]),
        @"noheadings": @"true",
        @"sections": @"all",
        @"page": title,
        @"thumbwidth": thumbnailWidth,
        @"prop": WMFJoinedPropertyParameters(@[@"sections", @"text", @"lastmodified", @"lastmodifiedby", @"languagecount", @"id", @"protection", @"editable", @"displaytitle", @"thumb", @"description", @"image", @"revision", @"namespace", @"pageprops"]),
        @"pageprops": @"wikibase_item"
        //@"pilicense": @"any"
    };

    NSURLSessionTask *operation = [self performCancelableMediaWikiAPIGETForURL:articleURL
                                                               cancellationKey:articleURL.wmf_articleDatabaseKey
                                                           withQueryParameters:params
                                                             completionHandler:^(NSDictionary<NSString *, id> *_Nullable result, NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
                                                                 articleResponse = result[@"mobileview"];
                                                                 articleError = error;
                                                                 [taskGroup leave];
                                                             }];

    operation.priority = priority;

    [taskGroup waitInBackgroundAndNotifyOnQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
                                      withBlock:^{
                                          [[MWNetworkActivityIndicatorManager sharedManager] pop];
                                          if (articleResponse && [articleResponse isKindOfClass:[NSDictionary class]]) {
                                              NSMutableDictionary *mutableArticleResponse = [articleResponse mutableCopy];
                                              //[mutableArticleResponse setValue:mediaResponse forKey:@"media"];
                                              if (!articleResponse[@"coordinates"] && summaryResponse.coordinates) {
                                                  mutableArticleResponse[@"coordinates"] = @{@"lat": @(summaryResponse.coordinates.lat), @"lon": @(summaryResponse.coordinates.lon)};
                                              }

                                              NSURL *updatedArticleURL = articleURL;
                                              NSString *redirectedTitleAndFragment = articleResponse[@"redirected"];
                                              NSArray<NSString *> *redirectedTitleAndFragmentComponents = [redirectedTitleAndFragment componentsSeparatedByString:@"#"];
                                              NSString *redirectedTitle = [redirectedTitleAndFragmentComponents firstObject];
                                              if (redirectedTitle) {
                                                  NSString *redirectedFragment = nil;
                                                  if (redirectedTitleAndFragmentComponents.count > 1) {
                                                      redirectedFragment = redirectedTitleAndFragmentComponents.lastObject;
                                                  }
                                                  updatedArticleURL = [articleURL wmf_URLWithTitle:redirectedTitle fragment:redirectedFragment query:nil];
                                              }

                                              articleResponse = mutableArticleResponse;

                                              NSError *articleSerializationError = nil;
                                              MWKArticle *mwkArticle = [self serializedArticleWithURL:updatedArticleURL response:articleResponse error:&articleSerializationError];

                                              if (articleSerializationError) {
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      failure(articleSerializationError);
                                                  });
                                                  return;
                                              }
                                              [self.dataStore asynchronouslyCacheArticle:mwkArticle
                                                                                  toDisk:saveToDisk
                                                                              completion:^(NSError *_Nonnull articleCacheError) {
                                                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                                                      NSManagedObjectContext *moc = self.dataStore.viewContext;
                                                                                      WMFArticle *article = [moc fetchOrCreateArticleWithURL:updatedArticleURL];
                                                                                      article.isExcludedFromFeed = mwkArticle.ns != 0 || updatedArticleURL.wmf_isMainPage;
                                                                                      article.isDownloaded = NO; //isDownloaded == NO so that any new images added to the article will be downloaded by the SavedArticlesFetcher
                                                                                      article.wikidataID = mwkArticle.wikidataId;
                                                                                      if (summaryResponse) {
                                                                                          [article updateWithSummary:summaryResponse];
                                                                                      }
                                                                                      article.wikidataDescription = mwkArticle.entityDescription; // summary response not as up-to-date as mediawiki
                                                                                      NSError *saveError = nil;
                                                                                      if ([moc hasChanges] && ![moc save:&saveError]) {
                                                                                          DDLogError(@"Error saving after updating article: %@", saveError);
                                                                                      }
                                                                                      if (articleCacheError) {
                                                                                          failure(articleCacheError);
                                                                                      } else {
                                                                                          success(mwkArticle, updatedArticleURL);
                                                                                      }
                                                                                  });
                                                                              }];
                                          } else {
                                              if (!articleError) {
                                                  articleError = WMFFetcher.unexpectedResponseError;
                                              }
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  failure(articleError);
                                              });
                                          }
                                      }];

    return operation;
}

#pragma mark - Operation Tracking / Cancelling

- (void)cancelFetchForArticleURL:(NSURL *)articleURL {
    [self cancelTaskWithCancellationKey:articleURL.wmf_articleDatabaseKey];
}

- (nullable MWKArticle *)serializedArticleWithURL:(NSURL *)url response:(NSDictionary *)response error:(NSError **)error {
    MWKArticle *article = [[MWKArticle alloc] initWithURL:url dataStore:self.dataStore];
    @try {
        [article importMobileViewJSON:response];
        if ([article.url.wmf_language isEqualToString:@"zh"]) {
            NSString *header = [NSLocale wmf_acceptLanguageHeaderForPreferredLanguages];
            article.acceptLanguageRequestHeader = header;
        }
        return article;
    } @catch (NSException *e) {
        DDLogError(@"Failed to import article data. Response: %@. Error: %@", response, e);
        if (error) {
            *error = [WMFFetcher unexpectedResponseError];
        }
        return nil;
    }
}

- (nullable NSURLSessionTask *)fetchLatestVersionOfArticleWithURL:(NSURL *)url
                                                    forceDownload:(BOOL)forceDownload
                                                       saveToDisk:(BOOL)saveToDisk
                                                         priority:(float)priority
                                                          failure:(WMFErrorHandler)failure
                                                          success:(WMFArticleHandler)success {

    NSParameterAssert(url.wmf_title);
    if (!url.wmf_title) {
        DDLogError(@"Can't fetch nil title, cancelling implicitly.");
        failure([WMFFetcher invalidParametersError]);
        return nil;
    }

    MWKArticle *cachedArticle;
    BOOL isChinese = [url.wmf_language isEqualToString:@"zh"];

    if (!forceDownload || isChinese) {
        cachedArticle = [self.dataStore existingArticleWithURL:url];
    }

    BOOL forceDownloadForMismatchedHeader = NO;

    if (isChinese) {
        NSString *header = [NSLocale wmf_acceptLanguageHeaderForPreferredLanguages];
        if (![cachedArticle.acceptLanguageRequestHeader isEqualToString:header]) {
            forceDownloadForMismatchedHeader = YES;
        }
    }

    failure = ^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo ?: @{}];
            userInfo[WMFArticleFetcherErrorCachedFallbackArticleKey] = cachedArticle;
            userInfo[NSLocalizedDescriptionKey] = error.localizedDescription;
            failure([NSError errorWithDomain:error.domain
                                        code:error.code
                                    userInfo:userInfo]);
        });
    };

    @weakify(self);
    NSURLSessionTask *task;
    if (forceDownload || forceDownloadForMismatchedHeader || !cachedArticle || !cachedArticle.revisionId || [cachedArticle isMain]) {
        if (forceDownload) {
            DDLogInfo(@"Forcing Download for %@, fetching immediately", url);
        } else if (!cachedArticle) {
            DDLogInfo(@"No cached article found for %@, fetching immediately.", url);
        } else if (!cachedArticle.revisionId) {
            DDLogInfo(@"Cached article for %@ doesn't have revision ID, fetching immediately.", url);
        } else if (forceDownloadForMismatchedHeader) {
            DDLogInfo(@"Language Headers are mismatched for %@, assume simplified vs traditional as changed, fetching immediately.", url);
        } else {
            //Main pages dont neccesarily have revisions every day. We can't rely on the revision check
            DDLogInfo(@"Cached article for main page: %@, fetching immediately.", url);
        }
        task = [self fetchArticleForURL:url saveToDisk:saveToDisk priority:priority failure:failure success:success];
    } else {
        task = [self.revisionFetcher fetchLatestRevisionsForArticleURL:url
                                                           resultLimit:1
                                                    endingWithRevision:cachedArticle.revisionId.unsignedIntegerValue
                                                               failure:failure
                                                               success:^(id _Nonnull results) {
                                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                                       @strongify(self);
                                                                       if (!self) {
                                                                           failure([WMFFetcher cancelledError]);
                                                                           return;
                                                                       } else if ([[results revisions].firstObject.revisionId isEqualToNumber:cachedArticle.revisionId]) {
                                                                           DDLogInfo(@"Returning up-to-date local revision of %@", url);
                                                                           success(cachedArticle, url);
                                                                           return;
                                                                       } else {
                                                                           [self fetchArticleForURL:url saveToDisk:saveToDisk priority:priority failure:failure success:success];
                                                                           return;
                                                                       }
                                                                   });
                                                               }];
    }
    task.priority = priority;
    return task;
}

- (nullable NSURLSessionTask *)fetchLatestVersionOfArticleWithURLIfNeeded:(NSURL *)url
                                                               saveToDisk:(BOOL)saveToDisk
                                                                 priority:(float)priority
                                                                  failure:(WMFErrorHandler)failure
                                                                  success:(WMFArticleHandler)success {
    return [self fetchLatestVersionOfArticleWithURL:url forceDownload:NO saveToDisk:saveToDisk priority:priority failure:failure success:success];
}

@end

NS_ASSUME_NONNULL_END
