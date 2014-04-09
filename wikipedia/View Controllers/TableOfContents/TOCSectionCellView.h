//  Created by Monte Hurd on 12/28/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface TOCSectionCellView : UIView

@property (strong, nonatomic) NSMutableArray *sectionImageViews;
@property (strong, nonatomic) NSManagedObjectID *sectionId;
@property (strong, nonatomic) NSArray *sectionImageIds;
@property (nonatomic) BOOL isHighlighted;
@property (nonatomic) BOOL isSelected;

-(void)resetSectionImageViewsBorderStyle;

-(NSArray *)imagesIntersectingYOffset:(CGFloat)yOffset inView:(UIView *)view;

@end
