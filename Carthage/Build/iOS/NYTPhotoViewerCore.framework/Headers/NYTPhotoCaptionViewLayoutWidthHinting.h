//
//  NYTPhotoCaptionViewLayoutWidthHinting.h
//  NYTPhotoViewer
//
//  Created by Chris Dzombak on 10/30/15.
//
//

@import Foundation;
@import UIKit;

/**
 *  Allows a view to opt-in to receiving a hint of its layout width. This aids in calculating an appropriate intrinsic content size.
 */
@protocol NYTPhotoCaptionViewLayoutWidthHinting <NSObject>

/**
 *  The preferred maximum width, in points, of this caption view.
 *
 *  This property works exactly as it does on `UILabel`.
 *
 *  This property affects the size of the view when layout constraints are applied to it. During layout, if the text extends beyond the width specified by this property, the additional text is flowed to one or more new lines, thereby increasing the height of the view.
 */
@property (nonatomic) CGFloat preferredMaxLayoutWidth;

@end

@interface UILabel (NYTPhotoCaptionViewLayoutWidthHinting) <NYTPhotoCaptionViewLayoutWidthHinting>
@end
