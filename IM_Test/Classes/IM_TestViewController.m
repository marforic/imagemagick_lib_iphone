//
//  IM_TestViewController.m
//  IM_Test
//
//  Created by Claudio Marforio on 7/9/09.
//  Copyright Claudio Marforio 2009. All rights reserved.
//

#import "IM_TestViewController.h"

#define NUM_OF_ROUNDS 10
#define DO_BENCHMARKS
// comment this line if you want to do benchmarks
#undef DO_BENCHMARKS

// if you are benchmarking this one isn't taken into account!
#define USE_JPEG_COMPRESSION
// comment this line if you want to use JPEG compression
// #undef USE_JPEG_COMPRESSION

// if you want to use the new method for images with unusual number of bits per component
// thank you to Jon Keane: kean.jon@gmail.com
#define UNUSUAL_NUMBER_OF_BITS
// comment this line if you want to use the new method
#undef UNUSUAL_NUMBER_OF_BITS

// if you want to test PNG files rather than TIFF ones comment this line
#define USE_PNG

#define ThrowWandException(wand) { \
char * description; \
ExceptionType severity; \
\
description = MagickGetException(wand,&severity); \
(void) fprintf(stderr, "%s %s %lu %s\n", GetMagickModule(), description); \
description = (char *) MagickRelinquishMemory(description); \
exit(-1); \
}

@implementation IM_TestViewController

@synthesize imageViewButton;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	// set the path so that IM can find the configuration files (*.xml files)
	NSString * path = [[NSBundle mainBundle] resourcePath];
	setenv("MAGICK_CONFIGURE_PATH", [path UTF8String], 1);
	
	// printout ImageMagick version
	NSLog(@"%s", GetMagickVersion(nil));
	
#ifndef USE_PNG
	[imageViewButton setImage:[UIImage imageNamed:@"iphone.tif"] forState:UIControlStateNormal];
#endif
	
}

CGImageRef createStandardImage(CGImageRef image) {
	const size_t width = CGImageGetWidth(image);
	const size_t height = CGImageGetHeight(image);
	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
	CGContextRef ctx = CGBitmapContextCreate(NULL, width, height, 8, 4*width, space,
											 kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedFirst);
	CGColorSpaceRelease(space);
	CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), image);
	CGImageRef dstImage = CGBitmapContextCreateImage(ctx);
	CGContextRelease(ctx);
	return dstImage;
}

- (UIImage*) createPosterizeImage:(CGImageRef)srcCGImage {
	const unsigned long width = CGImageGetWidth(srcCGImage);
	const unsigned long height = CGImageGetHeight(srcCGImage);
	// could use the image directly if it has 8/16 bits per component,
	// otherwise the image must be converted into something more common (such as images with 5-bits per component)
	// here we’ll be simple and always convert
	const char *map = "ARGB"; // hard coded
	const StorageType inputStorage = CharPixel;
	CGImageRef standardized = createStandardImage(srcCGImage);
	NSData *srcData = (NSData *) CGDataProviderCopyData(CGImageGetDataProvider(standardized));
	CGImageRelease(standardized);
	const void *bytes = [srcData bytes];
	MagickWandGenesis();
	MagickWand * magick_wand_local= NewMagickWand();
	MagickBooleanType status = MagickConstituteImage(magick_wand_local, width, height, map, inputStorage, bytes);
	if (status == MagickFalse) {
		ThrowWandException(magick_wand_local);
	}
	/*
	status = MagickOrderedPosterizeImage(magick_wand_local, "h8x8o");
	if (status == MagickFalse) {
		ThrowWandException(magick_wand_local);
	}
	 */
    status = MagickSepiaToneImage(magick_wand_local, 0.8 * QuantumRange);
	if (status == MagickFalse) {
		ThrowWandException(magick_wand_local);
	}
	const int bitmapBytesPerRow = (width * strlen(map));
	const int bitmapByteCount = (bitmapBytesPerRow * height);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	char *trgt_image = malloc(bitmapByteCount);
	status = MagickExportImagePixels(magick_wand_local, 0, 0, width, height, map, CharPixel, trgt_image);
	if (status == MagickFalse) {
		ThrowWandException(magick_wand_local);
	}
	magick_wand_local = DestroyMagickWand(magick_wand_local);
	MagickWandTerminus();
	CGContextRef context = CGBitmapContextCreate (trgt_image,
												  width,
												  height,
												  8, // bits per component
												  bitmapBytesPerRow,
												  colorSpace,
												  kCGImageAlphaPremultipliedFirst);
	CGColorSpaceRelease(colorSpace);
	CGImageRef cgimage = CGBitmapContextCreateImage(context);
	UIImage *image = [[UIImage alloc] initWithCGImage:cgimage];
	CGImageRelease(cgimage);
	CGContextRelease(context);
	[srcData release];
	free(trgt_image);
	return image;
}

- (void)posterizeImageWithNewMethod {
	NSLog(@"we're using the new method");
	
	CGImageRef ref = createStandardImage(imageViewButton.imageView.image.CGImage);
	UIImage * image = [self createPosterizeImage:ref];
	[imageViewButton setImage:image forState:UIControlStateNormal];
	[image release];
}

- (void)posterizeImageWithCompression {
	// Here we use JPEG compression.
	NSLog(@"we're using JPEG compression");
	
	MagickWandGenesis();
	magick_wand = NewMagickWand();
	NSData * dataObject = UIImagePNGRepresentation([UIImage imageNamed:@"iphone.png"]);//UIImageJPEGRepresentation([imageViewButton imageForState:UIControlStateNormal], 90);
	MagickBooleanType status;
	status = MagickReadImageBlob(magick_wand, [dataObject bytes], [dataObject length]);
	if (status == MagickFalse) {
		ThrowWandException(magick_wand);
	}
	
	// posterize the image, this filter uses a configuration file, that means that everything in IM should be working great
	status = MagickOrderedPosterizeImage(magick_wand, "h8x8o");
	if (status == MagickFalse) {
		ThrowWandException(magick_wand);
	}
	
	size_t my_size;
	unsigned char * my_image = MagickGetImageBlob(magick_wand, &my_size);
	NSData * data = [[NSData alloc] initWithBytes:my_image length:my_size];
	free(my_image);
	magick_wand = DestroyMagickWand(magick_wand);
	MagickWandTerminus();
	UIImage * image = [[UIImage alloc] initWithData:data];
	[data release];
	
	[imageViewButton setImage:image forState:UIControlStateNormal];
	[image release];
}

- (void)posterizeImageWithoutCompression {
	// WITHOUT JPEG COMPRESSION, work done by Karl: karl@xk72.com
	NSLog(@"we're not using JPEG compression");
	
	MagickWandGenesis();
	magick_wand = NewMagickWand();
	UIImage * src = [imageViewButton imageForState:UIControlStateNormal];
	CGImageRef srcCGImage = [src CGImage];
	NSData * srcData = (NSData *) CGDataProviderCopyData(CGImageGetDataProvider(srcCGImage));
	unsigned long width = src.size.width;
	unsigned long height = src.size.height;
	const void *bytes = [srcData bytes];
	const char *map;
	CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(srcCGImage);
	CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(srcCGImage);
	if ((bitmapInfo & kCGBitmapByteOrder32Little) != 0)
		switch (alphaInfo) {
			case kCGImageAlphaLast:
			case kCGImageAlphaPremultipliedLast:
				map = "ABGR";
				break;
			case kCGImageAlphaFirst:
			case kCGImageAlphaPremultipliedFirst:
				map = "BGRA";
				break;
			case kCGImageAlphaNoneSkipLast:
				map = "PBGR";
				break;
			case kCGImageAlphaNoneSkipFirst:
				map = "BGRP";
				break;
			case kCGImageAlphaNone:
				map = "BGR";
				break;
		}
	else {
		switch (alphaInfo) {
			case kCGImageAlphaLast:
			case kCGImageAlphaPremultipliedLast:
				map = "RGBA";
				break;
			case kCGImageAlphaFirst:
			case kCGImageAlphaPremultipliedFirst:
				map = "ARGB";
				break;
			case kCGImageAlphaNoneSkipLast:
				map = "RGBP";
				break;
			case kCGImageAlphaNoneSkipFirst:
				map = "PRGB";
				break;
			case kCGImageAlphaNone:
				map = "RGB";
				break;
		}
	}
	MagickBooleanType status = MagickConstituteImage(magick_wand, width, height, map, CharPixel, bytes);
	if (status == MagickFalse) {
		ThrowWandException(magick_wand);
	}
	
	MagickSetFormat(magick_wand, "tif");
	MagickSetImageDepth(magick_wand, 8);
#if TARGET_IPHONE_SIMULATOR
	const char * filename= "/Users/cloud/Desktop/testimage.tif";
	status = MagickWriteImage(magick_wand, filename);
	if (status == MagickFalse) {
		ThrowWandException(magick_wand);
	}
#endif	
	status = MagickOrderedPosterizeImage(magick_wand, "h8x8o");
	if (status == MagickFalse) {
		ThrowWandException(magick_wand);
	}
	
	/* We'll always get the image out in a consistent format - it's not always possible to get it back in the original format? */
	map = "ARGB";
	
	int bitmapBytesPerRow = (width * strlen(map));
	//int bitmapByteCount = (bitmapBytesPerRow * height);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = NULL;
	char * trgt_image = malloc(bitmapBytesPerRow * height);
	status = MagickExportImagePixels(magick_wand,0,0,width,height,map,CharPixel,trgt_image);
	if (status == MagickFalse) {
		ThrowWandException(magick_wand);
	}
	
	magick_wand = DestroyMagickWand(magick_wand);
	MagickWandTerminus();
	
	context = CGBitmapContextCreate (trgt_image,
									 width,
									 height,
									 8, // bits per component
									 bitmapBytesPerRow,
									 colorSpace,
									 kCGImageAlphaNoneSkipFirst);
	
	CGColorSpaceRelease(colorSpace);
	
	CGImageRef cgimage = CGBitmapContextCreateImage(context);
	UIImage *image = [[UIImage alloc] initWithCGImage:cgimage];
	CGImageRelease(cgimage);
	CGContextRelease(context);
	free(trgt_image);
	
	[imageViewButton setImage:image forState:UIControlStateNormal];
	[image release];
}

- (void)printMaxAndMin:(NSMutableArray *)times {
	NSUInteger i, count = [times count];
	NSNumber * max = [NSNumber numberWithFloat:0.0];
	NSNumber * min = [NSNumber numberWithFloat:50.0];
	for (i = 0; i < count; i++) {
		NSNumber * ti = (NSNumber *)[times objectAtIndex:i];
		if ([ti compare:max] == NSOrderedDescending)
			max = ti;
		if ([ti compare:min] == NSOrderedAscending)
			min = ti;
	}
	NSLog(@"min time: %f, max time: %f", [min floatValue], [max floatValue]);
}

- (IBAction)posterizeImage {
#ifdef DO_BENCHMARKS
	NSLog(@"Starting benchmarks, it'll take some time... (%i rounds selected)", NUM_OF_ROUNDS);
	NSMutableArray * times = [NSMutableArray arrayWithCapacity:NUM_OF_ROUNDS];
	NSDate * bench_date = [NSDate date];
	NSDate * total_time = [NSDate date];
	
	for (unsigned int i = 0; i < NUM_OF_ROUNDS; i++) {
		bench_date = [NSDate date];
		[self posterizeImageWithCompression];
		[times addObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSinceDate:bench_date]]];
	}
	
	NSTimeInterval total = [[NSDate date] timeIntervalSinceDate:total_time];
	NSLog(@"-- JPEG compression");
	NSLog(@"Total time for %i rounds with JPEG compression: %f", NUM_OF_ROUNDS, total);
	[self printMaxAndMin:times];
	NSLog(@"Mean time: %f", (float)total/NUM_OF_ROUNDS);
	
	times = [NSMutableArray arrayWithCapacity:NUM_OF_ROUNDS];
	total_time = [NSDate date];
	for (unsigned int i = 0; i < NUM_OF_ROUNDS; i++) {
		bench_date = [NSDate date];
		[self posterizeImageWithoutCompression];
		[times addObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSinceDate:bench_date]]];
	}
	
	total = [[NSDate date] timeIntervalSinceDate:total_time];
	NSLog(@"-- NO compression");
	NSLog(@"Total time for %i rounds without compression: %f", NUM_OF_ROUNDS, total);
	[self printMaxAndMin:times];
	NSLog(@"Mean time: %f", (float)total/NUM_OF_ROUNDS);
	NSLog(@"Benchmarks finished");
#else
	
#ifdef USE_JPEG_COMPRESSION
	[self posterizeImageWithCompression];
#else
#ifdef UNUSUAL_NUMBER_OF_BITS
	[self posterizeImageWithNewMethod];
	return;
#endif /* UNUSUAL_NUMBER_OF_BITS */
	[self posterizeImageWithoutCompression];	
#endif /* END USE_JPEG_COMPRESSION */
	
#endif /* END DO_BENCHMARKS */
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
}


- (void)dealloc {
	[self.imageViewButton release];
    [super dealloc];
}

@end
