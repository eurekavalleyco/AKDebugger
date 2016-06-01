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
+ (Class)class;

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

+ (NSArray <NSString *> *)tagsToPrint;
+ (NSArray <NSString *> *)tagsToSkip;

// RULES (Classes) //

+ (NSArray <NSString *> *)classesToPrint;
+ (NSArray <NSString *> *)classesToSkip;

// RULES (Categories) //

+ (BOOL)printCategories;
+ (NSArray <NSString *> *)categoriesToPrint;
+ (NSArray <NSString *> *)categoriesToSkip;

// RULES (Methods) //

+ (NSArray <NSString *> *)methodsToPrint;
+ (NSArray <NSString *> *)methodsToSkip;

@end

#pragma mark - // DEFINITIONS (Public) //

// TAGS //

extern NSString * const AKD_ACCOUNTS;
extern NSString * const AKD_ANALYTICS;
extern NSString * const AKD_CONNECTIVITY;
extern NSString * const AKD_CORE_DATA;
extern NSString * const AKD_DATA;
extern NSString * const AKD_NOTIFICATION_CENTER;
extern NSString * const AKD_REMOTE_DATA;
extern NSString * const AKD_UI;

// OPTIONS //

#define PRINT_DEBUGGER NO

// OTHER //

#define RULES_CLASS (Class <AKDebuggerRules>)NSClassFromString(@"AKDebuggerRules")
#define METHOD_NAME [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__]

typedef enum {
    AKLogTypeMethodName,
    AKLogTypeInfo,
    AKLogTypeDebug,
    AKLogTypeNotice,
    AKLogTypeAlert,
    AKLogTypeWarning,
    AKLogTypeError,
    AKLogTypeCritical,
    AKLogTypeEmergency
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
    void AKLogInfo(NSString * format, ...);
#else
    #define AKLogInfo(...)
#endif

#if AK_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_DEBUG
    void AKLogDebug(NSString * format, ...);
#else
    #define AKLogDebug(...)
#endif

#if AK_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_NOTICE
    void AKLogNotice(NSString * format, ...);
#else
    #define AKLogNotice(...)
#endif

#if AK_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_ALERT
    void AKLogAlert(NSString * format, ...);
#else
    #define AKLogAlert(...)
#endif

#if AK_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_WARNING
    void AKLogWarning(NSString * format, ...);
#else
    #define AKLogWarning(...)
#endif

#if AK_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_ERR
    void AKLogError(NSString * format, ...);
#else
    #define AKLogError(...)
#endif

#if AK_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_CRIT
    void AKLogCritical(NSString * format, ...);
#else
    #define AKLogCritical(...)
#endif

#if AK_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_EMERG
    void AKLogEmergency(NSString * format, ...);
#else
    #define AKLogEmergency(...)
#endif

@interface AKDebugger : NSObject
+ (void)logMethod:(NSString *)prettyFunction logType:(AKLogType)logType methodType:(AKMethodType)methodType tags:(NSArray *)tags message:(NSString *)message;
@end
