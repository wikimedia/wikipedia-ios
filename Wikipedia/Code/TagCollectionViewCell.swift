class TagCollectionViewCell: CollectionViewCell {
    static let reuseIdentifier = "TagCollectionViewCell"
    fileprivate let label = UILabel()
    
    func configure(with tag: String) {
        label.text = tag
        setNeedsLayout()
    }
}
