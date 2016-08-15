//
//  MWKDataStore+TemporaryDataStore.h
//  Wikipedia
//
//  Created by Brian Gerstle on 3/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKDataStore.h"

NS_ASSUME_NONNULL_BEGIN

@interface MWKDataStore (Testing)

/**
 * Create a data store which persists objects in a random folder in the application's @c tmp directory.
 * @see WMFRandomTemporaryDirectoryPath()
 */
+ (instancetype)temporaryDataStore;

@end

NS_ASSUME_NONNULL_END
