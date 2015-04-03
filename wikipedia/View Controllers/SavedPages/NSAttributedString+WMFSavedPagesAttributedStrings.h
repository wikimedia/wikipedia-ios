//  Created by Monte Hurd on 4/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

@interface NSAttributedString (WMFSavedPagesAttributedStrings)

+ (NSAttributedString*)wmf_attributedStringWithTitle:(NSString*)title
                                         description:(NSString*)description
                                            language:(NSString*)language;

@end
