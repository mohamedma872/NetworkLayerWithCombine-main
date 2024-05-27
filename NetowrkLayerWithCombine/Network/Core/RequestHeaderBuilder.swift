import Foundation

enum ConnectionHeaders: String {
    case keepAlive = "keep-alive"
    case close = "close"
    var name: String {
        return "connection"
    }
}

enum AcceptHeaders: String {
    case all = "*/*"
    case applicationJson = "application/json"
    case applicationJsonUTF8 = "application/json; charset=utf-8"
    case text = "text/plain"
    case combinedAll = "application/json, text/plain, */*"
    var name: String {
        return "accept"
    }
}

enum ContentTypeHeaders: String {
    case applicationJson = "application/json"
    case applicationJsonUTF8 = "application/json; charset=utf-8"
    case urlEncoded = "application/x-www-form-urlencoded"
    case formData = "multipart/form-data"
    var name: String {
        return "content-type"
    }
}

enum AcceptEncodingHeaders: String {
    case gzip = "gzip"
    case compress = "compress"
    case deflate = "deflate"
    case br = "br"
    case identity = "identity"
    case all = "*"
    var name: String {
        return "accept-encoding"
    }
}

enum AcceptLanguageHeaders: String {
    case en = "en"
    case fa = "fa"
    case all = "*"
    var name: String {
        return "accept-language"
    }
}

enum AuthorizationHeaders: String {
    case basic = "Basic"
    case bearer = "Bearer"
    var name: String {
        return "authorization"
    }
}

// MARK: - RequestHeaderBuilder

class RequestHeaderBuilder {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = RequestHeaderBuilder()

    @discardableResult
    func addContentTypeHeader(type: ContentTypeHeaders) -> RequestHeaderBuilder {
        self.headers.updateValue(type.rawValue, forKey: type.name)
        return self
    }

    @discardableResult
    func addConnectionHeader(type: ConnectionHeaders) -> RequestHeaderBuilder {
        self.headers.updateValue(type.rawValue, forKey: type.name)
        return self
    }

    @discardableResult
    func addAcceptHeaders(type: AcceptHeaders) -> RequestHeaderBuilder {
        self.headers.updateValue(type.rawValue, forKey: type.name)
        return self
    }

    @discardableResult
    func addAcceptLanguageHeaders(type: AcceptLanguageHeaders) -> RequestHeaderBuilder {
        self.headers.updateValue(type.rawValue, forKey: type.name)
        return self
    }

    @discardableResult
    func addAcceptEncodingHeaders(type: AcceptEncodingHeaders) -> RequestHeaderBuilder {
        self.headers.updateValue(type.rawValue, forKey: type.name)
        return self
    }

    @discardableResult
    func addAuthorizationHeader(type: AuthorizationHeaders) -> RequestHeaderBuilder {
        let token = "" // Replace with actual token logic
        self.headers.updateValue("\(type.rawValue) \(token)", forKey: type.name)
        return self
    }

    @discardableResult
    func addCustomHeaders(headers: [String: String]) -> RequestHeaderBuilder {
        for (key, value) in headers {
            self.headers.updateValue(value, forKey: key)
        }
        return self
    }

    @discardableResult
    func addCustomHeader(name: String, value: String) -> RequestHeaderBuilder {
        self.headers.updateValue(value, forKey: name)
        return self
    }

    func build() -> [String: String] {
        return self.headers
    }

    // MARK: Private

    private var headers: [String: String] = .init()
}
