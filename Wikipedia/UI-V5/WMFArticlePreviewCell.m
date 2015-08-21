
#import "WMFArticlePreviewCell.h"

#import "Wikipedia-Swift.h"
#import "PromiseKit.h"

static CGFloat const WMFTextPadding    = 8.0;
static CGFloat const WMFImageHeight    = 160;

@interface WMFArticlePreviewCell ()

@property (strong, nonatomic) IBOutlet UIImageView* imageView;
@property (strong, nonatomic) IBOutlet UILabel* titleLabel;
@property (strong, nonatomic) IBOutlet UILabel* descriptionLabel;
@property (strong, nonatomic) IBOutlet UILabel* summaryLabel;

@end

@implementation WMFArticlePreviewCell

- (void)prepareForReuse {
    [super prepareForReuse];
    [[WMFImageController sharedInstance] cancelFetchForURL:self.imageURL];
    self.imageView.image = [UIImage imageNamed:@"logo-placeholder-nearby.png"];
    _imageURL            = nil;
    _titleLabel.text     = nil;
    _titleText           = nil;
    _descriptionText     = nil;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.imageView.image                            = [UIImage imageNamed:@"logo-placeholder-nearby.png"];
}

- (UICollectionViewLayoutAttributes*)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes*)layoutAttributes {
    
    self.titleLabel.preferredMaxLayoutWidth = layoutAttributes.size.width - WMFTextPadding - WMFTextPadding;
    self.descriptionLabel.preferredMaxLayoutWidth = layoutAttributes.size.width - WMFTextPadding - WMFTextPadding;
    self.summaryLabel.preferredMaxLayoutWidth = layoutAttributes.size.width - WMFTextPadding - WMFTextPadding;
    
    UICollectionViewLayoutAttributes* preferredAttributes = [layoutAttributes copy];
    CGFloat height                                        = MAX(200, self.summaryLabel.intrinsicContentSize.height + WMFImageHeight + WMFTextPadding + WMFTextPadding);
    preferredAttributes.size = CGSizeMake(layoutAttributes.size.width, height);
    return preferredAttributes;
}


- (void)setImageURL:(NSURL*)imageURL {
    _imageURL = imageURL;
    @weakify(self);
    [[WMFImageController sharedInstance] fetchImageWithURL:imageURL]
    .then(^id (WMFImageDownload* download) {
        @strongify(self);
        if ([self.imageURL isEqual:imageURL]) {
            self.imageView.image = download.image;
        }
        return nil;
    })
    .catch(^(NSError* error){
        //TODO: Show placeholder
    });
}

- (void)setTitleText:(NSString*)titleText {
    _titleText = titleText;
    self.titleLabel.text = titleText;
}

- (void)setDescriptionText:(NSString*)descriptionText {
    _descriptionText = descriptionText;
    self.descriptionLabel.text = descriptionText;
}

- (void)setSummaryText:(NSString *)summaryText{
    _summaryText = summaryText;
    self.summaryLabel.text = summaryText;
}

@end
