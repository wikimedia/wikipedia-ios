//
//  MWKSavedPageEntry+ImageMigration.h
//  Wikipedia
//
//  Created by Brian Gerstle on 10/14/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKSavedPageEntry.h"

@interface MWKSavedPageEntry ()

/// Mutable redeclaration of migration flag. Set using @c MWKSavedPageList
/// @see -[MWKSavedPageList markImageDataAsMigratedForEntryWithTitle:]
@property (nonatomic, readwrite) BOOL didMigrateImageData;

@end
