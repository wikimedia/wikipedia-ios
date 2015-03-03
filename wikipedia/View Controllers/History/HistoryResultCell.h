//  Created by Monte Hurd on 11/19/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

@interface HistoryResultCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel* methodLabel;
@property (weak, nonatomic) IBOutlet UIImageView* imageView;
@property (weak, nonatomic) IBOutlet UILabel* textLabel;
@property (nonatomic) BOOL useField;

@end
