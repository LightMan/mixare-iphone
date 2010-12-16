/* Copyright (C) 2010- Peer internet solutions
 * 
 * This file is part of mixare.
 * 
 * This program is free software: you can redistribute it and/or modify it 
 * under the terms of the GNU General Public License as published by 
 * the Free Software Foundation, either version 3 of the License, or 
 * (at your option) any later version. 
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License 
 * for more details. 
 * 
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see <http://www.gnu.org/licenses/> */

#import "AugmentedViewController.h"

#import <QuartzCore/QuartzCore.h>

#define VIEWPORT_WIDTH_RADIANS 0.5
#define VIEWPORT_HEIGHT_RADIANS .7392


// Private methods and properties
@interface AugmentedViewController()

@property (nonatomic, retain) UIImagePickerController *cameraController;

@end


@implementation AugmentedViewController

// -----------------------------------------------------------------------------

@synthesize cameraController = _cameraController;
@synthesize radarView = _radarView;
@synthesize radarScopeView = _radarScopeView;
@synthesize ARViewDelegate = _ARViewdelegate;
@synthesize locationDelegate = _locationDelegate;
@synthesize accelerometerDelegate = _accelerometerDelegate;
@synthesize locationManager = _locationManager;
@synthesize accelerometerManager = _accelerometerManager;
@synthesize debugMode = _debugMode;
@synthesize lblDebug = _lblDebug;

//IBOutlets
@synthesize radiusSlider = _radiusSlider;
@synthesize lblCurrentDistance = _lblCurrentDistance;
@synthesize notificationView = _notificationView;

// -----------------------------------------------------------------------------

@synthesize centerCoordinate = _centerCoordinate;

@synthesize scaleViewsBasedOnDistance, rotateViewsBasedOnPerspective;
@synthesize maximumScaleDistance;
@synthesize minimumScaleFactor, maximumRotationAngle;

@synthesize updateFrequency;
@synthesize coordinates = ar_coordinates;


// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		ar_coordinates = [[NSMutableArray alloc] init];
		ar_coordinateViews = [[NSMutableArray alloc] init];
		
		self.updateFrequency = 1 / 20.0;	
		self.scaleViewsBasedOnDistance = NO;
		self.maximumScaleDistance = 0.0;
		self.minimumScaleFactor = 1.5;
		
		self.rotateViewsBasedOnPerspective = YES;
		self.maximumRotationAngle = M_PI / 6.0;
		
		self.wantsFullScreenLayout = NO;
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	[ar_overlayView release];
	ar_overlayView = [[UIView alloc] initWithFrame:CGRectZero];
	
#if !TARGET_IPHONE_SIMULATOR	
	self.cameraController = [[[UIImagePickerController alloc] init] autorelease];
	self.cameraController.sourceType = UIImagePickerControllerSourceTypeCamera;
	CGAffineTransform cameraTransform = CGAffineTransformMakeScale(1.232, 1.232);
	self.cameraController.cameraViewTransform = cameraTransform;//CGAffineTransformScale(self.cameraController.cameraViewTransform, 1.23f,  1.23f);
	
	self.cameraController.showsCameraControls = NO;
	self.cameraController.navigationBarHidden = YES;
#endif
		
    float radius = [[NSUserDefaults standardUserDefaults] floatForKey:@"radius"];
    if (radius <= 0 || radius > 100){
        self.radiusSlider.value = 5.0;
        self.lblCurrentDistance.text= @"5.0 km";
    }else{
        self.radiusSlider.value = radius;
        NSLog(@"RADIUS VALUE: %f", radius);
        self.lblCurrentDistance.text= [NSString stringWithFormat:@"%.2f km",radius];
    }
	
	self.scaleViewsBasedOnDistance = YES;
	self.minimumScaleFactor = 0.6;
	self.rotateViewsBasedOnPerspective = YES;
						
	if (self.debugMode) {
		self.lblDebug = [[[UILabel alloc] initWithFrame:CGRectMake(0,
																   ar_overlayView.frame.size.height - _lblDebug.frame.size.height,
																   ar_overlayView.frame.size.width,
																   _lblDebug.frame.size.height)] autorelease];
		self.lblDebug.textAlignment = UITextAlignmentCenter;
		self.lblDebug.text = @"Waiting...";
		[self.lblDebug sizeToFit];
		[ar_overlayView addSubview:self.lblDebug];
	}
	
	[self.view addSubview:ar_overlayView];	
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];	
	[self showLoadingView];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
#if !TARGET_IPHONE_SIMULATOR
//	[ar_overlayView setFrame:self.cameraController.view.bounds];
//	[ar_overlayView setFrame:self.cameraController.view.bounds];
//	[self.view setFrame:self.cameraController.view.bounds];
	[self.cameraController setCameraOverlayView:self.view];
	[self presentModalViewController:self.cameraController animated:NO];	
#endif
	
	if (!_updateTimer) {
		_updateTimer = [[NSTimer scheduledTimerWithTimeInterval:self.updateFrequency
														 target:self
													   selector:@selector(updateLocations:)
													   userInfo:nil
														repeats:YES] retain];
	}
	
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	[ar_overlayView release];
	ar_overlayView = nil;
	
	
	self.radiusSlider = nil;
	self.radarView = nil;
	self.radarScopeView = nil;
	self.lblCurrentDistance = nil;
}


- (void)dealloc {
	[_lblDebug release];
	[ar_coordinateViews release];
	[ar_coordinates release];
	
// -----------------------------------------------------------------------------
	
	[_radiusSlider release];
	[_radarView release];
	[_radarScopeView release];
	[_lblCurrentDistance release];
	[_locationManager release];
	
    [super dealloc];
}

- (void)closeCameraView{
	[self.cameraController.view removeFromSuperview];
	[self.cameraController release];
}

- (void)setUpdateFrequency:(double)newUpdateFrequency {
	
	updateFrequency = newUpdateFrequency;
	
	if (!_updateTimer)
		return;
	
	[_updateTimer invalidate];
	[_updateTimer release];
	
	_updateTimer = [[NSTimer scheduledTimerWithTimeInterval:self.updateFrequency
													 target:self
												   selector:@selector(updateLocations:)
												   userInfo:nil
													repeats:YES] retain];
}

- (void)setDebugMode:(BOOL)flag {
	if (_debugMode == flag)
		return;
	
	_debugMode = flag;
	
	//we don't need to update the view.
	if (![self isViewLoaded])
		return;
	
	if (_debugMode)
		[ar_overlayView addSubview:self.lblDebug];
	else
		[self.lblDebug removeFromSuperview];
}

- (BOOL)viewportContainsCoordinate:(PoiItem *)coordinate {
	double centerAzimuth = self.centerCoordinate.azimuth;
	double leftAzimuth = centerAzimuth - VIEWPORT_WIDTH_RADIANS / 2.0;
	
	if (leftAzimuth < 0.0) {
		leftAzimuth = 2 * M_PI + leftAzimuth;
	}
	
	double rightAzimuth = centerAzimuth + VIEWPORT_WIDTH_RADIANS / 2.0;
	
	if (rightAzimuth > 2 * M_PI) {
		rightAzimuth = rightAzimuth - 2 * M_PI;
	}
	
	BOOL result = (coordinate.azimuth > leftAzimuth && coordinate.azimuth < rightAzimuth);
	
	if(leftAzimuth > rightAzimuth) {
		result = (coordinate.azimuth < rightAzimuth || coordinate.azimuth > leftAzimuth);
	}
	
	double centerInclination = self.centerCoordinate.inclination;
	double bottomInclination = centerInclination - VIEWPORT_HEIGHT_RADIANS / 2.0;
	double topInclination = centerInclination + VIEWPORT_HEIGHT_RADIANS / 2.0;
	
	//check the height.
	result = result && (coordinate.inclination > bottomInclination && coordinate.inclination < topInclination);
	
	//NSLog(@"coordinate: %@ result: %@", coordinate, result?@"YES":@"NO");
	
	return result;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	NSLog(@"shouldAutorotateToInterfaceOrientation %d", interfaceOrientation); /* DEBUG LOG */
	return YES;
}

- (CGPoint)pointInView:(MarkerView *)realityView forCoordinate:(PoiItem *)coordinate {
	
	CGPoint point;
	
	//x coordinate.
	
	double pointAzimuth = coordinate.azimuth;
	
	//our x numbers are left based.
	double leftAzimuth = self.centerCoordinate.azimuth - VIEWPORT_WIDTH_RADIANS / 2.0;
	
	if (leftAzimuth < 0.0) {
		leftAzimuth = 2 * M_PI + leftAzimuth;
	}
	
	if (pointAzimuth < leftAzimuth) {
		//it's past the 0 point.
		point.x = ((2 * M_PI - leftAzimuth + pointAzimuth) / VIEWPORT_WIDTH_RADIANS) * realityView.frame.size.width;
	} else {
		point.x = ((pointAzimuth - leftAzimuth) / VIEWPORT_WIDTH_RADIANS) * realityView.frame.size.width;
	}
	
	//y coordinate.
	
	double pointInclination = coordinate.inclination;
	
	double topInclination = self.centerCoordinate.inclination - VIEWPORT_HEIGHT_RADIANS / 2.0;
	
	point.y = realityView.frame.size.height - ((pointInclination - topInclination) / VIEWPORT_HEIGHT_RADIANS) * realityView.frame.size.height;
    
	return point;
}

-(CGPoint) rotatePointAboutOrigin:(CGPoint) point angle: (float) angle{
    float s = sinf(angle);
    float c = cosf(angle);
    return CGPointMake(c * point.x - s * point.y, s * point.x + c * point.y);
}


- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
	const float kFilteringFactor = 0.05f;
	UIAccelerationValue rollingX, rollingZ;

	// -1 face down.
	// 1 face up.
	
	//update the center coordinate.
	
	//NSLog(@"x: %f y: %f z: %f", acceleration.x, acceleration.y, acceleration.z);
	
	//this should be different based on orientation.
	if([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft){
        rollingZ  = (acceleration.z * kFilteringFactor) + (rollingZ  * (1.0 - kFilteringFactor));
        rollingX = (acceleration.x * kFilteringFactor) + (rollingX * (1.0 - kFilteringFactor));
    }else{
        rollingZ  = (acceleration.z * kFilteringFactor) + (rollingZ  * (1.0 - kFilteringFactor));
        rollingX = (acceleration.y * kFilteringFactor) + (rollingX * (1.0 - kFilteringFactor));
	}
	if (rollingZ > 0.0) {
		self.centerCoordinate.inclination = atan(rollingX / rollingZ) + M_PI / 2.0;
	} else if (rollingZ < 0.0) {
		self.centerCoordinate.inclination = atan(rollingX / rollingZ) - M_PI / 2.0;// + M_PI;
	} else if (rollingX < 0) {
		self.centerCoordinate.inclination = M_PI/2.0;
	} else if (rollingX >= 0) {
		self.centerCoordinate.inclination = 3 * M_PI/2.0;
	}
	
	if (self.accelerometerDelegate && [self.accelerometerDelegate respondsToSelector:@selector(accelerometer:didAccelerate:)]) {
		//forward the acceleromter.
		[self.accelerometerDelegate accelerometer:accelerometer didAccelerate:acceleration];
	}
}

NSComparisonResult LocationSortClosestFirst(PoiItem *s1, PoiItem *s2, void *ignore) {
    if (s1.radialDistance < s2.radialDistance) {
		return NSOrderedAscending;
	} else if (s1.radialDistance > s2.radialDistance) {
		return NSOrderedDescending;
	} else {
		return NSOrderedSame;
	}
}

- (void)addCoordinate:(PoiItem *)coordinate animated:(BOOL)animated {
	//do some kind of animation?
	[ar_coordinates addObject:coordinate];
	
	if (coordinate.radialDistance > self.maximumScaleDistance) {
		self.maximumScaleDistance = coordinate.radialDistance;
	}
	
	//message the delegate.
	[ar_coordinateViews addObject:[self.ARViewDelegate viewForCoordinate:coordinate]];
}

- (void)removeCoordinates:(NSMutableArray *)coordinates {	
	[ar_coordinates removeAllObjects];
	[ar_coordinateViews removeAllObjects];
    for (UIView * view in ar_overlayView.subviews){
        [view removeFromSuperview];
    }
}

- (void)updateLocations:(NSTimer *)timer {
	//update locations!
	
	if (!ar_coordinateViews || ar_coordinateViews.count == 0) {
		return;
	}
	
	_lblDebug.text = [self.centerCoordinate description];
	
	int index = 0;
    NSMutableArray * radarPointValues= [[NSMutableArray alloc]initWithCapacity:[ar_coordinates count]];
    
	for (PoiItem *item in ar_coordinates) {
		
		MarkerView *viewToDraw = [ar_coordinateViews objectAtIndex:index];
		
		if ([self viewportContainsCoordinate:item]) {
			
			CGPoint loc = [self pointInView:ar_overlayView forCoordinate:item];
			CGFloat scaleFactor = 1.5;
			if (self.scaleViewsBasedOnDistance) {
				scaleFactor = 1.0 - self.minimumScaleFactor * (item.radialDistance / self.maximumScaleDistance);
			}
			
			float width = viewToDraw.bounds.size.width * scaleFactor;
			float height = viewToDraw.bounds.size.height * scaleFactor;
			
			viewToDraw.frame = CGRectMake(loc.x - width / 2.0, loc.y-height / 2.0, width, height);
			
			CATransform3D transform = CATransform3DIdentity;
			
			//set the scale if it needs it.
			if (self.scaleViewsBasedOnDistance) {
				//scale the perspective transform if we have one.
				transform = CATransform3DScale(transform, scaleFactor, scaleFactor, scaleFactor);
			}
			
			if (self.rotateViewsBasedOnPerspective) {
				transform.m34 = 1.0 / 300.0;
				
				double itemAzimuth = item.azimuth;
				double centerAzimuth = self.centerCoordinate.azimuth;
				if (itemAzimuth - centerAzimuth > M_PI) centerAzimuth += 2*M_PI;
				if (itemAzimuth - centerAzimuth < -M_PI) itemAzimuth += 2*M_PI;
				
				double angleDifference = itemAzimuth - centerAzimuth;
				transform = CATransform3DRotate(transform, self.maximumRotationAngle * angleDifference / (VIEWPORT_HEIGHT_RADIANS / 2.0) , 0, 1, 0);
			}
			
			viewToDraw.layer.transform = transform;
			
			//if we don't have a superview, set it up.
			if (!(viewToDraw.superview)) {
				[ar_overlayView addSubview:viewToDraw];
				[ar_overlayView sendSubviewToBack:viewToDraw];
			}
		} else {
			[viewToDraw removeFromSuperview];
			viewToDraw.transform = CGAffineTransformIdentity;
		}
        CGPoint loc = [self pointInView:ar_overlayView forCoordinate:item];
        item.radarPos = loc;
		//        if( fmod((locationManager.heading.trueHeading+item.azimuth),360)==0){
		//            item.azimuth= locationManager.heading.trueHeading+item.azimuth;
		//        }else{
		//            item.azimuth=fmod((locationManager.heading.trueHeading+item.azimuth),360);
		//        }
        [radarPointValues addObject:item];
		index++;
	}
	
    float radius = [[[NSUserDefaults standardUserDefaults] objectForKey:@"radius"] floatValue];
    
	if(radius <= 0 || radius > 100){
        radius = 5.0;
    }
    
    self.radarView.pois = radarPointValues;
    self.radarView.radius = radius;
    [self.radarView setNeedsDisplay];
	
	[radarPointValues release];
}

#pragma mark -
#pragma mark locationManager delegates and methods

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
	self.centerCoordinate.azimuth = fmod(newHeading.magneticHeading, 360.0) * (2 * (M_PI / 360.0));
    if([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft){
        if(self.centerCoordinate.azimuth <(3*M_PI/2)){
            self.centerCoordinate.azimuth += (M_PI/2);
        }else{
            self.centerCoordinate.azimuth = fmod(self.centerCoordinate.azimuth + (M_PI/2),360);
            
        }
        
    }
    int gradToRotate = newHeading.trueHeading-90-22.5;
    if([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft){
        gradToRotate+= 90;
    }
    if(gradToRotate < 0){
        gradToRotate= 360 + gradToRotate;
    }
	self.radarScopeView.referenceAngle = gradToRotate;
    [self.radarScopeView setNeedsDisplay];
	
    oldHeading = newHeading.trueHeading;
	if (self.locationDelegate && [self.locationDelegate respondsToSelector:@selector(locationManager:didUpdateHeading:)]) {
		//forward the call.
		[self.locationDelegate locationManager:manager didUpdateHeading:newHeading];
	}
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager {
	if (self.locationDelegate && [self.locationDelegate respondsToSelector:@selector(locationManagerShouldDisplayHeadingCalibration:)]) {
		//forward the call.
		return [self.locationDelegate locationManagerShouldDisplayHeadingCalibration:manager];
	}
	
	return YES;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	if (self.locationDelegate && [self.locationDelegate respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)]) {
		//forward the call.
		[self.locationDelegate locationManager:manager didUpdateToLocation:newLocation fromLocation:oldLocation];
	}
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	if (self.locationDelegate && [self.locationDelegate respondsToSelector:@selector(locationManager:didFailWithError:)]) {
		//forward the call.
		return [self.locationDelegate locationManager:manager didFailWithError:error];
	}
}

- (void)setAsLocationManagerController:(CLLocationManager *)manager withDelegate:(id<CLLocationManagerDelegate>)delegate {
	self.locationManager = manager;
	self.locationManager.delegate = self;
	self.locationDelegate = delegate;
	[self startListening];	
}

-(void)stopListening{
	if (self.locationManager != nil){
		[self.locationManager stopUpdatingHeading];
	}
}

- (void)startListening {
	//we want every move.
	self.locationManager.headingFilter = kCLHeadingFilterNone;
	self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	[self.locationManager startUpdatingHeading];
	
	if (self.accelerometerManager == nil) {
		self.accelerometerManager = [UIAccelerometer sharedAccelerometer];
	}
	self.accelerometerManager.updateInterval = 0.01;
	self.accelerometerManager.delegate = self;
	
	if (self.centerCoordinate == nil) {
		self.centerCoordinate = [PoiItem coordinateWithRadialDistance:0 inclination:0 azimuth:0];
	}
}

#pragma mark -
#pragma mark controls methods

- (IBAction)closeButtonPressed {
	[self.ARViewDelegate viewDidClose];
}

- (IBAction)radiusSliderChanged:(UISlider*)slider {
	self.lblCurrentDistance.text= [NSString stringWithFormat:@"%.2f km",slider.value];
	[self showLoadingView];
	
	[self.ARViewDelegate sliderValueChanged:slider];
}

#pragma mark -
#pragma mark loading view

- (void)showLoadingView {
	self.notificationView.hidden = NO;
}

- (void)hideLoadingView {
	self.notificationView.hidden = YES;
}

@end
