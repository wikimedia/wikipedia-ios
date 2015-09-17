# SelfSizingWaterfallCollectionViewLayout

SelfSizingWaterfallCollectionViewLayout is a UICollectionViewLayout subclass that organises items of dynamic height into a grid of variable columns. Items flow from one row or column to the next, with each item being placed beneath the shortest column in the section (as if you're winning at Tetris upside-down). It supports multiple sections, headers and footers. It's designed to be used alongside AutoLayout and self-sizing cell technologies introduced in iOS8.

![demo-vid](resources/demo.mp4.gif)

## Integration

`pod 'SelfSizingWaterfallCollectionViewLayout'`

## API

The API has been designed to replicate `UICollectionViewFlowLayout` so it should be familiar. There are a few additions to support variable columns and waterfall design.

### Properties

**Section insets**

`@property (nonatomic) UIEdgeInsets sectionInset;`

The margins used to lay out content in a section. Default: UIEdgeInsetsZero.

**Number of columns**

`@property (nonatomic) NSUInteger numberOfColumns;`

The number of columns in the layout. Default: 2. Use the `SelfSizingWaterfallCollectionViewLayoutDelegate` delegate method to specify a different variable number of columns between sections.

**Inter-item spacing**

`@property (nonatomic) CGFloat minimumInteritemSpacing;`

The minimum spacing to use between items in the same row. Default: 8.0f;

**Line spacing**

`@property (nonatomic) CGFloat minimumLineSpacing;`

The minimum spacing to use between lines of items in the layout. Default: 8.0f;

**Header size**

`@property (nonatomic) CGSize headerReferenceSize;`

The size for collection view headers. Default: CGSizeZero;

**Footer size**

`@property (nonatomic) CGSize footerReferenceSize;`

The size for collection view footers. Default: CGSizeZero;

**Estimated item height**

`@property (nonatomic) CGFloat estimatedItemHeight;`

An estimate for an item’s height for use in a preliminary layout. A value returned by `preferredLayoutAttributesFittingAttributes:` in a UICollectionViewCell will take precedence over this value.

### SelfSizingWaterfallCollectionViewLayoutDelegate <UICollectionViewDelegate>

An object conforming to `SelfSizingWaterfallCollectionViewLayoutDelegate` may provide layout information for a `SelfSizingWaterfallCollectionViewLayout` instance. All of the methods in this protocol are optional. If you do not implement a particular method, the layout will fall back to use values in its own properties for the appropriate layout information.
 
The self sizing waterfall layout object expects the collection view’s delegate object to adopt this protocol (as with `UICollectionViewDelegateFlowLayout`).

**Section insets**

`- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section;
`

Asks the delegate for the margins to apply to content in the specified section.

**Number of columns in section**

`- (NSUInteger)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout numberOfColumnsInSection:(NSUInteger)section;`

Asks the delegate how many columns a section should contain.

**Inter-item spacing**

` - (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section;`

Asks the delegate for the horizontal spacing between columns.

**Line spacing**

` - (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section;`

Asks the delegate for the vertical spacing between successive items in a column of a section.

**Header size**

` - (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSUInteger)section;`

Asks the delegate for the size of the header view in the specified section.

**Footer size**

` - (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSUInteger)section;`

Asks the delegate for the size of the footer view in the specified section.

**Estimated item height**

` - (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout estimatedHeightForItemAtIndexPath:(NSIndexPath *)indexPath;`

Asks the delegate for an estimate of the height of the specified item’s cell for a preliminary layout pass.

## Contact

[@adamwaite](http://twitter.com/adamwaite)

##License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
