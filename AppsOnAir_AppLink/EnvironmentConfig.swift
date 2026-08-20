struct EnvironmentConfig {

    // MARK: - Server API URL:
    static let serverBaseURl = "https://server.appsonair.link/api"

    // MARK: - API Endpoints:

    static let createShortLink = serverBaseURl + "/dynamic-link"

    static let getLinkInfo = createShortLink + "/"

    static let getAnalytics = serverBaseURl + "/dynamic-link-analytics"

    static let getReferral = createShortLink + "/referral/details"
}
