//
//  MediaRemoteController.swift
//  LosslessSwitcher
//
//  Created by Vincent Neo on 1/5/22.
//

import Cocoa
import Combine
import PrivateMediaRemote

fileprivate let kMusicAppBundle = "com.apple.Music"

class MediaRemoteController {
    
    private var infoChangedCancellable: AnyCancellable?
    private var queueChangedCancellable: AnyCancellable?
    
    //private var previousTrack: MediaTrack?
    
    init(outputDevices: OutputDevices) {
        infoChangedCancellable = NotificationCenter.default.publisher(for: NSNotification.Name.mrMediaRemoteNowPlayingInfoDidChange)
                // Reduced throttle from 1s to 0.5s for better responsiveness while still avoiding excessive updates
                .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: true)
                .sink(receiveValue: { notification in
                        //print(notification)
                    print("Info Changed Notification Received")
                    MRMediaRemoteGetNowPlayingInfo(.main) { info in
                        if let info = info as? [String : Any] {
                            let currentTrack = MediaTrack(mediaRemote: info)
                            // Reduced delay from 1s to 0.8s for faster switching response
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                print("Current Track \(outputDevices.currentTrack?.title ?? "nil"), previous: \(outputDevices.previousTrack?.title ?? "nil"), isSame: \(outputDevices.previousTrack == outputDevices.currentTrack)")
                                outputDevices.previousTrack = outputDevices.currentTrack
                                outputDevices.currentTrack = currentTrack
                                if outputDevices.previousTrack != outputDevices.currentTrack {
                                    outputDevices.renewTimer()
                                }
                                outputDevices.switchLatestSampleRate()
                            }
//                            if currentTrack != self.previousTrack {
//                                self.send(command: MRMediaRemoteCommandPause, ifBundleMatches: kMusicAppBundle) {
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                                    outputDevices.switchLatestSampleRate()
//                                    //self.send(command: MRMediaRemoteCommandPlay, ifBundleMatches: kMusicAppBundle) {}
//                                }
//                                //}
//                            }
                            //self.previousTrack = currentTrack
                        }
                    }
                })
        
        MRMediaRemoteRegisterForNowPlayingNotifications(.main)
    }
    
    func send(command: MRMediaRemoteCommand, ifBundleMatches bundleId: String, completion: @escaping () -> ()) {
        MRMediaRemoteGetNowPlayingClient(.main) { client in
            guard let client = client else { return }
            if client.bundleIdentifier == bundleId {
                MRMediaRemoteSendCommand(command, nil)
            }
            completion()
        }
    }
}
