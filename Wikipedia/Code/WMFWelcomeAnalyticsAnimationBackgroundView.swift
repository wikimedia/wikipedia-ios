import Foundation

open class WMFWelcomeAnalyticsAnimationBackgroundView : WMFWelcomeAnimationBackgroundView {
    override var imageModels:[ImageModel]? {
        return [
            ImageModel.init(name: "ftux-background-chart", unitSize: CGSize(width: 0.05, height: 0.04375), unitDestination:CGPoint(x: 0.26875, y: 0.329268), delay: 0.8, duration: 1.3, initialOpacity: 0.0),
            ImageModel.init(name: "ftux-background-shield-star", unitSize: CGSize(width: 0.05, height: 0.0625), unitDestination:CGPoint(x: -0.3234375, y: -0.41158), delay: 1.0, duration: 1.4, initialOpacity: 0.0),
            
            ImageModel.init(name: "ftux-background-plus", unitSize: CGSize(width: 0.03125, height: 0.03125), unitDestination:CGPoint(x: 0.23125, y: -0.466463), delay: 1.1, duration: 1.5, initialOpacity: 0.0),
            ImageModel.init(name: "ftux-background-plus", unitSize: CGSize(width: 0.03125, height: 0.03125), unitDestination:CGPoint(x: 0.2984375, y: 0.076219), delay: 0.5, duration: 1.3, initialOpacity: 0.0),
            ImageModel.init(name: "ftux-background-plus", unitSize: CGSize(width: 0.03125, height: 0.03125), unitDestination:CGPoint(x: -0.309375, y: 0.070121), delay: 0.9, duration: 1.5, initialOpacity: 0.0),
            
            ImageModel.init(name: "ftux-background-circle", unitSize: CGSize(width: 0.040625, height: 0.040625), unitDestination:CGPoint(x: 0.3359375, y: -0.161585), delay: 0.6, duration: 1.5, initialOpacity: 0.0),
            ImageModel.init(name: "ftux-background-circle", unitSize: CGSize(width: 0.040625, height: 0.040625), unitDestination:CGPoint(x: -0.3984375, y: -0.125), delay: 0.8, duration: 1.2, initialOpacity: 0.0),
            ImageModel.init(name: "ftux-background-circle", unitSize: CGSize(width: 0.040625, height: 0.040625), unitDestination:CGPoint(x: -0.2765625, y: 0.31707), delay: 0.8, duration: 1.2, initialOpacity: 0.0)
        ]
    }
}

