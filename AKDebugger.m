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

#define DEFAULT_BOOL YES

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

+ (NSDictionary *)dictionaryForPrettyFunction:(nonnull NSString *)prettyFunction;
+ (void)printMethod:(NSString *)prettyFunction logType:(AKLogType)logType message:(NSString *)message;
+ (void)didPrintLogType:(AKLogType)logType;

// VALIDATORS //

+ (BOOL)printForLogType:(AKLogType)logType;
+ (BOOL)printForMethodType:(AKMethodType)methodType;
+ (BOOL)printForTag:(NSString *)tag;
+ (BOOL)printForScope:(AKMethodScope)methodScope;
+ (BOOL)printForClass:(NSString *)className;
+ (BOOL)printForCategory:(NSString *)category;
+ (BOOL)printForMethodName:(NSString *)method;

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

// RULES //

+ (BOOL)boolForRule:(SEL)rule;
+ (NSArray <NSString *> *)arrayForRule:(SEL)rule;

@end

@implementation AKDebugger

#pragma mark - // SETTERS AND GETTERS //

#pragma mark - // INITS AND LOADS //

#pragma mark - // PUBLIC METHODS //

+ (void)logMethod:(nonnull NSString *)prettyFunction logType:(AKLogType)logType methodType:(AKMethodType)methodType tags:(nullable NSArray *)tags message:(nullable NSString *)message
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
    
    if (![AKDebugger boolForRule:@selector(masterOn)]) return;
    
    BOOL shouldPrint = YES;
    
    if (![AKDebugger printForLogType:logType]) shouldPrint = NO;
    
    if (![AKDebugger printForMethodType:methodType]) shouldPrint = NO;
    
    if (tags)
    {
        for (NSString *tag in tags)
        {
            if (![AKDebugger printForTag:tag]) shouldPrint = NO;
        }
    }
    
    NSDictionary *dictionary = [AKDebugger dictionaryForPrettyFunction:prettyFunction];
    
    if (![AKDebugger printForScope:[[dictionary objectForKey:SCOPE] intValue]]) shouldPrint = NO;
    
    if (![AKDebugger printForClass:[dictionary objectForKey:CLASS]]) shouldPrint = NO;
    
    if (![AKDebugger printForCategory:[dictionary objectForKey:CATEGORY]]) shouldPrint = NO;
    
    if (![AKDebugger printForMethodName:[dictionary objectForKey:METHOD]]) shouldPrint = NO;
    
    if (shouldPrint) [AKDebugger printMethod:prettyFunction logType:logType message:message];
}

#pragma mark - // DELEGATED METHODS //

#pragma mark - // OVERWRITTEN METHODS //

#pragma mark - // PRIVATE METHODS (General) //

+ (NSDictionary *)dictionaryForPrettyFunction:(nonnull NSString *)prettyFunction
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
    
    NSArray *components = [prettyFunction componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[ ]"]];
    if (components.count != 4)
    {
        if (PRINT_DEBUGGER) AKLog(@"[INFO] Could not parse %@ for %s", stringFromVariable(prettyFunction), __PRETTY_FUNCTION__);
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
    NSString *className, *categoryName;
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
    
    SEL rule;
    switch (logType) {
        case AKLogTypeMethodName:
            rule = @selector(printMethodNames);
            break;
        case AKLogTypeInfo:
            rule = @selector(printInfos);
            break;
        case AKLogTypeDebug:
            rule = @selector(printDebugs);
            break;
        case AKLogTypeNotice:
            rule = @selector(printNotices);
            break;
        case AKLogTypeAlert:
            rule = @selector(printAlerts);
            break;
        case AKLogTypeWarning:
            rule = @selector(printWarnings);
            break;
        case AKLogTypeError:
            rule = @selector(printErrors);
            break;
        case AKLogTypeCritical:
            rule = @selector(printCriticals);
            break;
        case AKLogTypeEmergency:
            rule = @selector(printEmergencies);
            break;
        default:
            if (PRINT_DEBUGGER) AKLog(@"Unknown %@ for %s", stringFromVariable(logType), __PRETTY_FUNCTION__);
            return NO;
    }
    
    BOOL shouldPrint = [AKDebugger boolForRule:rule];
    if (PRINT_DEBUGGER && !shouldPrint) AKLog(@"[INFO] %@ = NO for %s", NSStringFromSelector(rule), __PRETTY_FUNCTION__);
    return shouldPrint;
}

+ (BOOL)printForMethodType:(AKMethodType)methodType
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
    
    SEL rule;
    switch (methodType) {
        case AKMethodTypeSetup:
            rule = @selector(printSetups);
            break;
        case AKMethodTypeSetter:
            rule = @selector(printSetters);
            break;
        case AKMethodTypeGetter:
            rule = @selector(printGetters);
            break;
        case AKMethodTypeCreator:
            rule = @selector(printCreators);
            break;
        case AKMethodTypeDeletor:
            rule = @selector(printDeletors);
            break;
        case AKMethodTypeAction:
            rule = @selector(printActions);
            break;
        case AKMethodTypeValidator:
            rule = @selector(printValidators);
            break;
        case AKMethodTypeUnspecified:
            rule = @selector(printUnspecifieds);
            break;
        default:
            if (PRINT_DEBUGGER) AKLog(@"Unknown %@ for %s", stringFromVariable(logType), __PRETTY_FUNCTION__);
            return NO;
    }
    
    BOOL shouldPrint = [AKDebugger boolForRule:rule];
    if (PRINT_DEBUGGER && !shouldPrint) AKLog(@"[INFO] %@ = NO for %s", NSStringFromSelector(rule), __PRETTY_FUNCTION__);
    return shouldPrint;
}

+ (BOOL)printForTag:(NSString *)tag
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
    
    NSArray *tagsToSkip = [AKDebugger arrayForRule:@selector(tagsToSkip)];
    if (tagsToSkip && ([tagsToSkip containsObject:tag]))
    {
        if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_%@ = NO for %s", tag, __PRETTY_FUNCTION__);
        return NO;
    }
    
    NSArray *tagsToPrint = [AKDebugger arrayForRule:@selector(tagsToPrint)];
    if (tagsToPrint && (![tagsToPrint containsObject:tag]))
    {
        if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_%@ = NO for %s", tag, __PRETTY_FUNCTION__);
        return NO;
    }
    
    return YES;
}

+ (BOOL)printForScope:(AKMethodScope)methodScope
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
    
    SEL rule;
    switch (methodScope) {
        case AKClassMethod:
            rule = @selector(printClassMethods);
            break;
        case AKInstanceMethod:
            rule = @selector(printInstanceMethods);
            break;
    }
    BOOL shouldPrint = [AKDebugger boolForRule:rule];
    if (PRINT_DEBUGGER && !shouldPrint) AKLog(@"[INFO] %@ = NO for %s", NSStringFromSelector(rule), __PRETTY_FUNCTION__);
    return shouldPrint;
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
    
    NSArray *classesToSkip = [AKDebugger arrayForRule:@selector(tagsToSkip)];
    if (classesToSkip)
    {
        for (NSString *classToSkip in classesToSkip)
        {
            if ([NSClassFromString(className) isSubclassOfClass:NSClassFromString(classToSkip)])
            {
                if (PRINT_DEBUGGER) AKLog(@"[INFO] %@ = NO for %s", classToSkip, __PRETTY_FUNCTION__);
                return NO;
            }
        }
    }
    
    NSArray *classesToPrint = [AKDebugger arrayForRule:@selector(tagsToPrint)];
    if (classesToPrint)
    {
        for (NSString *classToPrint in classesToPrint)
        {
            if ([NSClassFromString(className) isSubclassOfClass:NSClassFromString(classToPrint)])
            {
                return YES;
            }
        }
        
        if (PRINT_DEBUGGER) AKLog(@"[INFO] %@ = NO for %s", className, __PRETTY_FUNCTION__);
        return NO;
    }
    
    return YES;
}

+ (BOOL)printForCategory:(NSString *)category
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
    
    if (![AKDebugger boolForRule:@selector(printCategories)])
    {
        if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_CATEGORIES = NO for %s", __PRETTY_FUNCTION__);
        return NO;
    }
    
    NSArray *categoriesToSkip = [AKDebugger arrayForRule:@selector(categoriesToSkip)];
    if (categoriesToSkip && ([categoriesToSkip containsObject:category]))
    {
        if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_%@ = NO for %s", category, __PRETTY_FUNCTION__);
        return NO;
    }
    
    NSArray *categoriesToPrint = [AKDebugger arrayForRule:@selector(categoriesToPrint)];
    if (categoriesToPrint && (![categoriesToPrint containsObject:category]))
    {
        if (PRINT_DEBUGGER) AKLog(@"[INFO] PRINT_%@ = NO for %s", category, __PRETTY_FUNCTION__);
        return NO;
    }
    
    return YES;
}

+ (BOOL)printForMethodName:(NSString *)method
{
    if (PRINT_DEBUGGER) AKLog(@"%s", __PRETTY_FUNCTION__);
    
    NSArray *methodsToSkip = [AKDebugger arrayForRule:@selector(methodsToSkip)];
    if (methodsToSkip && ([methodsToSkip containsObject:method]))
    {
        if (PRINT_DEBUGGER) AKLog(@"[INFO] %@ = NO for %s", method, __PRETTY_FUNCTION__);
        return NO;
    }
    
    NSArray *methodsToPrint = [AKDebugger arrayForRule:@selector(methodsToPrint)];
    if (methodsToPrint && (![methodsToPrint containsObject:method]))
    {
        if (PRINT_DEBUGGER) AKLog(@"[INFO] %@ = NO for %s", method, __PRETTY_FUNCTION__);
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

#pragma mark - // PRIVATE METHODS (Rules) //

+ (BOOL)boolForRule:(SEL)rule
{
    if ([RULES_CLASS respondsToSelector:rule]) return (BOOL)[RULES_CLASS performSelector:rule];
    
    return DEFAULT_BOOL;
}

+ (NSArray <NSString *> *)arrayForRule:(SEL)rule
{
    if ([RULES_CLASS respondsToSelector:rule]) return (NSArray <NSString *> *)[RULES_CLASS performSelector:rule];
    
    return nil;
}

@end
