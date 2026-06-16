import Flutter
import UIKit
import GoogleMaps
import AVFoundation

class RetroAudioPlayer {
  static let shared = RetroAudioPlayer()
  private var players = [String: AVAudioPlayer]()
  
  func loadSound(name: String, key: String) {
    if let path = Bundle.main.path(forResource: key, ofType: nil) {
      let url = URL(fileURLWithPath: path)
      do {
        let player = try AVAudioPlayer(contentsOf: url)
        player.prepareToPlay()
        players[name] = player
      } catch {
        print("Error loading sound \(name): \(error)")
      }
    } else {
      print("Could not find sound path for key: \(key)")
    }
  }
  
  func play(name: String) {
    if let player = players[name] {
      if player.isPlaying {
        player.stop()
      }
      player.currentTime = 0
      player.play()
    } else {
      print("Player not found for sound: \(name)")
    }
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyCTd5Kqot24CcIFGvuTyMxsrHb6V6ekxBA")
    
    // Register custom MethodChannel for audio SFX
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let soundChannel = FlutterMethodChannel(name: "turf.app/sfx",
                                            binaryMessenger: controller.binaryMessenger)
    
    let sounds = [
      "button_click",
      "start_walk",
      "end_walk",
      "login",
      "logout",
      "recenter",
      "delete_history"
    ]
    
    for name in sounds {
      let key = controller.lookupKey(forAsset: "assets/sfx_\(name).wav")
      RetroAudioPlayer.shared.loadSound(name: name, key: key)
    }
    
    soundChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "playSfx" {
        if let args = call.arguments as? [String: Any],
           let name = args["name"] as? String {
          RetroAudioPlayer.shared.play(name: name)
          result(nil)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Sound name is null", details: nil))
        }
      } else if call.method == "playRetroClick" {
        RetroAudioPlayer.shared.play(name: "button_click")
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
