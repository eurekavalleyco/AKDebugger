//
//  AKDebugger.m
//  AKDebugger
//
//  Created by Ken M. Haggerty on 9/24/13.
//  Copyright (c) 2013 Eureka Valley Co. All rights reserved.
//

#pragma mark - // NOTES (Private) //

// [_] Add AKMethodTypeCreator

#pragma mark - // IMPORTS (Private) //

#import "AKDebugger.h"

#pragma mark - // DEFINITIONS (Private) //

typedef enum {
    AKClassMethod = 1,
    AKInstanceMethod
} AKMethodScope;

#define SCOPE @"Scope"
#define CLASS @"Class"
#define CATEGORY @"Category"
#define METHOD @"Method"

#ifdef AK_COMPILE_TIME_LOG_LEVEL
    #undef AK_COMPILE_TIME_LOG_LEVEL
    #define AK_COMPILE_TIME_LOG_LEVEL ASL_LEVEL_DEBUG
#endif

#define AK_COMPILE_TIME_LOG_LEVEL ASL_LEVEL_DEBUG

static void AddStderrOnce()
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        asl_add_log_file(NULL, STDERR_FILENO);
    });
}

#define __AK_MAKE_LOG_FUNCTION(LEVEL, NAME) \
void NAME (NSString *format, ...) \
{ \
    AddStderrOnce(); \
    va_list args; \
    va_start(args, format); \
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args]; \
    asl_log(NULL, NULL, (LEVEL), "%s", [message UTF8String]); \
    va_end(args); \
}

__AK_MAKE_LOG_FUNCTION(ASL_LEVEL_EMERG, AKLogEmergency)
__AK_MAKE_LOG_FUNCTION(ASL_LEVEL_ALERT, AKLogAlert)
__AK_MAKE_LOG_FUNCTION(ASL_LEVEL_CRIT, AKLogCritical)
__AK_MAKE_LOG_FUNCTION(ASL_LEVEL_ERR, AKLogError)
__AK_MAKE_LOG_FUNCTION(ASL_LEVEL_WARNING, AKLogWarning)
__AK_MAKE_LOG_FUNCTION(ASL_LEVEL_NOTICE, AKLogNotice)
__AK_MAKE_LOG_FUNCTION(ASL_LEVEL_INFO, AKLogInfo)
__AK_MAKE_LOG_FUNCTION(ASL_LEVEL_DEBUG, AKLogDebug)

#undef __AK_MAKE_LOG_FUNCTION

@interface AKDebugger ()
+ (void)printMethod:(NSString *)prettyFunction logType:(AKLogType)logType message:(NSString *)message;
+ (NSDictionary *)dictionaryForPrettyFunction:(NSString *)prettyFunction;
+ (BOOL)printForLogType:(AKLogType)logType;
+ (BOOL)printForMethodType:(AKMethodType)methodType;
+ (BOOL)printForScope:(AKMethodScope)methodScope;
+ (BOOL)printForClass:(NSString *)className;
+ (BOOL)printForCategory:(NSString *)categoryName;
+ (BOOL)printForMethodName:(NSString *)methodName;
@end

@implementation AKDebugger

#pragma mark - // SETTERS AND GETTERS //

#pragma mark - // INITS AND LOADS //

#pragma mark - // PUBLIC METHODS (Settings) //

+ (BOOL)printForMethod:(NSString *)prettyFunction logType:(AKLogType)logType methodType:(AKMethodType)methodType
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
    
    BOOL shouldPrint = NO;
    if (RULES_CLASS)
    {
        if ([RULES_CLASS conformsToProtocol:@protocol(AKDebuggerRules)])
        {
            if ([RULES_CLASS masterOn])
            {
                shouldPrint = YES;
                if (![AKDebugger printForLogType:logType]) shouldPrint = NO;
                if (![AKDebugger printForMethodType:methodType]) shouldPrint = NO;
                NSDictionary *dictionary = [AKDebugger dictionaryForPrettyFunction:prettyFunction];
                AKMethodScope methodScope = [[dictionary objectForKey:SCOPE] intValue];
                if (![AKDebugger printForScope:methodScope]) shouldPrint = NO;
                NSString *className = [dictionary objectForKey:CLASS];
                if (![AKDebugger printForClass:className]) shouldPrint = NO;
                NSString *categoryName = [dictionary objectForKey:CATEGORY];
                if (![AKDebugger printForCategory:categoryName]) shouldPrint = NO;
                NSString *methodName = [dictionary objectForKey:METHOD];
                if (![AKDebugger printForMethodName:methodName]) shouldPrint = NO;
            }
        }
        else AKLog(@"[WARNING] %@ does not conform to protocol <AKDebuggerRules> for %s", RULES_CLASS, __PRETTY_FUNCTION__);
    }
    else AKLog(@"[WARNING] %@ is of unknown class or does not exist for %s", RULES_CLASS, __PRETTY_FUNCTION__);
    return shouldPrint;
}

+ (void)logMethod:(NSString *)prettyFunction logType:(AKLogType)logType methodType:(AKMethodType)methodType customCategory:(NSString *)category message:(NSString *)message
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
    
    BOOL shouldPrint = NO;
    if (RULES_CLASS)
    {
        if ([RULES_CLASS conformsToProtocol:@protocol(AKDebuggerRules)])
        {
            if ([RULES_CLASS masterOn])
            {
                shouldPrint = YES;
                if (![AKDebugger printForLogType:logType]) shouldPrint = NO;
                if (![AKDebugger printForMethodType:methodType]) shouldPrint = NO;
                if (![AKDebugger printForCustomCategory:category]) shouldPrint = NO;
                NSDictionary *dictionary = [AKDebugger dictionaryForPrettyFunction:prettyFunction];
                AKMethodScope methodScope = [[dictionary objectForKey:SCOPE] intValue];
                if (![AKDebugger printForScope:methodScope]) shouldPrint = NO;
                NSString *className = [dictionary objectForKey:CLASS];
                if (![AKDebugger printForClass:className]) shouldPrint = NO;
                NSString *categoryName = [dictionary objectForKey:CATEGORY];
                if (![AKDebugger printForCategory:categoryName]) shouldPrint = NO;
                NSString *methodName = [dictionary objectForKey:METHOD];
                if (![AKDebugger printForMethodName:methodName]) shouldPrint = NO;
            }
        }
        else AKLog(@"[WARNING] %@ does not conform to protocol <AKDebuggerRules> for %s", NSStringFromClass(RULES_CLASS), __PRETTY_FUNCTION__);
    }
    else AKLog(@"[WARNING] Class %@ is unknown or does not exist for %s", NSStringFromClass(RULES_CLASS), __PRETTY_FUNCTION__);
    if (shouldPrint) [AKDebugger printMethod:prettyFunction logType:logType message:message];
}

#pragma mark - // PUBLIC METHODS (Formatting) //

#pragma mark - // PUBLIC METHODS (Debugging) //

#pragma mark - // DELEGATED METHODS //

#pragma mark - // OVERWRITTEN METHODS //

#pragma mark - // PRIVATE METHODS //

+ (void)printMethod:(NSString *)prettyFunction logType:(AKLogType)logType message:(NSString *)message
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
    
    switch (logType) {
        case AKLogTypeMethodName:
            AKLogInfo([NSString stringWithFormat:@"%@", prettyFunction]);
            break;
        case AKLogTypeEmergency:
            AKLogEmergency([NSString stringWithFormat:@"%@ %@", prettyFunction, message]);
            break;
        case AKLogTypeAlert:
            AKLogAlert([NSString stringWithFormat:@"%@ %@", prettyFunction, message]);
            break;
        case AKLogTypeCritical:
            AKLogCritical([NSString stringWithFormat:@"%@ %@", prettyFunction, message]);
            break;
        case AKLogTypeError:
            AKLogError([NSString stringWithFormat:@"%@ %@", prettyFunction, message]);
            break;
        case AKLogTypeWarning:
            AKLogWarning([NSString stringWithFormat:@"%@ %@", prettyFunction, message]);
            break;
        case AKLogTypeNotice:
            AKLogNotice([NSString stringWithFormat:@"%@ %@", prettyFunction, message]);
            break;
        case AKLogTypeInfo:
            AKLogInfo([NSString stringWithFormat:@"%@ %@", prettyFunction, message]);
            break;
        case AKLogTypeDebug:
            AKLogDebug([NSString stringWithFormat:@"%@", message]);
            break;
        default:
            if (PRINT_DEBUGGER) AKLog(@"Unknown logType for %s", __PRETTY_FUNCTION__);
            break;
    }
}

+ (NSDictionary *)dictionaryForPrettyFunction:(NSString *)prettyFunction
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
    
    if (prettyFunction)
    {
        NSArray *components = [prettyFunction componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[ ]"]];
        if (components.count == 4)
        {
            NSNumber *methodScope;
            NSString *scopeString = [components objectAtIndex:0];
            if ([[scopeString substringFromIndex:scopeString.length-1] isEqualToString:@"+"]) methodScope = [NSNumber numberWithInt:AKClassMethod];
            else if ([[scopeString substringFromIndex:scopeString.length-1] isEqualToString:@"-"]) methodScope = [NSNumber numberWithInt:AKInstanceMethod];
            else AKLog(@"[WARNING] Unknown methodScope for %s", __PRETTY_FUNCTION__);
            NSString *className;
            NSString *categoryName;
            NSArray *classComponents = [[components objectAtIndex:1] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"()"]];
            if (classComponents.count == 3)
            {
                className = [classComponents objectAtIndex:0];
                categoryName = [classComponents objectAtIndex:1];
            }
            else
            {
                className = [components objectAtIndex:1];
                categoryName = @"";
            }
            NSString *methodName = [components objectAtIndex:2];
            if (PRINT_DEBUGGER)
            {
                if (!methodScope) AKLog(@"[INFO] methodScope is nil for %s", __PRETTY_FUNCTION__);
                if (!className) AKLog(@"[INFO] className is nil for %s", __PRETTY_FUNCTION__);
                if (!methodName) AKLog(@"[INFO] methodName is nil for %s", __PRETTY_FUNCTION__);
            }
            if (methodScope && className && methodName)
            return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:methodScope, className, categoryName, methodName, nil] forKeys:[NSArray arrayWithObjects:SCOPE, CLASS, CATEGORY, METHOD, nil]];
            
        }
        else if(PRINT_DEBUGGER) AKLog(@"[INFO] Could not parse prettyString for %s", __PRETTY_FUNCTION__);
    }
    else if(PRINT_DEBUGGER) AKLog(@"[INFO] prettyFunction cannot be nil for %s", __PRETTY_FUNCTION__);
    return nil;
}

+ (BOOL)printForLogType:(AKLogType)logType
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
    
    if (logType == AKLogTypeMethodName)
    {
        if (![RULES_CLASS printMethodNames])
        {
            if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_METHOD_NAMES = NO for %s", __PRETTY_FUNCTION__);
            return NO;
        }
    }
    else if (logType == AKLogTypeEmergency)
    {
        if (![RULES_CLASS printWarnings])
        {
            if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_WARNINGS = NO for %s", __PRETTY_FUNCTION__);
            return NO;
        }
    }
    else if (logType == AKLogTypeAlert)
    {
        if (![RULES_CLASS printAlerts])
        {
            if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_ALERTS = NO for %s", __PRETTY_FUNCTION__);
            return NO;
        }
    }
    else if (logType == AKLogTypeCritical)
    {
        if (![RULES_CLASS printFailures])
        {
            if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_CRITICAL = NO for %s", __PRETTY_FUNCTION__);
            return NO;
        }
    }
    else if (logType == AKLogTypeError)
    {
        if (![RULES_CLASS printErrors])
        {
            if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_ERRORS = NO for %s", __PRETTY_FUNCTION__);
            return NO;
        }
    }
    else if (logType == AKLogTypeWarning)
    {
        if (![RULES_CLASS printWarnings])
        {
            if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_WARNINGS = NO for %s", __PRETTY_FUNCTION__);
            return NO;
        }
    }
    else if (logType == AKLogTypeNotice)
    {
        if (![RULES_CLASS printNotices])
        {
            if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_NOTICES = NO for %s", __PRETTY_FUNCTION__);
            return NO;
        }
    }
    else if (logType == AKLogTypeInfo)
    {
        if (![RULES_CLASS printInformation])
        {
            if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_INFO = NO for %s", __PRETTY_FUNCTION__);
            return NO;
        }
    }
    else if (logType == AKLogTypeDebug)
    {
        if (![RULES_CLASS printDebug])
        {
            if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_DEBUG = NO for %s", __PRETTY_FUNCTION__);
            return NO;
        }
    }
    else
    {
        if (PRINT_DEBUGGER) AKLog(@"[INFO] Unknown logType for %s", __PRETTY_FUNCTION__);
        return NO;
    }
    return YES;
}

+ (BOOL)printForMethodType:(AKMethodType)methodType
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
    
    switch (methodType) {
        case AKMethodTypeSetup:
            if (![RULES_CLASS printSetup])
            {
                if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_SETUP = NO for %s", __PRETTY_FUNCTION__);
                return NO;
            }
            break;
        case AKMethodTypeSetter:
            if (![RULES_CLASS printSetters])
            {
                if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_SETTERS = NO for %s", __PRETTY_FUNCTION__);
                return NO;
            }
            break;
        case AKMethodTypeGetter:
            if (![RULES_CLASS printGetters])
            {
                if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_GETTERS = NO for %s", __PRETTY_FUNCTION__);
                return NO;
            }
            break;
        case AKMethodTypeValidator:
            if (![RULES_CLASS printValidators])
            {
                if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_VALIDATORS = NO for %s", __PRETTY_FUNCTION__);
                return NO;
            }
            break;
        case AKMethodTypeUnspecified:
            if (![RULES_CLASS printUnspecified])
            {
                if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_UNSPECIFIED = NO for %s", __PRETTY_FUNCTION__);
                return NO;
            }
            break;
        default:
            AKLog(@"[WARNING] Unrecognized methodType for %s", __PRETTY_FUNCTION__);
            return NO;
            break;
    }
    return YES;
}

+ (BOOL)printForCustomCategory:(NSString *)category
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
    
    if (([RULES_CLASS customCategoriesToPrint].count > 0) && (![[RULES_CLASS customCategoriesToPrint] containsObject:category]))
    {
        if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_%@ = NO for %s", category, __PRETTY_FUNCTION__);
        return NO;
    }
    return YES;
}

+ (BOOL)printForScope:(AKMethodScope)methodScope
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
    
    if (methodScope == AKClassMethod)
    {
        if (![RULES_CLASS printClassMethods])
        {
            if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_CLASS_METHODS = NO for %s", __PRETTY_FUNCTION__);
            return NO;
        }
    }
    else if (methodScope == AKInstanceMethod)
    {
        if (![RULES_CLASS printInstanceMethods])
        {
            if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_INSTANCE_METHODS = NO for %s", __PRETTY_FUNCTION__);
            return NO;
        }
    }
    else
    {
        AKLog(@"[WARNING] Unknown methodScope for %s", __PRETTY_FUNCTION__);
        return NO;
    }
    return YES;
}

+ (BOOL)printForClass:(NSString *)className
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
    
    Class class = NSClassFromString(className);
    if (class)
    {
        if ([class isSubclassOfClass:[UIViewController class]])
        {
            if ([RULES_CLASS printViewControllers])
            {
                if ([[RULES_CLASS viewControllersToSkip] containsObject:className])
                {
                    if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_%@ = NO for %s", className, __PRETTY_FUNCTION__);
                    return NO;
                }
            }
            else
            {
                if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_VIEWCONTROLLERS = NO for %s", __PRETTY_FUNCTION__);
                return NO;
            }
        }
        else if ([class isSubclassOfClass:[UIView class]])
        {
            if ([RULES_CLASS printViews])
            {
                if ([[RULES_CLASS viewsToSkip] containsObject:className])
                {
                    if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_%@ = NO for %s", className, __PRETTY_FUNCTION__);
                    return NO;
                }
            }
            else
            {
                if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_VIEWS = NO for %s", __PRETTY_FUNCTION__);
                return NO;
            }
        }
        else if ([RULES_CLASS printOtherClasses])
        {
            if ([[RULES_CLASS otherClassesToSkip] containsObject:className])
            {
                if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_%@ = NO for %s", className, __PRETTY_FUNCTION__);
                return NO;
            }
        }
        else
        {
            if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_OTHERCLASSES = NO for %s", __PRETTY_FUNCTION__);
            return NO;
        }
    }
    else
    {
        AKLog(@"[WARNING] Unrecognized class %@ for %s", className, __PRETTY_FUNCTION__);
        return NO;
    }
    return YES;
}

+ (BOOL)printForCategory:(NSString *)categoryName
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
    
    if ([RULES_CLASS printCategories])
    {
        if ([[RULES_CLASS categoriesToSkip] containsObject:categoryName])
        {
            if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_%@ = NO for %s", categoryName, __PRETTY_FUNCTION__);
            return NO;
        }
    }
    else
    {
        if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_CATEGORIES = NO for %s", __PRETTY_FUNCTION__);
        return NO;
    }
    return YES;
}

+ (BOOL)printForMethodName:(NSString *)methodName
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
    
    NSSet *methodsToPrint = [RULES_CLASS methodsToPrint];
    if ((methodsToPrint) && (methodsToPrint.count > 0))
    {
        if (![methodsToPrint containsObject:methodName])
        {
            if (PRINT_DEBUGGER) AKLog(@"[INFO] %@ not a method to print for %s", methodName, __PRETTY_FUNCTION__);
            return NO;
        }
    }
    else
    {
        if ([[RULES_CLASS methodsToSkip] containsObject:methodName])
        {
            if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_%@ = NO for %s", methodName, __PRETTY_FUNCTION__);
            return NO;
        }
    }
    return YES;
}

@end