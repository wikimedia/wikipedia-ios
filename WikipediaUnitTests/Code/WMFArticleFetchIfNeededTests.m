@import Quick;
@import Nimble;
#import "MWKDataStore+TempDataStoreForEach.h"
#import "LSNocilla+Quick.h"
#import "LSStubResponseDSL+WithJSON.h"
#import "WMFArticleFetcher.h"

static inline id articleRevisionResponseWithRevId(NSUInteger revID) {
    return @{
        @"batchcomplete": @YES,
        @"query": @{
            @"pages": @[
                @{
                   @"pageid": @981989,
                   @"ns": @0,
                   @"title": @"Harry Glicken",
                   @"revisions": @[
                       @{
                          @"revid": @(revID),
                          @"parentid": @695972196,
                          @"minor": @YES,
                          @"size": @22416
                       }
                   ]
                }
            ]
        }
    };
}

QuickSpecBegin(WMFArticleFetchIfNeededTests)

    __block WMFArticleFetcher *articleFetcher;
configureTempDataStoreForEach(tempDataStore, ^{
    articleFetcher = [[WMFArticleFetcher alloc] initWithDataStore:tempDataStore];
});
startAndStopStubbingBetweenEach();

describe(@"fetchLatestVersionOfTitleIfNeeded", ^{
    context(@"title is cached with revision ID", ^{
        it(@"should fetch the latest if cache is out of date", ^{
            NSMutableDictionary *latestArticleJSON = [[[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"] mutableCopy];
            [latestArticleJSON setValue:@3 forKeyPath:@"mobileview.revision"];
            MWKArticle *cachedArticle = [[MWKArticle alloc] initWithURL:[NSURL wmf_randomArticleURL]
                                                              dataStore:tempDataStore
                                                                   dict:latestArticleJSON[@"mobileview"]];
            expect(cachedArticle.revisionId).to(equal(@3));
            [cachedArticle save];

            stubRequest(@"GET", [NSRegularExpression regularExpressionWithPattern:@"rvprop" options:0 error:nil])
                .andReturn(200)
                .withJSON(articleRevisionResponseWithRevId(4));

            [latestArticleJSON setValue:@4 forKeyPath:@"mobileview.revision"];

            stubRequest(@"GET", [NSRegularExpression regularExpressionWithPattern:@"mobileview" options:0 error:nil])
                .andReturn(200)
                .withJSON(latestArticleJSON);

            AnyPromise *fetchedArticlePromise = [articleFetcher fetchLatestVersionOfArticleWithURLIfNeeded:cachedArticle.url progress:nil];
            expect(@([fetchedArticlePromise resolved])).withTimeout(WMFDefaultExpectationTimeout).toEventually(beTrue());
            MWKArticle *fetchedArticle = [fetchedArticlePromise value];
            expect(fetchedArticle).toNotWithDescription(equal(cachedArticle), @"Should have fetched latest revision.");
            expect(fetchedArticle.entityDescription).to(equal(cachedArticle.entityDescription));
            expect(fetchedArticle.sections).to(equal(cachedArticle.sections));
        });

        it(@"should return cached article if cache is up to date", ^{
            NSMutableDictionary *latestArticleJSON = [[[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"] mutableCopy];
            [latestArticleJSON setValue:@3 forKeyPath:@"mobileview.revision"];
            MWKArticle *cachedArticle = [[MWKArticle alloc] initWithURL:[NSURL wmf_randomArticleURL]
                                                              dataStore:tempDataStore
                                                                   dict:latestArticleJSON[@"mobileview"]];
            expect(cachedArticle.revisionId).to(equal(@3));
            [cachedArticle save];

            stubRequest(@"GET", [NSRegularExpression regularExpressionWithPattern:@"rvprop" options:0 error:nil])
                .andReturn(200)
                .withJSON(articleRevisionResponseWithRevId(3));

            stubRequest(@"GET", [NSRegularExpression regularExpressionWithPattern:@"mobileview" options:0 error:nil])
                .andReturn(400);

            AnyPromise *fetchedArticlePromise = [articleFetcher fetchLatestVersionOfArticleWithURLIfNeeded:cachedArticle.url progress:nil];
            expect(@([fetchedArticlePromise resolved])).withTimeout(WMFDefaultExpectationTimeout).toEventually(beTrue());
            MWKArticle *fetchedArticle = [fetchedArticlePromise value];
            expect(fetchedArticle).to(beIdenticalTo(cachedArticle));
        });

        it(@"should ignore the cache if force is passed", ^{
            NSMutableDictionary *latestArticleJSON = [[[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"] mutableCopy];
            [latestArticleJSON setValue:@3 forKeyPath:@"mobileview.revision"];
            MWKArticle *cachedArticle = [[MWKArticle alloc] initWithURL:[NSURL wmf_randomArticleURL]
                                                              dataStore:tempDataStore
                                                                   dict:latestArticleJSON[@"mobileview"]];
            expect(cachedArticle.revisionId).to(equal(@3));
            [cachedArticle save];

            stubRequest(@"GET", [NSRegularExpression regularExpressionWithPattern:@"rvprop" options:0 error:nil])
                .andReturn(200)
                .withJSON(articleRevisionResponseWithRevId(3));

            [latestArticleJSON setValue:@1 forKeyPath:@"mobileview.revision"];

            stubRequest(@"GET", [NSRegularExpression regularExpressionWithPattern:@"mobileview" options:0 error:nil])
                .andReturn(200)
                .withJSON(latestArticleJSON);

            AnyPromise *fetchedArticlePromise = [articleFetcher fetchLatestVersionOfArticleWithURL:cachedArticle.url forceDownload:YES progress:nil];
            expect(@([fetchedArticlePromise resolved])).withTimeout(WMFDefaultExpectationTimeout).toEventually(beTrue());
            MWKArticle *fetchedArticle = [fetchedArticlePromise value];
            expect(fetchedArticle).toNotWithDescription(equal(cachedArticle), @"Should have fetched.");
            expect(fetchedArticle.entityDescription).to(equal(cachedArticle.entityDescription));
            expect(fetchedArticle.sections).to(equal(cachedArticle.sections));
            expect(fetchedArticle.revisionId).to(equal(@1));

        });

        whenOffline(^{
            it(@"should fall back to the cached article", ^{
                NSMutableDictionary *latestArticleJSON = [[[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"] mutableCopy];
                [latestArticleJSON setValue:@3 forKeyPath:@"mobileview.revision"];
                MWKArticle *cachedArticle = [[MWKArticle alloc] initWithURL:[NSURL wmf_randomArticleURL]
                                                                  dataStore:tempDataStore
                                                                       dict:latestArticleJSON[@"mobileview"]];
                expect(cachedArticle.revisionId).to(equal(@3));
                [cachedArticle save];

                AnyPromise *fetchedArticlePromise = [articleFetcher fetchLatestVersionOfArticleWithURLIfNeeded:cachedArticle.url progress:nil];
                expect(@([fetchedArticlePromise rejected])).withTimeout(WMFDefaultExpectationTimeout).toEventually(beTrue());
                NSError *error = [fetchedArticlePromise value];
                expect(error.userInfo[WMFArticleFetcherErrorCachedFallbackArticleKey])
                    .to(beIdenticalTo(cachedArticle));
            });
        });
    });

    context(@"title is cached without revision ID", ^{
        __block NSDictionary *cachedArticleJSON;
        __block MWKArticle *cachedArticle;
        beforeEach(^{
            cachedArticleJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"];
            cachedArticle = [[MWKArticle alloc] initWithURL:[NSURL wmf_randomArticleURL]
                                                  dataStore:tempDataStore
                                                       dict:cachedArticleJSON[@"mobileview"]];
            expect(cachedArticle.revisionId).to(beNil());
            [cachedArticle save];
        });

        it(@"should fetch the article without querying for the latest", ^{
            stubRequest(@"GET", [NSRegularExpression regularExpressionWithPattern:@"mobileview" options:0 error:nil])
                .andReturn(200)
                .withJSON(cachedArticleJSON);

            stubRequest(@"GET", [NSRegularExpression regularExpressionWithPattern:@"rvprop" options:0 error:nil])
                .andReturn(400);

            AnyPromise *fetchedArticlePromise = [articleFetcher fetchLatestVersionOfArticleWithURLIfNeeded:cachedArticle.url progress:nil];
            expect(@(fetchedArticlePromise.resolved)).withTimeout(WMFDefaultExpectationTimeout).toEventually(beTrue());
            MWKArticle *fetchedArticle = [fetchedArticlePromise value];
            expect(fetchedArticle).to(equal(cachedArticle));
        });

        whenOffline(^{
            it(@"should fall back to the cached article", ^{
                AnyPromise *fetchedArticlePromise = [articleFetcher fetchLatestVersionOfArticleWithURLIfNeeded:cachedArticle.url progress:nil];
                expect(@(fetchedArticlePromise.rejected)).withTimeout(WMFDefaultExpectationTimeout).toEventually(beTrue());
                NSError *error = [fetchedArticlePromise value];
                MWKArticle *fetchedArticle = error.userInfo[WMFArticleFetcherErrorCachedFallbackArticleKey];
                expect(fetchedArticle).to(beIdenticalTo(cachedArticle));
            });
        });
    });
});

QuickSpecEnd
