import SwiftUI
import MapKit


struct WMFYearInReviewSlideLocationView: View {
    @ObservedObject var viewModel: WMFYearInReviewSlideLocationViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    var body: some View {
        WMFYearInReviewScrollView(scrollViewContents: WMFYearInReviewSlideLocationViewContent(viewModel: viewModel))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: theme.midBackground))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

fileprivate struct WMFYearInReviewSlideLocationViewContent: View {
    @ObservedObject var viewModel: WMFYearInReviewSlideLocationViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    private var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    private var sizeClassPadding: CGFloat {
        horizontalSizeClass == .regular ? 64 : 32
    }
    
    private var subtitleStyles: HtmlUtils.Styles {
        return HtmlUtils.Styles(font: WMFFont.for(.body), boldFont: WMFFont.for(.boldBody), italicsFont: WMFFont.for(.body), boldItalicsFont: WMFFont.for(.body), color: theme.text, linkColor: theme.link, lineSpacing: 3)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 16) {
                YearInReviewMapView(viewModel: viewModel)
                    .aspectRatio(1.5, contentMode: .fit)
                    .frame(maxWidth: .infinity)
            }
            
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .background(Color(theme.midBackground))
                } else {
                    VStack(spacing: 12) {
                        HStack(alignment: .top) {
                            Text(viewModel.title)
                                .font(Font(WMFFont.for(.boldTitle1)))
                                .foregroundStyle(Color(uiColor: theme.text))
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                            Spacer()
                            if let uiImage = WMFSFSymbolIcon.for(symbol: .infoCircleFill) {
                                Button {
                                    viewModel.tappedInfo()
                                } label: {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .foregroundStyle(Color(uiColor: theme.icon))
                                        .frame(width: 24, height: 24)
                                        .alignmentGuide(.top) { dimensions in
                                            dimensions[.top] - 5
                                        }
                                }
                            }
                        }
                        
                        WMFHtmlText(html: viewModel.subtitle, styles: subtitleStyles)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        
                        Spacer()
                    }
                }
            }
            
            .padding(EdgeInsets(top: 0, leading: sizeClassPadding, bottom: 0, trailing: sizeClassPadding))
        }
    }
}


fileprivate struct YearInReviewMapView: UIViewRepresentable {
    
    @ObservedObject var viewModel: WMFYearInReviewSlideLocationViewModel
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: viewModel.markerReuseIdentifier)
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: viewModel.clusterReuseIdentifier)
        
        // Add annotations for each page view
        let annotations = viewModel.legacyPageViews.map { pageView -> MKPointAnnotation? in
            guard let latitude = pageView.latitude,
                  let longitude = pageView.longitude else {
                return nil
            }
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            annotation.title = pageView.title
            return annotation
        }.compactMap { $0 }
        
        mapView.addAnnotations(annotations)
        
        mapView.setVisibleMapRect(MKMapRect.world, animated: false)
        mapView.isUserInteractionEnabled = false
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        @ObservedObject var viewModel: WMFYearInReviewSlideLocationViewModel
        @ObservedObject var appEnvironment = WMFAppEnvironment.current
        
        init(viewModel: WMFYearInReviewSlideLocationViewModel) {
            self.viewModel = viewModel
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }
            
            if let cluster = annotation as? MKClusterAnnotation {
                let clusterView = mapView.dequeueReusableAnnotationView(withIdentifier: viewModel.clusterReuseIdentifier) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: cluster, reuseIdentifier: viewModel.clusterReuseIdentifier)
                clusterView.markerTintColor = appEnvironment.theme.accent
                clusterView.glyphText = "\(cluster.memberAnnotations.count)"
                return clusterView
            }
            
            let markerView = mapView.dequeueReusableAnnotationView(withIdentifier: viewModel.markerReuseIdentifier) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: viewModel.markerReuseIdentifier)
            markerView.markerTintColor = appEnvironment.theme.accent
            markerView.clusteringIdentifier = viewModel.clusteringIdentifier
            return markerView
        }
        
        func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
            guard !viewModel.didZoomToLargestCluster else {
                if fullyRendered {
                    
                    // Delay a bit so annotions finish loading
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        self?.viewModel.mapViewSnapshotForSharing = mapView.snapshot()
                    }
                    
                }
                return
            }
            
            // Schedule a check on the next run loop so clusters have time to form
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self else { return }
                
                let clusters = mapView.annotations.compactMap { $0 as? MKClusterAnnotation }
                
                // if no cluster exists, focus on a random article.
                if clusters.count == 0 {
                    
                    if let randomAnnotation = mapView.annotations.randomElement() {
                        populateAnnotationLocationName(mapView: mapView, annotation: randomAnnotation)
                    } else {
                        // Error state?
                    }
                    
                    
                } else if let largestCluster = clusters.max(by: { $0.memberAnnotations.count < $1.memberAnnotations.count }) {
                    populateClusterLocationName(mapView: mapView, cluster: largestCluster)
                }
            }
        }
        
        private func populateAnnotationLocationName(mapView: MKMapView, annotation: MKAnnotation) {
            if let title = annotation.title ?? nil {
                viewModel.randomArticleTitles = [title]
            }
            
            // Center map on annotation
            mapView.setVisibleMapRect(MKMapRect(origin: MKMapPoint(annotation.coordinate), size: MKMapSize(width: 0, height: 0)), animated: true)
            
            // wait for animation to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                
                guard let self else { return }
                
                viewModel.reverseGeocode(location: CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude))
            }
            
            
            viewModel.didZoomToLargestCluster = true
        }
        
        private func populateClusterLocationName(mapView: MKMapView, cluster: MKClusterAnnotation) {
            
            let annotations = cluster.memberAnnotations
            
            // Grab some article titles, save off to view model
            let allTitlesInCluster = annotations.compactMap { $0.title }.compactMap { $0 }
            let randomThreeTitlesInCluster = Array(allTitlesInCluster.shuffled().prefix(3))
            viewModel.randomArticleTitles = randomThreeTitlesInCluster
            
            // Center map only on largest cluster
            let rect = annotations.reduce(MKMapRect.null) { $0.union(MKMapRect(origin: MKMapPoint($1.coordinate), size: MKMapSize(width: 0, height: 0))) }
            mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
            
            // wait for animation to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self else { return }
                
                let coordinates = cluster.memberAnnotations.map { $0.coordinate }
                
                guard !coordinates.isEmpty else {
                    return
                }
                
                // Compute average coordinate for the cluster
                let avgLat = coordinates.map { $0.latitude }.reduce(0, +) / Double(coordinates.count)
                let avgLon = coordinates.map { $0.longitude }.reduce(0, +) / Double(coordinates.count)
                let location = CLLocation(latitude: avgLat, longitude: avgLon)
                
                viewModel.reverseGeocode(location: location)
            }
            
            viewModel.didZoomToLargestCluster = true
        }
    }
}
