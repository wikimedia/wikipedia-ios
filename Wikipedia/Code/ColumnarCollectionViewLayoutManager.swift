import UIKit

class ColumnarCollectionViewLayoutManager {
    private var placeholders: [String:UICollectionReusableView] = [:]

    weak var view: UIView!
    weak var collectionView: UICollectionView!
    
    required init(view: UIView, collectionView: UICollectionView) {
        self.view = view
        self.collectionView = collectionView
    }
    
    // MARK: - Cell & View Registration
    
    final private func placeholderForIdentifier(_ identifier: String) -> UICollectionReusableView? {
        let view = placeholders[identifier]
        view?.prepareForReuse()
        return view
    }
    
    final public func placeholder(forCellWithReuseIdentifier identifier: String) -> UICollectionViewCell? {
        return placeholderForIdentifier(identifier) as? UICollectionViewCell
    }
    
    final public func placeholder(forSupplementaryViewOfKind elementKind: String, withReuseIdentifier identifier: String) -> UICollectionReusableView? {
        return placeholderForIdentifier("\(elementKind)-\(identifier)")
    }
    
    @objc(registerCellClass:forCellWithReuseIdentifier:addPlaceholder:)
    final func register(_ cellClass: Swift.AnyClass?, forCellWithReuseIdentifier identifier: String, addPlaceholder: Bool) {
        collectionView.register(cellClass, forCellWithReuseIdentifier: identifier)
        guard addPlaceholder else {
            return
        }
        guard let cellClass = cellClass as? UICollectionViewCell.Type else {
            return
        }
        let cell = cellClass.init(frame: view.bounds)
        cell.isHidden = true
        view.insertSubview(cell, at: 0) // so that the trait collections are updated
        placeholders[identifier] = cell
    }
    
    @objc(registerNib:forCellWithReuseIdentifier:)
    final func register(_ nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        collectionView.register(nib, forCellWithReuseIdentifier: identifier)
        guard let cell = nib?.instantiate(withOwner: nil, options: nil).first as? UICollectionViewCell else {
            return
        }
        cell.isHidden = true
        view.insertSubview(cell, at: 0) // so that the trait collections are updated
        placeholders[identifier] = cell
    }
    
    @objc(registerViewClass:forSupplementaryViewOfKind:withReuseIdentifier:addPlaceholder:)
    final func register(_ viewClass: Swift.AnyClass?, forSupplementaryViewOfKind elementKind: String, withReuseIdentifier identifier: String, addPlaceholder: Bool) {
        collectionView.register(viewClass, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: identifier)
        guard addPlaceholder else {
            return
        }
        guard let viewClass = viewClass as? UICollectionReusableView.Type else {
            return
        }
        let reusableView = viewClass.init(frame: view.bounds)
        reusableView.isHidden = true
        view.insertSubview(reusableView, at: 0) // so that the trait collections are updated
        placeholders["\(elementKind)-\(identifier)"] = reusableView
    }
    
    @objc(registerNib:forSupplementaryViewOfKind:withReuseIdentifier:addPlaceholder:)
    final func register(_ nib: UINib?, forSupplementaryViewOfKind elementKind: String, withReuseIdentifier identifier: String, addPlaceholder: Bool) {
        collectionView.register(nib, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: identifier)
        guard addPlaceholder else {
            return
        }
        guard let reusableView = nib?.instantiate(withOwner: nil, options: nil).first as? UICollectionReusableView else {
            return
        }
        reusableView.isHidden = true
        view.insertSubview(reusableView, at: 0) // so that the trait collections are updated
        placeholders["\(elementKind)-\(identifier)"] = reusableView
    }
}
