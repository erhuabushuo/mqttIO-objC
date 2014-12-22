//
// ViewController.h
// HelloMQTT
// 
// Copyright (c) 2011, 2013, 2lemetry LLC
// 
// All rights reserved. This program and the accompanying materials
// are made available under the terms of the Eclipse Public License v1.0
// which accompanies this distribution, and is available at
// http://www.eclipse.org/legal/epl-v10.html
// 
// Contributors:
//    Kyle Roche - initial API and implementation and/or initial documentation
// 

#import <UIKit/UIKit.h>
#import "MQTTSession.h"


@interface ViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>{
//    MQTTSession *session;
    BOOL connecting;
    NSString * clientID;
    NSMutableArray * messageArray;
    NSMutableArray * topicArray;
    UIBackgroundTaskIdentifier backgroundTask;
}

@property (nonatomic, strong) MQTTSession * session;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *textMessage;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UITextField *topicName;
@property (weak, nonatomic) IBOutlet UITableView *messageTable;

- (IBAction)sendMessage:(id)sender;
- (IBAction)connect:(id)sender;
- (IBAction)subscribe:(id)sender;


@end
