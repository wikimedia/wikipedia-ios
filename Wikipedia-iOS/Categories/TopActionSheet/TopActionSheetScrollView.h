//  Created by Monte Hurd on 3/17/14.

#import <UIKit/UIKit.h>
#import "UINavigationController+TopActionSheet.h"

@interface TopActionSheetScrollView : UIScrollView

-(void)setTopActionSheetSubviews:(NSArray *)topActionSheetSubviews;

@property (nonatomic)TopActionSheetLayoutOrientation orientation;

@end
