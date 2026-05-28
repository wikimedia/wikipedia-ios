import UIKit
import SpriteKit

@MainActor
final class GlobeSnakeViewController: UIViewController {

    private var skView: SKView!

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .all }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.07, green: 0.04, blue: 0.18, alpha: 1.0)

        skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        skView.ignoresSiblingOrder = true
        view.addSubview(skView)

        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = UIColor.white.withAlphaComponent(0.35)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if skView.scene == nil {
            let scene = GlobeSnakeScene()
            scene.scaleMode = .resizeFill
            scene.safeAreaInsets = view.safeAreaInsets
            skView.presentScene(scene)
        }
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        (skView.scene as? GlobeSnakeScene)?.safeAreaInsets = view.safeAreaInsets
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
}
