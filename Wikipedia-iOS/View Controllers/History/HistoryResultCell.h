//  Created by Monte Hurd on 11/19/13.

@interface HistoryResultCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *methodImageView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (nonatomic) BOOL useField;

@end
