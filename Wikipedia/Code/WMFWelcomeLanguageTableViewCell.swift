
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
    override func awakeFromNib() {
        super.awakeFromNib()
        languageNameLabel.wmf_configureSubviewsForDynamicType()
    }
}
