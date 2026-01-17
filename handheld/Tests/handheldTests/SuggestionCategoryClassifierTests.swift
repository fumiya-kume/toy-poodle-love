import Testing
@testable import handheld

struct SuggestionCategoryClassifierTests {
    // MARK: - 駅パターン

    @Test func classify_stationInJapanese_returnsStation() {
        let result = SuggestionCategoryClassifier.classify(title: "東京駅", subtitle: "")
        #expect(result == .station)
    }

    @Test func classify_stationInEnglish_returnsStation() {
        let result = SuggestionCategoryClassifier.classify(title: "Tokyo Station", subtitle: "")
        #expect(result == .station)
    }

    @Test func classify_stationAbbreviation_returnsStation() {
        let result = SuggestionCategoryClassifier.classify(title: "Shibuya Sta.", subtitle: "")
        #expect(result == .station)
    }

    @Test func classify_busStop_returnsStation() {
        let result = SuggestionCategoryClassifier.classify(title: "渋谷停留所", subtitle: "")
        #expect(result == .station)
    }

    @Test func classify_terminal_returnsStation() {
        let result = SuggestionCategoryClassifier.classify(title: "新宿バスターミナル", subtitle: "")
        #expect(result == .station)
    }

    // MARK: - ホテルパターン

    @Test func classify_hotelInJapanese_returnsHotel() {
        let result = SuggestionCategoryClassifier.classify(title: "東京ホテル", subtitle: "")
        #expect(result == .hotel)
    }

    @Test func classify_hotelInEnglish_returnsHotel() {
        let result = SuggestionCategoryClassifier.classify(title: "Tokyo Hotel", subtitle: "")
        #expect(result == .hotel)
    }

    @Test func classify_ryokan_returnsHotel() {
        let result = SuggestionCategoryClassifier.classify(title: "草津温泉旅館", subtitle: "")
        #expect(result == .hotel)
    }

    @Test func classify_guesthouse_returnsHotel() {
        let result = SuggestionCategoryClassifier.classify(title: "京都ゲストハウス", subtitle: "")
        #expect(result == .hotel)
    }

    @Test func classify_inn_returnsHotel() {
        let result = SuggestionCategoryClassifier.classify(title: "Hakone Inn", subtitle: "")
        #expect(result == .hotel)
    }

    // MARK: - レストランパターン

    @Test func classify_restaurantInJapanese_returnsRestaurant() {
        let result = SuggestionCategoryClassifier.classify(title: "イタリアンレストラン", subtitle: "")
        #expect(result == .restaurant)
    }

    @Test func classify_cafe_returnsRestaurant() {
        let result = SuggestionCategoryClassifier.classify(title: "スターバックスカフェ", subtitle: "")
        #expect(result == .restaurant)
    }

    @Test func classify_ramen_returnsRestaurant() {
        let result = SuggestionCategoryClassifier.classify(title: "一蘭ラーメン", subtitle: "")
        #expect(result == .restaurant)
    }

    @Test func classify_izakaya_returnsRestaurant() {
        let result = SuggestionCategoryClassifier.classify(title: "和民居酒屋", subtitle: "")
        #expect(result == .restaurant)
    }

    @Test func classify_sushi_returnsRestaurant() {
        let result = SuggestionCategoryClassifier.classify(title: "築地寿司", subtitle: "")
        #expect(result == .restaurant)
    }

    // MARK: - 病院パターン

    @Test func classify_hospitalInJapanese_returnsHospital() {
        let result = SuggestionCategoryClassifier.classify(title: "東京大学病院", subtitle: "")
        #expect(result == .hospital)
    }

    @Test func classify_clinic_returnsHospital() {
        let result = SuggestionCategoryClassifier.classify(title: "山田クリニック", subtitle: "")
        #expect(result == .hospital)
    }

    @Test func classify_pharmacy_returnsHospital() {
        let result = SuggestionCategoryClassifier.classify(title: "マツモトキヨシ薬局", subtitle: "")
        #expect(result == .hospital)
    }

    @Test func classify_dentist_returnsHospital() {
        let result = SuggestionCategoryClassifier.classify(title: "田中歯科", subtitle: "")
        #expect(result == .hospital)
    }

    // MARK: - 公園パターン

    @Test func classify_parkInJapanese_returnsPark() {
        let result = SuggestionCategoryClassifier.classify(title: "代々木公園", subtitle: "")
        #expect(result == .park)
    }

    @Test func classify_garden_returnsPark() {
        let result = SuggestionCategoryClassifier.classify(title: "浜離宮庭園", subtitle: "")
        #expect(result == .park)
    }

    @Test func classify_parkInEnglish_returnsPark() {
        let result = SuggestionCategoryClassifier.classify(title: "Ueno Park", subtitle: "")
        #expect(result == .park)
    }

    // MARK: - ショッピングパターン

    @Test func classify_mall_returnsShopping() {
        let result = SuggestionCategoryClassifier.classify(title: "イオンモール", subtitle: "")
        #expect(result == .shopping)
    }

    @Test func classify_departmentStore_returnsShopping() {
        let result = SuggestionCategoryClassifier.classify(title: "三越百貨店", subtitle: "")
        #expect(result == .shopping)
    }

    @Test func classify_supermarket_returnsShopping() {
        let result = SuggestionCategoryClassifier.classify(title: "イトーヨーカドースーパー", subtitle: "")
        #expect(result == .shopping)
    }

    @Test func classify_convenienceStore_returnsShopping() {
        let result = SuggestionCategoryClassifier.classify(title: "セブンイレブンコンビニ", subtitle: "")
        #expect(result == .shopping)
    }

    // MARK: - 特殊ケース

    @Test func classify_nearbySearch_returnsSearchQuery() {
        let result = SuggestionCategoryClassifier.classify(title: "ラーメン", subtitle: "近くを検索")
        #expect(result == .searchQuery)
    }

    @Test func classify_withAddressSubtitle_returnsPoi() {
        // Use a subtitle without pattern keywords to test POI fallback
        let result = SuggestionCategoryClassifier.classify(title: "東京タワー", subtitle: "東京都港区芝4丁目")
        #expect(result == .poi)
    }

    @Test func classify_noPatternMatch_returnsGeneric() {
        let result = SuggestionCategoryClassifier.classify(title: "何か", subtitle: "")
        #expect(result == .generic)
    }

    // MARK: - 大文字小文字

    @Test func classify_caseInsensitive_works() {
        let result1 = SuggestionCategoryClassifier.classify(title: "TOKYO STATION", subtitle: "")
        let result2 = SuggestionCategoryClassifier.classify(title: "tokyo station", subtitle: "")
        #expect(result1 == .station)
        #expect(result2 == .station)
    }

    // MARK: - title + subtitle の組み合わせ

    @Test func classify_patternInSubtitle_works() {
        let result = SuggestionCategoryClassifier.classify(title: "ABC", subtitle: "東京駅近く")
        #expect(result == .station)
    }
}
