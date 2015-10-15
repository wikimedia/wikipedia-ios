//
//  MWKSavedPageList+ImageMigrationTesting.h
//  Wikipedia
//
//  Created by Brian Gerstle on 10/14/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKSavedPageList.h"

@interface MWKSavedPageList (ImageMigrationInternal)

- (void)markImageDataAsMigrated:(BOOL)didMigrate forEntryWithTitle:(MWKTitle*)title;

@end
