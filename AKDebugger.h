//
//  AKDebugger.h
//  AKDebugger
//
//  Created by Ken M. Haggerty on 9/24/13.
//  Copyright (c) 2013 Eureka Valley Co. All rights reserved.
//

#pragma mark - // NOTES (Public) //

//  To use AKDebugger correctly:
//  • Create a copy of AKDebuggerRules (both .h and .m) for your project and edit appropriate parameters in .m file.
//  • Import AKDebugger.h/.m without creating a copy.
//  • Call +[AKDebugger printForMethod:logType:methodType:] as appropriate.

#pragma mark - // IMPORTS (Public) //

#import <asl.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#pragma mark - // PROTOCOLS //

@protocol AKDebuggerRules <NSObject>
@optional

// RULES (General) //

+ (BOOL)masterOn;

+ (BOOL)printClassMethods;
+ (BOOL)printInstanceMethods;

// RULES (AKLogType) //

+ (BOOL)printMethodNames;
+ (BOOL)printInfos;
+ (BOOL)printDebugs;
+ (BOOL)printNotices;
+ (BOOL)printAlerts;
+ (BOOL)printWarnings;
+ (BOOL)printErrors;
+ (BOOL)printCriticals;
+ (BOOL)printEmergencies;

// RULES (AKMethodType) //

+ (BOOL)printSetups;
+ (BOOL)printSetters;
+ (BOOL)printGetters;
+ (BOOL)printCreators;
+ (BOOL)printDeletors;
+ (BOOL)printActions;
+ (BOOL)printValidators;
+ (BOOL)printUnspecifieds;

// RULES (Tags) //

+ (nullable NSArray <NSString *> *)tagsToPrint;
+ (nullable NSArray <NSString *> *)tagsToSkip;

// RULES (Classes) //

+ (nullable NSArray <NSString *> *)classesToPrint;
+ (nullable NSArray <NSString *> *)classesToSkip;

// RULES (Categories) //

+ (BOOL)printCategories;
+ (nullable NSArray <NSString *> *)categoriesToPrint;
+ (nullable NSArray <NSString *> *)categoriesToSkip;

// RULES (Methods) //

+ (nullable NSArray <NSString *> *)methodsToPrint;
+ (nullable NSArray <NSString *> *)methodsToSkip;

@end

#pragma mark - // DEFINITIONS (Public) //

// TAGS //

#define AKD_UI @"User Interface"
#define AKD_NOTIFICATION_CENTER @"Notification Center"
#define AKD_DATA @"Data"
#define AKD_ACCOUNTS @"Accounts"
#define AKD_CORE_DATA @"Core Data"
#define AKD_PARSE @"Parse"
#define AKD_PUSH_NOTIFICATIONS @"Push Notifications"
#define AKD_ANALYLTICS @"Analytics"

// OPTIONS //

#define PRINT_DEBUGGER NO

// OTHER //

#define RULES_CLASS (Class <AKDebuggerRules>)NSClassFromString(@"AKDebuggerRules")
#define METHOD_NAME [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__]

typedef enum {
    AKLogTypeMethodName = 0,
    AKLogTypeInfo = 1,
    AKLogTypeDebug = 2,
    AKLogTypeNotice = 3,
    AKLogTypeAlert = 4,
    AKLogTypeWarning = 5,
    AKLogTypeError = 6,
    AKLogTypeCritical = 7,
    AKLogTypeEmergency = 8
} AKLogType;

typedef enum {
    AKMethodTypeSetup,
    AKMethodTypeSetter,
    AKMethodTypeGetter,
    AKMethodTypeCreator,
    AKMethodTypeDeletor,
    AKMethodTypeValidator,
    AKMethodTypeAction,
    AKMethodTypeUnspecified,
} AKMethodType;

#ifdef NDEBUG
    #define AKLog(...)
#else
    #define AKLog NSLog
#endif

#ifndef AK_COMPILE_TIME_LOG_LEVEL
    #ifdef NDEBUG
        #define AK_COMPILE_TIME_LOG_LEVEL ASL_LEVEL_NOTICE
    #else
        #define AK_COMPILE_TIME_LOG_LEVEL ASL_LEVEL_DEBUG
    #endif
#endif

#if AK_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_INFO
    void AKLogInfo(NSString * _Nullable format, ...);
#else
    #define AKLogInfo(...)
#endif

#if AK_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_DEBUG
    void AKLogDebug(NSString * _Nullable format, ...);
#else
    #define AKLogDebug(...)
#endif

#if AK_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_NOTICE
    void AKLogNotice(NSString * _Nullable format, ...);
#else
    #define AKLogNotice(...)
#endif

#if AK_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_ALERT
    void AKLogAlert(NSString * _Nullable format, ...);
#else
    #define AKLogAlert(...)
#endif

#if AK_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_WARNING
    void AKLogWarning(NSString * _Nullable format, ...);
#else
    #define AKLogWarning(...)
#endif

#if AK_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_ERR
    void AKLogError(NSString * _Nullable format, ...);
#else
    #define AKLogError(...)
#endif

#if AK_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_CRIT
    void AKLogCritical(NSString * _Nullable format, ...);
#else
    #define AKLogCritical(...)
#endif

#if AK_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_EMERG
    void AKLogEmergency(NSString * _Nullable format, ...);
#else
    #define AKLogEmergency(...)
#endif

@interface AKDebugger : NSObject
+ (void)logMethod:(nonnull NSString *)prettyFunction logType:(AKLogType)logType methodType:(AKMethodType)methodType tags:(nullable NSArray *)tags message:(nullable NSString *)message;
@end
