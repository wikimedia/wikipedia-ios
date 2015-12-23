//
//  SessionSingletonTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/10/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

@import Quick;
@import Nimble;

#import "MWKDataStore+TempDataStoreForEach.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "PostNotificationMatcherShorthand.h"

#import "SessionSingleton.h"
#import "QueuesSingleton+AllManagers.h"
#import "NSUserDefaults+WMFReset.h"
#import "ReadingActionFunnel.h"

QuickSpecBegin(SessionSingletonTests)

__block SessionSingleton * testSession;

configureTempDataStoreForEach(tempDataStore, ^{
    [[NSUserDefaults standardUserDefaults] wmf_resetToDefaultValues];

    testSession = [[SessionSingleton alloc] initWithDataStore:tempDataStore];
    WMF_TECH_DEBT_TODO(refactor sendUsageReports to use a notification to make it easier to test)
    /*
       ^ this only works now because the queues singleton grabs its values directly from the shared instance
       AND the shared instance doesn't "cache" the sendUsageReports value in memory, so setting it from a different
       "SessionSingleton" is fine
     */

    [[QueuesSingleton sharedInstance] reset];
});

afterSuite(^{
    [[NSUserDefaults standardUserDefaults] wmf_resetToDefaultValues];
    [[QueuesSingleton sharedInstance] reset];
});

describe(@"searchLanguage", ^{
    it(@"should default to the current device language", ^{
        expect(testSession.searchSite.language)
        .to(equal([[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]));
    });

    itBehavesLike(@"a persistent property", ^{
        return @{ @"session": testSession,
                  @"key": WMF_SAFE_KEYPATH(testSession, searchLanguage),
                  // set to a different value by appending to current
                  @"value": [testSession.searchLanguage stringByAppendingString:@"a"] };
    });

    it(@"should ignore nil values", ^{
        NSString* langBeforeNil = [testSession searchLanguage];
        [testSession setSearchLanguage:nil];
        expect(testSession.searchLanguage).to(equal(langBeforeNil));
    });

    it(@"should be idempotent", ^{
        expectAction(^{
            [testSession setSearchLanguage:testSession.searchSite.language];
        }).notTo(postNotification(WMFSearchLanguageDidChangeNotification, nil));
    });
});

describe(@"searchSite", ^{
    it(@"should depend on search language", ^{
        expect([MWKSite siteWithLanguage:testSession.searchLanguage]).to(equal(testSession.searchSite));
        [testSession setSearchLanguage:[testSession.searchLanguage stringByAppendingString:@"a"]];
        expect([MWKSite siteWithLanguage:testSession.searchLanguage]).to(equal(testSession.searchSite));
    });
});

describe(@"send usage reports", ^{
    itBehavesLike(@"a persistent property", ^{
        return @{ @"session": testSession,
                  @"key": WMF_SAFE_KEYPATH(testSession, shouldSendUsageReports),
                  // set to different value by
                  @"value": @(!testSession.shouldSendUsageReports) };
    });

    void (^ expectAllManagersToHaveExpectedAnalyticsHeaderForCurrentUsageReportsValue)(NSArray* managers) =
        ^(NSArray* managers) {
        NSString* expectedHeaderValue = [[ReadingActionFunnel new] appInstallID];
        NSArray* headerValues =
            [managers valueForKeyPath:@"requestSerializer.HTTPRequestHeaders.X-WMF-UUID"];
        id<NMBMatcher> allEqualExpectedValueOrNull =
            allPass(equal(testSession.shouldSendUsageReports ? expectedHeaderValue : [NSNull null]));

        expect(headerValues).to(allEqualExpectedValueOrNull);
    };

    WMF_TECH_DEBT_TODO(shared example for all non - global fetchers to ensure they honor current & future values of this prop)
    it(@"should reset the global request managers", ^{
        NSArray* oldManagers = [[QueuesSingleton sharedInstance] allManagers];
        expect(oldManagers).toNot(beEmpty());
        expect(oldManagers).to(allPass(beAKindOf([AFHTTPRequestOperationManager class])));

        expectAllManagersToHaveExpectedAnalyticsHeaderForCurrentUsageReportsValue(oldManagers);

        // change send usage reports
        [testSession setShouldSendUsageReports:!testSession.shouldSendUsageReports];

        NSArray* newManagers = [[QueuesSingleton sharedInstance] allManagers];
        expect(newManagers).to(haveCount(@(oldManagers.count)));
        expect(newManagers).toNot(equal(oldManagers));
        expect(newManagers).to(allPass(beAKindOf([AFHTTPRequestOperationManager class])));

        expectAllManagersToHaveExpectedAnalyticsHeaderForCurrentUsageReportsValue(newManagers);
    });

    it(@"should be idempotent", ^{
        NSArray* oldManagers = [[QueuesSingleton sharedInstance] allManagers];
        expect(oldManagers).toNot(beEmpty());
        expect(oldManagers).to(allPass(beAKindOf([AFHTTPRequestOperationManager class])));
        expectAllManagersToHaveExpectedAnalyticsHeaderForCurrentUsageReportsValue(oldManagers);

        [testSession setShouldSendUsageReports:testSession.shouldSendUsageReports];

        NSArray* managersAfterRedundantSet = [[QueuesSingleton sharedInstance] allManagers];
        expect(managersAfterRedundantSet).to(equal(oldManagers));
        expectAllManagersToHaveExpectedAnalyticsHeaderForCurrentUsageReportsValue(managersAfterRedundantSet);
    });
});

QuickSpecEnd

QuickConfigurationBegin(SessionSingletonSharedExamples)

+ (void)configure : (Configuration*)configuration {
    sharedExamples(@"a persistent property", ^(QCKDSLSharedExampleContext getContext) {
        __block SessionSingleton* session;
        __block id value;
        __block NSString* key;

        beforeEach(^{
            [[NSUserDefaults standardUserDefaults] wmf_resetToDefaultValues];
            NSDictionary* context = getContext();
            session = context[@"session"];
            value = context[@"value"];
            key = context[@"key"];
        });

        it(@"a persistent property", ^{
            [session setValue:value forKey:key];
            SessionSingleton* newSession = [[SessionSingleton alloc] initWithDataStore:[MWKDataStore temporaryDataStore]];
            expect([newSession valueForKey:key]).to(equal(value));
            [newSession.dataStore removeFolderAtBasePath];
        });
    });
}

QuickConfigurationEnd
