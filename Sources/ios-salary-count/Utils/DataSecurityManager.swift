import Foundation
import CryptoKit

enum DataSecurityError: Error {
    case encryptionError(String)
    case decryptionError(String)
    case validationError(String)
    case integrityError(String)
}

class DataSecurityManager {
    static let shared = DataSecurityManager()
    
    private let keychain = KeychainManager.shared
    private let encryptionKey: SymmetricKey
    
    private init() {
        // 从 Keychain 获取或生成加密密钥
        if let keyData = keychain.getEncryptionKey() {
            encryptionKey = SymmetricKey(data: keyData)
        } else {
            let newKey = SymmetricKey(size: .bits256)
            keychain.saveEncryptionKey(newKey.withUnsafeBytes { Data($0) })
            encryptionKey = newKey
        }
    }
    
    // MARK: - 数据加密
    
    func encrypt(_ data: Data) throws -> Data {
        do {
            let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
            return sealedBox.combined ?? Data()
        } catch {
            throw DataSecurityError.encryptionError("加密失败: \(error.localizedDescription)")
        }
    }
    
    func decrypt(_ data: Data) throws -> Data {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealedBox, using: encryptionKey)
        } catch {
            throw DataSecurityError.decryptionError("解密失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 数据验证
    
    func validateSalaryConfig(_ config: SalaryConfig) throws {
        // 验证月薪
        guard config.monthlySalary > 0 else {
            throw DataSecurityError.validationError("月薪必须大于0")
        }
        
        // 验证工作时间
        guard config.workStartTime < config.workEndTime else {
            throw DataSecurityError.validationError("工作时间设置无效")
        }
        
        // 验证午休时间
        if let lunchStart = config.lunchStartTime,
           let lunchEnd = config.lunchEndTime {
            guard lunchStart < lunchEnd else {
                throw DataSecurityError.validationError("午休时间设置无效")
            }
            guard lunchStart > config.workStartTime && lunchEnd < config.workEndTime else {
                throw DataSecurityError.validationError("午休时间必须在工作时间内")
            }
        }
        
        // 验证工作日设置
        guard !config.workDays.isEmpty else {
            throw DataSecurityError.validationError("工作日设置不能为空")
        }
        
        // 验证加班时间
        if let overtimeStart = config.overtimeStartTime,
           let overtimeEnd = config.overtimeEndTime {
            guard overtimeStart < overtimeEnd else {
                throw DataSecurityError.validationError("加班时间设置无效")
            }
        }
        
        // 验证加班倍率
        guard config.overtimeRate >= 1.0 else {
            throw DataSecurityError.validationError("加班倍率必须大于等于1")
        }
        
        // 验证节假日加班倍率
        guard config.holidayOvertimeRate >= 1.0 else {
            throw DataSecurityError.validationError("节假日加班倍率必须大于等于1")
        }
    }
    
    func validateHolidayConfig(_ config: HolidayConfig) throws {
        // 验证日期
        guard config.date > Date() else {
            throw DataSecurityError.validationError("节假日日期必须大于当前日期")
        }
        
        // 验证节日名称
        guard !config.name.isEmpty else {
            throw DataSecurityError.validationError("节日名称不能为空")
        }
    }
    
    // MARK: - 数据完整性检查
    
    func checkDataIntegrity(salaryConfigs: [SalaryConfig], holidayConfigs: [HolidayConfig]) throws {
        // 检查工资配置的唯一性
        let uniqueConfigs = Set(salaryConfigs.map { $0.id })
        guard uniqueConfigs.count == salaryConfigs.count else {
            throw DataSecurityError.integrityError("存在重复的工资配置")
        }
        
        // 检查节假日配置的唯一性
        let uniqueHolidays = Set(holidayConfigs.map { $0.date })
        guard uniqueHolidays.count == holidayConfigs.count else {
            throw DataSecurityError.integrityError("存在重复的节假日配置")
        }
        
        // 检查节假日日期范围
        let now = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: now)
        
        for holiday in holidayConfigs {
            let holidayYear = calendar.component(.year, from: holiday.date)
            guard holidayYear == year else {
                throw DataSecurityError.integrityError("节假日日期超出当前年份范围")
            }
        }
    }
    
    // MARK: - 数据备份
    
    func createBackup() throws -> Data {
        let dataManager = DataManager.shared
        
        // 获取所有数据
        let salaryConfigs = try dataManager.fetchSalaryConfigs()
        let holidayConfigs = try dataManager.fetchHolidayConfigs()
        
        // 验证数据完整性
        try checkDataIntegrity(salaryConfigs: salaryConfigs, holidayConfigs: holidayConfigs)
        
        // 创建备份数据
        let backupData = ExportData(
            salaryConfigs: salaryConfigs,
            holidayConfigs: holidayConfigs
        )
        
        // 编码数据
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encodedData = try encoder.encode(backupData)
        
        // 加密数据
        return try encrypt(encodedData)
    }
    
    func restoreFromBackup(_ backupData: Data) throws {
        let dataManager = DataManager.shared
        
        // 解密数据
        let decryptedData = try decrypt(backupData)
        
        // 解码数据
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let importData = try decoder.decode(ExportData.self, from: decryptedData)
        
        // 验证数据完整性
        try checkDataIntegrity(salaryConfigs: importData.salaryConfigs, holidayConfigs: importData.holidayConfigs)
        
        // 验证每个配置
        for config in importData.salaryConfigs {
            try validateSalaryConfig(config)
        }
        for config in importData.holidayConfigs {
            try validateHolidayConfig(config)
        }
        
        // 导入数据
        try dataManager.importData(decryptedData)
    }
} 