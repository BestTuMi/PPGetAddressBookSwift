//
//  PPGetAddressBookSwift.swift
//  PPGetAddressBookSwift
//
//  Created by AndyPang on 16/9/16.
//  Copyright © 2016年 AndyPang. All rights reserved.
//
/*
 *********************************************************************************
 *
 *⭐️⭐️⭐️ 新建 PP-iOS学习交流群: 323408051 欢迎加入!!! ⭐️⭐️⭐️
 *
 * 如果您在使用 PPGetAddressBookSwift 的过程中出现bug或有更好的建议,还请及时以下列方式联系我,我会及
 * 时修复bug,解决问题.
 *
 * Weibo : CoderPang
 * Email : jkpang@outlook.com
 * QQ 群 : 323408051
 * GitHub: https://github.com/jkpang
 *
 * PS:PPGetAddressBookSwift的Objective-C版本:
 * https://github.com/jkpang/PPGetAddressBook
 *
 * 如果 PPGetAddressBookSwift 好用,希望您能Star支持,你的 ⭐️ 是我持续更新的动力!
 *********************************************************************************
 */


import Foundation
import AddressBook

/// 获取原始顺序的所有联系人的闭包
public typealias AddressBookArrayClosure = (_ addressBookArray: [PPPersonModel])->()
/// 获取按A~Z顺序排列的所有联系人的闭包
public typealias AddressBookDictClosure = (_ addressBookDict: [String:[PPPersonModel]], _ nameKeys: [String])->()


public class PPGetAddressBook: NSObject {
    
    /**
     请求用户是否授权APP访问通讯录的权限,建议在APPDeletegate.m中的didFinishLaunchingWithOptions方法中调用
     */
    public class func requestAddressBookAuthorization() {
        // 1.获取授权的状态
        let status = ABAddressBookGetAuthorizationStatus()
        // 2.判断授权状态,如果是未决定状态,才需要请求
        if status == ABAuthorizationStatus.notDetermined {
            // 3.创建通讯录进行授权
            let addressBook = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
            ABAddressBookRequestAccessWithCompletion(addressBook, { (success, error) in
                if success {
                    print("授权成功")
                }else {
                    print("授权失败")
                }
            })
            
        }
    }
    
    // MARK: - 获取原始顺序所有联系人
    public class func getOriginalAddressBook(addressBookArray success: @escaping AddressBookArrayClosure, authorizationFailure failure:@escaping AuthorizationFailure) {
        
        //开启一个子线程,将耗时操作放到异步串行队列
        
        let queue = DispatchQueue(label: "addressBook.array")
        queue.async {
            
            var modelArray = [PPPersonModel]()
            PPAddressBookHandle.getAddressBookDataSource(personModel: { (model) in
                
                //将单个联系人模型装进数组
                modelArray.append(model)
                
                }, authorizationFailure: {
                    
                //将授权失败的信息回调到主线程
                DispatchQueue.main.async {
                    failure()
                }
            })
            
            // 将联系人数组回调到主线程
            DispatchQueue.main.async {
                success(modelArray)
            }
            
        }
        
    }
    
    // MARK: - 获取按A~Z顺序排列的所有联系人
    public class func getOrderAddressBook(addressBookInfo success: @escaping AddressBookDictClosure, authorizationFailure failure: @escaping AuthorizationFailure) {
        
        let queue = DispatchQueue(label:"addressBook.infoDict")
        queue.async {
            
            var addressBookDict = [String:[PPPersonModel]]()
            PPAddressBookHandle.getAddressBookDataSource(personModel: { (model) in
                
                // 获取到姓名的大写首字母
                let firstLetterString = getFirstLetterFromString(string: model.name)
                
                if addressBookDict[firstLetterString] != nil {
                    // swift的字典,如果对应的key在字典中没有,则会新增
                    addressBookDict[firstLetterString]?.append(model)
                    
                } else {
                    let arrGroupNames = [model]
                    addressBookDict[firstLetterString] = arrGroupNames
                }
                
                }, authorizationFailure: {
                    
                //将授权失败的信息回调到主线程
                DispatchQueue.main.async {
                    failure()
                }
            })
            
            // 将addressBookDict字典中的所有Key值进行排序: A~Z
            let peopleNameKey = Array(addressBookDict.keys).sorted()
            // 将排序好的通讯录数据回调到主线程
            DispatchQueue.main.async {
                success(addressBookDict, peopleNameKey)
            }
            
        }
    }
    
    // MARK: - 获取联系人姓名首字母(传入汉字字符串, 返回大写拼音首字母)
    private class func getFirstLetterFromString(string: String) -> (String) {
        
        // 注意,这里一定要转换成可变字符串
        let mutableString = NSMutableString.init(string: string)
        // 将中文转换成带声调的拼音
        CFStringTransform(mutableString as CFMutableString, nil, kCFStringTransformToLatin, false)
        // 去掉声调(用此方法大大提高遍历的速度)
        let pinyinString = mutableString.folding(options: String.CompareOptions.diacriticInsensitive, locale: NSLocale.current)
        // 将拼音首字母装换成大写
        let strPinYin = pinyinString.capitalized
        // 截取大写首字母
        let firstString = strPinYin.substring(to: strPinYin.index(strPinYin.startIndex, offsetBy:1))
        // 判断姓名首位是否为大写字母
        let regexA = "^[A-Z]$"
        let predA = NSPredicate.init(format: "SELF MATCHES %@", regexA)
        return predA.evaluate(with: firstString) ? firstString : "#"
    }
    
}
