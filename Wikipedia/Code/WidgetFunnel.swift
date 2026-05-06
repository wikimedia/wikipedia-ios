import WMF
import WMFComponents
import WMFTestKitchen

public final class WidgetFunnel: NSObject {
    public lazy var widgetInstrument: InstrumentImpl = {
        TestKitchenAdapter.shared.client
            .getInstrument(name: "apps-widgetchallenge")
            .startFunnel(name: "widget_challenge")
    }()
}
