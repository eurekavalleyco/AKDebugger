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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <asl.h>

#pragma mark - // PROTOCOLS //

@protocol AKDebuggerRules <NSObject>

// RULES (General) //

+ (BOOL)masterOn;

+ (BOOL)printClassMethods;
+ (BOOL)printInstanceMethods;

+ (BOOL)printSetup;
+ (BOOL)printSetters;
+ (BOOL)printGetters;
+ (BOOL)printValidators;
+ (BOOL)printUnspecified;

+ (BOOL)printMethodNames;
+ (BOOL)printEmergencies;
+ (BOOL)printAlerts;
+ (BOOL)printFailures;
+ (BOOL)printErrors;
+ (BOOL)printWarnings;
+ (BOOL)printNotices;
+ (BOOL)printInformation;
+ (BOOL)printDebug;

// RULES (Custom Categories) //

+ (NSSet *)customCategoriesToPrint;

// RULES (View Controllers) //

+ (BOOL)printViewControllers;
+ (NSSet *)viewControllersToSkip;

// RULES (Views) //

+ (BOOL)printViews;
+ (NSSet *)viewsToSkip;

// RULES (Other) //

+ (BOOL)printOtherClasses;
+ (NSSet *)otherClassesToSkip;
+ (NSSet *)methodsToSkip;

+ (NSSet *)methodsToPrint;

// RULES (Categories) //

+ (BOOL)printCategories;
+ (NSSet *)categoriesToSkip;

@end

#pragma mark - // DEFINITIONS (Public) //

#define PRINT_DEBUGGER NO

#define RULES_CLASS NSClassFromString(@"AKDebuggerRules")
#define METHOD_NAME [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__]

typedef enum {
    AKLogTypeMethodName = 1,
    AKLogTypeEmergency,
    AKLogTypeAlert,
    AKLogTypeCritical,
    AKLogTypeError,
    AKLogTypeWarning,
    AKLogTypeNotice,
    AKLogTypeInfo,
    AKLogTypeDebug
} AKLogType;

typedef enum {
    AKMethodTypeUnspecified = 1,
    AKMethodTypeSetup,
    AKMethodTypeSetter,
    AKMethodTypeGetter,
    AKMethodTypeValidator
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

#if AK_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_EMERG
    void AKLogEmergency(NSString *format, ...);
#else
    #define AKLogEmergency(...)
#endif

#if AK_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_ALERT
    void AKLogAlert(NSString *format, ...);
#else
    #define AKLogAlert(...)
#endif

#if AK_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_CRIT
    void AKLogCritical(NSString *format, ...);
#else
    #define AKLogCritical(...)
#endif

#if AK_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_ERR
    void AKLogError(NSString *format, ...);
#else
    #define AKLogError(...)
#endif

#if AK_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_WARNING
    void AKLogWarning(NSString *format, ...);
#else
    #define AKLogWarning(...)
#endif

#if AK_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_NOTICE
    void AKLogNotice(NSString *format, ...);
#else
    #define AKLogNotice(...)
#endif

#if AK_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_INFO
    void AKLogInfo(NSString *format, ...);
#else
    #define AKLogInfo(...)
#endif

#if AK_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_DEBUG
    void AKLogDebug(NSString *format, ...);
#else
    #define AKLogDebug(...)
#endif

@interface AKDebugger : NSObject
+ (BOOL)printForMethod:(NSString *)prettyFunction logType:(AKLogType)logType methodType:(AKMethodType)methodType;
+ (void)logMethod:(NSString *)prettyFunction logType:(AKLogType)logType methodType:(AKMethodType)methodType customCategory:(NSString *)category message:(NSString *)message;
@end