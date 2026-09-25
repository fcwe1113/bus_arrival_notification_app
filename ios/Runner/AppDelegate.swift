import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

        if let controller = window?.rootViewController as? FlutterViewController {
            let mapsChannel = FlutterMethodChannel(
                name: "com.fcwe1113.future_new_app_name/google_maps",
                binaryMessenger: controller.binaryMessenger
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
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    }
}
