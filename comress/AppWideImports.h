//
//  AppWideImports.h
//  comress
//
//  Created by Diffy Romano on 25/11/14.
//  Copyright (c) 2014 Combuilder. All rights reserved.
//

#ifndef comress_AppWideImports_h
#define comress_AppWideImports_h


#endif

#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDASLLogger.h"

#if DEBUG
    static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
    static const int ddLogLevel = LOG_LEVEL_OFF;
#endif
//static const int ddLogLevel = LOG_LEVEL_OFF;

static const int ping_interval = 600;

static const BOOL allowLogging = YES;

static const int sync_interval = 5;

static const int overDueDays = 3;

static const int goingOverDueDays = 3;

