//  Created by Monte Hurd on 12/28/13.

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface TOCSectionCellView : UIView

@property (strong, nonatomic) NSManagedObjectID *sectionId;
@property (strong, nonatomic) NSArray *sectionImageIds;
@property (nonatomic) BOOL isHighlighted;
@property (nonatomic) BOOL isSelected;

@end
