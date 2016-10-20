
class WMFWelcomeLanguageTableViewCell: WMFCustomDeleteButtonTableViewCell {
    @IBOutlet var languageNameLabel:UILabel!
    var languageName: String? {
        set (newLanguageName){
            languageNameLabel.text = newLanguageName
        }
        get {
            return languageNameLabel.text
        }
    }
}
