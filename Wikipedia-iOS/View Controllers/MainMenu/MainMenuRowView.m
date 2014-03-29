//  Created by Monte Hurd on 3/27/14.

#import "MainMenuRowView.h"
#import "UIImage+ColorMask.h"
#import "QueuesSingleton.h"

@interface MainMenuRowView()

@property (strong, nonatomic) UIColor *imageColor;

@end

@implementation MainMenuRowView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.highlighted = YES;
        self.imageColor = [UIColor clearColor];
    }
    return self;
}

-(void)setImageName:(NSString *)imageName
{
    UIColor *rowColor = (self.highlighted) ?
        [UIColor blackColor]
        :
        [UIColor lightGrayColor]
        ;
    
    if (_imageName == imageName){
        if (CGColorEqualToColor(rowColor.CGColor, self.imageColor.CGColor))return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        UIImage *image = [[UIImage imageNamed:imageName] getImageOfColor:rowColor.CGColor];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.thumbnailImageView.image = image;
        });
    });

    self.imageColor = rowColor;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
