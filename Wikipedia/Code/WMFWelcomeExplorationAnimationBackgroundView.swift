import Foundation

open class WMFWelcomeExplorationAnimationBackgroundView : WMFWelcomeAnimationBackgroundView {
    override var imageModels:[ImageModel]? {
        return [
            ImageModel.init(name: "ftux-background-globe", unitSize: CGSize(width: 0.071875, height: 0.071875), unitDestination:CGPoint(x: 0.265625, y: -0.32621), delay: 0.8, duration: 1.3, initialOpacity: 0.0),
            ImageModel.init(name: "ftux-background-map-dot", unitSize: CGSize(width: 0.0625, height: 0.071875), unitDestination:CGPoint(x: 0.2015625, y: 0.286585), delay: 1.0, duration: 1.4, initialOpacity: 0.0),
            ImageModel.init(name: "ftux-background-calendar", unitSize: CGSize(width: 0.0625, height: 0.071875), unitDestination:CGPoint(x: -0.3140625, y: -0.417682), delay: 1.2, duration: 1.5, initialOpacity: 0.0),
            
            ImageModel.init(name: "ftux-background-plus", unitSize: CGSize(width: 0.03125, height: 0.03125), unitDestination:CGPoint(x: 0.2015625, y: -0.49085), delay: 1.1, duration: 1.5, initialOpacity: 0.0),
            ImageModel.init(name: "ftux-background-plus", unitSize: CGSize(width: 0.03125, height: 0.03125), unitDestination:CGPoint(x: 0.284375, y: 0.10670), delay: 0.5, duration: 1.3, initialOpacity: 0.0),
            ImageModel.init(name: "ftux-background-plus", unitSize: CGSize(width: 0.03125, height: 0.03125), unitDestination:CGPoint(x: -0.303125, y: 0.051829), delay: 0.9, duration: 1.5, initialOpacity: 0.0),
            
            ImageModel.init(name: "ftux-background-circle", unitSize: CGSize(width: 0.040625, height: 0.040625), unitDestination:CGPoint(x: 0.3359375, y: -0.100609), delay: 1.1, duration: 1.4, initialOpacity: 0.0),
            ImageModel.init(name: "ftux-background-circle", unitSize: CGSize(width: 0.040625, height: 0.040625), unitDestination:CGPoint(x: -0.275, y: 0.34756), delay: 0.6, duration: 1.5, initialOpacity: 0.0),
            ImageModel.init(name: "ftux-background-circle", unitSize: CGSize(width: 0.040625, height: 0.040625), unitDestination:CGPoint(x: -0.3984375, y: -0.155487), delay: 0.8, duration: 1.2, initialOpacity: 0.0)
        ]
    }
}
