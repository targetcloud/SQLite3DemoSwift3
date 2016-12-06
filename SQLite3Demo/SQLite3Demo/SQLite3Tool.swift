//
//  SQLite3Tool.swift
//  SQLite3Demo
//
//  Created by targetcloud on 2016/12/7.
//  Copyright © 2016年 targetcloud. All rights reserved.
//

import Foundation

class SQLite3Tool: NSObject {
    static let shareInstance = SQLite3Tool()
    var appdb: OpaquePointer? = nil
    let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    
    override init() {
        super.init()
        //        let path = "/Users/targetcloud/Desktop/appdb.sqlite"//实际中用下面的path
        let docDir: String! = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first
        //        let path = docDir + "/appdb.sqlite"//建议下面写法
        //        print(path)
        let DBPath = (docDir! as NSString).appendingPathComponent("appdb.sqlite")
        let path = DBPath.cString(using: String.Encoding.utf8)
        print(DBPath)
        /*
         /Users/targetcloud/Library/Developer/CoreSimulator/Devices/A2BB310A-7C11-4A30-B1DE-B3488B7D87D7/data/Containers/Data/Application/0E8D813A-BD6D-4E4F-B500-27C3B5E896DA/Documents/appdb.sqlite
        */
        if  sqlite3_open(path, &appdb) == SQLITE_OK {
            dropTable("t_user")
            createTable("create table if not exists t_user(id integer primary key autoincrement, name text not null, age integer, score real default 60, money real default 100 )")
        }else {
            print("open fail")
        }
    }
    
    func queryAllStmt(_ sql :String) ->[[String:Any]] {
        var stmt: OpaquePointer? = nil
        var queryDataArrM = [[String:Any]]()
        if sqlite3_prepare_v2(appdb, sql, -1, &stmt, nil) != SQLITE_OK {
            print("prepare fail")
            return queryDataArrM
        }
        while sqlite3_step(stmt) == SQLITE_ROW {
            let count = sqlite3_column_count(stmt)
            var dict = [String:Any]()
            for i in 0..<count {
                let columnName = String(cString: sqlite3_column_name(stmt, i), encoding: String.Encoding.utf8)
                let type = sqlite3_column_type(stmt, i)
                if type == SQLITE_INTEGER {
                    let value = sqlite3_column_int(stmt, i)
                    dict[columnName!] = value
                    print(columnName,value)
                }
                if type == SQLITE_FLOAT {
                    let value = sqlite3_column_double(stmt, i)
                    dict[columnName!] = value
                    print(columnName,value)
                }
                if type == SQLITE_TEXT {
                    let value =  String(cString:sqlite3_column_text(stmt, i)!)
                    let valueStr = String(cString: value, encoding: String.Encoding.utf8)
                    dict[columnName!] = valueStr
                    print(columnName,valueStr)
                }
            }
            queryDataArrM.append(dict)
        }
        sqlite3_finalize(stmt)
        return queryDataArrM
    }
    
    func queryAll(_ sql :String) {
        //参数: 一个打开的数据库、需要执行的SQL语句、查询结果回调(执行0次或多次)、回调函数的第一个值、错误信息
        let result = sqlite3_exec(appdb, sql, { (
            firstValue, columnCount, values , columnNames ) -> Int32 in // 参数: 外层的第4个参数的值、列的个数、结果值的数组所有列的名称数组。返回值: 0代表继续执行一直到结束, 1代表执行一次
            let count = Int(columnCount)
            for i in 0..<count {
                let column = columnNames?[i]
                let columnNameStr = String(cString: column!, encoding: String.Encoding.utf8)//(columnNames?[i]!)!
                let value = values?[i]
                let valueStr = String(cString: value!, encoding: String.Encoding.utf8)//(values?[i]!)!
                print(columnNameStr! + "=" + valueStr!)
            }
            return 0//0代表继续执行一直到结束, 1代表执行一次
        }, nil, nil)
        if result == SQLITE_OK {
            print("all query ok")
        }else {
            print("all query fail")
        }
    }
    
    //建表
    fileprivate func createTable(_ sql: String) ->Bool {
        return execSQL(sql)
    }
    
    //删表
    fileprivate func dropTable(_ tableName: String) ->Bool {
        let sql = "drop table if exists "+tableName
        return execSQL(sql)
    }
    
    //普通更新
    func updateRecord(_ table: String, setStr: String, condition: String?) -> Bool {
        let whereCondition = (condition == nil) ? ("") : ("where \(condition!)")
        let sql = "update \(table) set \(setStr) \(whereCondition)"
        return execSQL(sql)
    }
    
    //普通INSERT
    func insert(_ tableName: String, columnNameArray: [String], values: CVarArg...) -> Bool {
        return insert(tableName, columnNameArray: columnNameArray, valueArray:values)
    }
    
    //普通INSERT
    func insert(_ tableName: String, columnNameArray: [String], valueArray: [Any]) -> Bool {
        if columnNameArray.count != valueArray.count{
            return false
        }
        let tempColumnNameArray = columnNameArray as NSArray
        let columnNames = tempColumnNameArray.componentsJoined(by: ",")
        let tempValueArray = valueArray as NSArray
        let values = tempValueArray.componentsJoined(by: "\',\'")
        let sql = "INSERT INTO \(tableName)(\(columnNames)) values (\'\(values)\')"
        return execSQL(sql)
    }
    
    //批量INSERT
    func insertBatch(_ tableName: String, columnNameArray: [String], valuesBlock: () -> Array<Array<Any>>){
        guard let stmt: OpaquePointer = getPrepareStmt(tableName, columnNameArray: columnNameArray) else { return}
        beginTransaction()
        for array in valuesBlock(){
            insertBind(stmt, values: array)
            resetStmt(stmt)
        }
        commitTransaction()
        releaseStmt(stmt)
    }
    
    //step Stmt
    fileprivate func insertBind(_ stmt: OpaquePointer, values: [Any]) -> Bool  {
        var index: Int32 = 1
        for obj in values{
            if obj is Int{
                sqlite3_bind_int(stmt, index, Int32(obj as! Int))
            } else if obj is Double{
                sqlite3_bind_double(stmt, index, obj as! Double)
            } else if obj is Float{
                sqlite3_bind_double(stmt, index, Double(obj as! Float))//MARK:- 重点！Float要分开判断
            }else if obj is String{
                sqlite3_bind_text(stmt, index, obj as! String, -1, SQLITE_TRANSIENT)
            }else {
                continue
            }
            index += 1
        }
        return sqlite3_step(stmt) == SQLITE_DONE
    }
    
    //得到INSERT Stmt
    fileprivate func getPrepareStmt(_ tableName: String, columnNameArray: [String]) -> OpaquePointer? {
        let tempColumnNameArray = columnNameArray as NSArray
        let columnNames = tempColumnNameArray.componentsJoined(by: ",")
        var tempValues: Array = [String]()
        for _ in 0 ..< columnNameArray.count{
            tempValues.append("?")
        }
        let valuesStr = (tempValues as NSArray).componentsJoined(by: ",")
        let prepareSql = "INSERT INTO \(tableName)(\(columnNames)) values (\(valuesStr))"
        var stmt: OpaquePointer? = nil
        if sqlite3_prepare_v2(appdb, prepareSql, -1, &stmt, nil) != SQLITE_OK{
            print("prepare fail")
            sqlite3_finalize(stmt)
            return nil
        }
        return stmt!
    }
    
    //重置Stmt
    fileprivate func resetStmt(_ stmt: OpaquePointer) -> Bool {
        return sqlite3_reset(stmt) == SQLITE_OK
    }
    
    //释放Stmt
    fileprivate func releaseStmt(_ stmt: OpaquePointer) {
        sqlite3_finalize(stmt)
    }
    
    func execSqls(_ sqlarr : [String]) -> Bool {
        for item in sqlarr {
            if execSQL(item) == false {
                return false
            }
        }
        return true
    }
    
    func execSQL(_ sql : String) -> Bool {
        let errmsg : UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>? = nil
        if sqlite3_exec(appdb, sql, nil, nil, errmsg) == SQLITE_OK {
            return true
        }else{
            print("error \(errmsg)")
            return false
        }
    }
    
    //开启事务
    func beginTransaction() -> Bool{
        let sql = "begin transaction"
        return execSQL(sql)
    }
    
    //提交事务
    func commitTransaction() -> Bool{
        let sql = "commit transaction"
        return execSQL(sql)
    }
    
    //回滚事务
    func rollbackTransaction() -> Bool{
        let sql = "rollback transaction"
        return execSQL(sql)
    }
}
