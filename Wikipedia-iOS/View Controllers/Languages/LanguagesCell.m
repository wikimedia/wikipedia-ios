//  Created by Monte Hurd on 1/23/14.

#import "LanguagesCell.h"

#define BACKGROUND_COLOR [UIColor colorWithWhite:0.97f alpha:1.0f]

@implementation LanguagesCell

@synthesize textLabel;
@synthesize canonicalLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];

    // Initial changes to ui elements go here.
    // See: http://stackoverflow.com/a/15591474 for details.

    //self.textLabel.layer.borderWidth = 1;
    //self.textLabel.layer.borderColor = [UIColor redColor].CGColor;
    self.backgroundColor = BACKGROUND_COLOR;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
