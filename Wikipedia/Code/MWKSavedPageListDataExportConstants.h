//
//  MWKSavedPageListDataExportConstants.h
//  Wikipedia
//
//  Created by Brian Gerstle on 10/15/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

typedef NS_ENUM(NSUInteger, MWKSavedPageListSchemaVersion) {
    /// Legacy version, pre-5.0
    MWKSavedPageListSchemaVersionUnknown = 0,
    /// Introduced in 5.0, where saved page list started being stored by most-to-least recently added.
    MWKSavedPageListSchemaVersionCurrent = 1
};

extern NSString *const MWKSavedPageExportedEntriesKey;
extern NSString *const MWKSavedPageExportedSchemaVersionKey;
