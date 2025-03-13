import Foundation
import SwiftData

enum DataError: Error {
    case saveError(String)
    case loadError(String)
    case migrationError(String)
}

class DataManager {
    static let shared = DataManager()
    
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    private init() {
        do {
            // 创建模型配置
            let schema = Schema([
                SalaryConfig.self,
                HolidayConfig.self
            ])
            
            // 创建模型容器
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: DataMigrationPlan.self
            )
            
            // 创建模型上下文
            modelContext = ModelContext(modelContainer)
        } catch {
            fatalError("Failed to initialize DataManager: \(error)")
        }
    }
    
    // MARK: - 数据操作
    
    // 保存数据
    func save() throws {
        do {
            try modelContext.save()
        } catch {
            throw DataError.saveError("Failed to save data: \(error)")
        }
    }
    
    // 获取所有工资配置
    func fetchSalaryConfigs() throws -> [SalaryConfig] {
        let descriptor = FetchDescriptor<SalaryConfig>()
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataError.loadError("Failed to fetch salary configs: \(error)")
        }
    }
    
    // 获取所有节假日配置
    func fetchHolidayConfigs() throws -> [HolidayConfig] {
        let descriptor = FetchDescriptor<HolidayConfig>()
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataError.loadError("Failed to fetch holiday configs: \(error)")
        }
    }
    
    // 添加工资配置
    func addSalaryConfig(_ config: SalaryConfig) throws {
        modelContext.insert(config)
        try save()
    }
    
    // 添加节假日配置
    func addHolidayConfig(_ config: HolidayConfig) throws {
        modelContext.insert(config)
        try save()
    }
    
    // 删除工资配置
    func deleteSalaryConfig(_ config: SalaryConfig) throws {
        modelContext.delete(config)
        try save()
    }
    
    // 删除节假日配置
    func deleteHolidayConfig(_ config: HolidayConfig) throws {
        modelContext.delete(config)
        try save()
    }
    
    // 更新工资配置
    func updateSalaryConfig(_ config: SalaryConfig) throws {
        try save()
    }
    
    // 更新节假日配置
    func updateHolidayConfig(_ config: HolidayConfig) throws {
        try save()
    }
    
    // MARK: - 数据备份和恢复
    
    // 导出数据
    func exportData() throws -> Data {
        let configs = try fetchSalaryConfigs()
        let holidays = try fetchHolidayConfigs()
        
        let exportData = ExportData(
            salaryConfigs: configs,
            holidayConfigs: holidays
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            return try encoder.encode(exportData)
        } catch {
            throw DataError.saveError("Failed to encode export data: \(error)")
        }
    }
    
    // 导入数据
    func importData(_ data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let importData = try decoder.decode(ExportData.self, from: data)
            
            // 删除现有数据
            let salaryConfigs = try fetchSalaryConfigs()
            let holidayConfigs = try fetchHolidayConfigs()
            
            salaryConfigs.forEach { modelContext.delete($0) }
            holidayConfigs.forEach { modelContext.delete($0) }
            
            // 导入新数据
            importData.salaryConfigs.forEach { modelContext.insert($0) }
            importData.holidayConfigs.forEach { modelContext.insert($0) }
            
            try save()
        } catch {
            throw DataError.loadError("Failed to decode import data: \(error)")
        }
    }
}

// MARK: - 数据迁移计划

enum DataMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] = [
        SchemaV1.self,
        SchemaV2.self
    ]
    
    static var stages: [MigrationStage] = [
        MigrationStage.custom(
            fromVersion: SchemaV1.self,
            toVersion: SchemaV2.self,
            willMigrate: { context in
                // 迁移前的准备工作
            },
            didMigrate: { context in
                // 迁移后的清理工作
            }
        )
    ]
    
    enum SchemaV1: VersionedSchema {
        static var versionIdentifier: Schema.Version = Schema.Version(1, 0, 0)
        
        static var models: [any PersistentModel.Type] = [
            SalaryConfig.self,
            HolidayConfig.self
        ]
    }
    
    enum SchemaV2: VersionedSchema {
        static var versionIdentifier: Schema.Version = Schema.Version(2, 0, 0)
        
        static var models: [any PersistentModel.Type] = [
            SalaryConfig.self,
            HolidayConfig.self
        ]
    }
}

// MARK: - 数据导出/导入模型

struct ExportData: Codable {
    let salaryConfigs: [SalaryConfig]
    let holidayConfigs: [HolidayConfig]
} 