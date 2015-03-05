//
//  WMFImageGalleryDetailOverlayView.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/9/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WMFImageGalleryDetailOverlayView : UIView

@property (nonatomic, copy) dispatch_block_t ownerTapCallback;

- (UILabel*) imageDescriptionLabel;
- (UIButton*)ownerButton;

/// Set all child view alphas to @c alpha. This is preferred to hiding & showing them.
- (void)setGroupAlpha:(float)alpha;

@end
