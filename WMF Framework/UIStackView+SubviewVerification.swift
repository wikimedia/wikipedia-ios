public extension UIView {
    func wmf_hasRequiredNonZeroHeightConstraint() -> Bool {
        let requiredHeightConstraint = constraints.first(where: {constraint in
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
    }
}

public extension UIStackView {
    func wmf_firstArrangedSubviewWithRequiredNonZeroHeightConstraint() -> UIView? {
        return arrangedSubviews.first(where: { arrangedSubview in
            return arrangedSubview.wmf_hasRequiredNonZeroHeightConstraint()
        })
    }
    func wmf_anArrangedSubviewHasRequiredNonZeroHeightConstraintAssertString() -> String {
        return "\n\nAll stackview arrangedSubview height constraints need to have a priority of < 1000 so the stackview can collapse the 'cell' if the arrangedSubview's isHidden property is set to true. This arrangedSubview was determined to have a required height: \(String(describing: wmf_firstArrangedSubviewWithRequiredNonZeroHeightConstraint())). To fix reduce the priority of its height constraint to < 1000.\n\n"
    }
}
