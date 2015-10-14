//
//  MWKSavedPageList+ImageMigration.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/14/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKSavedPageList+ImageMigration.h"
#import "MWKList+Subclass.h"
#import "MWKSavedPageEntry+ImageMigration.h"

@implementation MWKSavedPageList (ImageMigration)

- (void)markImageDataAsMigratedForEntryWithTitle:(MWKTitle*)title {
    return [self updateEntryWithListIndex:title update:^BOOL (MWKSavedPageEntry* entry) {
        if (entry.didMigrateImageData) {
            return NO;
        }
        entry.didMigrateImageData = YES;
        return YES;
    }];
}

@end
