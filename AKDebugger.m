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
#import "AKGenerics.h"

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

__AK_MAKE_LOG_FUNCTION(ASL_LEVEL_INFO, AKLogInfo)
__AK_MAKE_LOG_FUNCTION(ASL_LEVEL_DEBUG, AKLogDebug)
__AK_MAKE_LOG_FUNCTION(ASL_LEVEL_NOTICE, AKLogNotice)
__AK_MAKE_LOG_FUNCTION(ASL_LEVEL_ALERT, AKLogAlert)
__AK_MAKE_LOG_FUNCTION(ASL_LEVEL_WARNING, AKLogWarning)
__AK_MAKE_LOG_FUNCTION(ASL_LEVEL_ERR, AKLogError)
__AK_MAKE_LOG_FUNCTION(ASL_LEVEL_CRIT, AKLogCritical)
__AK_MAKE_LOG_FUNCTION(ASL_LEVEL_EMERG, AKLogEmergency)

#undef __AK_MAKE_LOG_FUNCTION

@interface AKDebugger ()

// GENERAL //

+ (NSDictionary *)dictionaryForPrettyFunction:(NSString *)prettyFunction;
+ (void)printMethod:(NSString *)prettyFunction logType:(AKLogType)logType message:(NSString *)message;
+ (void)didPrintLogType:(AKLogType)logType;

// VALIDATORS //

+ (BOOL)printForLogType:(AKLogType)logType;
+ (BOOL)printForMethodType:(AKMethodType)methodType;
+ (BOOL)printForScope:(AKMethodScope)methodScope;
+ (BOOL)printForClass:(NSString *)className;
+ (BOOL)printForCategory:(NSString *)categoryName;
+ (BOOL)printForMethodName:(NSString *)methodName;

// BREAKPOINTS //

+ (void)logTypeMethodName;
+ (void)logTypeInfo;
+ (void)logTypeDebug;
+ (void)logTypeNotice;
+ (void)logTypeAlert;
+ (void)logTypeWarning;
+ (void)logTypeError;
+ (void)logTypeCritical;
+ (void)logTypeEmergency;

@end

@implementation AKDebugger

#pragma mark - // SETTERS AND GETTERS //

#pragma mark - // INITS AND LOADS //

#pragma mark - // PUBLIC METHODS (Settings) //

+ (void)logMethod:(NSString *)prettyFunction logType:(AKLogType)logType methodType:(AKMethodType)methodType customCategories:(NSArray *)categories message:(NSString *)message
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
    
    if (!RULES_CLASS)
    {
        AKLog(@"[WARNING] Class %@ is unknown or does not exist for %s", NSStringFromClass(RULES_CLASS), __PRETTY_FUNCTION__);
        return;
    }
    
    if (![RULES_CLASS conformsToProtocol:@protocol(AKDebuggerRules)])
    {
        AKLog(@"[WARNING] %@ does not conform to protocol <%@> for %s", NSStringFromClass(RULES_CLASS), NSStringFromProtocol(@protocol(AKDebuggerRules)), __PRETTY_FUNCTION__);
        return;
    }
    
    if (![RULES_CLASS masterOn]) return;
    
    BOOL shouldPrint = YES;
    
    if (![AKDebugger printForLogType:logType]) shouldPrint = NO;
    
    if (![AKDebugger printForMethodType:methodType]) shouldPrint = NO;
    
    for (NSString *category in categories)
    {
        if (![AKDebugger printForCustomCategory:category]) shouldPrint = NO;
    }
    
    NSDictionary *dictionary = [AKDebugger dictionaryForPrettyFunction:prettyFunction];
    
    if (![AKDebugger printForScope:[[dictionary objectForKey:SCOPE] intValue]]) shouldPrint = NO;
    
    if (![AKDebugger printForClass:[dictionary objectForKey:CLASS]]) shouldPrint = NO;
    
    if (![AKDebugger printForCategory:[dictionary objectForKey:CATEGORY]]) shouldPrint = NO;
    
    if (![AKDebugger printForMethodName:[dictionary objectForKey:METHOD]]) shouldPrint = NO;
    
    if (shouldPrint) [AKDebugger printMethod:prettyFunction logType:logType message:message];
}

#pragma mark - // PUBLIC METHODS (Formatting) //

#pragma mark - // PUBLIC METHODS (Debugging) //

#pragma mark - // DELEGATED METHODS //

#pragma mark - // OVERWRITTEN METHODS //

#pragma mark - // PRIVATE METHODS (General) //

+ (NSDictionary *)dictionaryForPrettyFunction:(NSString *)prettyFunction
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
    
    if (!prettyFunction)
    {
        if(PRINT_DEBUGGER) AKLog(@"[INFO] %@ cannot be nil for %s", stringFromVariable(prettyFunction), __PRETTY_FUNCTION__);
        return nil;
    }
    
    NSArray *components = [prettyFunction componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[ ]"]];
    if (components.count != 4)
    {
        if(PRINT_DEBUGGER) AKLog(@"[INFO] Could not parse %@ for %s", stringFromVariable(prettyFunction), __PRETTY_FUNCTION__);
        return nil;
    }
    
    NSNumber *methodScope;
    NSString *scopeString = [components objectAtIndex:0];
    if ([[scopeString substringFromIndex:scopeString.length-1] isEqualToString:@"+"])
    {
        methodScope = [NSNumber numberWithInt:AKClassMethod];
    }
    else if ([[scopeString substringFromIndex:scopeString.length-1] isEqualToString:@"-"])
    {
        methodScope = [NSNumber numberWithInt:AKInstanceMethod];
    }
    else AKLog(@"[WARNING] Unknown %@ for %s", stringFromVariable(methodScope), __PRETTY_FUNCTION__);
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
        if (!methodScope) AKLog(@"[INFO] %@ is nil for %s", stringFromVariable(methodScope), __PRETTY_FUNCTION__);
        if (!className) AKLog(@"[INFO] %@ is nil for %s", stringFromVariable(className), __PRETTY_FUNCTION__);
        if (!methodName) AKLog(@"[INFO] %@ is nil for %s", stringFromVariable(methodName), __PRETTY_FUNCTION__);
    }
    if (!methodScope || !className || !methodName) return nil;
    
    return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:methodScope, className, categoryName, methodName, nil] forKeys:[NSArray arrayWithObjects:SCOPE, CLASS, CATEGORY, METHOD, nil]];
}

+ (void)printMethod:(NSString *)prettyFunction logType:(AKLogType)logType message:(NSString *)message
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
    
    switch (logType) {
        case AKLogTypeMethodName:
            AKLogInfo([NSString stringWithFormat:@"%@", prettyFunction]);
            break;
        case AKLogTypeInfo:
            AKLogInfo([NSString stringWithFormat:@"%@ %@", prettyFunction, message]);
            break;
        case AKLogTypeDebug:
            AKLogDebug([NSString stringWithFormat:@"%@", message]);
            break;
        case AKLogTypeNotice:
            AKLogNotice([NSString stringWithFormat:@"%@ %@", prettyFunction, message]);
            break;
        case AKLogTypeAlert:
            AKLogAlert([NSString stringWithFormat:@"%@ %@", prettyFunction, message]);
            break;
        case AKLogTypeWarning:
            AKLogWarning([NSString stringWithFormat:@"%@ %@", prettyFunction, message]);
            break;
        case AKLogTypeError:
            AKLogError([NSString stringWithFormat:@"%@ %@", prettyFunction, message]);
            break;
        case AKLogTypeCritical:
            AKLogCritical([NSString stringWithFormat:@"%@ %@", prettyFunction, message]);
            break;
        case AKLogTypeEmergency:
            AKLogEmergency([NSString stringWithFormat:@"%@ %@", prettyFunction, message]);
            break;
        default:
            if (PRINT_DEBUGGER) AKLog(@"Unknown %@ for %s", stringFromVariable(logType), __PRETTY_FUNCTION__);
            break;
    }
    [AKDebugger didPrintLogType:logType];
}

+ (void)didPrintLogType:(AKLogType)logType
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
    
    switch (logType) {
        case AKLogTypeMethodName:
            [AKDebugger logTypeMethodName];
            break;
        case AKLogTypeInfo:
            [AKDebugger logTypeInfo];
            break;
        case AKLogTypeDebug:
            [AKDebugger logTypeDebug];
            break;
        case AKLogTypeNotice:
            [AKDebugger logTypeNotice];
            break;
        case AKLogTypeAlert:
            [AKDebugger logTypeAlert];
            break;
        case AKLogTypeWarning:
            [AKDebugger logTypeWarning];
            break;
        case AKLogTypeError:
            [AKDebugger logTypeError];
            break;
        case AKLogTypeCritical:
            [AKDebugger logTypeCritical];
            break;
        case AKLogTypeEmergency:
            [AKDebugger logTypeEmergency];
            break;
        default:
            if (PRINT_DEBUGGER) AKLog(@"Unknown %@ for %s", stringFromVariable(logType), __PRETTY_FUNCTION__);
            break;
    }
}

#pragma mark - // PRIVATE METHODS (Validators) //

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
        case AKMethodTypeCreator:
            if (![RULES_CLASS printCreators])
            {
                if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_CREATORS = NO for %s", __PRETTY_FUNCTION__);
                return NO;
            }
            break;
        case AKMethodTypeDeletor:
            if (![RULES_CLASS printDeletors])
            {
                if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_DELETORS = NO for %s", __PRETTY_FUNCTION__);
                return NO;
            }
            break;
        case AKMethodTypeAction:
            if (![RULES_CLASS printActions])
            {
                if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_ACTIONS = NO for %s", __PRETTY_FUNCTION__);
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
    else if (([RULES_CLASS customCategoriesToSkip].count > 0) && ([[RULES_CLASS customCategoriesToSkip] containsObject:category]))
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
    if (!class)
    {
        AKLog(@"[WARNING] Unrecognized class %@ for %s", className, __PRETTY_FUNCTION__);
        return NO;
    }
    
    if ([class isSubclassOfClass:[UIViewController class]])
    {
        if (![RULES_CLASS printViewControllers])
        {
            if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_VIEWCONTROLLERS = NO for %s", __PRETTY_FUNCTION__);
            return NO;
        }
        
        if ([[RULES_CLASS viewControllersToSkip] containsObject:className])
        {
            if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_%@ = NO for %s", className, __PRETTY_FUNCTION__);
            return NO;
        }
    }
    else if ([class isSubclassOfClass:[UIView class]])
    {
        if (![RULES_CLASS printViews])
        {
            if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_VIEWS = NO for %s", __PRETTY_FUNCTION__);
            return NO;
        }
        
        if ([[RULES_CLASS viewsToSkip] containsObject:className])
        {
            if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_%@ = NO for %s", className, __PRETTY_FUNCTION__);
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
    
    return YES;
}

+ (BOOL)printForCategory:(NSString *)categoryName
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
    
    if (![RULES_CLASS printCategories])
    {
        if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_CATEGORIES = NO for %s", __PRETTY_FUNCTION__);
        return NO;
    }
    
    if ([[RULES_CLASS categoriesToSkip] containsObject:categoryName])
    {
        if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_%@ = NO for %s", categoryName, __PRETTY_FUNCTION__);
        return NO;
    }
    
    return YES;
}

+ (BOOL)printForMethodName:(NSString *)methodName
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
    
    NSSet *methodsToPrint = [RULES_CLASS methodsToPrint];
    if (methodsToPrint)
    {
        if (![methodsToPrint containsObject:methodName])
        {
            if (PRINT_DEBUGGER) AKLog(@"[INFO] %@ does not contain %@ for %s", stringFromVariable(methodsToPrint), methodName, __PRETTY_FUNCTION__);
            return NO;
        }
    }
    else if ([[RULES_CLASS methodsToSkip] containsObject:methodName])
    {
        if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_%@ = NO for %s", methodName, __PRETTY_FUNCTION__);
        return NO;
    }
    
    return YES;
}

#pragma mark - // PRIVATE METHODS (Breakpoints) //

+ (void)logTypeMethodName
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
}

+ (void)logTypeInfo
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
}

+ (void)logTypeDebug
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
}

+ (void)logTypeNotice
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
}

+ (void)logTypeAlert
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
}

+ (void)logTypeWarning
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
}

+ (void)logTypeError
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
}

+ (void)logTypeCritical
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
}

+ (void)logTypeEmergency
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
}


@end