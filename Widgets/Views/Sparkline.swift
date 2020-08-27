import SwiftUI
import WMF

private struct SparklineShape: Shape {

	// MARK: Private Properties

	private let data: [CGFloat]

	// MARK: Public

	init(data: [NSNumber]?) {
		self.data = data?.compactMap { CGFloat($0.doubleValue) } ?? []
	}

	// MARK: Shape

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard data.count > 1, let min = data.min(), let max = data.max() else {
            return path
        }

        guard min != max else {
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return path
        }
                        
        let minY = rect.minY
        let width = rect.width / CGFloat(data.count - 1)
        let height = rect.maxY - rect.minY
        
        var points: [CGPoint] = []
        
        for (index, dataPoint) in data.enumerated() {
            let relativeY = dataPoint - CGFloat(min)
            let normalizedY = 1 - relativeY/(CGFloat(max-min))
            let y = minY + height * normalizedY
            let x = width * CGFloat(index)
            points.append(CGPoint(x: x, y: y))
        }
        
        path.move(to: points[0])
        for (index, point) in points[1...points.count-1].enumerated() {
            let fromPoint = points[index]
            let midPoint = CGPoint.midPointFrom(fromPoint, to: point)
            let midPointControlPoint = CGPoint.quadCurveControlPointFrom(midPoint, to: fromPoint)
            path.addQuadCurve(to: midPoint, control: midPointControlPoint)
            let toPointControlPoint = CGPoint.quadCurveControlPointFrom(midPoint, to: point)
            path.addQuadCurve(to: point, control: toPointControlPoint)
        }
    
        return path
    }
    
}

struct SparklineGrid: View {
	@Environment(\.colorScheme) private var colorScheme

	// MARK: Properties

	var gridStyle: Sparkline.GridStyle

	// MARK: View

	var body: some View {
		// TODO
		Rectangle()
	}
}

struct Sparkline: View {
    @Environment(\.colorScheme) private var colorScheme

	// MARK: Nested Types

	enum Style {
		case compact
        case compactWithViewCount
		case expanded
	}
    
    enum GridStyle {
        case horizontal
        case horizontalAndVertical
    }

	// MARK: Properties

	var style: Style = .compact
    var gridStyle: GridStyle = .horizontal
    var lineWidth: CGFloat = 1.5
    
	var timeSeries: [NSNumber]? = []
	var containerBackgroundColor: Color = Color.white
    
    var gradientStartColor: Color {
        colorScheme == .light
            ? Theme.light.colors.rankGradientStart.asColor
            : Theme.dark.colors.rankGradientStart.asColor
    }

    var gradientEndColor: Color {
        colorScheme == .light
            ? Theme.light.colors.rankGradientEnd.asColor
            : Theme.dark.colors.rankGradientEnd.asColor
    }

	// MARK: View

	var body: some View {
		if style == .compact || style == .compactWithViewCount {
			HStack {
				Spacer().frame(width: 4)
				SparklineShape(data: timeSeries)
					.stroke(
						LinearGradient(gradient: Gradient(colors: [gradientStartColor, gradientEndColor]), startPoint: /*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/, endPoint: /*@START_MENU_TOKEN@*/.trailing/*@END_MENU_TOKEN@*/), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
					.frame(width: 30, alignment: .leading)
					.padding([.top, .bottom], 3)
					// TODO
					// .background(SparklineGrid(gridStyle: gridStyle).frame(height: proxy.size.height / 2))
				if style == .compactWithViewCount {
					Text("\(currentViewCountOrEmpty)")
						.font(.system(size: 12))
						.fontWeight(.medium)
						.foregroundColor(Theme.light.colors.rankGradientEnd.asColor)
					}
					Spacer().frame(width: 4)
			}
			.background(containerBackgroundColor)
		} else {
			ZStack {
				Rectangle()
				Rectangle().inset(by: 5).fill(Color.secondary)
			}
			.background(containerBackgroundColor)
		}
	}

	// MARK: Private

	private var currentViewCountOrEmpty: String {
		guard let currentViewCount = timeSeries?.last else {
			return "–"
		}

		return NumberFormatter.localizedThousandsStringFromNumber(currentViewCount)
	}

}
