import Foundation
import WebKit
import AppsOnAir_Core

internal class AppLinkApiService {
    static let appHelper = AppLinkService.shared.appHelper
    
    
    private static func getURLFromString(urlString: String) -> URL{
        if #available(iOS 16.0, *) {
            return URL(string: urlString) ?? URL(filePath: "")
        } else {
            return URL(string: urlString) ?? URL(fileURLWithPath: "")
        }
    }
    
    //Core service
    private static var appsOnAirCoreServices = AppLinkService.shared.appsOnAirCoreServices
    
    /// API for getting Short Link
    /// If [isOpenInAndroidApp] and [isOpenInIosApp] are false,
    /// then [isOpenInBrowserAndroid] and [isOpenInBrowserApple] must be true.
    /// Otherwise, an error will be thrown.
    ///
    internal static func apiGenerateShortLink(
        url: String,
        name: String,
        urlPrefix: String,
        shortId: String? = nil,
        socialMeta: [String: Any]? = nil,
        isOpenInBrowserApple: Bool? = nil,
        isOpenInIosApp: Bool? = nil,
        iosFallbackUrl: String? = nil,
        isOpenInAndroidApp: Bool? = nil,
        isOpenInBrowserAndroid: Bool? = nil,
        androidFallbackUrl: String? = nil,
        completion: @escaping ([String:Any]) -> Void
    ) {
        
        if(appsOnAirCoreServices.appId.trimmed.isEmpty){
            Logger.logInfo(errorAppIdMissing, prefix: appsOnAirLink)
            completion([errorStr: errorAppIdMissing])
            return
        }
        
        // server URL from EnvironmentConfig
        let generateShortLink = self.getURLFromString(urlString: EnvironmentConfig.createShortLink)
        
        var request = URLRequest(url: generateShortLink)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appsOnAirCoreServices.appId, forHTTPHeaderField: xApplicationId)
        
        
        // Building JSON object
        var shortLinkData: [String: Any] = [:]
        
        shortLinkData["name"] = name
        shortLinkData["link"] = url
        
        if let shortId = shortId {
            shortLinkData["shortId"] = shortId
        }
        
        if !(socialMeta?.isEmpty ?? false) {
            shortLinkData["socialMetaTags"] = socialMeta
        }
        
        //IOS Params
        shortLinkData["isOpenInBrowserApple"] = isOpenInBrowserApple
        shortLinkData["isOpenInIosApp"] = isOpenInIosApp
        if let iosFallbackUrl = iosFallbackUrl {
            shortLinkData["customUrlForIos"] = iosFallbackUrl
        }
        
        //Android Params
        shortLinkData["isOpenInBrowserAndroid"] = isOpenInBrowserAndroid
        shortLinkData["isOpenInAndroidApp"] = isOpenInAndroidApp
        if let customUrlForAndroid = androidFallbackUrl {
            shortLinkData["customUrlForAndroid"] = customUrlForAndroid
        }
        
        let apiShortLinkPassData: [String: Any] = [
            "where": ["urlPrefix":urlPrefix],
            "data": shortLinkData
        ]
        
        let httpBody = try? JSONSerialization.data(withJSONObject: apiShortLinkPassData, options: [])
        request.httpBody = httpBody
        
        URLSession.shared.dataTask(with: request) { responseData, response, error in
            
            Logger.logInternal("\(String(describing: url)) = \(generateShortLink)")
            
            let httpResponse = response as? HTTPURLResponse
            
            let statusCode = httpResponse?.statusCode
            do {
                guard let responseData = responseData, !responseData.isEmpty else {
                    completion([errorStr: errorSomeThingWrong])
                    return
                }
                
                Logger.logInternal("\(String(describing: url)) = \(responseData)")
                
                if statusCode == 429 {
                    let errorMessage = String(data: responseData, encoding: .utf8) ?? ""
                    completion([errorStr: errorMessage])
                } else if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] {
                    Logger.logInternal("\(responseJson) \(json)")
                    completion(json)
                }
            } catch {
                Logger.logInternal("\(errorFailedToLoad) \(error.localizedDescription)")
                completion([errorStr: errorSomeThingWrong])
            }
            
        }.resume()
    }
    
    /// API for fetch referral link
    @objc internal static func apiReferralInfo(completion: @escaping ([String:Any]) -> Void) {
        if(appsOnAirCoreServices.appId.isEmpty){
            Logger.logInfo(errorAppIdMissing, prefix: appsOnAirLink)
            completion([errorStr: errorAppIdMissing])
            return
        }
        
        // server URL from EnvironmentConfig
        let generateReferralLink = self.getURLFromString(urlString: EnvironmentConfig.getReferral)
        
        var request = URLRequest(url: generateReferralLink)
        
        appHelper.getUserAgent { linkUserAgent in
            request.httpMethod = "GET"
            
            request.setValue(linkUserAgent, forHTTPHeaderField: userAgent)
            request.setValue("application/json", forHTTPHeaderField: contentType)
            request.setValue(appsOnAirCoreServices.appId, forHTTPHeaderField: xApplicationId)
            
            URLSession.shared.dataTask(with: request) { responseData, response, error in
                
                Logger.logInternal("\(String(describing: url)) = \(generateReferralLink)")
                
                let httpResponse = response as? HTTPURLResponse
                
                let statusCode = httpResponse?.statusCode
                do {
                    guard let responseData = responseData, !responseData.isEmpty else {
                        completion([errorStr: errorSomeThingWrong])
                        return
                    }
                    
                    Logger.logInternal("\(String(describing: url)) = \(responseData)")
                    
                    if statusCode == 429 {
                        let errorMessage = String(data: responseData, encoding: .utf8) ?? ""
                        Logger.logInfo(errorMessage,prefix: appsOnAirLink)
                        completion([errorStr: errorMessage])
                    } else if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] {
                        Logger.logInternal("\(responseJson) \(json)")
                        completion(json)
                    }
                } catch {
                    Logger.logInternal("\(errorFailedToLoad) \(error.localizedDescription)")
                    completion([errorStr: errorSomeThingWrong])
                }
                
            }.resume()
        }
    }
    
    /// API for Get Config ID from AppId
    @objc internal static func apiLinkAnalytics(isClicked:Bool,urlPrefix: String,
                                                shortId: String? = nil,  completion: @escaping ([String:Any]) -> Void) {
        
        if(appsOnAirCoreServices.appId.isEmpty){
            Logger.logInfo(errorAppIdMissing, prefix: appsOnAirLink)
            completion([errorStr: errorAppIdMissing])
            return
        }
        
        // server URL from EnvironmentConfig
        let generateShortLink = self.getURLFromString(urlString: EnvironmentConfig.getAnalytics)
        
        var request = URLRequest(url: generateShortLink)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appsOnAirCoreServices.appId, forHTTPHeaderField: xApplicationId)
        
        let apiShortLinkPassData: [String: Any] = [
            "shortId": shortId as Any,
            "domain": urlPrefix,
            "isClicked": isClicked,
            "isInstalled":  appHelper.isUserReferral,
            "isFirstOpen":  appHelper.isUserReferral,
            "isReOpen":   !appHelper.isUserReferral && !appHelper.isAppFirstOpen
        ]
        
        let httpBody = try? JSONSerialization.data(withJSONObject: apiShortLinkPassData, options: [])
        request.httpBody = httpBody
        
        URLSession.shared.dataTask(with: request) { responseData, response, error in
            
            Logger.logInternal("\(String(describing: url)) = \(generateShortLink)")
            
            let httpResponse = response as? HTTPURLResponse
            
            let statusCode = httpResponse?.statusCode
            do {
                guard let responseData = responseData, !responseData.isEmpty else {
                    completion([errorStr: errorSomeThingWrong])
                    return
                }
                
                Logger.logInternal("\(String(describing: url)) = \(responseData)")
                
                if statusCode == 429 {
                    let errorMessage = String(data: responseData, encoding: .utf8) ?? ""
                    Logger.logInfo(errorMessage,prefix: appsOnAirLink)
                    completion([errorStr: errorMessage])
                } else if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] {
                    Logger.logInternal("\(responseJson) \(json)")
                    completion(json)
                }
            } catch {
                Logger.logInternal("\(errorFailedToLoad) \(error.localizedDescription)")
                completion([errorStr: errorSomeThingWrong])
            }
            
        }.resume()
    }
    
    /// API for fetch Link Info
    @objc internal static func apiFetchLinkInfo(domain:String,linkId:String, completion: @escaping ([String:Any]) -> Void) {
        
        if(appsOnAirCoreServices.appId.trimmed.isEmpty){
            Logger.logInfo(errorAppIdMissing, prefix: appsOnAirLink)
            completion([errorStr: errorAppIdMissing])
            return
        }
        
        let linkURL :URL = self.getURLFromString(urlString: EnvironmentConfig.getLinkInfo + linkId)
        var linkURLComponents = URLComponents(url: linkURL, resolvingAgainstBaseURL: false)!
        linkURLComponents.queryItems = [
            URLQueryItem(name: "domain", value: domain)
        ]
        
        Logger.logInternal("\(url): \(String(describing: linkURL))")
        guard let appLinkURL = linkURLComponents.url else { return }
        var request = URLRequest(url: appLinkURL)
        
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appsOnAirCoreServices.appId, forHTTPHeaderField: "x-application-key")
        
        URLSession.shared.dataTask(with: request) { responseData, response, error in
            Logger.logInternal("\(String(describing: url)) = \(linkURL)")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                Logger.logInternal(errorResponse)
                completion([errorStr: errorSomeThingWrong])
                return
            }
            
            let statusCode = httpResponse.statusCode
            do {
                guard let responseData = responseData, !responseData.isEmpty else {
                    completion([errorStr: errorSomeThingWrong])
                    return
                }
                
                Logger.logInternal("\(String(describing: url)) = \(responseData)")
                
                if statusCode == 429 {
                    let errorMessage = String(data: responseData, encoding: .utf8) ?? ""
                    completion([errorStr: errorMessage])
                } else if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] {
                    Logger.logInternal("\(responseJson) \(json)")
                    completion(json)
                }
            } catch {
                Logger.logInternal("\(errorFailedToLoad) \(error.localizedDescription)")
                completion([errorStr: errorSomeThingWrong])
            }
            
        }.resume()
    }
}
