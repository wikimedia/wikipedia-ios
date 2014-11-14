//  Created by Monte Hurd on 11/19/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

@interface SearchResultCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *bottomBorder;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomBorderHeight;
@property (nonatomic) BOOL useField;

-(void)setTitle: (NSString *)title
    description: (NSString *)description
 highlightWords: (NSArray *)wordsToHighlight;

@end
