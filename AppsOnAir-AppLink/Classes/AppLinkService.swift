import UIKit
import Foundation
import Combine
import AppsOnAir_Core


@available(iOS 13.0, *)
public final class AppLinkService: NSObject {
    public static let shared = AppLinkService()
    
    //Core Services initialization
    let appsOnAirCoreServices = AppsOnAirCoreServices()
    
    //network Error
    private let networkError = "Please check internet connection"
    
    //Latest link for Dynamic Link
    @Published var latestLink: String = ""
    
    private var getInitialLink: String?
    var initialLinkSet: Bool = false
    
    // Listener for whenever link is Update
    private var linkListener: AnyCancellable?
    
    deinit {
        // Cancel the listener when the object is deallocated
        linkListener?.cancel()
    }
    
    
    //initialize the common services like AppsOnAir-Core and swizzling method and fetch the latest Link
    ///fetch the latest link for universal link and custom URL schema
    @objc public func initialize(completion: @escaping (String) -> ()) {
        //initialize the AppsOnAir-core
        appsOnAirCoreServices.initialize()
        
        //initialize the Swizzling methods
        _ = AppDelegateSwizzler.shared
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.linkListener = self.$latestLink.sink { [weak self] _ in
                DispatchQueue.main.async {
                    if(!(self?.latestLink ?? "").isEmpty) {
                        completion(self?.latestLink ?? "" )
                    }
                }
            }
        }
    }
    
    @objc public func getShortLink(completion: @escaping (NSDictionary) -> Void) {
        DispatchQueue.main.async {
            if self.appsOnAirCoreServices.isNetworkConnected ?? false {
                // FIXME: - Change code for API changes 
                 AppLinkApiService.apiGenerateShortLink { shortLink in
                     // Write code for shortURL from server
                    completion(shortLink)
                }
            } else {
                Logger.logInfo(self.networkError, prefix: appsOnAirLink)
                completion([:])
            }
        }
    }
    
    //manage links form override methods
    func handleLink(url: URL) -> Void {
        let link = url.absoluteString
        if ((self.getInitialLink == nil || ((self.getInitialLink ?? "").isEmpty)) && initialLinkSet) {
            self.getInitialLink = link
        }else{
            self.latestLink = link
        }
        // FIXME: - Change code for API changes
        AppLinkApiService.fetchAppLink(linkId: "" ) { latestLinkData in
            // Write code of handle params from server
        }
    }
}

