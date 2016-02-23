//
// VTAcknowledgementViewController.m
//
// Copyright (c) 2013-2015 Vincent Tourraine (http://www.vtourraine.net)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "VTAcknowledgementViewController.h"

@interface VTAcknowledgementViewController ()

@property (nonatomic, copy) NSString *text;

@end


@implementation VTAcknowledgementViewController

- (instancetype)initWithTitle:(NSString *)title text:(NSString *)text
{
    self = [super init];
    if (self) {
        self.title = title;
        self.text  = text;
    }

    return self;
}

- (void)loadView
{
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectZero];
    if ([UIFont respondsToSelector:@selector(preferredFontForTextStyle:)]) {
        textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    }
    else {
        textView.font = [UIFont systemFontOfSize:17];
    }
    textView.alwaysBounceVertical = YES;
    textView.text                 = self.text;
    textView.editable             = NO;
    textView.dataDetectorTypes    = UIDataDetectorTypeLink;
    if ([textView respondsToSelector:@selector(setTextContainerInset:)]) {
        textView.textContainerInset = UIEdgeInsetsMake(12, 10, 12, 10);
    }
    textView.contentOffset = CGPointZero;

    self.view = textView;

    self.textView = textView;
}

@end
