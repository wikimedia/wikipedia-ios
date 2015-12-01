//
//  CIContext+WMFImageProcessing.h
//  Wikipedia
//
//  Created by Brian Gerstle on 7/21/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <CoreImage/CoreImage.h>

@interface CIContext (WMFImageProcessing)

/**
 * Singleton background context.
 * @see +wmf_backgroundContext
 */
+ (instancetype)wmf_sharedBackgroundContext;

/// Create a context for rendering images using CPU in the background.
+ (instancetype)wmf_backgroundContext;

@end
