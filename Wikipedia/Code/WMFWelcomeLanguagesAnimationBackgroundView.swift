import Foundation

open class WMFWelcomeLanguagesAnimationBackgroundView : WMFWelcomeAnimationBackgroundView {
    override var imageModels:[ImageModel]? {
        return [
            ImageModel.init(name: "ftux-background-langs", unitSize: CGSize(width: 0.08125, height: 0.071875), unitDestination:CGPoint(x: 0.303125, y: -0.121951), delay: 0.8, duration: 1.3, initialOpacity: 0.0),
            ImageModel.init(name: "ftux-background-langs", unitSize: CGSize(width: 0.08125, height: 0.071875), unitDestination:CGPoint(x: -0.259375, y: 0.277439), delay: 1.0, duration: 1.4, initialOpacity: 0.0),
            
            ImageModel.init(name: "ftux-background-plus", unitSize: CGSize(width: 0.03125, height: 0.03125), unitDestination:CGPoint(x: 0.2109375, y: -0.36585), delay: 1.1, duration: 1.5, initialOpacity: 0.0),
            ImageModel.init(name: "ftux-background-plus", unitSize: CGSize(width: 0.03125, height: 0.03125), unitDestination:CGPoint(x: 0.2875, y: 0.195121), delay: 0.5, duration: 1.3, initialOpacity: 0.0),
            ImageModel.init(name: "ftux-background-plus", unitSize: CGSize(width: 0.03125, height: 0.03125), unitDestination:CGPoint(x: -0.309375, y: 0.070121), delay: 0.9, duration: 1.5, initialOpacity: 0.0),
            
            ImageModel.init(name: "ftux-background-circle", unitSize: CGSize(width: 0.040625, height: 0.040625), unitDestination:CGPoint(x: 0.2359375, y: 0.381097), delay: 0.6, duration: 1.5, initialOpacity: 0.0),
            ImageModel.init(name: "ftux-background-circle", unitSize: CGSize(width: 0.040625, height: 0.040625), unitDestination:CGPoint(x: -0.29375, y: -0.393292), delay: 0.8, duration: 1.2, initialOpacity: 0.0)
        ]
    }
}
