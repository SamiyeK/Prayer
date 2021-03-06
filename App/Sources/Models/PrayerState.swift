//
//  Created by Cihat Gündüz on 25.01.17.
//  Copyright © 2017 Flinesoft. All rights reserved.
//

import UIKit

class PrayerState {
    // MARK: - Stored Instance Properties
    private let salah: Salah
    private let changingTextSpeedFactor: Double
    private let fixedTextsSpeedFactor: Double
    private let movementSoundInstrument: String

    private var rakatIndex: Int = 0
    private var componentIndex: Int = 0
    private var lineIndex: Int = 0

    var previousArrow: Position.Arrow?
    var previousLine: String?

    private var previousPositon: Position = .standing
    private var currentPosition: Position = .standing

    // MARK: - Initializers
    init(salah: Salah, changingTextSpeedFactor: Double, fixedTextsSpeedFactor: Double, movementSoundInstrument: String) {
        self.salah = salah
        self.changingTextSpeedFactor = changingTextSpeedFactor
        self.fixedTextsSpeedFactor = fixedTextsSpeedFactor
        self.movementSoundInstrument = movementSoundInstrument
    }

    // MARK: - Computed Instance Properties
    private var currentRakah: Rakah { return salah.rakat[rakatIndex] }
    private var currentComponent: RakahComponent { return currentRakah.components()[componentIndex] }
    var currentArrow: Position.Arrow? { return previousPositon.arrow(forChangingTo: currentPosition) }
    var currentLine: String { return currentComponent.spokenTextLines[lineIndex] }

    private var readingSpeedupFactor: Double {
        return currentComponent.isChangingText ? changingTextSpeedFactor : fixedTextsSpeedFactor
    }

    var currentLineReadingTime: TimeInterval {
        var readingTime = currentLine.estimatedReadingTime / readingSpeedupFactor

        if lineIndex == 0 && currentComponent.needsMovement {
            readingTime += previousPositon.movementDuration(forChangingTo: currentPosition)
        }

        return readingTime
    }

    var currentMovementSoundUrl: URL? {
        guard let movementSound = currentComponent.movementSound else { return nil }
        return AudioPlayer.shared.movementSoundUrl(name: movementSound, instrument: movementSoundInstrument)
    }

    var currentRecitationChapterNum: Int? { return currentComponent.chapterNumber }

    private var nextRakah: Rakah? {
        guard rakatIndex + 1 < salah.rakat.count else { return nil }
        return salah.rakat[rakatIndex + 1]
    }

    private var nextComponent: RakahComponent? {
        guard componentIndex + 1 < currentRakah.components().count else { return nextRakah?.components().first }
        return currentRakah.components()[componentIndex + 1]
    }

    var nextArrow: Position.Arrow? {
        guard lineIndex + 1 >= currentComponent.spokenTextLines.count else { return nil }
        return currentPosition.arrow(forChangingTo: nextComponent?.position)
    }

    var nextLine: String? {
        guard lineIndex + 1 < currentComponent.spokenTextLines.count else { return nextComponent?.spokenTextLines.first }
        return currentComponent.spokenTextLines[lineIndex + 1]
    }

    private var movementSoundUrl: URL? {
        guard lineIndex == 0 else { return nil }
        guard let movementSound = currentComponent.movementSound else { return nil }

        return AudioPlayer.shared.movementSoundUrl(name: movementSound, instrument: movementSoundInstrument)
    }

    // MARK: - Instance Methods
    func moveToNextLine() -> Bool {
        previousLine = currentLine

        // update position
        previousPositon = currentPosition
        if lineIndex + 1 >= currentComponent.spokenTextLines.count {
            if let nextComponent = nextComponent {
                currentPosition = nextComponent.position
            }
        }

        guard lineIndex + 1 >= currentComponent.spokenTextLines.count else { lineIndex += 1; return true }
        lineIndex = 0

        guard componentIndex + 1 >= currentRakah.components().count else { componentIndex += 1; return true }
        componentIndex = 0

        guard rakatIndex + 1 >= salah.rakat.count else { rakatIndex += 1; return true }
        return false
    }

    func prayerViewModel() -> PrayerViewModel {
        return PrayerViewModel(
            currentComponentName: currentComponent.name,
            previousArrow: previousArrow,
            previousLine: previousLine,
            currentArrow: currentArrow,
            currentLine: currentLine,
            isChapterName: false,
            currentIsComponentBeginning: lineIndex == 0,
            nextArrow: nextArrow,
            nextLine: nextLine,
            nextIsComponentBeginning: lineIndex + 1 == currentComponent.spokenTextLines.count,
            movementSoundUrl: movementSoundUrl
        )
    }
}
