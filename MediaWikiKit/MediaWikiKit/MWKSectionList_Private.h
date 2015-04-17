//
//  MWKSectionList_Private.h
//  Wikipedia
//
//  Created by Brian Gerstle on 4/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKSectionList.h"

@interface MWKSectionList ()

/// Import list of sections from disk using the receiver's `article` and `dataStore`.
- (void)importSectionsFromDisk;

/// Read `sectionId` from the receiver's `article.dataStore` and insert it into the receiver's section list..
- (void)readAndInsertSection:(int)sectionId;

@end
