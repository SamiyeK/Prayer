//
//  Created by Cihat Gündüz on 09.01.17.
//  Copyright © 2017 Flinesoft. All rights reserved.
//

import Eureka
import HandyUIKit
import Imperio
import UIKit

class SettingsViewController: BrandedFormViewController, Coordinatable {
    // MARK: - Coordinatable Protocol Implementation
    enum Action {
        case setRakat(Int)
        case setFixedPartSpeed(Double)
        case setChangingPartSpeed(Double)
        case setShowChagingTextName(Bool)
        case changeLanguage(String)
        case confirmRestart
        case chooseInstrument(String)
        case startPrayer
        case didPressFAQButton
    }

    var coordinate: ((SettingsViewController.Action) -> Void)!

    // MARK: - Stored Instance Properties
    let l10n = L10n.Settings.self
    var viewModel: SettingsViewModel

    // MARK: - Initializers
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel

        super.init(style: .grouped)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.Settings.title
        tableView?.backgroundColor = Color.Theme.contentBackground

        setupAppSection()
        setupPrayerSection()
        setupStartSection()
        setupFAQButton()
    }

    // MARK: - Instance Methods
    private func setupAppSection() {
        let appSection = Section(l10n.AppSection.title) <<< ActionSheetRow<String> { row in
            row.title = l10n.AppSection.InterfaceLanguage.title
            row.options = SettingsViewModel.availableLanguageCodes
            row.value = viewModel.interfaceLanguageCode
            row.displayValueFor = { Locale.current.localizedString(forLanguageCode: $0!) }
        }.onChange { row in
            guard let rowValue = row.value else { log.error("Language had nil value."); return }
            self.coordinate(.changeLanguage(rowValue))
        }

        form.append(appSection)
    }

    private func setupPrayerSection() {
        let prayerSection = Section(l10n.PrayerSection.title)
            <<< rakatCountRow()
            <<< fixedTextsRow()
            <<< changingTextRow()
            <<< changingTextNameRow()
            <<< movementSoundInstrumentRow()

        form.append(prayerSection)
    }

    fileprivate func rakatCountRow() -> IntRow {
        return IntRow { row in
            row.title = l10n.PrayerSection.RakatCount.title
            row.value = viewModel.rakatCount
        }.onCellHighlightChanged { cell, row in
            if cell.textField.isFirstResponder {
                row.value = nil
            }
        }.onChange { row in
            guard let rowValue = row.value else { log.error("Rakat row had nil value."); return }
            self.coordinate(.setRakat(rowValue))
        }
    }

    fileprivate func fixedTextsRow() -> SliderRow {
        return SliderRow { row in
            row.title = l10n.PrayerSection.FixedTexts.title
            row.value = Float(viewModel.fixedTextsSpeedFactor)
            row.cell.slider.minimumValue = 0.5
            row.cell.slider.maximumValue = 2.0
            row.steps = UInt((row.cell.slider.maximumValue - row.cell.slider.minimumValue) / 0.05)
        }.onChange { row in
            guard let rowValue = row.value else { log.error("Fixed text speed had nil value."); return }
            let speed = Double(rowValue)
            self.coordinate(.setFixedPartSpeed(speed))
        }
    }

    fileprivate func changingTextRow() -> SliderRow {
        return SliderRow { row in
            row.title = l10n.PrayerSection.ChangingText.title
            row.value = Float(viewModel.changingTextSpeedFactor)
            row.cell.slider.minimumValue = 0.5
            row.cell.slider.maximumValue = 2.0
            row.steps = UInt((row.cell.slider.maximumValue - row.cell.slider.minimumValue) / 0.05)
        }.onChange { row in
            guard let rowValue = row.value else { log.error("Changing text speed had nil value."); return }
            let speed = Double(rowValue)
            self.coordinate(.setChangingPartSpeed(speed))
        }
    }

    fileprivate func changingTextNameRow() -> SwitchRow {
        return SwitchRow { row in
            row.title = l10n.PrayerSection.ChangingTextName.title
            row.value = viewModel.showChangingTextName
        }.onChange { row in
            guard let rowValue = row.value else { log.error("Show changing text name had nil value."); return }
            self.coordinate(.setShowChagingTextName(rowValue))
        }
    }

    fileprivate func movementSoundInstrumentRow() -> PushRow<String> {
        return PushRow<String> { row in
            row.title = l10n.PrayerSection.MovementSoundInstrument.title
            row.options = SettingsViewModel.availableMovementSoundInstruments
            row.value = viewModel.movementSoundInstrument
        }.onChange { row in
            guard let rowValue = row.value else { log.error("Instrument had nil value."); return }
            self.coordinate(.chooseInstrument(rowValue))
        }
    }

    private func setupStartSection() {
        let startSection = Section() <<< ButtonRow { row in
            row.title = L10n.Settings.StartButton.title
        }.cellSetup { cell, _ in
            cell.textLabel?.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.semibold)
        }.cellUpdate { cell, _ in
            cell.textLabel?.textColor = Color.Theme.accent
        }.onCellSelection { _, _ in
            self.coordinate(.startPrayer)
        }

        form.append(startSection)
    }

    private func setupFAQButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: l10n.FaqButton.title, style: .plain, target: self, action: #selector(didPressFAQButton))
    }

    @objc
    func didPressFAQButton() {
        coordinate(.didPressFAQButton)
    }

    func showRestartConfirmDialog() {
        let localL10n = l10n.ConfirmAlert.self

        let confirmAlertCtrl = UIAlertController(title: localL10n.title, message: localL10n.message, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: localL10n.Action.confirm, style: .destructive) { _ in
            self.coordinate(.confirmRestart)
        }

        confirmAlertCtrl.addAction(confirmAction)

        let laterAction = UIAlertAction(title: localL10n.Action.later, style: .cancel, handler: nil)
        confirmAlertCtrl.addAction(laterAction)

        present(confirmAlertCtrl, animated: true, completion: nil)
    }
}
