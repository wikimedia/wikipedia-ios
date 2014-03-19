//  Created by Monte Hurd on 1/15/14.

#import <UIKit/UIKit.h>

typedef enum {
    TOP_ACTION_SHEET_LAYOUT_VERTICAL = 0,
    TOP_ACTION_SHEET_LAYOUT_HORIZONTAL = 1
} TopActionSheetLayoutOrientation;

@interface UINavigationController (TopActionSheet)

-(void)topActionSheetShowWithViews:(NSArray *)views orientation:(TopActionSheetLayoutOrientation)orientation;

-(void)topActionSheetHide;

-(void)topActionSheetChangeOrientation:(TopActionSheetLayoutOrientation)orientation;

@end
