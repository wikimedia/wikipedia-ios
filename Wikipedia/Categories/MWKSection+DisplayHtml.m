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
        [NSString stringWithFormat:@"<div id='section_heading_and_content_block_%ld'>%@<div id='content_block_%ld' class='content_block'>%@%@</div></div>",
         (long)self.sectionId,
         (isMainPage ? @"" : [self getHeaderTag]),
         (long)self.sectionId,
         ((self.sectionId == 0) && !isMainPage) ? [self getEditPencilAnchor] : @"",
         html
        ];
}

- (NSString*)getHeaderTag {
    NSString* pencilAnchor = [self getEditPencilAnchor];

    if (self.sectionId == 0) {
        // Lead section.
        return MWKSectionDisambigAndPageIssuesPlaceholderDiv;
    } else {
        // Non-lead section.
        NSInteger headingTagSize = [self getHeadingTagSize];

        return
            [NSString stringWithFormat:@"<h%ld class='section_heading' data-id='%ld' id='%@'>%@%@</h%ld>",
             (long)headingTagSize,
             (long)self.sectionId,
             self.anchor,
             self.line,
             pencilAnchor,
             (long)headingTagSize
            ];
    }
}

- (NSInteger)getHeadingTagSize {
    // Varies <H#> tag size based on section level.

    return 1;

    NSInteger size = self.level.integerValue;

    // Don't go smaller than 1 - ie "<H1>"
    size = MAX(size, 1);

    // Don't go larger than 6 - ie "<H6>"
    size = MIN(size, 6);

    return size;
}

- (NSString*)getEditPencilAnchor {
    return
        [NSString stringWithFormat:@"<a class='edit_section_button' data-action='edit_section' data-id='%ld' id='edit_section_button_%ld'></a>",
         (long)self.sectionId,
         (long)self.sectionId
        ];
}

@end
