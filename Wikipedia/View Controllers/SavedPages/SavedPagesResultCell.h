//  Created by Monte Hurd on 11/19/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

@class PaddedLabel;

@interface SavedPagesResultCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView* imageView;
@property (weak, nonatomic) IBOutlet PaddedLabel* savedItemLabel;

/**
 *  This "field" is a slight background color and a light border.
 *  It helps images which may have large amounts of white, or which
 *  may have transparent parts, look much nicer and more visually
 *  consistent. The thumbnails for enwiki "Monaco" and "Poland",
 *  for example, look much better atop this field.
 */
@property (nonatomic) BOOL useField;

@end
