import Foundation
import Testing

@testable import Tolgee

struct LocalLanguageToCdnLanguageTests {

    @Test func testSimpleLanguageCode() throws {
        let result = localLanguageToCdnLanguage("en")
        
        #expect(result == "en")
    }
    
    @Test func testLanguageWithRegionCode() throws {
        let result = localLanguageToCdnLanguage("pt-br")
        
        #expect(result == "pt-BR")
    }
    
    @Test func testEnglishUS() throws {
        let result = localLanguageToCdnLanguage("en-us")
        
        #expect(result == "en-US")
    }
    
    @Test func testChineseSimplified() throws {
        let result = localLanguageToCdnLanguage("zh-hans")
        
        #expect(result == "zh-Hans")
    }
    
    @Test func testChineseTraditional() throws {
        let result = localLanguageToCdnLanguage("zh-hant")
        
        #expect(result == "zh-Hant")
    }
    
    @Test func testChineseSimplifiedChina() throws {
        let result = localLanguageToCdnLanguage("zh-hans-cn")
        
        #expect(result == "zh-Hans-CN")
    }
    
    @Test func testChineseTraditionalHongKong() throws {
        let result = localLanguageToCdnLanguage("zh-hant-hk")
        
        #expect(result == "zh-Hant-HK")
    }
    
    @Test func testChineseTraditionalTaiwan() throws {
        let result = localLanguageToCdnLanguage("zh-hant-tw")
        
        #expect(result == "zh-Hant-TW")
    }
    
    @Test func testCzech() throws {
        let result = localLanguageToCdnLanguage("cs")
        
        #expect(result == "cs")
    }
    
    @Test func testCzechCzechRepublic() throws {
        let result = localLanguageToCdnLanguage("cs-cz")
        
        #expect(result == "cs-CZ")
    }
    
    @Test func testSpanishMexico() throws {
        let result = localLanguageToCdnLanguage("es-mx")
        
        #expect(result == "es-MX")
    }
    
    @Test func testFrenchCanada() throws {
        let result = localLanguageToCdnLanguage("fr-ca")
        
        #expect(result == "fr-CA")
    }
    
    @Test func testEnglishGreatBritain() throws {
        let result = localLanguageToCdnLanguage("en-gb")
        
        #expect(result == "en-GB")
    }
    
    @Test func testSerbianCyrillic() throws {
        let result = localLanguageToCdnLanguage("sr-cyrl")
        
        #expect(result == "sr-Cyrl")
    }
    
    @Test func testSerbianLatin() throws {
        let result = localLanguageToCdnLanguage("sr-latn")
        
        #expect(result == "sr-Latn")
    }
    
    @Test func testEmptyString() throws {
        let result = localLanguageToCdnLanguage("")
        
        #expect(result == "")
    }
    
    @Test func testAlreadyCapitalizedLanguageWithRegion() throws {
        let result = localLanguageToCdnLanguage("pt-BR")
        
        // Should still normalize to correct format
        #expect(result == "pt-BR")
    }
    
    @Test func testMixedCaseInput() throws {
        let result = localLanguageToCdnLanguage("PT-br")
        
        // Should normalize to correct format
        #expect(result == "pt-BR")
    }
}
