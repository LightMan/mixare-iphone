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

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import "ListViewController.h"
#import "AugmentedViewController.h"
#import "JsonHandler.h"
#import "MapViewController.h"
#import "MarkerView.h"
#import "MoreViewController.h"
#import "SourceViewController.h"

@interface MixareAppDelegate : NSObject <UIApplicationDelegate, ARViewDelegate, UITabBarControllerDelegate, CLLocationManagerDelegate>{
	
@private
	CLLocationManager *_mainLocationManager;
    BOOL _beforeWasLandscape;
	BOOL _firstPositionDetected;
	float _radius;
	
	//IBOutlets
    UIWindow *_window;		
	UITabBarController *_tabBarController;
	AugmentedViewController *_auViewController;
	NSMutableArray * _poisData;

// -----------------------------------------------------------------------------
	
    UILabel *maxRadiusLabel;
    SourceViewController *_sourceViewController;
}

@property (nonatomic, retain) CLLocationManager *mainLocationManager;
@property (nonatomic, retain) NSMutableArray *poisData;

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@property (nonatomic, retain) IBOutlet AugmentedViewController *auViewController;

// -----------------------------------------------------------------------------


@property (nonatomic, retain) IBOutlet SourceViewController *sourceViewController;

- (void)initARView;
- (void)initLocationManager;
- (void)mapData;
- (void)downloadData;
- (BOOL)checkIfDataSourceIsEnabled:(NSString *)source;
//- (void)setViewToLandscape:(UIView*)viewObject;
//- (void)setViewToPortrait:(UIView*)viewObject;

// ARViewDelegate
- (MarkerView *)viewForCoordinate:(PoiItem *)coordinate;
- (void)viewDidClose;


@end
