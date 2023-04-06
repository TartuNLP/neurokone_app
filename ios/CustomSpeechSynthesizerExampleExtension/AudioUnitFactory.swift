/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An object that provides an instance of the speech synthesizer audio unit.
*/

import CoreAudioKit

public class AudioUnitFactory: NSObject, AUAudioUnitFactory {
    
    var audioUnit: AUAudioUnit?

    public func beginRequest(with context: NSExtensionContext) {
    
    }

    @objc
    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        audioUnit = try CustomSpeechSynthesizerExampleAudioUnit(componentDescription: componentDescription, options: [])
        return audioUnit!
    }
    
}
