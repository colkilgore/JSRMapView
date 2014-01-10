//
//  JSRViewController.m
//  RedexpertsTask
//
//  Created by Jan Skommer on 10.01.2014.
//  Copyright (c) 2014 Jan Skommer. All rights reserved.
//

#import "JSRMainViewController.h"
#import "JSRMapAnnotation.h"
#import <MapKit/MapKit.h>

NSString *const kTaskURL = @"https://dl.dropboxusercontent.com/u/6556265/test.json";

NSString *const kLocationAlertTitle = @"Problem z Lokalizacją";
NSString *const kLocationAlertMessage = @"Usługi Lokalizacji mogą nie być włączone";
NSString *const kCloseAlertButton = @"Zamknij";

NSString *const kNetworkAlertTitle = @"Problem z Siecią";
NSString *const kNetworkAlertMessage = @"Sprawdź ustawienia połączenia internetowego i spróbuj ponownie";

NSString *const kParserAlertTitle = @"Problem z Danymi";
NSString *const kParserAlertMessage = @"Problem z przetworzeniem danych";

NSString *const kDistanceNotAvailable =  @"Brak Dystansu";
NSString *const kDistanceAvailable =  @"Dystans: %1.2f";

@interface JSRMainViewController () <MKMapViewDelegate, UIAlertViewDelegate, UIToolbarDelegate>

// Widok mapy
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

// Gorny pasek
@property (weak, nonatomic) IBOutlet UIToolbar *topBar;

// Element wyswietlajacy dystans
@property (weak, nonatomic) IBOutlet UIBarButtonItem *distanceBarButtonItem;

@end

@implementation JSRMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Ustaw siebie jako delegata MKMapView
    self.mapView.delegate = self;
    
    // Ustaw siebie jako delegata UIToolbar
    self.topBar.delegate = self;
    [self.distanceBarButtonItem setTitle:kDistanceNotAvailable];
}

#pragma mark - Wewnetrzne metody

- (void)showLocationAlert
{
    // Stworz obiekt UIAlertView w celu poinformowania uzytkownika o problemie z lokalizacja
    UIAlertView *locationAlert = [[UIAlertView alloc] initWithTitle:kLocationAlertTitle
                                                            message:kLocationAlertMessage
                                                           delegate:self
                                                  cancelButtonTitle:kCloseAlertButton otherButtonTitles:nil];
    [locationAlert show];
}

// Metoda liczaca Region otaczajacy wszystkie aktualne annotacje
- (MKCoordinateRegion)calculateRegionForAnnotations
{
    // Tworzymy najwiekszy mozliwy region
    CLLocationCoordinate2D topLeft, bottomRight;
    topLeft.latitude = -90;
    topLeft.longitude = 180;
    bottomRight.latitude = 90;
    bottomRight.longitude = -180;
    
    // szukamy najbardziej wysunietych punktow i odpowiednio dopasowujemy region
    for (id <MKAnnotation> annotation in self.mapView.annotations)
    {
        topLeft.latitude  = fmax(topLeft.latitude, annotation.coordinate.latitude);
        topLeft.longitude = fmin(topLeft.longitude, annotation.coordinate.longitude);
        
        bottomRight.latitude = fmin(bottomRight.latitude, annotation.coordinate.latitude);
        bottomRight.longitude = fmax(bottomRight.longitude, annotation.coordinate.longitude);
    }
    
    // Lekko poszerzamy region zeby elementy z krawedzi byly widoczne a nie uciete
    CLLocationCoordinate2D regionCenter = CLLocationCoordinate2DMake((topLeft.latitude + bottomRight.latitude)/2.0, (topLeft.longitude + bottomRight.longitude)/2.0);
    MKCoordinateSpan regionSpan = MKCoordinateSpanMake(fmin(fabs(topLeft.latitude - bottomRight.latitude)*1.4,180.0), fmin(fabs(topLeft.longitude - bottomRight.longitude)*1.1,360.0));
    return MKCoordinateRegionMake(regionCenter, regionSpan);
}

- (NSString*)distanceBetweenLocations
{
    NSString *distanceString = nil;
    JSRMapAnnotation *pinAnnotation = nil;
    
    // Szukamy naszej annotacji
    for (id annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[JSRMapAnnotation class]]) {
            pinAnnotation = annotation;
        }
    }
    
    // Jezeli istnieje liczymy odleglosc i wyswietlamy na ekranie
    if (pinAnnotation && self.mapView.showsUserLocation) {
        // Tworzymy obiekt CLLocation na podstawie polozenia pin'a
        CLLocation *pinLocation = [[CLLocation alloc] initWithLatitude:pinAnnotation.coordinate.latitude
                                                             longitude:pinAnnotation.coordinate.longitude];
        // Liczymy dystans
        double distance = [self.mapView.userLocation.location distanceFromLocation:pinLocation];
        
        // Jezeli wiekszy niz kilometr, zmieniamy jednostki
        NSString *suffix = @" m";
        if (distance > 1000) {
            distance /= 1000.0;
            suffix = @" km";
        }
        // Wyswietlamy go na ekranie
        distanceString = [NSString stringWithFormat:kDistanceAvailable,distance];
        distanceString = [distanceString stringByAppendingString:suffix];
        [self.distanceBarButtonItem setTitle:distanceString];
    } else {
        // w przeciwnym przypadku informujemy o braku dystansu
        distanceString = kDistanceNotAvailable;
    }
    return distanceString;
}


#pragma mark - Metody interakcji z UI

// Przycisk pobrania danych JSON
- (IBAction)downloadTouch:(UIBarButtonItem *)sender {
    // Konstrukcja URL
    NSURL *jsonURL = [NSURL URLWithString:kTaskURL];
    
    // Ustawiamy indykator mowiacy uzytkowniku ze korzystamy z sieci,
    // oraz tymaczaowo blokujemy przycisk w celu zazpieczenie sie przed wielokrotnym pobraniem
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [sender setEnabled:NO];
    
    // Pobieranie zawartości URL na osobnym watku zeby nie blokowac glownej (wlacznie z UI)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Pobieranie danych z sieci
        NSError *downloadError = nil;
        NSData *jsonData = [NSData dataWithContentsOfURL:jsonURL
                                                 options:NSDataReadingUncached
                                                   error:&downloadError];
        dispatch_async(dispatch_get_main_queue(), ^{
            // Zatrzymaj indykator i wlacz przycisk
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            [sender setEnabled:YES];
            
            // Sprawdzamy czy wystapil blad
            if (downloadError) {
                [[[UIAlertView alloc] initWithTitle:kNetworkAlertTitle
                                            message:kNetworkAlertMessage
                                           delegate:nil
                                  cancelButtonTitle:kCloseAlertButton
                                  otherButtonTitles:nil, nil] show];
            } else {
                // Parsowanie pobranych danych
                NSError *parseError = nil;
                NSDictionary *parsedPin = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                          options:NSJSONReadingMutableContainers
                                                                            error:&parseError];
                if (parseError) {
                    [[[UIAlertView alloc] initWithTitle:kParserAlertTitle
                                                message:kParserAlertMessage
                                               delegate:nil
                                      cancelButtonTitle:kCloseAlertButton
                                      otherButtonTitles:nil, nil] show];
                } else {
                    // Tworzenie annotacji wysrodkowanie widoku
                    NSObject <MKAnnotation> *annotation = [JSRMapAnnotation annotationForJSONObject:parsedPin];
                    
                    [self.mapView setCenterCoordinate:annotation.coordinate animated:YES];
                    
                    // Sprawdzenie czy taka annotacja jest, jezeli tak to usuwamy i wstawiamy ponownie
                    for (id annotation in self.mapView.annotations) {
                        if ([annotation isKindOfClass:[JSRMapAnnotation class]]) {
                            [self.mapView removeAnnotation:annotation];
                        }
                    }
                    [self.mapView addAnnotation:annotation];
                    
                    // Ustawiamy widok tak zeby bral pod uwage wszystkie elementy
                    [self.mapView setRegion:[self calculateRegionForAnnotations] animated:YES];
                    
                    // Sprawdzamy odleglosc jezeli istnieje
                    [self.distanceBarButtonItem setTitle:[self distanceBetweenLocations]];
                }
            }
        });
    });
}

// Przycisk lokalizacji
- (IBAction)locateTouch:(UIBarButtonItem *)sender {
    // Sprawdzamy czy uslugi lokalizacji sa dostepne
    if([CLLocationManager locationServicesEnabled]){
        switch([CLLocationManager authorizationStatus]){
            case kCLAuthorizationStatusAuthorized: case kCLAuthorizationStatusNotDetermined:
                if (self.mapView.showsUserLocation) { // Czy aktualnie pokazujemy lokacje
                    self.mapView.showsUserLocation = NO;
                } else {
                    self.mapView.showsUserLocation = YES;
                }
                break;
            case kCLAuthorizationStatusDenied: case kCLAuthorizationStatusRestricted:
                // Powiadom uzytkownika o problemie z lokalizacja
                [self showLocationAlert];
                break;
        }
    } else {
        // Powiadom uzytkownika o problemie z lokalizacja
       [self showLocationAlert];
    }
}

#pragma mark - MKMapView Delegate Methods

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // Jezeli annotacja jest lokalizacja uzytkownika zwracamy nil aby uzyc systemowego widoku
    if ([annotation isKindOfClass:[MKUserLocation class]]) return nil;
    
    // Stworz nowy obiekt MKPinAnnotationView
    MKPinAnnotationView *annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"Pin View"];
    
    // Ustawiam animacje oraz mozliwosc wyswietlania chmurki z informacja
    annotationView.animatesDrop = YES;
    annotationView.canShowCallout = YES;
    
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    // Jezeli annotacja jest typu JSRMapAnnotation wstawiamy obrazek
    if ([view.annotation isKindOfClass:[JSRMapAnnotation class]]) {
        
        // Pobierz url z annotacji
        NSURL *imageURL = [(JSRMapAnnotation *)view.annotation imageURL];
        
        // Ustaw tymczasowy indykator pobierania w annotacji w celu poinformowania uzytkownika
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [spinner startAnimating];
        [view setLeftCalloutAccessoryView:spinner];
        
        // Ustaw indykator na pasku statusu informujacy o aktywnosci sieciowej
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

        
        // Pobierz obraz na osobnym watku zeby nie blokowac UI
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // Pobieranie obrazka
            NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
            UIImage *image = [UIImage imageWithData:imageData];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // Ustawienie obrazka jako lewy widok jezeli udalo nam sie pobrac, w przeciwnym przypadku usuwamy lewy widok
                if (image) {
                    // Ustawiamy szerokosc i wysokosc na 32px wedlug zalecen Apple
                    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
                    [imageView setImage:image];
                    [view setLeftCalloutAccessoryView:imageView];
                } else {
                    [view setLeftCalloutAccessoryView:nil];
                }
                
                // Zatrzymaj indykatory
                [spinner stopAnimating];
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            });
        });
    }
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    // Ustawiamy widok tak zeby lokalizacja i pin miescily sie na ekranie
    [self.mapView setRegion:[self calculateRegionForAnnotations] animated:YES];
    
    // sprawdzamy odleglosc miedzy punktami
    [self.distanceBarButtonItem setTitle:[self distanceBetweenLocations]];
}

- (void)mapViewDidStopLocatingUser:(MKMapView *)mapView
{
    // Nie jestesmy lokalizowani, trzeba o tym poinformowac
    [self.distanceBarButtonItem setTitle:kDistanceNotAvailable];
}

#pragma mark - UIToolBar delegate

// Metoda pozwalajaca na zamocowanie UIToolbar na gorze ekranu bez nachodzenia na statusbar
- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
