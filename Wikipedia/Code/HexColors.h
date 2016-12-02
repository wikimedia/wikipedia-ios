//
//  HexColor.h
//
//  Created by Marius Landwehr on 02.12.12.
//  The MIT License (MIT)
//  Copyright (c) 2013 Marius Landwehr marius.landwehr@gmail.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "TargetConditionals.h"

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
  #import <UIKit/UIKit.h>
  #define HXColor UIColor
#else
  #import <Cocoa/Cocoa.h>
  #define HXColor NSColor
#endif

@interface HXColor (HexColorAddition)

/** 
 Creates a UIColor or NSColor from a HexString like #fff, #ffff, #ff00aa or #ff00aaee.
 With complete support for short hand hex values, short hand with short alpha value, full 
 hex values and full hex values with alpha.
 
 @param hexString NSString hex string for color generation
 @return UIColor / NSColor or nil
 */
+ (nullable HXColor *)hx_colorWithHexString:(nonnull NSString *)hexString __attribute__ ((deprecated("Use '-hx_colorWithHexRGBAString' instead.")));

/**
 Creates a UIColor or NSColor from a HexString like #fff, #ffff, #ff00aa or #ff00aaee.
 With complete support for short hand hex values, short hand with short alpha value, full
 hex values and full hex values with alpha. To include alpha with the hex string append the values
 at the end of the string.
 
 @param hexString NSString hex string for color generation
 @return UIColor / NSColor or nil
 */
+ (nullable HXColor *)hx_colorWithHexRGBAString:(nonnull NSString *)hexString;

/**
 Same implementation as hx_colorWithHexString but you can hand in a normal alpha value from 0 to 1
 
 @param hexString NSString hex string for color generation
 @param alpha CGFloat from 0 to 1
 @return UIColor / NSColor or nil
 */
+ (nullable HXColor *)hx_colorWithHexString:(nonnull NSString *)hexString alpha:(CGFloat)alpha __attribute__ ((deprecated("Use '-hx_colorWithHexRGBAString :alpha' instead.")));

/**
 Same implementation as hx_colorWithHexRGBAString but you can hand in a normal alpha value from 0 to 1
 
 @param hexString NSString hex string for color generation
 @param alpha CGFloat from 0 to 1
 @return UIColor / NSColor or nil
 */
+ (nullable HXColor *)hx_colorWithHexRGBAString:(nonnull NSString *)hexString alpha:(CGFloat)alpha;

/**
 Don't like to devide by 255 to get a value between 0 to 1 for creating a color? This helps you create 
 a UIColor without the hassle, which leads to cleaner code
 
 @param red NSInteger hand in a value for red between 0 and 255
 @param green NSInteger hand in a value for green between 0 and 255
 @param blue NSInteger hand in a value for blue between 0 and 255
 @return UIColor / NSColor
 */
+ (nonnull HXColor *)hx_colorWith8BitRed:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue;

/**
 Same implementation as hx_colorWith8BitRed:green:blue but you can hand in a normal alpha value from 0 to 1
 
 @param red NSInteger hand in a value for red between 0 and 255
 @param green NSInteger hand in a value for green between 0 and 255
 @param blue NSInteger hand in a value for blue between 0 and 255
 @param alpha CGFloat from 0 to 1
 @return UIColor / NSColor
 */
+ (nonnull HXColor *)hx_colorWith8BitRed:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue alpha:(CGFloat)alpha;

@end


@interface NSString (hx_StringTansformer)

/**
 Checks for a short hexString like #fff and transform it to a long hexstring like #ffffff
 
 @return hexString NSString a normal hexString with the length of 7 characters like #ffffff or the initial string
 */
- (nonnull NSString *)hx_hexStringTransformFromThreeCharacters;

@end