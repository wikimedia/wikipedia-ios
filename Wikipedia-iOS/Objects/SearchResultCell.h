//  Created by Monte Hurd on 11/19/13.

@interface SearchResultCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) IBOutlet UIView *bottomBorder;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomBorderHeight;
@property (nonatomic) BOOL useField;

@end
