//
// ViewController.m
// MQTTLibTest
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

#import "ViewController.h"
#import "MQTTSession.h"

@interface ViewController ()
@property NSMutableArray * executionLog;
@property NSMutableArray * executionTimes;


@property (strong,nonatomic) MQTTSession *mqttSession1Rx;
@property (strong,nonatomic) MQTTSession *mqttSession2Tx;
@property (strong,nonatomic) MQTTSession *mqttSession3Tx;
@property (strong,nonatomic) MQTTSession *mqttSession4Rx;

@property (assign,nonatomic) BOOL  mqttSession1Connected;
@property (assign,nonatomic) BOOL  mqttSession1ConnectionFailed;
@property (assign,nonatomic) BOOL  mqttSession2Connected;
@property (assign,nonatomic) BOOL  mqttSession2ConnectionFailed;
@property (assign,nonatomic) BOOL  mqttSession1GetMessage;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.executionLog = [[NSMutableArray alloc] init];
    self.executionTimes = [[NSMutableArray alloc] init];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.executionLog.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    int row = indexPath.row;
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"logCell"];
    
    cell.textLabel.text = [self.executionTimes objectAtIndex:row];
    cell.detailTextLabel.text = [self.executionLog objectAtIndex:row];
    
    return cell;
}


#pragma mark - Utility Functions

-(NSString*)randomIdWithLength:(int)length {
    NSString *alphabet  = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY0123456789";
    NSMutableString *client = [NSMutableString stringWithCapacity:length];
    for (NSUInteger i = 0; i < length ; i++) {
        u_int32_t r = arc4random() % [alphabet length];
        unichar c = [alphabet characterAtIndex:r];
        [client appendFormat:@"%C", c];
    }
    return client;
}

- (NSString *)md5:(NSString *)stringToHash {
    const char *cStr = [stringToHash UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, strlen(cStr), result ); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
    
}

#pragma mark - MQTT Session Callback functions

- (void)session:(MQTTSession*)session handleEvent:(MQTTSessionEvent)eventCode {
    NSLog(@"MQTT Session Event");
    switch (eventCode) {
        case MQTTSessionEventConnected:
            NSLog(@"connected");
            
            if(session==self.mqttSession1Rx){
                self.mqttSession1Connected = YES;
            }
            if(session==self.mqttSession2Tx){
                self.mqttSession2Connected = YES;
            }
            
            break;
        case MQTTSessionEventConnectionRefused:
            NSLog(@"connection refused");
            if(session==self.mqttSession1Rx){
                self.mqttSession1ConnectionFailed = YES;
            }
            if(session==self.mqttSession2Tx){
                self.mqttSession2ConnectionFailed = YES;
            }
            
            break;
        case MQTTSessionEventConnectionClosed:
            NSLog(@"connection closed");
            if(session==self.mqttSession1Rx){
                self.mqttSession1Connected = NO;
            }
            if(session==self.mqttSession2Tx){
                self.mqttSession2Connected = NO;
            }
            
            break;
        case MQTTSessionEventConnectionError:
            NSLog(@"connection error");
            if(session==self.mqttSession1Rx){
                self.mqttSession1ConnectionFailed = YES;
            }
            if(session==self.mqttSession2Tx){
                self.mqttSession2ConnectionFailed = YES;
            }
            break;
        case MQTTSessionEventProtocolError:
            NSLog(@"protocol error");
            break;
    }
}

- (void)session:(MQTTSession*)session newMessage:(NSData*)data onTopic:(NSString*)topic {
    NSLog(@"MQTT New Message \n Topic: %@ \n Message: %@",topic, [NSString stringWithUTF8String:[data bytes]]);
    if(session==self.mqttSession1Rx){
        self.mqttSession1GetMessage = YES;
    }
}


#pragma mark - Test Logic Subroutines

-(void)setupMqttSession1 {
    self.mqttSession1Connected = NO;
    self.mqttSession1ConnectionFailed = NO;
    self.mqttSession1GetMessage = NO;
    
    NSString * clientId = [NSString stringWithFormat:@"WEBSOCKET/%@",[self randomIdWithLength:5]];
    
    NSLog(@"Client ID: %@",clientId);
    
    self.mqttSession1Rx = [[MQTTSession alloc] initWithClientId:clientId runLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [self.mqttSession1Rx connectToHost:@"test.mosquitto.org" port:8883 usingSSL:YES];
    [self.mqttSession1Rx setDelegate:self];
    
    
}

-(void)setupMqttSession2 {
    self.mqttSession2Connected = NO;
    self.mqttSession2ConnectionFailed = NO;
    
    
    NSString * clientId = [NSString stringWithFormat:@"WEBSOCKET/%@",[self randomIdWithLength:5]];
    
    NSLog(@"Client ID: %@",clientId);
    
    self.mqttSession2Tx = [[MQTTSession alloc] initWithClientId:clientId runLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [self.mqttSession2Tx connectToHost:@"q.m2m.io" port:1883];
    [self.mqttSession2Tx setDelegate:self];
    
    
}

#pragma mark - Log Support

-(void)makeLogMT: (NSString*)message {
    
    NSString * dateString = [NSString stringWithFormat:@"%@",[NSDate date]];
    
    [self.executionTimes insertObject:dateString atIndex:0];
    [self.executionLog insertObject:message atIndex:0];
    
    [self.logTableView reloadData];
}

-(void)makeLog: (NSString*)message {
    
    [self performSelectorOnMainThread:@selector(makeLogMT:) withObject:message waitUntilDone:YES];
}

#pragma mark - Testcases
- (void)test01setupFirstMqttSession {
    [self setupMqttSession1];
    
    int counter = 0;
    do{
        usleep(1000000);
        if(self.mqttSession1Connected == YES) {
            [self makeLog: @"Test 01 Passed"];
            return;
        }
        if(self.mqttSession1ConnectionFailed == YES) {
            [self makeLog: @"Test 01 Failed"];
            return;
        }
        counter ++;
    }while(counter <30);
    [self makeLog: @"Test 01 Failed"];
}

-(void)test02tearDownFirstMqttSession {
    [self makeLog: @"Closing MQTT Connection"];
    [self.mqttSession1Rx close];
    int counter = 0;
    do{
        usleep(1000000);
        if(self.mqttSession1Connected == NO) {
            [self makeLog: @"Test 02 Passed"];
            return;
        }
        counter ++;
    }while(counter <30);
    [self makeLog: @"Test 02 Failed"];
}

-(void)test03twoSessionWithMessage {
    [self.mqttSession2Tx close];
    [self setupMqttSession1];
    [self setupMqttSession2];
    int counter = 0;
    do{
        usleep(1000000);
        if(self.mqttSession1Connected == YES && self.mqttSession2Connected == YES) {
            NSString* topic = [NSString stringWithFormat:@"public/whatever/%@",[self randomIdWithLength:5]];
            [self.mqttSession1Rx subscribeTopic:topic];
            [self.mqttSession2Tx publishData:[@"testMessage" dataUsingEncoding:NSUTF8StringEncoding] onTopic:topic];
            int counter1 = 0;
            do{
                usleep(1000000);
                if (self.mqttSession1GetMessage == YES) {
                    [self makeLog: @"Test 03 Passed"];
                    return;
                }
                counter1 ++;
            }while(counter1 <30);
             [self makeLog: @"Test 03 Failed"];
            return;
        }
        counter ++;
    }while(counter <30);
    [self makeLog: @"Test 03 Failed"];
}

-(void)test04sendMessageOneSession {
    [self.mqttSession1Rx close];
    [self setupMqttSession1];
    int counter = 0;
    do{
        usleep(1000000);
        if(self.mqttSession1Connected == YES) {
            NSString* topic = [NSString stringWithFormat:@"public/whatever/%@",[self randomIdWithLength:5]];
            [self.mqttSession1Rx subscribeTopic:topic];
            [self.mqttSession2Tx publishData:[@"testMessage" dataUsingEncoding:NSUTF8StringEncoding] onTopic:topic];
            int counter1 = 0;
            do{
                usleep(1000000);
                if (self.mqttSession1GetMessage == YES) {
                    [self makeLog: @"Test 04 Passed"];
                    return;
                }
                counter1 ++;
            }while(counter1 <30);
            [self makeLog: @"Test 04 Failed"];
            return;
        }
        counter ++;
    }while(counter <30);
    [self makeLog: @"Test 04 Failed"];
}

- (IBAction)startButtonClicked:(id)sender {
    NSOperationQueue * queue = [[NSOperationQueue alloc] init];
    
    NSOperation* testOperation = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"Operation executed");
        [self test01setupFirstMqttSession];
        //[self test02tearDownFirstMqttSession];
        //[self test03twoSessionWithMessage];
        //[self test04sendMessageOneSession];
    }];
    
    [queue addOperation:testOperation];
    
}
@end
