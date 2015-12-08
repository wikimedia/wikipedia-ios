//  Created by Monte Hurd on 1/23/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

/// Table cell designed for displaying a language autonym & a page title in that language.
@interface LanguageCell : UITableViewCell

/// Large, left-aligned label.
@property (weak, nonatomic) IBOutlet UILabel* languageLabel;

/// Smaller, left-aligned label beneath @c languageLabel.
@property (weak, nonatomic) IBOutlet UILabel* titleLabel;

@property (weak, nonatomic) IBOutlet UILabel* localizedLanguageLabel;
@property (weak, nonatomic) IBOutlet UILabel* languageCodeLabel;

@end
