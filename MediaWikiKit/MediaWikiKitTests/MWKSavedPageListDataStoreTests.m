//
//  MWKSavedPageListDataStoreTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/14/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKDataStoreListTests.h"
#import "MWKSavedPageEntry+ImageMigration.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKSavedPageListDataStoreTests : MWKDataStoreListTests

@end

@implementation MWKSavedPageListDataStoreTests

+ (Class)listClass {
    return [MWKSavedPageList class];
}

+ (id)uniqueListEntry {
    static BOOL migrated = NO;
    migrated ^= YES;
    MWKSavedPageEntry* entry = [[MWKSavedPageEntry alloc] initWithTitle:[MWKTitle random]];
    entry.didMigrateImageData = migrated;
    return entry;
}

- (void)verifyList:(MWKList*)list isEqualToList:(MWKList*)otherList {
    [super verifyList:list isEqualToList:otherList];
    NSString* didMigrateImageData = WMF_SAFE_KEYPATH([MWKSavedPageEntry new], didMigrateImageData);
    assertThat([list.entries valueForKey:didMigrateImageData], is([otherList.entries valueForKey:didMigrateImageData]));
}

@end
