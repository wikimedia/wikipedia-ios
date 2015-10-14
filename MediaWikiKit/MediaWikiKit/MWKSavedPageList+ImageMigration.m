//
//  MWKSavedPageList+ImageMigration.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/14/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKSavedPageList+ImageMigration.h"
#import "MWKSavedPageList+ImageMigrationTesting.h"

@implementation MWKSavedPageList (ImageMigration)

- (void)markImageDataAsMigratedForEntryWithTitle:(MWKTitle*)title {
    [self markImageDataAsMigrated:YES forEntryWithTitle:title];
}

@end
