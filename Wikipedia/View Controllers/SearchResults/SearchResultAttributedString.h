//  Created by Monte Hurd on 11/21/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SearchResultFetcher.h"

@interface SearchResultAttributedString : NSMutableAttributedString

+ (instancetype)initWithTitle:(NSString*)title
                      snippet:(NSString*)snippet
          wikiDataDescription:(NSString*)description
               highlightWords:(NSArray*)wordsToHighlight
         shouldHighlightWords:(BOOL)shouldHighlightWords
                   searchType:(SearchType)searchType;

@end
