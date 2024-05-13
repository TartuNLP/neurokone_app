//
//  AudioUnitFactory.swift
//  EestiTtsMacOS
//
//  Created by Rasmus Lellep on 06.03.2024.
//

import CoreAudioKit
import os

private let log = Logger(subsystem: "com.bundle.id.test", category: "AudioUnitFactory")

public class AudioUnitFactory: NSObject, AUAudioUnitFactory {
    var auAudioUnit: AUAudioUnit?

    private var observation: NSKeyValueObservation?

    public func beginRequest(with context: NSExtensionContext) {

    }

    @objc
    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        auAudioUnit = try EestiTtsUnit(componentDescription: componentDescription, options: [])

        guard let audioUnit = auAudioUnit as? EestiTtsUnit else {
            fatalError("Failed to create TtsUnit")
        }

        return audioUnit
    }
    
}
