//  Created by Monte Hurd on 1/23/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

/// Table cell designed for displaying a language autonym & a page title in that language.
@interface LanguageCell : UITableViewCell

@property (strong, nonatomic) NSString* localizedLanguageName;
@property (strong, nonatomic) NSString* articleTitle;
@property (strong, nonatomic) NSString* languageName;
@property (strong, nonatomic) NSString* languageCode;
@property (strong, nonatomic) NSString* languageID;

@property (nonatomic) BOOL isPreferred;

@end
