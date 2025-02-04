import Foundation
import AppsOnAir_Core


@available(iOS 13.0, *)
class AppLinkApiService {
    //Core service
    private static var appsOnAirCoreServices = AppLinkService.shared.appsOnAirCoreServices
    
    /// API for getting Short Link
    @objc static func apiGenerateShortLink(
        url: String? = nil,
        prefixUrl: String? = nil,
        customParams: [String: Any]? = nil,
        socialMeta: [String: Any]? = nil,
        analytics: [String: Any]? = nil,
        isShortLink: Bool = true,
        androidFallbackUrl: String? = nil,
        iOSFallbackUrl: String? = nil,
        completion: @escaping (NSDictionary) -> Void
    ) {
        
        // server URL from EnvironmentConfig
        guard let generateShortLink = URL(string: EnvironmentConfig.getShortLink) else {
            Logger.logInternal(errorURL)
            completion([:]) // Call completion with empty dictionary on failure
            return
        }
        
        var request = URLRequest(url: generateShortLink)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // get AppId from Core Services
        
        let appsOnAirAppId = appsOnAirCoreServices.appId
        
        // Building JSON object
        var apiShortLinkPassData: [String: Any] = [
            "appsonairId": appsOnAirAppId,
            "isShortLink": isShortLink
        ]
        
        if let url = url {
            apiShortLinkPassData["url"] = url
        }
        if let prefixUrl = prefixUrl {
            apiShortLinkPassData["prefixUrl"] = prefixUrl
        }
        if let customParams = customParams {
            apiShortLinkPassData["customParams"] = customParams
        }
        if let socialMeta = socialMeta {
            apiShortLinkPassData["socialMeta"] = socialMeta
        }
        if let analytics = analytics {
            apiShortLinkPassData["analytics"] = analytics
        }
        if let androidFallbackUrl = androidFallbackUrl {
            apiShortLinkPassData["androidFallbackUrl"] = androidFallbackUrl
        }
        if let iOSFallbackUrl = iOSFallbackUrl {
            apiShortLinkPassData["iOSFallbackUrl"] = iOSFallbackUrl
        }
        
        let shortLinkParams = apiShortLinkPassData
        let httpBody = try? JSONSerialization.data(withJSONObject: shortLinkParams, options: [])
        request.httpBody = httpBody
        
        if(!(appsOnAirAppId.isEmpty)){
            
            URLSession.shared.dataTask(with: request) { responseData, response, error in
                do {
                    var linkData:NSDictionary = [:]
                    
                    Logger.logInternal("\(String(describing: url)) = \(generateShortLink)")
                    
                    // make sure this JSON is in the format we expect
                    // convert data to json
                    if let responseData = responseData, !(responseData.isEmpty) {
                        Logger.logInternal("\(String(describing: url)) = \(String(describing: responseData))")
                        
                        if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] {
                            Logger.logInternal(" \(responseJson) \(json)")
                            
                            if let httpResponse = response as? HTTPURLResponse {
                                if httpResponse.statusCode == 200 {
                                    linkData = json as NSDictionary
                                } else {
                                    Logger.logInternal("\(failedGetResponse) \(statusCode) \(httpResponse.statusCode) : \(httpResponse.description)")
                                    linkData = [errorStr:errorSomeThingWrong]
                                }
                            }
                        }
                    }
                    completion(linkData)
                } catch let error as NSError {
                    Logger.logInternal("\(failedToLoad) \(error.localizedDescription)")
                    completion([errorStr:errorSomeThingWrong])
                }
            }.resume()
        }else{
            completion([:])
        }
    }
    
    /// API for fetch app Link
    @objc public static func fetchAppLink(linkId: String, completion: @escaping (NSDictionary) -> Void) {
        // Replace with the actual app link URL
        guard let appLinkURL = URL(string: EnvironmentConfig.getAppLink) else {
            Logger.logInternal(errorURL)
            completion([:])
            return
        }
        
        var request = URLRequest(url: appLinkURL)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
//        var systemInfo:[String:Any] = [:]
//        
//        let deviceInfo:[String:Any] = appsOnAirCoreServices.getDeviceInfo()["deviceInfo"] as? [String : Any] ?? [:]
//        let appInfo:[String:Any] = appsOnAirCoreServices.getDeviceInfo()["appInfo"] as? [String : Any]  ?? [:]
//        
//        systemInfo.merge(appInfo){ (_, appDetails) in appDetails }
//        systemInfo.merge(deviceInfo) { (_, deviceDetails) in deviceDetails }
        
        // Prepare the request payload
        let appLinkParams: [String: Any] = [
            "where": [
                "linkId": linkId
            ],
            "data": [
                // "deviceInfo" : systemInfo,
                "deviceInfo": appsOnAirCoreServices.getDeviceInfo()["deviceInfo"],
                "appInfo": appsOnAirCoreServices.getDeviceInfo()["appInfo"],
            ]
        ]
        
        let httpBody = try? JSONSerialization.data(withJSONObject: appLinkParams, options: [])
        request.httpBody = httpBody
        
        
        URLSession.shared.dataTask(with: request) { responseData, response, error in
            do {
                var appLinkData:NSDictionary = [:]
                
                Logger.logInternal("\(String(describing: url)) = \(appLinkURL)")
                
                // make sure this JSON is in the format we expect
                // convert data to json
                if let responseData = responseData, !(responseData.isEmpty) {
                    Logger.logInternal("\(String(describing: url)) = \(String(describing: responseData))")
                    
                    if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] {
                        Logger.logInternal(" \(responseJson) \(json)")
                        
                        if let httpResponse = response as? HTTPURLResponse {
                            if httpResponse.statusCode == 200 {
                                appLinkData =  json as NSDictionary
                            } else {
                                Logger.logInternal("\(failedGetResponse) \(statusCode) \(httpResponse.statusCode) : \(httpResponse.description)")
                            }
                        }
                    }
                }
                completion(appLinkData)
            } catch let error as NSError {
                Logger.logInternal("\(failedToLoad) \(error.localizedDescription)")
                completion([:])
            }
        }.resume()
    }
}
