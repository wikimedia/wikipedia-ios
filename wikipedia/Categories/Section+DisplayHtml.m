//  Created by Monte Hurd on 5/31/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "Section+DisplayHtml.h"
#import "SessionSingleton.h"
#import "ArticleCoreDataObjects.h"

@implementation Section (DisplayHtml)

-(NSString *)displayHTML
{
    BOOL isMainPage = [[SessionSingleton sharedInstance] isCurrentArticleMain];

    return
        [NSString stringWithFormat:@"\
<div id=\"section_heading_and_content_block_%ld\">\
%@\
<div id=\"content_block_%ld\">\
%@\
</div>\
</div>\
         ",
             (long)self.sectionId.integerValue,
             (isMainPage ? @"" : [self getHeaderTag:isMainPage]),
             (long)self.sectionId.integerValue,
             self.html
         ];
}

-(NSString *)getHeaderTag:(BOOL)isMainPage
{
    // Don't show the edit pencil on "main" articles.
    NSString *pencilAnchor = isMainPage ? @"" : [self getEditPencilAnchor];
    
    // Use the article's title for lead section header text.
    NSString *title = [self getHeaderTitle];
    
    NSInteger headingTagSize = [self getHeadingTagSize];

    return
        [NSString stringWithFormat:@"\
<h%ld class=\"section_heading\" data-id=\"%ld\" id=\"%@\">\
%@\
%@\
</h%ld>\
            ",
            (long)headingTagSize,
            (long)self.sectionId.integerValue,
            self.anchor,
            title,
            pencilAnchor,
            (long)headingTagSize
        ];
}

-(NSString*)getHeaderTitle{
    if ([self.sectionId isEqualToNumber:@(0)]) {
        if (self.article.displayTitle != nil && self.article.displayTitle.length > 0) {
            return self.article.displayTitle;
        }else{
            return self.article.title;
        }
    }else{
        return self.title;
    }
}

-(NSInteger)getHeadingTagSize
{
    // Determines <H#> tag size based on section level.
    
    NSInteger size = self.level.integerValue;

    /*
    Note: Adjust H tag font sizes in CSS file instead of doing this here:
    // Make everything one size bigger.
    sectionLevel -= 1;
    */

    // Don't go smaller than 1 - ie "<H1>"
    size = MAX(size, 1);

    // Don't go larger than 6 - ie "<H6>"
    size = MIN(size, 6);

    //NSLog(@"H tag size = <H%d>", size);
    return size;
}

-(NSString *)getEditPencilAnchor
{
    return [NSString stringWithFormat:
        @"<a class=\"edit_section_button\" data-action=\"edit_section\" data-id=\"%ld\"></a>",
        (long)self.sectionId.integerValue];
}

@end
