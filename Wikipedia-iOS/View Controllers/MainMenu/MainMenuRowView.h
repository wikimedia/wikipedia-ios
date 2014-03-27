//  Created by Monte Hurd on 3/27/14.

#import <UIKit/UIKit.h>

@interface MainMenuRowView : UIView

@property (strong, nonatomic) IBOutlet UILabel *textLabel;
@property (strong, nonatomic) IBOutlet UIImageView *thumbnailImageView;

@property (strong, nonatomic) NSString *imageName;
@property (nonatomic) BOOL highlighted;

@end
