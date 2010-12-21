/*
 * Copyright (C) 2010- Peer internet solutions
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
 * this program. If not, see <http://www.gnu.org/licenses/>
 */

#import "MixareAppDelegate.h"
#import "SourceViewController.h"
#import "JsonHandler.h"
#import "PhysicalPlace.h"
#import "DataSource.h"


#define degreesToRadian(x) (M_PI * (x) / 180.0)
#define CAMERA_TRANSFORM 1.12412
 

@implementation MixareAppDelegate

const int kCameraTabBarIndex = 0;
const int kSourcesTabBarIndex = 1;
const int kListTabBarIndex = 2;
const int kMapTabBarIndex = 3;
const int kMoreTabBarIndex = 4;

const float kDefaultRadius = 5.0f;

@synthesize mainLocationManager = _mainLocationManager;
@synthesize locationDelegate = _locationDelegate;

@synthesize poisData = _poisData;
@synthesize sourceViewController = _sourceViewController;

// IBOutlets
@synthesize auViewController = _auViewController;
@synthesize window = _window;
@synthesize tabBarController = _tabBarController;

#pragma mark -
#pragma  mark URL Handler
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
	NSLog(@"the url: %@", [url absoluteString]);
	if (!url) {  return NO; }
    NSString *URLString = [url absoluteString];
    [[NSUserDefaults standardUserDefaults] setObject:URLString forKey:@"extern_url"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return YES;
}

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    		
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	_radius = [defaults floatForKey:@"radius"];
	//No radius set
	if (_radius == 0.0) 
		_radius = kDefaultRadius;
 	
	///TODO: Remove these 3 lines 
	[defaults setBool:YES forKey:@"Wikipedia"];
	[defaults setBool:NO forKey:@"Buzz"];
	[defaults setBool:NO forKey:@"Twitter"];  

	
	[self initLocationManager];
	[self initARView];
	    	
    _beforeWasLandscape = NO;
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
	
    ((UITabBarItem *)[self.tabBarController.tabBar.items objectAtIndex:0]).title = NSLocalizedString(@"Camera", @"First tabbar icon");
    ((UITabBarItem *)[self.tabBarController.tabBar.items objectAtIndex:1]).title = NSLocalizedString(@"Sources", @"2 tabbar icon");
    ((UITabBarItem *)[self.tabBarController.tabBar.items objectAtIndex:2]).title = NSLocalizedString(@"List View", @"3 tabbar icon");
    ((UITabBarItem *)[self.tabBarController.tabBar.items objectAtIndex:3]).title = NSLocalizedString(@"Map", @"4 tabbar icon");
	
	self.window.rootViewController = self.auViewController; //Available >= 4.0
	//    [self.window addSubview:self.auViewController.view];
	
	[self.window makeKeyAndVisible];
	
	///TODO: Remove later
//    if (![defaults boolForKey:@"mixareInitialized"]) {
//        UIAlertView *addAlert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"License",nil)message:@"Copyright (C) 2010- Peer internet solutions\n This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. \n This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. \nYou should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/" delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil, nil];
//        [addAlert show];
//        [addAlert release];
//        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"mixareInitialized"];
//    }
	
	return YES;
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}

- (void)dealloc {	
	[_mainLocationManager release];
	
    [_tabBarController release];
    [_window release];
	
    [super dealloc];
}

#pragma mark -
#pragma mark locationManager
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
	if (!_firstPositionDetected && self.auViewController != nil){
		_firstPositionDetected = YES;
		[self downloadData];
		[self mapData];					
	}
	
	// Notify all the delegates
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

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
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

#pragma mark -
#pragma mark rotation control methods

-(void)didRotate:(NSNotification *)notification{ 
    //Maintain the camera in Landscape orientation [[UIDevice currentDevice] setOrientation:UIInterfaceOrientationLandscapeRight];
    //UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft){
		[self.auViewController willRotateToInterfaceOrientation:UIInterfaceOrientationLandscapeLeft	duration:1.0];
        _beforeWasLandscape = YES;
    }
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortrait && _beforeWasLandscape){
		[self.auViewController willRotateToInterfaceOrientation:UIInterfaceOrientationPortrait	duration:1.0];
        _beforeWasLandscape = NO;
    }
	
	// -----------------------------------------------------------------------------
	// Debug Orientation
	NSString *orientation;
	switch ([[UIDevice currentDevice] orientation]) {
	case UIDeviceOrientationUnknown:
		orientation = @"UIDeviceOrientationUnknown";
		break;
	case UIDeviceOrientationPortrait:
		orientation = @"UIDeviceOrientationPortrait";
		break;
	case UIDeviceOrientationPortraitUpsideDown:
		orientation = @"UIDeviceOrientationPortraitUpsideDown";
		break;
	case UIDeviceOrientationLandscapeLeft:
		orientation = @"UIDeviceOrientationLandscapeLeft";
		break;
	case UIDeviceOrientationLandscapeRight:
		orientation = @"UIDeviceOrientationLandscapeRight";
		break;
	case UIDeviceOrientationFaceUp:
		orientation = @"UIDeviceOrientationFaceUp";
		break;
	case UIDeviceOrientationFaceDown:
		orientation = @"UIDeviceOrientationFaceDown";
		break;
	default:
		orientation = @"Orientación desconocida";		
	}
    NSLog(@"DID ROTATE to orientation %@", orientation);
}

- (void)initARView {
	if (self.auViewController == nil) {
		self.auViewController = [[[AugmentedViewController alloc] initWithNibName:@"AugmentedViewController" bundle:nil] autorelease];		
	}
	self.auViewController.debugMode = YES;
	self.auViewController.ARViewDelegate = self;
	self.locationDelegate = self.auViewController;
	[self.auViewController startListening:self.mainLocationManager];
}

- (void)initLocationManager{
	if (self.mainLocationManager == nil){
		self.mainLocationManager = [[[CLLocationManager alloc] init] autorelease];
		self.mainLocationManager.desiredAccuracy = kCLLocationAccuracyBest;
		self.mainLocationManager.delegate = self;
		self.mainLocationManager.distanceFilter = 3.0;
		[self.mainLocationManager startUpdatingLocation];		
	}
}

-(void)mapData{
	if (self.poisData != nil){
		CLLocation *tempLocation;
		PhysicalPlace *tempCoordinate;
		for (NSDictionary *poi in self.poisData){
			CGFloat alt = [[poi valueForKey:@"alt"]floatValue];
			if(alt ==0.0){
				alt = self.mainLocationManager.location.altitude+50;
			}
			float lat = [[poi valueForKey:@"lat"]floatValue];
			float lon = [[poi valueForKey:@"lon"]floatValue];
			
			tempLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(lat, lon) altitude:alt horizontalAccuracy:1.0 verticalAccuracy:1.0 timestamp:nil];
			tempCoordinate = [PhysicalPlace coordinateWithLocation:tempLocation];
			tempCoordinate.title = [poi valueForKey:@"title"];
			tempCoordinate.source = [poi valueForKey:@"source"];
            tempCoordinate.url = [poi valueForKey:@"url"];
			[self.auViewController addCoordinate:tempCoordinate animated:NO];
			[tempLocation release];
		}
	}else
		NSLog(@"no data received");
	
	if (self.auViewController != nil && self.mainLocationManager != nil)
		[self.auViewController recalculateDataWithNewLocation:self.mainLocationManager.location];
	
	[self.auViewController hideLoadingViewOnMainThread];	
}

//Method wich manages the download of data specified by the user. The standard source is wikipedia. By selecting the different sources in the sources
//menu the appropriate data will be downloaded
-(BOOL)checkIfDataSourceIsEnabled: (NSString *)source{
	return [[NSUserDefaults standardUserDefaults] boolForKey:source];
}

-(void)downloadData{
	JsonHandler *jHandler = [[JsonHandler alloc]init];
	CLLocation *pos = self.mainLocationManager.location;
	NSString *wikiData;
    NSString *mixareData;
    NSString *twitterData;
	NSString *buzzData;
	    
    if ([self checkIfDataSourceIsEnabled:@"Wikipedia"]){
        NSLog(@"Downloading Wiki data");
        NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
        NSLog(@"Language: %@",language);
        wikiData = [[NSString alloc]initWithContentsOfURL:[NSURL URLWithString:[DataSource createRequestURLFromDataSource:@"WIKIPEDIA" Lat:pos.coordinate.latitude Lon:pos.coordinate.longitude Alt:pos.altitude radius:_radius Lang:language]] encoding:NSUTF8StringEncoding error:nil];
        NSLog(@"Download done");
    } else {
        wikiData = nil;
    }
    if ([self checkIfDataSourceIsEnabled:@"Buzz"]){
        NSLog(@"Downloading Buzz data");
        buzzData = [[NSString alloc]initWithContentsOfURL:[NSURL URLWithString:[DataSource createRequestURLFromDataSource:@"BUZZ" Lat:pos.coordinate.latitude Lon:pos.coordinate.longitude Alt:700 radius:_radius Lang:@"de"]]encoding:NSUTF8StringEncoding error:nil];
        NSLog(@"Download done");
    } else {
        buzzData = nil;
    }
	
    if ([self checkIfDataSourceIsEnabled:@"Twitter"]){
        NSLog(@"Downloading Twitter data");
        twitterData = [[NSString alloc]initWithContentsOfURL:[NSURL URLWithString:[DataSource createRequestURLFromDataSource:@"TWITTER" Lat:pos.coordinate.latitude Lon:pos.coordinate.longitude Alt:700 radius:_radius Lang:@"de"]]encoding:NSUTF8StringEncoding error:nil];
        NSLog(@"Download done");
    } else {
        twitterData = nil;
    }
    //User specific Sources .. 
    if (self.sourceViewController != nil && [self.sourceViewController.dataSourceArray count]>3){
        //datasource contains sources added by the user
        NSLog(@"Downloading Mixare data");
        //mixareData = [[NSString alloc]initWithContentsOfURL:[NSURL URLWithString:@"http://www.suedtirolerland.it/api/map/getARData/?client%5Blat%5D=46.47895932197436&client%5Blng%5D=11.295661926269203&client%5Brad%5D=100&lang_id=1&project_id=15&showTypes=13%2C14&key=51016f95291ef145e4b260c51b06af61"] encoding:NSUTF8StringEncoding error:nil];
        //getting selected Source
        NSString * customURL;
        for(int i=3;i< [self.sourceViewController.dataSourceArray count];i++){
            if([self checkIfDataSourceIsEnabled:[self.sourceViewController.dataSourceArray objectAtIndex:i]]){
                customURL = [NSString stringWithFormat:@"http://%@",[self.sourceViewController.dataSourceArray objectAtIndex:i]];
            }
        }
		
        NSURL *customDsURL;
        @try {
            customDsURL = [NSURL URLWithString:customURL];
            mixareData = [[NSString alloc]initWithContentsOfURL:customDsURL];
            NSLog(@"Download done");
        }
        @catch (NSException *exception) {
            NSLog(@"ERROR Downloading custom ds");
        }
        @finally {
            
        }
    } else {
        mixareData = nil;
    }
 
    [self.poisData removeAllObjects];
	
    if (wikiData != nil){
        self.poisData= [jHandler processWikipediaJSONData:wikiData];
        NSLog(@"data count: %d", [self.poisData count]);
        [wikiData release];
    }
    if (buzzData != nil){
        [self.poisData addObjectsFromArray:[jHandler processBuzzJSONData:buzzData]];
        NSLog(@"data count: %d", [self.poisData count]);
        [buzzData release];
    }
    if (twitterData != nil && ![twitterData isEqualToString:@""]){
       [self.poisData addObjectsFromArray:[jHandler processTwitterJSONData:twitterData]]; 
        NSLog(@"data count: %d", [self.poisData count]);
        [twitterData release];
    }
    if (mixareData != nil && ![mixareData isEqualToString:@""]){
        [self.poisData addObjectsFromArray:[jHandler processMixareJSONData:mixareData]];
        NSLog(@"data count: %d", [self.poisData count]);
        [mixareData release];
    }	
    
	[jHandler release];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"extern_url"];
}

#pragma mark -
#pragma mark UITabBarControllerDelegate methods


// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
//	if(tabBarController.selectedIndex == kCameraTabBarIndex){
//		NSLog(@"cam mode on");
//		//[self.locManager startUpdatingHeading];
//	}else{
//		//[self.locManager stopUpdatingHeading];
//	}
    
    if(tabBarController.selectedIndex == kCameraTabBarIndex ){
		[self.auViewController removeCoordinates:self.poisData];
        [self downloadData];
		[self mapData];		
        [self initARView];
		
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
	} else {
		[self.auViewController stopListening:self.mainLocationManager];
		
        if (tabBarController.selectedIndex == kSourcesTabBarIndex) {

			ListViewController *listViewController = (ListViewController *)[[[tabBarController viewControllers] objectAtIndex:kListTabBarIndex] visibleViewController];
			
            if (listViewController.dataSourceArray != nil){
                listViewController.dataSourceArray = nil;
            }
        }
		
        if (tabBarController.selectedIndex == kListTabBarIndex ){
			ListViewController *listViewController = (ListViewController *)[[[tabBarController viewControllers] objectAtIndex:kListTabBarIndex] visibleViewController];
            if (self.poisData != nil){
                listViewController.dataSourceArray =nil;
                NSLog(@"data set");
                [listViewController setDataSourceArray:self.poisData];
                [listViewController.tableView reloadData];
                NSLog(@"elements in data: %d in datasource: %d", [self.poisData count], [listViewController.dataSourceArray count]);
            }else{
                NSLog(@"data NOOOOT set");
            }
        }
		
        if(tabBarController.selectedIndex == kMapTabBarIndex ){
            NSLog(@"map");
            if (self.poisData != nil){
                NSLog(@"data map set");
				MapViewController *mapViewController = (MapViewController*) viewController; 
                [mapViewController setData:self.poisData];
                [mapViewController mapDataToMapAnnotations];
            }
        }
		
        if (tabBarController.selectedIndex == kMoreTabBarIndex ){ //_moreViewController
            NSLog(@"latitude: %f", self.mainLocationManager.location.coordinate.latitude);
            [(MoreViewController*)viewController showGPSInfo:self.mainLocationManager.location.coordinate.latitude
														 lng:self.mainLocationManager.location.coordinate.longitude
														 alt:self.mainLocationManager.location.altitude
													   speed:self.mainLocationManager.location.speed
														date:self.mainLocationManager.location.timestamp];
			
        }
    }
	
}

- (void)poiButtonPressed:(id)object {
	NSLog(@"Button pressed"); /* DEBUG LOG */
}

#pragma mark -
#pragma mark ARViewDelegate
- (MarkerView *)viewForCoordinate:(PoiItem *)coordinate {	
	const float kBoxWidth = 150.0f;
	const float kBoxHeight = 100.0f;

	CGRect theFrame = CGRectMake(0, 0, kBoxWidth, kBoxHeight);
	MarkerView *tempView = [[MarkerView alloc] initWithFrame:theFrame];
		
	UIImage* buttonImage = nil;
	if ([coordinate.source isEqualToString:@"WIKIPEDIA"] || [coordinate.source isEqualToString:@"MIXARE"]){
		buttonImage = [UIImage imageNamed:@"circle.png"];
	}else if([coordinate.source isEqualToString:@"TWITTER"]){
        buttonImage = [UIImage imageNamed:@"twitter_logo.png"];
	}else if([coordinate.source isEqualToString:@"BUZZ"]){
		buttonImage = [UIImage imageNamed:@"buzz_logo.png"];
	} else
		buttonImage = [UIImage imageNamed:@"circle.png"];		
	
	CGRect buttonFrame = CGRectMake( (kBoxWidth - buttonImage.size.width) / 2.0, 0, buttonImage.size.width, buttonImage.size.height);
	
	UIButton *poiButton = [[UIButton alloc] initWithFrame:buttonFrame];
	[poiButton setImage:buttonImage forState:UIControlStateNormal];
	[poiButton addTarget:self action:@selector(poiButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	
	UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, kBoxHeight / 2.0 , kBoxWidth, 20.0)];
	titleLabel.backgroundColor = [UIColor colorWithWhite:.3 alpha:.8];
	titleLabel.textColor = [UIColor whiteColor];
	titleLabel.textAlignment = UITextAlignmentCenter;
	titleLabel.text = coordinate.title;
    if ([coordinate.source isEqualToString:@"BUZZ"]){
        //wrapping long buzz messages
        titleLabel.lineBreakMode = UILineBreakModeCharacterWrap;
        titleLabel.numberOfLines = 0;
        CGRect frame = [titleLabel frame];
        CGSize size = [titleLabel.text sizeWithFont:titleLabel.font	constrainedToSize:CGSizeMake(frame.size.width, 9999) lineBreakMode:UILineBreakModeClip];
        frame.size.height = size.height;
        [titleLabel setFrame:frame];
    }else{
        //Markers get automatically resized
        [titleLabel sizeToFit];
	}
	
	titleLabel.frame = CGRectMake(kBoxWidth / 2.0 - titleLabel.frame.size.width / 2.0 - 4.0, buttonImage.size.height + 5, titleLabel.frame.size.width + 8.0, titleLabel.frame.size.height + 8.0);
		
    tempView.url = coordinate.url;
	
	[tempView addSubview:titleLabel];
	[tempView addSubview:poiButton];
	
	[poiButton release];
	[titleLabel release];
	
    tempView.userInteractionEnabled = YES;
    
	return [tempView autorelease];
}

- (void)viewDidClose {
	[self.auViewController closeCameraView];
	[self.auViewController.view removeFromSuperview];
	[self.auViewController release];
	
	self.tabBarController.selectedIndex = kSourcesTabBarIndex;
	[self tabBarController:self.tabBarController didSelectViewController:[self.tabBarController.viewControllers objectAtIndex:kSourcesTabBarIndex]];		
	
	[UIApplication sharedApplication].statusBarHidden = NO;
	[UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
	
	self.window.rootViewController = self.tabBarController;
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceOrientationDidChangeNotification" object:nil];	
}

- (void)sliderValueChanged:(UISlider*)slider {
	_radius = slider.value;
	[self.auViewController removeCoordinates:self.poisData];	
    [[NSUserDefaults standardUserDefaults] setFloat:slider.value forKey:@"radius"];
	[self downloadData];
	[self mapData];	
//    [self initARView];
    
	NSLog(@"POIS CHANGED");	
}

@end

