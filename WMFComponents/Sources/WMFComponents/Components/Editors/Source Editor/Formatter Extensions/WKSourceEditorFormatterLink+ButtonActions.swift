import Foundation
import WMFComponentsObjC

enum WMFSourceEditorFormatterLinkButtonAction {
    case edit
    case insert
}

public struct WMFSourceEditorFormatterLinkWizardParameters {
    public let editPageTitle: String?
    public let editPageLabel: String?
    public let insertSearchTerm: String?
    let preselectedTextRange: UITextRange
}

extension WMFSourceEditorFormatterLink {

    func linkWizardParameters(action: WMFSourceEditorFormatterLinkButtonAction, in textView: UITextView) -> WMFSourceEditorFormatterLinkWizardParameters? {
        
        switch action {
        case .edit:
            expandSelectedRangeUpToNearestFormattingStrings(startingFormattingString: "[[", endingFormattingString: "]]", in: textView)
            
            guard let selectedTextRange = textView.selectedTextRange,
                  let selectedText = textView.text(in: selectedTextRange) else {
                return nil
            }
            
            let splitText = selectedText.split(separator: "|").map {String($0)}
            
            switch splitText.count {
            case 1:
                return WMFSourceEditorFormatterLinkWizardParameters(editPageTitle: splitText[0], editPageLabel: nil, insertSearchTerm: nil, preselectedTextRange: selectedTextRange)
            case 2:
                return WMFSourceEditorFormatterLinkWizardParameters(editPageTitle: splitText[0], editPageLabel: splitText[1], insertSearchTerm: nil, preselectedTextRange: selectedTextRange)
            default:
                return nil
            }
            
        case .insert:
            
            guard let selectedTextRange = textView.selectedTextRange,
                  let selectedText = textView.text(in: selectedTextRange) else {
                return nil
            }
            
            return WMFSourceEditorFormatterLinkWizardParameters(editPageTitle: nil, editPageLabel: nil, insertSearchTerm: selectedText, preselectedTextRange: selectedTextRange)
        }
        
        
    }
    
    func insertLink(in textView: UITextView, pageTitle: String, preselectedTextRange: UITextRange) {
        var content = "[[\(pageTitle)]]"
        
        guard let selectedText = textView.text(in: preselectedTextRange) else {
            return
        }
        
        if pageTitle != selectedText {
            content = "[[\(pageTitle)|\(selectedText)]]"
        }
        
        textView.replace(preselectedTextRange, withText: content)

        if let newStartPosition = textView.position(from: preselectedTextRange.start, offset: 2),
            let newEndPosition = textView.position(from: preselectedTextRange.start, offset: content.count-2) {
            textView.selectedTextRange = textView.textRange(from: newStartPosition, to: newEndPosition)
        }
        
    }

    func editLink(in textView: UITextView, newPageTitle: String, newPageLabel: String?, preselectedTextRange: UITextRange) {
        if let newPageLabel, !newPageLabel.isEmpty {
            textView.replace(preselectedTextRange, withText: "\(newPageTitle)|\(newPageLabel)")
        } else {
            textView.replace(preselectedTextRange, withText: "\(newPageTitle)")
        }
    }
    
    func removeLink(in textView: UITextView, preselectedTextRange: UITextRange) {
        
        guard let selectedText = textView.text(in: preselectedTextRange) else {
                  return
              }
        
        if let markupStartPosition = textView.position(from: preselectedTextRange.start, offset: -2),
           let markupEndPosition = textView.position(from: preselectedTextRange.end, offset: 2),
           let newSelectedRange = textView.textRange(from: markupStartPosition, to: markupEndPosition) {
            textView.replace(newSelectedRange, withText: selectedText)

            if let newStartPosition = textView.position(from: preselectedTextRange.start, offset: -2),
               let newEndPosition = textView.position(from: preselectedTextRange.end, offset: -2) {
                textView.selectedTextRange = textView.textRange(from: newStartPosition, to: newEndPosition)
            }
        }
    }
    
    func insertImage(wikitext: String, in textView: UITextView) {
        
        guard let selectedTextRange = textView.selectedTextRange else {
            return
        }
        
        textView.replace(selectedTextRange, withText: wikitext)
    }
}
