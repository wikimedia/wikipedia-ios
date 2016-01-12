//
//  WMFTextualSaveButton.h
//  Wikipedia
//
//  Created by Brian Gerstle on 1/12/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  RTL-compliant control which lays out a save button (bookmark icon) and text.
 *
 *  @warning
 *  This class hard-codes images and text according to its @c selected state. Anything set in Interface Builder will
 *  be overwritten.
 *
 *  @discussion
 *  Also, AutoLayout constraints are used to ensure RTL compliance across iOS 8 & 9. Initial implementaion of a textual
 *  save button used @c UIButton "out of the box" with @c titleEdgeInsets to space the icon & text.  The problems with
 *  this approach were:
 *
 *    - iOS 8: Icon & text were still LTR when device was set to RTL language.<br/>
 *    - iOS 9: Icon & text were overlapping each other since the inset wasn't also flipped.
 *
 *  The iOS 9 issue could've been worked around easily enough by flipping the inset (and setting the
 *  @c contentHorizontalAlignment), but a custom control was needed for complete RTL compliance in iOS 8 & 9. See
 *  https://phabricator.wikimedia.org/T121681 for more information, including screenshots.
 */
@interface WMFTextualSaveButton : UIControl

/**
 *  The image view shown to the left (in LTR) of the text.
 */
@property (nonatomic, weak) IBOutlet UIImageView* saveIconImageView;

/**
 *  The text shown to the right of the image which describes the future state of the article.
 *
 *  In other words, if the article isn't saved, it says "Save for later".
 */
@property (nonatomic, weak) IBOutlet UILabel* saveTextLabel;

@end
