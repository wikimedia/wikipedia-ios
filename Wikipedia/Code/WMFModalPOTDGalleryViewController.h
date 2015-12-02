//
//  WMFModalPOTDGalleryViewController.h
//  Wikipedia
//
//  Created by Brian Gerstle on 12/1/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFModalImageGalleryViewController.h"

@interface WMFModalPOTDGalleryViewController : WMFModalImageGalleryViewController

- (instancetype)initWithTodaysInfo:(MWKImageInfo*)info;

- (instancetype)init NS_UNAVAILABLE;

@end
