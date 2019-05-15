//
//  TalkPageUpdateStackView.swift
//  Wikipedia
//
//  Created by Toni Sevener on 5/15/19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import UIKit

protocol TalkPageUpdateStackViewDelegate: class {
    func textDidChange()
}

class TalkPageUpdateStackView: UIStackView {

    @IBOutlet private(set) var subjectTextField: ThemeableTextField!
    @IBOutlet private(set) var bodyTextView: ThemeableTextView!
    @IBOutlet private var finePrintTextView: UITextView!
    
    @IBOutlet private var divViews: [UIView]!
    @IBOutlet private var containerViews: [UIView]!
    
    @IBOutlet private var firstDivView: UIView!
    @IBOutlet private var subjectContainerView: UIView!
    
    private var theme: Theme!
    weak var delegate: TalkPageUpdateStackViewDelegate?
    
    private var licenseTitleTextViewAttributedString: NSAttributedString {
        let localizedString = WMFLocalizedString("talk-page-publish-terms-and-licenses", value: "By saving changes, you agree to the %1$@Terms of Use%2$@, and agree to release your contribution under the %3$@CC BY-SA 3.0%4$@ and the %5$@GFDL%6$@ licenses.", comment: "Text for information about the Terms of Use and edit licenses on talk pages. Parameters:\n* %1$@ - app-specific non-text formatting, %2$@ - app-specific non-text formatting, %3$@ - app-specific non-text formatting, %4$@ - app-specific non-text formatting, %5$@ - app-specific non-text formatting,  %6$@ - app-specific non-text formatting.") //todo: gfd or gfdl?
        
        let substitutedString = String.localizedStringWithFormat(
            localizedString,
            "<a href=\"\(Licenses.saveTermsURL?.absoluteString ?? "")\">",
            "</a>",
            "<a href=\"\(Licenses.CCBYSA3URL?.absoluteString ?? "")\">",
            "</a>" ,
            "<a href=\"\(Licenses.GFDLURL?.absoluteString ?? "")\">",
            "</a>"
        )
        
        let attributedString = substitutedString.byAttributingHTML(with: .caption1, boldWeight: .regular, matching: traitCollection, withBoldedString: nil, color: theme.colors.secondaryText, linkColor: theme.colors.link, tagMapping: nil, additionalTagAttributes: nil)
        
        return attributedString
    }
    
    func commonSetup() {
        subjectTextField.isUnderlined = false
        bodyTextView.isUnderlined = false
        bodyTextView.placeholderDelegate = self
    }
    
    func newDiscussionSetup() {
        subjectTextField.placeholder = WMFLocalizedString("talk-page-new-subject-placeholder-text", value: "Subject", comment: "Placeholder text which appears initially in the new discussion subject field for talk pages.")
        bodyTextView.placeholder = WMFLocalizedString("talk-page-new-discussion-body-placeholder-text", value: "Compose new discussion", comment: "Placeholder text which appears initially in the new discussion body field for talk pages.")
        subjectTextField.addTarget(self, action: #selector(subjectEditingChanged), for: .editingChanged)
    }
    
    @objc private func subjectEditingChanged() {
        delegate?.textDidChange()
    }
    
    func newReplySetup() {
        bodyTextView.placeholder = WMFLocalizedString("talk-page-new-reply-body-placeholder-text", value: "Compose response", comment: "Placeholder text which appears initially in the new reply field for talk pages.")
        subjectContainerView.isHidden = true
        firstDivView.isHidden = true
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        subjectTextField.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
        bodyTextView.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
        finePrintTextView.attributedText = licenseTitleTextViewAttributedString
    }
}

extension TalkPageUpdateStackView: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        containerViews.forEach { $0.backgroundColor = theme.colors.paperBackground }
        divViews.forEach { $0.backgroundColor = theme.colors.border }
        finePrintTextView.backgroundColor = theme.colors.paperBackground
        finePrintTextView.textColor = theme.colors.secondaryText
        
        subjectTextField.apply(theme: theme)
        bodyTextView.apply(theme: theme)
        backgroundColor = theme.colors.paperBackground
    }
}

extension TalkPageUpdateStackView: ThemeableTextViewPlaceholderDelegate {
    func themeableTextViewPlaceholderDidHide(_ themeableTextView: UITextView, isPlaceholderHidden: Bool) {
        //no-op
    }
    
    func themeableTextViewDidChange(_ themeableTextView: UITextView) {
        delegate?.textDidChange()
    }
}
