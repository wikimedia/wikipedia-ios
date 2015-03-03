//  Created by Monte Hurd on 3/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

typedef NS_ENUM (NSInteger, RowType) {
    ROW_TYPE_UNKNOWN,
    ROW_TYPE_HEADING,
    ROW_TYPE_SELECTION
};

typedef NS_ENUM (NSInteger, RowPosition) {
    ROW_POSITION_UNKNOWN,
    ROW_POSITION_TOP
};

@class PaddedLabel;

@interface SecondaryMenuRowView : UIView

@property (strong, nonatomic) IBOutlet PaddedLabel* textLabel;
@property (strong, nonatomic) IBOutlet UILabel* iconLabel;
@property (strong, nonatomic) IBOutlet UISwitch* optionSwitch;

@property (nonatomic) RowType rowType;
@property (nonatomic) RowPosition rowPosition;

@end
