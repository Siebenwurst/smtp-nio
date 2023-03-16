import struct Foundation.Locale
import class Foundation.DateFormatter

// RFC 2822
let rfc2822DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
    return dateFormatter
}()
