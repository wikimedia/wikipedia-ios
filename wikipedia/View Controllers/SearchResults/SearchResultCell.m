//  Created by Monte Hurd on 11/19/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SearchResultCell.h"
#import "WikipediaAppUtils.h"
#import "NSObject+ConstraintsScale.h"
#import "Defines.h"
#import "NSString+Extras.h"

#define PADDING_ABOVE_DESCRIPTION 2.0f

@interface SearchResultCell()

@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (strong, nonatomic) NSDictionary *attributesTitle;
@property (strong, nonatomic) NSDictionary *attributesDescription;
@property (strong, nonatomic) NSDictionary *attributesHighlight;

@end

@implementation SearchResultCell

@synthesize imageView;
@synthesize textLabel;
@synthesize bottomBorder;
@synthesize useField;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.useField = NO;
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        [self setupStringAttributes];
    }
    return self;
}

-(void)setupStringAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.paragraphSpacingBefore = PADDING_ABOVE_DESCRIPTION;
    
    self.attributesDescription =
    @{
      NSFontAttributeName : SEARCH_RESULT_DESCRIPTION_FONT,
      NSForegroundColorAttributeName : SEARCH_RESULT_DESCRIPTION_FONT_COLOR,
      NSParagraphStyleAttributeName : paragraphStyle
      };
    
    self.attributesTitle =
    @{
      NSFontAttributeName : SEARCH_RESULT_FONT,
      NSForegroundColorAttributeName : SEARCH_RESULT_FONT_COLOR
      };
    
    self.attributesHighlight =
    @{
      NSFontAttributeName : SEARCH_RESULT_FONT_HIGHLIGHTED,
      NSForegroundColorAttributeName : SEARCH_RESULT_FONT_HIGHLIGHTED_COLOR
      };
}

-(void)setUseField:(BOOL)use
{
    if (use) {
        // This "field" - ie a slight background color, slightly rounded corners,
        // and a light border - helps images which may have large amounts of white,
        // or which may have transparent parts, look much nicer and more visually
        // consistent. The thumbnails for search terms "Monaco" and "Poland", for
        // example, look much better atop this field.
        UIColor *borderColor = [UIColor colorWithWhite:0.0 alpha:0.1];
        
        self.imageView.layer.borderColor = borderColor.CGColor;
        self.imageView.layer.borderWidth = 1.0f / [UIScreen mainScreen].scale;
        
        self.imageView.layer.cornerRadius = 0.0f;
        self.imageView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.025];
        
        bottomBorder.backgroundColor = borderColor;
    }else{
        // The field can be turned off, when displaying the search term placeholder
        // image, for example.
        self.imageView.layer.borderWidth = 0.0f;
        self.imageView.backgroundColor = [UIColor clearColor];
    }
    useField = use;
}

-(void)awakeFromNib
{
    [super awakeFromNib];

    // Use finer line on retina displays
    self.bottomBorderHeight.constant = 1.0f / [UIScreen mainScreen].scale;

    // Initial changes to ui elements go here.
    // See: http://stackoverflow.com/a/15591474 for details.

    //self.textLabel.layer.borderWidth = 1;
    //self.textLabel.layer.borderColor = [UIColor redColor].CGColor;
    //self.backgroundColor = [UIColor greenColor];

    self.textLabel.textAlignment = [WikipediaAppUtils rtlSafeAlignment];
    
    [self adjustConstraintsScaleForViews:@[self.textLabel, self.imageView]];
}

-(void)prepareForReuse
{
    //NSLog(@"imageView frame = %@", NSStringFromCGRect(self.imageView.frame));
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (selected) self.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];

    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

-(void)setTitle: (NSString *)title
    description: (NSString *)description
 highlightWords: (NSArray *)wordsToHighlight
{
    self.textLabel.attributedText = [self getAttributedTitle: title
                                         wikiDataDescription: description
                                              highlightWords: wordsToHighlight];
}

#pragma mark Search term highlighting

-(NSAttributedString *)getAttributedTitle: (NSString *)title
                      wikiDataDescription: (NSString *)description
                           highlightWords: (NSArray *)wordsToHighlight
{
    // Returns attributed string of title with the current search term highlighted.
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:title];

    // Set base color and font of the entire result title
    [str setAttributes: self.attributesTitle
                 range: NSMakeRange(0, str.length)];

    for (NSString *word in wordsToHighlight.copy) {
        // Search term highlighting
        NSRange rangeOfThisWordInTitle =
        [title rangeOfString: word
                     options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch];
        [str setAttributes: self.attributesHighlight
                     range: rangeOfThisWordInTitle];
    }
    
    // Capitalize first character of WikiData description.
    description = [description capitalizeFirstLetter];
    
    // Style and append the wikidata description.
    if ((description.length > 0)) {
        NSMutableAttributedString *attributedDesc = [[NSMutableAttributedString alloc] initWithString:description];

        [attributedDesc setAttributes: self.attributesDescription
                                range: NSMakeRange(0, attributedDesc.length)];
        
        NSAttributedString *newline = [[NSMutableAttributedString alloc] initWithString:@"\n"];
        [str appendAttributedString:newline];
        [str appendAttributedString:attributedDesc];
    }

    return str;
}

@end
