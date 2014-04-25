//  Created by Monte Hurd on 4/24/14.

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, EditSummaryHandleState) {
    EDIT_SUMMARY_HANDLE_BOTTOM = 0,
    EDIT_SUMMARY_HANDLE_TOP = 1
};

@interface EditSummaryHandleView : UIView

@property (nonatomic) EditSummaryHandleState state;

@end
