import Foundation

func parseFlatJSON(data: Data) throws -> [String: String] {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) else {
            throw TolgeeError.invalidJSONString
        }

        guard let jsonDict = jsonObject as? [String: String] else {
            throw TolgeeError.invalidJSONString
        }

        return jsonDict
    }
}