//
//  WMFRandomFileUtilities.h
//  Wikipedia
//
//  Created by Brian Gerstle on 3/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

/// @return The path to a folder or extension-less file with a uniquely random name in the @c tmp directory.
extern NSString *WMFRandomTemporaryPath();

/// @return The path to a file in the @c tmp directory with a random name and a path extension of @c extension.
extern NSString *WMFRandomTemporaryFileOfType(NSString *extension);