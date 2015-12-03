//
//  WMFModalPOTDGalleryViewController.h
//  Wikipedia
//
//  Created by Brian Gerstle on 12/1/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFModalImageGalleryViewController.h"

/**
 *  Dispays a modal gallery of images & metadata for Wikimedia Commons pictures of the day.
 */
@interface WMFModalPOTDGalleryViewController : WMFModalImageGalleryViewController

/**
 *  Initalize a gallery with pre-fetched info.
 *
 *  @note This class is meant to be shown after today's (or another day's) POTD has already been retrieved for the Home
 *  view.
 *
 *  @param info Partial info for today's POTD (lower-res placeholder image & sparse metadata).
 *
 *  @return A new gallery for displaying pictures of the day.
 */
- (instancetype)initWithTodaysInfo:(MWKImageInfo*)info NS_DESIGNATED_INITIALIZER;

///
/// @name Unsupported Initializers
///

- (instancetype)init NS_UNAVAILABLE;

@end
