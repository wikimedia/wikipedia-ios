import SwiftUI
import WMF
import WMFComponents

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
		switch gridStyle {
		case .horizontal:
			GeometryReader { proxy in
				let yOffset = proxy.size.height / 2.0

				Path { path in
					path.move(to: CGPoint(x: 0, y: yOffset))
					path.addLine(to: CGPoint(x: proxy.size.width, y: yOffset))

					path.move(to: CGPoint(x: 0, y: yOffset / 2.0))
					path.addLine(to: CGPoint(x: proxy.size.width, y: yOffset / 2.0))

					path.move(to: CGPoint(x: 0, y: yOffset * 1.5))
					path.addLine(to: CGPoint(x: proxy.size.width, y: yOffset * 1.5))
				}
				.stroke(style: StrokeStyle(lineWidth: 1.0, lineCap: .round))
			}
		case .horizontalAndVertical:
			ZStack {
				VStack {
					Spacer()
					Rectangle().frame(height: 1)
					Spacer()
					Rectangle().frame(height: 1)
					Spacer()
					Rectangle().frame(height: 1)
					Spacer()
					Rectangle().frame(height: 1)
					Spacer()
				}
				HStack {
					Spacer()
					Rectangle().frame(width: 1)
					Spacer()
					Rectangle().frame(width: 1)
					Spacer()
					Rectangle().frame(width: 1)
					Spacer()
				}
			}
		}
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
	var lineWidth: CGFloat {
		return style == .expanded ? 2.25 : 1.5
	}
    
	var timeSeries: [NSNumber]? = []
	var containerBackgroundColor: Color {
		switch style {
		case .compactWithViewCount:
			return colorScheme == .dark ? Color.white.opacity(0.12) : Color(red: 248/255.0, green: 248/255.0, blue: 250/255.0, opacity: 1)
		case .compact:
			return colorScheme == .dark ? .black : .white
		case .expanded:
			return colorScheme == .dark ? .black : .white
		}
	}
    
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
				ZStack {
					SparklineGrid(gridStyle: .horizontal)
						.foregroundColor(colorScheme == .dark
							? Color(.sRGB, red: 55/255.0, green: 55/255.0, blue: 55/255.0, opacity: 1)
							: Color(.sRGB, red: 235/255.0, green: 235/255.0, blue: 235/255.0, opacity: 1)
						)
						.layoutPriority(-1)
					SparklineShape(data: timeSeries)
						.stroke(
							LinearGradient(gradient: Gradient(colors: [gradientStartColor, gradientEndColor]), startPoint: /*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/, endPoint: /*@START_MENU_TOKEN@*/.trailing/*@END_MENU_TOKEN@*/), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
						.frame(width: style == .compact ? 22 : 30, alignment: .leading)
						.padding([.top, .bottom, .leading, .trailing], 3)
				}
				if style == .compactWithViewCount {
					Text("\(currentViewCountOrEmpty)")
                        .font(Font(WMFFont.for(.caption1)))
						.fontWeight(.medium)
						.foregroundColor(Theme.light.colors.rankGradientEnd.asColor)
					}
					Spacer().frame(width: 4)
			}
			.background(containerBackgroundColor)
		} else {
			ZStack {
				SparklineGrid(gridStyle: .horizontalAndVertical)
					.foregroundColor(colorScheme == .dark
						? Color(.sRGB, red: 55/255.0, green: 55/255.0, blue: 55/255.0, opacity: 1)
						: Color(.sRGB, red: 235/255.0, green: 235/255.0, blue: 235/255.0, opacity: 1)
					)
				SparklineShape(data: timeSeries)
					.stroke(
						LinearGradient(gradient: Gradient(colors: [gradientStartColor, gradientEndColor]), startPoint: /*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/, endPoint: /*@START_MENU_TOKEN@*/.trailing/*@END_MENU_TOKEN@*/), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
					.padding([.top, .bottom, .leading, .trailing], 8)
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
