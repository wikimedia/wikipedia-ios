@import Quick;
@import Nimble;
@import NSDate_Extensions;

#import "WMFExploreSection.h"
#import "WMFExploreSectionSchema_Testing.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "WMFRandomFileUtilities.h"
#import "WMFRelatedSectionBlacklist.h"
#import "WMFMockLocationManager.h"

QuickSpecBegin(WMFExploreSectionSchemaTests)

    __block WMFExploreSectionSchema *schema;
__block MWKDataStore *dataStore;
__block WMFMockLocationManager *mockLocationManager;

// Convenience setup method which creates a schema for the given site, injecting mocks & temporary stores for other fields.
<<<<<<< HEAD
void (^setupSchemaWithSiteURL)(NSURL *) = ^(NSURL *siteURL) {
    // TODO: setup w/ temp blacklist
    schema = [WMFExploreSectionSchema schemaWithSiteURL:siteURL
                                             savedPages:dataStore.userDataStore.savedPageList
                                                history:dataStore.userDataStore.historyList
                                              blackList:[WMFRelatedSectionBlackList new]
                                        locationManager:mockLocationManager
                                                   file:[NSURL fileURLWithPath:WMFRandomTemporaryFileOfType(@"plist")]];
=======
void (^setupSchemaWithSiteURL)(NSURL *) = ^(NSURL *siteURL) {
    // TODO: setup w/ temp blacklist
    schema = [WMFExploreSectionSchema schemaWithSiteURL:siteURL
                                             savedPages:dataStore.userDataStore.savedPageList
                                                history:dataStore.userDataStore.historyList
                                              blackList:[WMFRelatedSectionBlackList new]
                                        locationManager:mockLocationManager
                                                   file:[NSURL fileURLWithPath:WMFRandomTemporaryFileOfType(@"plist")]];
>>>>>>> develop
};

beforeEach(^{
    dataStore = [MWKDataStore temporaryDataStore];
    mockLocationManager = [WMFMockLocationManager new];
});

afterEach(^{
    [dataStore removeFolderAtBasePath];
    [[NSFileManager defaultManager] removeItemAtPath:schema.fileURL.path error:nil];
});

describe(@"initial state", ^{
    __block NSURL *siteURL;

    context(@"en wiki", ^{
        beforeEach(^{
            siteURL = [NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"];
        });

        context(@"location allowed", ^{
            beforeEach(^{
                [mockLocationManager setLocation:[[CLLocation alloc] initWithLatitude:0 longitude:0]];
            });

            it(@"should contain everything except 'because you read' sections", ^{
                setupSchemaWithSiteURL(siteURL);

                expect(@([schema.lastUpdatedAt isToday])).to(beTrue());
                expect([schema.sections valueForKey:WMF_SAFE_KEYPATH([WMFExploreSection new], type)])
                    .withTimeout(5)
                    .toEventually(equal(@[ @(WMFExploreSectionTypeFeaturedArticle),
                                           @(WMFExploreSectionTypeMostRead),
                                           @(WMFExploreSectionTypePictureOfTheDay),
                                           @(WMFExploreSectionTypeMainPage),
                                           @(WMFExploreSectionTypeRandom),
                                           @(WMFExploreSectionTypeNearby) ]));

                WMFExploreSection *featuredArticleSection = schema.sections[0];
                expect(@(featuredArticleSection.type)).to(equal(@(WMFExploreSectionTypeFeaturedArticle)));
                expect(featuredArticleSection.siteURL).to(equal(siteURL));
                expect(@([featuredArticleSection.dateCreated isToday])).to(beTrue());

                WMFExploreSection *mostReadSection = schema.sections[1];
                expect(@(mostReadSection.type)).to(equal(@(WMFExploreSectionTypeMostRead)));
                expect(mostReadSection.siteURL).to(equal(siteURL));
                // not asserting most read section date, see WMFMostReadDateTests

                WMFExploreSection *potdSection = schema.sections[2];
                expect(@(potdSection.type)).to(equal(@(WMFExploreSectionTypePictureOfTheDay)));
                expect(@([potdSection.dateCreated isToday])).to(beTrue());

                WMFExploreSection *mainPageSection = schema.sections[3];
                expect(@(mainPageSection.type)).to(equal(@(WMFExploreSectionTypeMainPage)));
                expect(mainPageSection.siteURL).to(equal(siteURL));
                expect(@([mainPageSection.dateCreated isToday])).to(beTrue());

                WMFExploreSection *randomSection = schema.sections[4];
                expect(@(randomSection.type)).to(equal(@(WMFExploreSectionTypeRandom)));
                expect(@([randomSection.dateCreated isToday])).to(beTrue());

                WMFExploreSection *nearbySection = schema.sections[5];
                expect(@(nearbySection.type)).to(equal(@(WMFExploreSectionTypeNearby)));
                expect(nearbySection.location).to(equal(mockLocationManager.location));
                expect(@([nearbySection.dateCreated isToday])).to(beTrue());
            });

            context(@"saved and recent pages", ^{
                beforeEach(^{
                    // TODO: add saved & recent page
                });

<<<<<<< HEAD
                pending(@"should include saved & recent page entries", ^{
                        });
            });
        });

        context(@"no location", ^{
            it(@"should contain everything except 'because you read', continue reading, and location sections", ^{
                setupSchemaWithSiteURL(siteURL);
                expect(@([schema.lastUpdatedAt isToday])).to(beTrue());
                expect([schema.sections valueForKey:WMF_SAFE_KEYPATH([WMFExploreSection new], type)])
                    .withTimeout(5)
                    .toEventually(equal(@[ @(WMFExploreSectionTypeFeaturedArticle),
                                           @(WMFExploreSectionTypeMostRead),
                                           @(WMFExploreSectionTypePictureOfTheDay),
                                           @(WMFExploreSectionTypeMainPage),
                                           @(WMFExploreSectionTypeRandom) ]));

                WMFExploreSection *featuredArticleSection = schema.sections[0];
                expect(@(featuredArticleSection.type)).to(equal(@(WMFExploreSectionTypeFeaturedArticle)));
                expect(featuredArticleSection.siteURL).to(equal(siteURL));
                expect(@([featuredArticleSection.dateCreated isToday])).to(beTrue());

                WMFExploreSection *mostReadSection = schema.sections[1];
                expect(@(mostReadSection.type)).to(equal(@(WMFExploreSectionTypeMostRead)));
                expect(mostReadSection.siteURL).to(equal(siteURL));
                // not asserting most read section date, see WMFMostReadDateTests

                WMFExploreSection *potdSection = schema.sections[2];
                expect(@(potdSection.type)).to(equal(@(WMFExploreSectionTypePictureOfTheDay)));
                expect(@([potdSection.dateCreated isToday])).to(beTrue());

                WMFExploreSection *mainPageSection = schema.sections[3];
                expect(@(mainPageSection.type)).to(equal(@(WMFExploreSectionTypeMainPage)));
                expect(mainPageSection.siteURL).to(equal(siteURL));
                expect(@([mainPageSection.dateCreated isToday])).to(beTrue());

                WMFExploreSection *randomSection = schema.sections[4];
                expect(@(randomSection.type)).to(equal(@(WMFExploreSectionTypeRandom)));
                expect(@([randomSection.dateCreated isToday])).to(beTrue());
            });
=======
                context(@"location allowed", ^{
                    beforeEach(^{
                        [mockLocationManager setLocation:[[CLLocation alloc] initWithLatitude:0 longitude:0]];
                    });

                    it(@"should contain everything except 'because you read' sections", ^{
                        setupSchemaWithSiteURL(siteURL);

                        expect(@([schema.lastUpdatedAt isToday])).to(beTrue());
                        expect([schema.sections valueForKey:WMF_SAFE_KEYPATH([WMFExploreSection new], type)])
                            .withTimeout(5)
                            .toEventually(equal(@[ @(WMFExploreSectionTypeMainPage),
                                                   @(WMFExploreSectionTypeFeaturedArticle),
                                                   @(WMFExploreSectionTypeMostRead),
                                                   @(WMFExploreSectionTypePictureOfTheDay),
                                                   @(WMFExploreSectionTypeRandom),
                                                   @(WMFExploreSectionTypeNearby) ]));

                        WMFExploreSection *mainPageSection = schema.sections[0];
                        expect(@(mainPageSection.type)).to(equal(@(WMFExploreSectionTypeMainPage)));
                        expect(mainPageSection.siteURL).to(equal(siteURL));
                        expect(@([mainPageSection.dateCreated isToday])).to(beTrue());

                        WMFExploreSection *featuredArticleSection = schema.sections[1];
                        expect(@(featuredArticleSection.type)).to(equal(@(WMFExploreSectionTypeFeaturedArticle)));
                        expect(featuredArticleSection.siteURL).to(equal(siteURL));
                        expect(@([featuredArticleSection.dateCreated isToday])).to(beTrue());

                        WMFExploreSection *mostReadSection = schema.sections[2];
                        expect(@(mostReadSection.type)).to(equal(@(WMFExploreSectionTypeMostRead)));
                        expect(mostReadSection.siteURL).to(equal(siteURL));
                        // not asserting most read section date, see WMFMostReadDateTests

                        WMFExploreSection *potdSection = schema.sections[3];
                        expect(@(potdSection.type)).to(equal(@(WMFExploreSectionTypePictureOfTheDay)));
                        expect(@([potdSection.dateCreated isToday])).to(beTrue());

                        WMFExploreSection *randomSection = schema.sections[4];
                        expect(@(randomSection.type)).to(equal(@(WMFExploreSectionTypeRandom)));
                        expect(@([randomSection.dateCreated isToday])).to(beTrue());

                        WMFExploreSection *nearbySection = schema.sections[5];
                        expect(@(nearbySection.type)).to(equal(@(WMFExploreSectionTypeNearby)));
                        expect(nearbySection.location).to(equal(mockLocationManager.location));
                        expect(@([nearbySection.dateCreated isToday])).to(beTrue());
                    });

                    context(@"saved and recent pages", ^{
                        beforeEach(^{
                            // TODO: add saved & recent page
                        });

                        pending(@"should include saved & recent page entries", ^{
                                });
                    });
                });

                context(@"no location", ^{
                    it(@"should contain everything except 'because you read', continue reading, and location sections", ^{
                        setupSchemaWithSiteURL(siteURL);
                        expect(@([schema.lastUpdatedAt isToday])).to(beTrue());
                        expect([schema.sections valueForKey:WMF_SAFE_KEYPATH([WMFExploreSection new], type)])
                            .withTimeout(5)
                            .toEventually(equal(@[ @(WMFExploreSectionTypeMainPage),
                                                   @(WMFExploreSectionTypeFeaturedArticle),
                                                   @(WMFExploreSectionTypeMostRead),
                                                   @(WMFExploreSectionTypePictureOfTheDay),
                                                   @(WMFExploreSectionTypeRandom) ]));

                        WMFExploreSection *mainPageSection = schema.sections[0];
                        expect(@(mainPageSection.type)).to(equal(@(WMFExploreSectionTypeMainPage)));
                        expect(mainPageSection.siteURL).to(equal(siteURL));
                        expect(@([mainPageSection.dateCreated isToday])).to(beTrue());

                        WMFExploreSection *featuredArticleSection = schema.sections[1];
                        expect(@(featuredArticleSection.type)).to(equal(@(WMFExploreSectionTypeFeaturedArticle)));
                        expect(featuredArticleSection.siteURL).to(equal(siteURL));
                        expect(@([featuredArticleSection.dateCreated isToday])).to(beTrue());

                        WMFExploreSection *mostReadSection = schema.sections[2];
                        expect(@(mostReadSection.type)).to(equal(@(WMFExploreSectionTypeMostRead)));
                        expect(mostReadSection.siteURL).to(equal(siteURL));
                        // not asserting most read section date, see WMFMostReadDateTests

                        WMFExploreSection *potdSection = schema.sections[3];
                        expect(@(potdSection.type)).to(equal(@(WMFExploreSectionTypePictureOfTheDay)));
                        expect(@([potdSection.dateCreated isToday])).to(beTrue());

                        WMFExploreSection *randomSection = schema.sections[4];
                        expect(@(randomSection.type)).to(equal(@(WMFExploreSectionTypeRandom)));
                        expect(@([randomSection.dateCreated isToday])).to(beTrue());
                    });
                });
            });

            context(@"es wiki", ^{
                beforeEach(^{
                    siteURL = [NSURL wmf_URLWithDefaultSiteAndlanguage:@"es"];
                });

                context(@"clean install, with location", ^{
                    beforeEach(^{
                        [mockLocationManager setLocation:[[CLLocation alloc] initWithLatitude:0 longitude:0]];
                    });

                    it(@"should contain same as EN wiki, minus featured article", ^{
                        setupSchemaWithSiteURL(siteURL);
                        expect(@([schema.lastUpdatedAt isToday])).to(beTrue());
                        expect([schema.sections valueForKey:WMF_SAFE_KEYPATH([WMFExploreSection new], type)])
                            .withTimeout(5)
                            .toEventually(equal(@[ @(WMFExploreSectionTypeMainPage),
                                                   @(WMFExploreSectionTypeMostRead),
                                                   @(WMFExploreSectionTypePictureOfTheDay),
                                                   @(WMFExploreSectionTypeRandom),
                                                   @(WMFExploreSectionTypeNearby) ]));

                        WMFExploreSection *mainPageSection = schema.sections[0];
                        expect(@(mainPageSection.type)).to(equal(@(WMFExploreSectionTypeMainPage)));
                        expect(mainPageSection.siteURL).to(equal(siteURL));
                        expect(@([mainPageSection.dateCreated isToday])).to(beTrue());

                        WMFExploreSection *mostReadSection = schema.sections[1];
                        expect(@(mostReadSection.type)).to(equal(@(WMFExploreSectionTypeMostRead)));
                        expect(mostReadSection.siteURL).to(equal(siteURL));
                        // not asserting most read section date, see WMFMostReadDateTests

                        WMFExploreSection *potdSection = schema.sections[2];
                        expect(@(potdSection.type)).to(equal(@(WMFExploreSectionTypePictureOfTheDay)));
                        expect(@([potdSection.dateCreated isToday])).to(beTrue());

                        WMFExploreSection *randomSection = schema.sections[3];
                        expect(@(randomSection.type)).to(equal(@(WMFExploreSectionTypeRandom)));
                        expect(@([randomSection.dateCreated isToday])).to(beTrue());

                        WMFExploreSection *nearbySection = schema.sections[4];
                        expect(@(nearbySection.type)).to(equal(@(WMFExploreSectionTypeNearby)));
                        expect(nearbySection.location).to(equal(mockLocationManager.location));
                        expect(@([nearbySection.dateCreated isToday])).to(beTrue());
                    });
                });
>>>>>>> develop
        });
    });

    context(@"es wiki", ^{
        beforeEach(^{
            siteURL = [NSURL wmf_URLWithDefaultSiteAndlanguage:@"es"];
        });

<<<<<<< HEAD
        context(@"clean install, with location", ^{
            beforeEach(^{
                [mockLocationManager setLocation:[[CLLocation alloc] initWithLatitude:0 longitude:0]];
            });

            it(@"should contain same as EN wiki, minus featured article", ^{
                setupSchemaWithSiteURL(siteURL);
                expect(@([schema.lastUpdatedAt isToday])).to(beTrue());
                expect([schema.sections valueForKey:WMF_SAFE_KEYPATH([WMFExploreSection new], type)])
                    .withTimeout(5)
                    .toEventually(equal(@[ @(WMFExploreSectionTypeMostRead),
                                           @(WMFExploreSectionTypePictureOfTheDay),
                                           @(WMFExploreSectionTypeMainPage),
                                           @(WMFExploreSectionTypeRandom),
                                           @(WMFExploreSectionTypeNearby) ]));

                WMFExploreSection *mostReadSection = schema.sections[0];
                expect(@(mostReadSection.type)).to(equal(@(WMFExploreSectionTypeMostRead)));
                expect(mostReadSection.siteURL).to(equal(siteURL));
                // not asserting most read section date, see WMFMostReadDateTests

                WMFExploreSection *potdSection = schema.sections[1];
                expect(@(potdSection.type)).to(equal(@(WMFExploreSectionTypePictureOfTheDay)));
                expect(@([potdSection.dateCreated isToday])).to(beTrue());

                WMFExploreSection *mainPageSection = schema.sections[2];
                expect(@(mainPageSection.type)).to(equal(@(WMFExploreSectionTypeMainPage)));
                expect(mainPageSection.siteURL).to(equal(siteURL));
                expect(@([mainPageSection.dateCreated isToday])).to(beTrue());

                WMFExploreSection *randomSection = schema.sections[3];
                expect(@(randomSection.type)).to(equal(@(WMFExploreSectionTypeRandom)));
                expect(@([randomSection.dateCreated isToday])).to(beTrue());

                WMFExploreSection *nearbySection = schema.sections[4];
                expect(@(nearbySection.type)).to(equal(@(WMFExploreSectionTypeNearby)));
                expect(nearbySection.location).to(equal(mockLocationManager.location));
                expect(@([nearbySection.dateCreated isToday])).to(beTrue());
            });
=======
            it(@"should be equal to a copy read from data serialized to disk", ^{
                expect(schema.sections).withTimeout(5).toEventually(haveCount(@6));

                AnyPromise *schemaSave = [schema save];
                expect(@(schemaSave.resolved)).withTimeout(5).toEventually(beTrue());

                WMFExploreSectionSchema *schema2 = [WMFExploreSectionSchema schemaWithSiteURL:schema.siteURL
                                                                                   savedPages:schema.savedPages
                                                                                      history:schema.historyPages
                                                                                    blackList:schema.blackList
                                                                              locationManager:mockLocationManager
                                                                                         file:schema.fileURL];
                // lastUpdatedAt times will be slightly different, since it will forcibly update on creation
                expect(schema2.sections).to(equal(schema.sections));
>>>>>>> develop
        });
    });
});

describe(@"persistence", ^{
    beforeEach(^{
        [mockLocationManager setLocation:[[CLLocation alloc] initWithLatitude:0 longitude:0]];
        setupSchemaWithSiteURL([NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"]);
    });

    it(@"should be equal to a copy read from data serialized to disk", ^{
        expect(schema.sections).withTimeout(5).toEventually(haveCount(@6));

        AnyPromise *schemaSave = [schema save];
        expect(@(schemaSave.resolved)).withTimeout(5).toEventually(beTrue());

        WMFExploreSectionSchema *schema2 = [WMFExploreSectionSchema schemaWithSiteURL:schema.siteURL
                                                                           savedPages:schema.savedPages
                                                                              history:schema.historyPages
                                                                            blackList:schema.blackList
                                                                      locationManager:mockLocationManager
                                                                                 file:schema.fileURL];
        // lastUpdatedAt times will be slightly different, since it will forcibly update on creation
        expect(schema2.sections).to(equal(schema.sections));
    });
});

describe(@"updates", ^{
    pending(@"should skip updates when lastUpdated is below threshold", ^{
            });
    pending(@"should update when the site has changed", ^{
            });
    pending(@"should add new location sections when location changes significantly", ^{
            });
    pending(@"should add new 'daily' sections every day", ^{
            });
    pending(@"should add recommended titles for saved & recent pages not already in the schema", ^{
            });
});

describe(@"blacklist", ^{
    pending(@"should filter recommended titles that are in blacklist", ^{
            });
    pending(@"should update when blacklist changes", ^{
            });
});

describe(@"continue reading", ^{
    pending(@"should show continue reading as first section when appropriate", ^{
            });
});

QuickSpecEnd
