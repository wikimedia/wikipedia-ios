//  Created by Monte Hurd on 8/5/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

@protocol WMFEditSectionDelegate <NSObject>

- (void)wmf_editSection:(NSNumber*)sectionId;

- (BOOL)wmf_isArticleEditable;

@end