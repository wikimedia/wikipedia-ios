//
//  WMFImageGalleryDetailOverlayView.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/9/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MWKLicense.h"

@interface WMFImageGalleryDetailOverlayView : UIView
@property (nonatomic, copy) NSString* imageDescription;
@property (nonatomic, copy) dispatch_block_t ownerTapCallback;

// use above setters instead of setting title/text attributes directly
@property (nonatomic, weak, readonly) UILabel* imageDescriptionLabel;
@property (nonatomic, weak, readonly) UIButton* ownerButton;

- (void)setLicense:(MWKLicense*)license owner:(NSString*)owner;

/// Set all child view alphas to @c alpha. This is preferred to hiding & showing them.
- (void)setGroupAlpha:(float)alpha;

@end
