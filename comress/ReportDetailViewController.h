//
//  ReportDetailViewController.h
//  comress
//
//  Created by Diffy Romano on 13/5/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActionSheetDatePicker.h"
#import "NSDate+TCUtils.h"
#import "AppWideImports.h"
#import "Database.h"

@interface ReportDetailViewController : UIViewController<UIWebViewDelegate, UITextFieldDelegate>
{
    Database *myDatabase;
}

@property (nonatomic, weak) IBOutlet UITextField *fromDateTextFied;
@property (nonatomic, weak) IBOutlet UITextField *toDateTextField;
@property (nonatomic, weak) IBOutlet UIWebView *webView;

@property (nonatomic, strong) AbstractActionSheetPicker *actionSheetPicker;
@property (nonatomic, strong) NSDate *selectedFromDate;
@property (nonatomic, strong) NSDate *selectedToDate;

@property (nonatomic, strong) NSString *reportType;

@end
