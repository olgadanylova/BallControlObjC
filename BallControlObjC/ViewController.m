
#import "ViewController.h"
#import "Backendless.h"

#define SHARED_OBJECT_NAME @"BallObject"
#define LOCATION_COEFITIENTS @"LocationCoeficients"

#define HOST_URL @"http://apitest.backendless.com"
#define APP_ID @"A81AB58A-FC85-EF00-FFE4-1A1C0FEADB00"
#define API_KEY @"FE202648-517E-B0A5-FF89-CBA9D7DFDD00"

@interface ViewController() {
    CGFloat statusBarHeight;
    CGFloat navigationBarHeight;
    CGFloat imageViewWidth, imageViewHeight;
    CGFloat workspaceMinX, workspaceMaxX;
    CGFloat workspaceMinY, workspaceMaxY;
    CGFloat coefficientX, coefficientY;
    CGFloat imageViewOriginX, imageViewOriginY;
    BOOL imageMoveEnabled;
    BOOL isDragging;
    SharedObject *sharedObject;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.textView.hidden = NO;
    self.imageView.hidden = YES;
    self.connectButton.enabled = NO;
    
    if (self.view.frame.size.width <= self.view.frame.size.height) {
        self.imageView.frame = CGRectMake(self.imageView.frame.origin.x, self.imageView.frame.origin.y, self.view.frame.size.width * 0.25, self.view.frame.size.width * 0.25);
    }
    else {
        self.imageView.frame = CGRectMake(self.imageView.frame.origin.x, self.imageView.frame.origin.y, self.view.frame.size.height * 0.25, self.view.frame.size.height * 0.25);
    }
    imageViewWidth = self.imageView.frame.size.width;
    imageViewHeight = self.imageView.frame.size.height;
    self.imageView.layer.cornerRadius = imageViewWidth / 2;
    
    statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
    workspaceMinX = 0;
    workspaceMaxX = self.view.frame.size.width;
    workspaceMinY = statusBarHeight + navigationBarHeight;
    workspaceMaxY = self.view.frame.size.height;
    
    [self calculateCoefficients];
    
    imageMoveEnabled = NO;
    isDragging = NO;
    
    backendless.hostURL = HOST_URL;
    [backendless initApp:APP_ID APIKey:API_KEY];
    
    sharedObject = [backendless.sharedObject connect:SHARED_OBJECT_NAME];
    [sharedObject get:LOCATION_COEFITIENTS response:^(id result) {
        NSDictionary *coefs = [NSDictionary dictionaryWithDictionary:result];
        CGFloat coefX = [[coefs valueForKey:@"coefX"] floatValue];
        CGFloat coefY = [[coefs valueForKey:@"coefY"] floatValue];
        [self animateImageViewMoving:coefX :coefY];
    } error:^(Fault *fault) {
        [self showErrorAlert:fault.message];
    }];
    [self addRTListeners];
}

-(void)calculateCoefficients {
    if (imageViewOriginX == workspaceMinX) {
        coefficientX = 0;
    }
    else if (imageViewOriginX + imageViewWidth == workspaceMaxX) {
        coefficientX = 1;
    }
    else {
        coefficientX = imageViewOriginX / workspaceMaxX;
    }
    
    if (imageViewOriginY == workspaceMinY) {
        coefficientY = 0;
    }
    else if (imageViewOriginY + imageViewHeight == workspaceMaxY) {
        coefficientY = 1;
    }
    else {
        coefficientY = imageViewOriginY / workspaceMaxY;
    }
}

-(void)addOnChangesListener {
    __weak ViewController *weakSelf = self;
    [sharedObject addChangesListener:^(SharedObjectChanges *changes) {
        CGFloat coefX = [[changes.data valueForKey:@"coefX"] floatValue];
        CGFloat coefY = [[changes.data valueForKey:@"coefY"] floatValue];
        [weakSelf animateImageViewMoving:coefX :coefY];
    } error:^(Fault *fault) {
        [weakSelf showErrorAlert:fault.message];
    }];
}

-(void)animateImageViewMoving:(CGFloat)coefX :(CGFloat)coefY {
    if (coefX == 0) {
        imageViewOriginX = workspaceMinX;
    }
    else if (coefX == 1) {
        imageViewOriginX = workspaceMaxX - imageViewWidth;
    }
    else {
        imageViewOriginX = coefX * (workspaceMaxX - imageViewWidth);
    }
    if (coefY == 0) {
        imageViewOriginY = workspaceMinY;
    }
    else if (coefY == 1) {
        imageViewOriginY = workspaceMaxY - imageViewHeight;
    }
    else {
        imageViewOriginY = coefY * (workspaceMaxY - imageViewWidth);
    }
    if (!isDragging) {
        [UIView animateWithDuration:0.3 animations:^{
            self.imageView.frame = CGRectMake(self->imageViewOriginX, self->imageViewOriginY, self->imageViewWidth, self->imageViewHeight);
        }];
    }
}

-(void)addRTListeners {
    __weak __block SharedObject *weakSharedObject = sharedObject;
    [backendless.rt addConnectEventListener:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            self.connectButton.enabled = YES;
            if ([self.connectButton.title isEqualToString:@"Connect"]) {
                self.navigationItem.title = @"Status: disconnected";
            }
            else if ([self.connectButton.title isEqualToString:@"Disconnect"]) {
                self.navigationItem.title = @"Status: connected";
            }
            if (!weakSharedObject.isConnected) {
                [weakSharedObject connect];
            }
        });
    }];
    [backendless.rt addConnectErrorEventListener:^(NSString *connectError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.connectButton.enabled = NO;
            weakSharedObject = [backendless.sharedObject connect:SHARED_OBJECT_NAME];
            self.navigationItem.title = [NSString stringWithFormat:@"Status: %@", connectError];
        });
    }];
    [backendless.rt addDisonnectEventListener:^(NSString *disconnectReason) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.connectButton.enabled = NO;
            weakSharedObject = [backendless.sharedObject connect:SHARED_OBJECT_NAME];
            self.navigationItem.title = [NSString stringWithFormat:@"Status: %@", disconnectReason];
        });
    }];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    isDragging = YES;
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    isDragging = NO;
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (imageMoveEnabled) {
        UITouch *touch = [touches anyObject];
        CGPoint location = [touch locationInView:self.view];
        self.imageView.center = location;
        
        imageViewOriginX = self.imageView.frame.origin.x;
        imageViewOriginY = self.imageView.frame.origin.y;
        
        if (imageViewOriginX <= workspaceMinX) {
            imageViewOriginX = workspaceMinX;
            location.x = workspaceMinX + imageViewWidth / 2;
        }
        if (imageViewOriginX + imageViewWidth >= workspaceMaxX) {
            imageViewOriginX = workspaceMaxX - imageViewWidth;
            location.x = workspaceMaxX - imageViewWidth / 2;
        }
        if (imageViewOriginY <= workspaceMinY) {
            imageViewOriginY = workspaceMinY;
            location.y = workspaceMinY + imageViewHeight / 2;
        }
        if (imageViewOriginY + imageViewHeight >= workspaceMaxY) {
            imageViewOriginY = workspaceMaxY - imageViewHeight;
            location.y = workspaceMaxY - imageViewHeight / 2;
        }
        self.imageView.center = location;
        [self calculateCoefficients];
        
        __weak ViewController *weakSelf = self;
        [sharedObject set:LOCATION_COEFITIENTS data:@{@"coefX" : [NSNumber numberWithFloat:coefficientX], @"coefY" : [NSNumber numberWithFloat:coefficientY]} response:^(id setResponse) {
        } error:^(Fault *fault) {
            [weakSelf showErrorAlert:fault.message];
        }];
    }
}

- (void)showErrorAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:^{
        self.textView.hidden = NO;
        self.imageView.hidden = YES;
        self->imageMoveEnabled = NO;
    }];
}

- (IBAction)pressedConnect:(id)sender {
    __weak ViewController *weakSelf = self;
    if ([self.connectButton.title isEqualToString:@"Connect"]) {
        self.connectButton.title = @"Disconnect";
        if (!sharedObject.isConnected) {
            [sharedObject connect];
            [self addOnChangesListener];
        }
        [sharedObject addConnectListener:^{
            weakSelf.navigationItem.title = @"Status: connected";
            weakSelf.textView.hidden = YES;
            weakSelf.imageView.hidden = NO;
            self->imageMoveEnabled = YES;
        } error:^(Fault *fault) {
            [weakSelf showErrorAlert:fault.message];
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
