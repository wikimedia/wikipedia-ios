//
// VTAcknowledgementsParser.m
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

#import "VTAcknowledgementsParser.h"
#import "VTAcknowledgement.h"


@interface VTAcknowledgementsParser ()

@property (nonatomic, copy, readwrite, nullable) NSString *header;
@property (nonatomic, copy, readwrite, nullable) NSString *footer;
@property (nonatomic, copy, readwrite, nullable) NSArray <VTAcknowledgement *> *acknowledgements;

- (instancetype)init NS_UNAVAILABLE;

@end


@implementation VTAcknowledgementsParser

- (instancetype)init
{
    @throw nil;
}

- (nonnull instancetype)initWithAcknowledgementsPlistPath:(nonnull NSString *)acknowledgementsPlistPath
{
    self = [super init];

    if (self) {
        NSDictionary *root = [NSDictionary dictionaryWithContentsOfFile:acknowledgementsPlistPath];
        NSArray *preferenceSpecifiers = root[@"PreferenceSpecifiers"];
        if (preferenceSpecifiers.count >= 2) {
            NSString *headerText = preferenceSpecifiers.firstObject[@"FooterText"];
            NSString *footerText = preferenceSpecifiers.lastObject[@"FooterText"];

            self.header = headerText;
            self.footer = footerText;

            // Remove the header and footer
            NSRange range = NSMakeRange(1, preferenceSpecifiers.count - 2);
            preferenceSpecifiers = [preferenceSpecifiers subarrayWithRange:range];
        }

        NSMutableArray <VTAcknowledgement *> *acknowledgements = [NSMutableArray array];
        for (NSDictionary *preferenceSpecifier in preferenceSpecifiers) {
            VTAcknowledgement *acknowledgement = [[VTAcknowledgement alloc]
                                                  initWithTitle:preferenceSpecifier[@"Title"]
                                                  text:preferenceSpecifier[@"FooterText"]];
            [acknowledgements addObject:acknowledgement];
        }

        if (preferenceSpecifiers) {
            self.acknowledgements = acknowledgements;
        }
    }

    return self;
}

@end
