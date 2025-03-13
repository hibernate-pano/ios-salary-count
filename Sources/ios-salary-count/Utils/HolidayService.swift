import Foundation

enum HolidayError: Error {
    case networkError(String)
    case invalidData
    case serverError(String)
}

class HolidayService {
    static let shared = HolidayService()
    private let baseURL = "https://api.apihubs.cn/holiday/get"
    private let cacheKey = "holiday_cache"
    
    private init() {}
    
    // 获取指定年份的节假日数据
    func fetchHolidays(year: Int) async throws -> [HolidayConfig] {
        // 1. 检查缓存
        if let cachedHolidays = getCachedHolidays(year: year) {
            return cachedHolidays
        }
        
        // 2. 构建请求URL
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "year", value: String(year)),
            URLQueryItem(name: "workday", value: "1"), // 包含调休工作日
            URLQueryItem(name: "holiday", value: "1")  // 包含节假日
        ]
        
        guard let url = components.url else {
            throw HolidayError.invalidData
        }
        
        // 3. 发起网络请求
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HolidayError.networkError("Invalid response type")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw HolidayError.serverError("Server returned status code \(httpResponse.statusCode)")
        }
        
        // 4. 解析数据
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        struct HolidayResponse: Codable {
            let code: Int
            let msg: String
            let data: HolidayData
        }
        
        struct HolidayData: Codable {
            let list: [HolidayItem]
        }
        
        struct HolidayItem: Codable {
            let date: String
            let name: String
            let isWorkday: Int
        }
        
        let holidayResponse = try decoder.decode(HolidayResponse.self, from: data)
        
        // 5. 转换为 HolidayConfig 对象
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let holidays = holidayResponse.data.list.compactMap { item -> HolidayConfig? in
            guard let date = dateFormatter.date(from: item.date) else { return nil }
            return HolidayConfig(
                date: date,
                name: item.name,
                isWorkday: item.isWorkday == 1
            )
        }
        
        // 6. 缓存数据
        cacheHolidays(holidays, year: year)
        
        return holidays
    }
    
    // 缓存节假日数据
    private func cacheHolidays(_ holidays: [HolidayConfig], year: Int) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(holidays)
            let cache = [
                "year": year,
                "data": data,
                "timestamp": Date()
            ] as [String : Any]
            
            UserDefaults.standard.set(cache, forKey: "\(cacheKey)_\(year)")
        } catch {
            print("Failed to cache holidays: \(error)")
        }
    }
    
    // 获取缓存的节假日数据
    private func getCachedHolidays(year: Int) -> [HolidayConfig]? {
        guard let cache = UserDefaults.standard.dictionary(forKey: "\(cacheKey)_\(year)"),
              let cachedYear = cache["year"] as? Int,
              cachedYear == year,
              let data = cache["data"] as? Data,
              let timestamp = cache["timestamp"] as? Date else {
            return nil
        }
        
        // 检查缓存是否过期（7天）
        let calendar = Calendar.current
        if let days = calendar.dateComponents([.day], from: timestamp, to: Date()).day,
           days > 7 {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode([HolidayConfig].self, from: data)
        } catch {
            print("Failed to decode cached holidays: \(error)")
            return nil
        }
    }
    
    // 清除指定年份的缓存
    func clearCache(year: Int) {
        UserDefaults.standard.removeObject(forKey: "\(cacheKey)_\(year)")
    }
    
    // 清除所有缓存
    func clearAllCache() {
        let defaults = UserDefaults.standard
        let keys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(cacheKey) }
        keys.forEach { defaults.removeObject(forKey: $0) }
    }
} 