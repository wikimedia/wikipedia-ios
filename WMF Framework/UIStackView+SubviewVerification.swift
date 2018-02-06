
extension UIStackView {
    public func wmf_firstArrangedSubviewWithRequiredNonZeroHeightConstraint() -> UIView? {
        return arrangedSubviews.first(where: {arrangedSubview in
            let requiredHeightConstraint = arrangedSubview.constraints.first(where: {constraint in
                guard
                    type(of: constraint) == NSLayoutConstraint.self,
                    constraint.firstAttribute == .height,
                    constraint.priority == UILayoutPriority.required,
                    constraint.constant != 0
                    else{
                        return false
                }
                return true
            })
            return (requiredHeightConstraint != nil)
        })
    }
}
