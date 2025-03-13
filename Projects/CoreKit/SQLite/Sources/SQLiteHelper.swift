import Foundation
import SQLite3


public class SQLiteHelper {
    public static let shared = SQLiteHelper()
    private var db: OpaquePointer?
    
    init() {
        openDatabase()
    }
    
    private func openDatabase() {
        let fileURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("coupleApp_ios.sqlite")
        
        if sqlite3_open(fileURL.path(), &db) != SQLITE_OK {
            print("sqlite3 open fail")
        }
    }
    
    // 객체 기반 테이블 생성
    func createTable(for object: Any, tableName: String) {
        let mirror = Mirror(reflecting: object)
        var columns: [String] = []
        
        for child in mirror.children {
            if let propertyName = child.label {
                let columnType = getSQLiteType(from: child.value)
                columns.append("\(propertyName) \(columnType)")
            }
        }

        let createTableQuery = "CREATE TABLE IF NOT EXISTS \(tableName) (id INTEGER PRIMARY KEY AUTOINCREMENT, \(columns.joined(separator: ", ")));"

        if sqlite3_exec(db, createTableQuery, nil, nil, nil) != SQLITE_OK {
            print("Error creating table \(tableName)")
        } else {
            print("Table \(tableName) created successfully")
        }
    }
    
    // SQLite 타입 변환
    private func getSQLiteType(from value: Any) -> String {
        switch value {
        case is Int:
            return "INTEGER"
        case is Double, is Float:
            return "REAL"
        case is Bool:
            return "INTEGER"
        case is String:
            return "TEXT"
        default:
            return "TEXT"
        }
    }
    // 컬럼 값 가져오기
    private func getColumnValue(statement: OpaquePointer, index: Int32) -> Any? {
        let columnType = sqlite3_column_type(statement, index)
        switch columnType {
        case SQLITE_INTEGER:
            return Int(sqlite3_column_int(statement, index))
        case SQLITE_FLOAT:
            return Double(sqlite3_column_double(statement, index))
        case SQLITE_TEXT:
            return String(cString: sqlite3_column_text(statement, index))
        default:
            return nil
        }
    }
    
    // 객체 조회
    public func fetchObjects<T: Decodable>(tableName: String, type: T.Type, whereString: String = "") -> [T] {
        var result: [T] = []
        let query = !whereString.isEmpty ? "SELECT * FROM \(tableName);" : "SELECT * FROM \(tableName) WHERE \(whereString);"
        
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let columnCount = sqlite3_column_count(statement)
                var dictionary: [String: Any] = [:]

                for i in 0..<columnCount {
                    let columnName = String(cString: sqlite3_column_name(statement, i))
                    if let value = getColumnValue(statement: statement!, index: i) {
                        dictionary[columnName] = value
                    }
                }

                if let jsonData = try? JSONSerialization.data(withJSONObject: dictionary),
                   let decodedObject = try? JSONDecoder().decode(T.self, from: jsonData) {
                    result.append(decodedObject)
                }
            }
        }

        sqlite3_finalize(statement)
        return result
    }
    
    // 객체 저장
    public func insertOrUpdateObject(_ object: Any, tableName: String, isUpdate: Bool) {
        let mirror = Mirror(reflecting: object)
        var columnNames: [String] = []
        var values: [String] = []
        var keyValuePairs: [String] = []
        var idValue: Any?

        for child in mirror.children {
            if let propertyName = child.label {
                columnNames.append(propertyName)
                values.append("'\(child.value)'")
                keyValuePairs.append("\(propertyName) = '\(child.value)'")

                if propertyName.lowercased() == "id" { // Assume `id` is the primary key
                    idValue = child.value
                }
            }
        }

        if isUpdate, let id = idValue {
            let updateQuery = "UPDATE \(tableName) SET \(keyValuePairs.joined(separator: ", ")) WHERE id = '\(id)';"

            if sqlite3_exec(db, updateQuery, nil, nil, nil) != SQLITE_OK {
                print("Error updating \(tableName)")
            } else {
                print("Updated successfully in \(tableName)")
            }
        } else {
            let insertQuery = "INSERT INTO \(tableName) (\(columnNames.joined(separator: ", "))) VALUES (\(values.joined(separator: ", ")));"

            if sqlite3_exec(db, insertQuery, nil, nil, nil) != SQLITE_OK {
                print("Error inserting into \(tableName)")
            } else {
                print("Inserted successfully into \(tableName)")
            }
        }
    }
    
}
