//
//  MWKSavedPageList+ImageMigration.h
//  Wikipedia
//
//  Created by Brian Gerstle on 10/14/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKSavedPageList.h"
@class MWKTitle;

@interface MWKSavedPageList (ImageMigration)

- (void)markImageDataAsMigratedForEntryWithTitle:(MWKTitle*)title;

@end
