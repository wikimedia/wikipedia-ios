//  Created by Monte Hurd on 5/31/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MWKSection+DisplayHtml.h"
#import "SessionSingleton.h"
#import "Defines.h"

static NSString* const MWKSectionDisambigAndPageIssuesPlaceholderDiv = @"<div class='issues_container' id='issues_container'><a href='#issues_container_close_button' id='issues_container_close_button' style='float:right;'>X</a></div>";

@implementation MWKSection (DisplayHtml)

- (NSString*)displayHTML:(NSString*)html {
    BOOL isMainPage = [SessionSingleton sharedInstance].currentArticle.isMain;

    return
        [NSString stringWithFormat:@"<div id='section_heading_and_content_block_%ld'>%@<div id='content_block_%ld' class='content_block'>%@</div></div>",
         (long)self.sectionId,
         (isMainPage ? @"" : [self getHeaderTag]),
         (long)self.sectionId,
         html
        ];
}

- (NSString*)getHeaderTag {
    NSUInteger headingSize = [self getHeadingTagSize];
    return
        [NSString stringWithFormat:@"<h%ld class='section_heading' id='%@' sectionId='%d'>%@</h%ld>%@",
         headingSize,
         self.anchor,
         self.sectionId,
         [self isLeadSection] ? self.title.text : self.line,
         headingSize,
         [self isLeadSection] ? MWKSectionDisambigAndPageIssuesPlaceholderDiv : @""
        ];
}

- (NSInteger)getHeadingTagSize {
    return MIN(MAX(self.level.integerValue, 1), 6);
}

@end
