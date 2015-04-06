//  Created by Monte Hurd on 12/28/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "PaddedLabel.h"

@interface TOCSectionCellView : PaddedLabel

@property (nonatomic) BOOL isHighlighted;
@property (nonatomic) BOOL isSelected;

- (id)initWithLevel:(NSInteger)level isLead:(BOOL)isLead isRTL:(BOOL)isRTL;

@end
