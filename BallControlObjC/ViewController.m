
#import "ViewController.h"
#import "Backendless.h"

#define SHARED_OBJECT_NAME @"BallObject"

#define APP_ID @"A81AB58A-FC85-EF00-FFE4-1A1C0FEADB00"
#define API_KEY @"FE202648-517E-B0A5-FF89-CBA9D7DFDD00"

@interface ViewController() {
    CGPoint location;
    NSDictionary *locationDictionary;
    SharedObject *sharedObject;
    BOOL imageMoveEnabled;
    
    CGFloat minX, maxX, minY, maxY;
    float koefX, koefY;
    BOOL dragging;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    dragging = NO;
    
    minX = 0;
    maxX = self.view.frame.size.width - self.imageView.frame.size.width;
    minY = 0;
    maxY = self.view.frame.size.height - self.imageView.frame.size.height;
    
    [self calculateKoef];
    
    self.textView.hidden = NO;
    self.imageView.hidden = YES;
    imageMoveEnabled = NO;
    self.connectButton.enabled = NO;
    
    backendless.hostURL = @"http://apitest.backendless.com";
    [backendless initApp:APP_ID APIKey:API_KEY];
    
    sharedObject = [backendless.sharedObject connect:SHARED_OBJECT_NAME];
    [self addOnChangesListener];
    [self addRTListeners];
}

-(void)calculateKoef {
    koefX = self.imageView.frame.origin.x / maxX;
    koefY = self.imageView.frame.origin.y / maxY;
    
    if (koefX < 0) {
        koefX = 0;
    }
    if (koefX > 1) {
        koefX = 1;
    }
    if (koefY < 0) {
        koefY = 0;
    }
    if (koefY > 1) {
        koefY = 1;
    }
    //
    //    NSLog(@"koefX = %f", koefX);
    //    NSLog(@"koefY = %f", koefY);
    //    NSLog(@"__________");
}

-(void)addRTListeners {
    [backendless.rt addConnectEventListener:^{
        if ([self.connectButton.title isEqualToString:@"Connect"]) {
            self.navigationItem.title = @"Status: disconnected";
        }
        else if ([self.connectButton.title isEqualToString:@"Disconnect"]) {
            self.navigationItem.title = @"Status: connected";
        }
        if (!sharedObject.isConnected) {
            [sharedObject connect];
        }
        self.connectButton.enabled = YES;
    }];
    
    [backendless.rt addConnectErrorEventListener:^(NSString *connectError) {
        sharedObject = [backendless.sharedObject connect:SHARED_OBJECT_NAME];
        [self addOnChangesListener];
        NSLog(@"Status: connection failed (%@)", connectError);
        self.connectButton.enabled = NO;
    }];
    
    [backendless.rt addDisonnectEventListener:^(NSString *disconnectReason) {
        sharedObject = [backendless.sharedObject connect:SHARED_OBJECT_NAME];
        [self addOnChangesListener];
        self.navigationItem.title = [NSString stringWithFormat:@"Status: disconnected (%@)", disconnectReason];
        self.connectButton.enabled = NO;
    }];
    
    [backendless.rt addReconnectAttemptEventListener:^(ReconnectAttemptObject *reconnectAttempt) {
        NSLog(@"Status: trying to connect");
    }];
}

-(void)addOnChangesListener {
    
    __weak __block ViewController *weakSelf = self;
    [sharedObject addChangesListener:^(SharedObjectChanges *changes) {
        // move imageView
        float xK = [[changes.data valueForKey:@"xKoef"] floatValue];
        float yK = [[changes.data valueForKey:@"yKoef"] floatValue];
        
        //        CGFloat locationX = [[locationDictionary valueForKey:@"x"] floatValue];
        //        CGFloat locationY = [[locationDictionary valueForKey:@"y"] floatValue];
        
        CGFloat originX = xK * maxX;//locationX - self.imageView.frame.size.width / 2;
        CGFloat originY = yK * maxY;//locationY - self.imageView.frame.size.height / 2;
        
        NSLog(@"oX = %f, oY = %f", originX, originY);
        if (!dragging) {
            NSLog(@"WILL move");
            
            [UIView animateWithDuration:0.3 animations:^{
                weakSelf.imageView.frame = CGRectMake(originX, originY, self.imageView.frame.size.width, self.imageView.frame.size.height);
            }];
        }
        
        
        //        [UIView animateWithDuration:0.3 animations:^{
        //            weakSelf.imageView.frame = CGRectMake(originX, originY, self.imageView.frame.size.width, self.imageView.frame.size.height);
        //        }];
        
    } error:^(Fault *fault) {
        
    }];
}

//-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
//    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
//    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
//        locationDictionary = @{@"x" : [NSNumber numberWithFloat:location.x], @"y" : [NSNumber numberWithFloat:location.y]};
//        [self animate:locationDictionary];
//    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
//    }];
//}

- (IBAction)animate:(id)sender {
    locationDictionary = sender;
    CGFloat locationX = [[locationDictionary valueForKey:@"x"] floatValue];
    CGFloat locationY = [[locationDictionary valueForKey:@"y"] floatValue];
    
    CGFloat originX = locationX - self.imageView.frame.size.width / 2;
    CGFloat originY = locationY - self.imageView.frame.size.height / 2;
    
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
    
    if (originX <= CGRectGetMinX(self.view.frame)) {
        originX = CGRectGetMinX(self.view.frame);
    }
    if (originX + self.imageView.frame.size.width >= CGRectGetMaxX(self.view.frame)) {
        originX = CGRectGetMaxX(self.view.frame) - self.imageView.frame.size.width;
    }
    if (originY <= statusBarHeight + navBarHeight) {
        originY = statusBarHeight + navBarHeight;
    }
    if (originY + self.imageView.frame.size.height >= CGRectGetMaxY(self.view.frame)) {
        originY = CGRectGetMaxY(self.view.frame) - self.imageView.frame.size.height;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        self.imageView.frame = CGRectMake(originX, originY, self.imageView.frame.size.width, self.imageView.frame.size.height);
    }];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    dragging = YES;
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    dragging = NO;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self calculateKoef];
    if (imageMoveEnabled) {
        UITouch *touch = [touches anyObject];
        location = [touch locationInView:self.view];
        
        self.imageView.center = location;
        locationDictionary = @{@"xKoef" : [NSNumber numberWithFloat:koefX], @"yKoef" : [NSNumber numberWithFloat:koefY]};
        [sharedObject set:@"locKoefs" data:locationDictionary response:^(id result) {
            
        } error:^(Fault *fault) {
            
        }];
        
        
        CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
        CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
        
        
        if (location.x - self.imageView.frame.size.width / 2 <= CGRectGetMinX(self.view.frame)) {
            location.x = self.imageView.frame.size.width / 2;
        }
        if (location.x + self.imageView.frame.size.width / 2 >= CGRectGetMaxX(self.view.frame)) {
            location.x = CGRectGetMaxX(self.view.frame) - self.imageView.frame.size.width / 2;
        }
        if (location.y - self.imageView.frame.size.height / 2 <= statusBarHeight + navBarHeight) {
            location.y = statusBarHeight + navBarHeight + self.imageView.frame.size.height / 2;
        }
        if (location.y + self.imageView.frame.size.height / 2 >= CGRectGetMaxY(self.view.frame)) {
            location.y = CGRectGetMaxY(self.view.frame) - self.imageView.frame.size.height / 2;
        }
        
        //        self.imageView.center = location;
        //        locationDictionary = @{@"x" : [NSNumber numberWithFloat:location.x], @"y" : [NSNumber numberWithFloat:location.y]};
        //        [sharedObject invokeOn:@"animate" targets:@[[NSNull null]] args:@[locationDictionary] response:^(id res) {
        //        } error:^(Fault *fault) {
        //        }];
    }
}

- (void)showErrorAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:^{
        self.textView.hidden = NO;
        self.imageView.hidden = YES;
        imageMoveEnabled = NO;
    }];
}

- (IBAction)pressedConnect:(id)sender {
    __weak ViewController *weakSelf = self;
    
    if ([self.connectButton.title isEqualToString:@"Connect"]) {
        self.connectButton.title = @"Disconnect";
        if (!sharedObject.isConnected) {
            [sharedObject connect];
        }
        sharedObject.invocationTarget = self;
        
        [sharedObject addConnectListener:^{
            weakSelf.navigationItem.title = @"Status: connected";
            weakSelf.textView.hidden = YES;
            weakSelf.imageView.hidden = NO;
            imageMoveEnabled = YES;
        } error:^(Fault *fault) {
            [weakSelf showErrorAlert:fault.detail];
        }];
        
        [sharedObject addInvokeListener:^(InvokeObject *invokeObject) {
            
        } error:^(Fault *fault) {
            [weakSelf showErrorAlert:fault.detail];
        }];
    }
    
    else if ([self.connectButton.title isEqualToString:@"Disconnect"]) {
        weakSelf.connectButton.title = @"Connect";
        weakSelf.navigationItem.title = @"Status: disconnected";
        weakSelf.textView.hidden = NO;
        weakSelf.imageView.hidden = YES;
        imageMoveEnabled = NO;
        [sharedObject disconnect];
    }
}
@end
