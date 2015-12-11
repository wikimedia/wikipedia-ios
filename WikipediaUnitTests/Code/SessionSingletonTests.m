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

QuickSpecBegin(SessionSingletonTests)

__block SessionSingleton* testSession;

configureTempDataStoreForEach(tempDataStore, ^{
    NSString *appDomain = [[NSBundle bundleForClass:[SessionSingleton class]] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    testSession = [[SessionSingleton alloc] initWithDataStore:tempDataStore];
});

describe(@"searchSite", ^{
    it(@"should default to the current device language", ^{
        expect(testSession.searchSite.language)
        .to(equal([[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]));
    });

    it(@"should be persistent", ^{
        expectAction(^{
            [testSession setSearchLanguage:@"fr"];
        }).to(postNotification(WMFSearchLanguageDidChangeNotification, nil));
        MWKSite* expectedSite = testSession.searchSite;
        SessionSingleton* newSession = [[SessionSingleton alloc] initWithDataStore:[MWKDataStore temporaryDataStore]];
        expect(newSession.searchSite).to(equal(expectedSite));
        [newSession.dataStore removeFolderAtBasePath];
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

QuickSpecEnd
