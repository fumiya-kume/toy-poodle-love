import Testing
@testable import handheld

struct AutoDriveSpeedTests {
    // MARK: - intervalSeconds

    @Test func slow_intervalSeconds_returns5() {
        #expect(AutoDriveSpeed.slow.intervalSeconds == 5.0)
    }

    @Test func normal_intervalSeconds_returns3() {
        #expect(AutoDriveSpeed.normal.intervalSeconds == 3.0)
    }

    @Test func fast_intervalSeconds_returns1_5() {
        #expect(AutoDriveSpeed.fast.intervalSeconds == 1.5)
    }

    // MARK: - icon

    @Test func slow_icon_returnsTortoise() {
        #expect(AutoDriveSpeed.slow.icon == "tortoise.fill")
    }

    @Test func normal_icon_returnsCar() {
        #expect(AutoDriveSpeed.normal.icon == "car.fill")
    }

    @Test func fast_icon_returnsHare() {
        #expect(AutoDriveSpeed.fast.icon == "hare.fill")
    }

    // MARK: - rawValue

    @Test func slow_rawValue_isCorrect() {
        #expect(AutoDriveSpeed.slow.rawValue == "遅い")
    }

    @Test func normal_rawValue_isCorrect() {
        #expect(AutoDriveSpeed.normal.rawValue == "普通")
    }

    @Test func fast_rawValue_isCorrect() {
        #expect(AutoDriveSpeed.fast.rawValue == "速い")
    }

    // MARK: - id

    @Test func id_equalsRawValue() {
        #expect(AutoDriveSpeed.slow.id == AutoDriveSpeed.slow.rawValue)
        #expect(AutoDriveSpeed.normal.id == AutoDriveSpeed.normal.rawValue)
        #expect(AutoDriveSpeed.fast.id == AutoDriveSpeed.fast.rawValue)
    }

    // MARK: - CaseIterable

    @Test func allCases_containsThreeCases() {
        #expect(AutoDriveSpeed.allCases.count == 3)
    }
}
