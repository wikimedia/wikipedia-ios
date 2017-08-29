import Foundation

/*

Problem:
  UIButtons displaying multiple lines of text don't change their intrinsic
  content size to reflect their multi-line height (when more than one line
  of text is being shown by the UIButton's titleLabel). This is a problem
  if we don't control the exact width of text being shown by the button
  which is common when displaying different string localizations.

  This is especially problematic as the label's additional lines will
  overlap the button's top and bottom frame boundaries. Also a problem
  when using AutoLayout to position something beneath the button.

Solution:
  This method returns a height that accounts for multiple line button text.
  You can use this height to update a height constraint on the button
  within a view controller's "updateViewConstraints" method.

Note:
  The returned height will respect any content and title edge constraints
  set in Interface Builder.

*/

extension UIButton {
    @objc func wmf_heightAccountingForMultiLineText() -> CGFloat {
        if let superview = self.superview, let titleLabel = self.titleLabel {
            return titleLabel.sizeThatFits(superview.frame.size).height +
                self.contentEdgeInsets.top +
                self.contentEdgeInsets.bottom +
                self.titleEdgeInsets.top +
                self.titleEdgeInsets.bottom
        }
        return self.frame.size.height;
    }
}
