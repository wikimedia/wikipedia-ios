import SwiftUI
import MapKit

// MARK: - Custom annotation object

final class WMFTrendingCountryMKAnnotation: NSObject, MKAnnotation {
    let country: WMFTrendingCountryAnnotation
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: country.latitude, longitude: country.longitude)
    }
    var title: String? { country.name }

    init(country: WMFTrendingCountryAnnotation) {
        self.country = country
    }
}

// MARK: - Map view

public struct WMFTrendingMapView: UIViewRepresentable {

    let countries: [WMFTrendingCountryAnnotation]
    let onTapCountry: (WMFTrendingCountryAnnotation) -> Void

    private let reuseID = "WMFTrendingCountryPin"

    public func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: reuseID)
        mapView.setVisibleMapRect(.world, edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), animated: false)

        let annotations = countries.map { WMFTrendingCountryMKAnnotation(country: $0) }
        mapView.addAnnotations(annotations)
        return mapView
    }

    public func updateUIView(_ mapView: MKMapView, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(reuseID: reuseID, onTapCountry: onTapCountry)
    }

    // MARK: Coordinator

    public final class Coordinator: NSObject, MKMapViewDelegate {
        private let reuseID: String
        private let onTapCountry: (WMFTrendingCountryAnnotation) -> Void
        @ObservedObject var appEnvironment = WMFAppEnvironment.current

        init(reuseID: String, onTapCountry: @escaping (WMFTrendingCountryAnnotation) -> Void) {
            self.reuseID = reuseID
            self.onTapCountry = onTapCountry
        }

        public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard annotation is WMFTrendingCountryMKAnnotation else { return nil }
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID, for: annotation) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            view.markerTintColor = .orange
            view.glyphTintColor = .white
            view.glyphImage = UIImage(systemName: "flame.fill")
            view.canShowCallout = true
            let button = UIButton(type: .detailDisclosure)
            button.tintColor = appEnvironment.theme.link
            view.rightCalloutAccessoryView = button
            return view
        }

        public func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            guard let annotation = view.annotation as? WMFTrendingCountryMKAnnotation else { return }
            onTapCountry(annotation.country)
        }
    }
}
