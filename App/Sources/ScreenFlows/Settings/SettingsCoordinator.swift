//
//  Created by Cihat Gündüz on 23.01.17.
//  Copyright © 2017 Flinesoft. All rights reserved.
//

import Imperio
import SafariServices
import SwiftyUserDefaults
import UIKit

class SettingsCoordinator: AppCoordinator {
    // MARK: - Stored Instance Properties
    private let l10n = L10n.Settings.self
    var settingsViewModel: SettingsViewModel!
    var settingsViewCtrl: SettingsViewController!

    // MARK: - Computed Instance Properties
    override var mainViewController: UIViewController? {
        return settingsViewCtrl
    }

    // MARK: - Coordinator Methods
    override func start() {
        super.start()

        settingsViewModel = SettingsViewModel()
        settingsViewCtrl = SettingsViewController(viewModel: settingsViewModel)

        settingsViewCtrl?.coordinate = handleUserInteraction()

        let navCtrl = BrandedNavigationController(rootViewController: settingsViewCtrl)
        present(initialViewController: navCtrl)

        if !Defaults[.faqClosed] {
            showFAQ()
        }
    }

    fileprivate func handleUserInteraction() -> (SettingsViewController.Action) -> Void { // swiftlint:disable:this cyclomatic_complexity
        return { [unowned self] action in
            switch action {
            case let .setRakat(rakatCount):
                self.settingsViewModel.rakatCount = rakatCount

            case let .setFixedPartSpeed(fixedPartSpeed):
                self.settingsViewModel.fixedTextsSpeedFactor = fixedPartSpeed

            case let .setChangingPartSpeed(changingPartSpeed):
                self.settingsViewModel.changingTextSpeedFactor = changingPartSpeed

            case let .setShowChagingTextName(showName):
                self.settingsViewModel.showChangingTextName = showName

            case let .changeLanguage(langCode):
                self.settingsViewModel.interfaceLanguageCode = langCode
                self.settingsViewCtrl.showRestartConfirmDialog()

            case .confirmRestart:
                exit(EXIT_SUCCESS) // see http://stackoverflow.com/a/9939963/3451975

            case let .chooseInstrument(instrument):
                self.settingsViewModel.movementSoundInstrument = instrument
                if let moveSoundUrl = AudioPlayer.shared.movementSoundUrl(name: "E-Short", instrument: instrument) {
                    AudioPlayer.shared.playSound(at: moveSoundUrl)
                }

            case .startPrayer:
                self.startPrayer()

            case .didPressFAQButton:
                self.showFAQ()
            }
        }
    }

    // MARK: - Action Methods
    func startPrayer() {
        guard settingsViewModel.rakatCount > 0 else { return }
        let salah = Salah(rakatCount: UInt(settingsViewModel.rakatCount))

        let prayerCoordinator = PrayerCoordinator(
            presentingViewController: settingsViewCtrl,
            salah: salah,
            fixedTextSpeedsFactor: settingsViewModel.fixedTextsSpeedFactor,
            changingTextSpeedFactor: settingsViewModel.changingTextSpeedFactor,
            showChangingTextName: settingsViewModel.showChangingTextName,
            movementSoundInstrument: settingsViewModel.movementSoundInstrument
        )

        start(subCoordinator: prayerCoordinator).onFinish {
            // no-op
        }
    }

    func showFAQ() {
        let faqNavCtrl = StoryboardScene.Settings.faqNavigationController.instantiate()
        let faqViewCtrl = faqNavCtrl.topViewController as! FAQViewController // swiftlint:disable:this force_cast
        let localL10n = l10n.FaqEntries.self

        faqViewCtrl.viewModel = FAQViewModel(
            entries: [
                (question: localL10n.AppMotivation.question, answer: localL10n.AppMotivation.answer),
                (question: localL10n.IpadReading.question, answer: localL10n.IpadReading.answer),
                (question: localL10n.Language.question, answer: localL10n.Language.answer),
                (question: localL10n.LanguageMix.question, answer: localL10n.LanguageMix.answer),
                (question: localL10n.TranslationProblem.question, answer: localL10n.TranslationProblem.answer)
            ]
        )

        faqViewCtrl.coordinate = { action in
            switch action {
            case .doneButtonPressed:
                Defaults[.faqClosed] = true
                faqViewCtrl.dismiss(animated: true, completion: nil)
            }
        }

        settingsViewCtrl.present(faqNavCtrl, animated: true, completion: nil)
    }
}

extension DefaultsKeys {
    static let faqClosed = DefaultsKey<Bool>("faqClosed")
}
