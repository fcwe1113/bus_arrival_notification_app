import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        if let registrar = self.registrar(forPlugin: "GoogleMapsApiKeyHandler") {
            let mapsChannel = FlutterMethodChannel(
                name: "com.fcwe1113.future_new_app_name/google_maps",
                binaryMessenger: registrar.messenger()
            )

            mapsChannel.setMethodCallHandler({ (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
                if call.method == "setApiKey",
                   let args = call.arguments as? [String: Any],
                   let apiKey = args["apiKey"] as? String {
                    GMSServices.provideAPIKey(apiKey)
                    result(true)
                } else {
                    result(FlutterMethodNotImplemented)
                }
            })
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

//    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
//        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
//    }
}
