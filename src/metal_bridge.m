#import "metal_bridge.h"

MetalContext init_metal(const char *shader_source) {
    MetalContext ctx = {0};
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device) return ctx;
    
    ctx.device = (__bridge_retained void *)device;
    ctx.commandQueue = (__bridge_retained void *)[device newCommandQueue];
    
    NSError *error = nil;
    NSString *source = [NSString stringWithUTF8String:shader_source];
    id<MTLLibrary> library = [device newLibraryWithSource:source options:nil error:&error];
    if (!library) {
        NSLog(@"Failed to create library: %@", error);
        return ctx;
    }
    
    id<MTLFunction> function = [library newFunctionWithName:@"vanity_search"];
    ctx.pipelineState = (__bridge_retained void *)[device newComputePipelineStateWithFunction:function error:&error];
    
    // Predicate buffers
    ctx.resultsBuffer = (__bridge_retained void *)[device newBufferWithLength:sizeof(MetalResult) * 256 options:MTLResourceStorageModeShared];
    ctx.patternsBuffer = (__bridge_retained void *)[device newBufferWithLength:sizeof(MetalPattern) * 32 options:MTLResourceStorageModeShared];
    
    return ctx;
}

void dispatch_metal(MetalContext ctx, MetalPattern *patterns, uint32_t num_patterns, uint64_t base_seed, uint32_t workgroup_size) {
    id<MTLCommandQueue> queue = (__bridge id<MTLCommandQueue>)ctx.commandQueue;
    id<MTLComputePipelineState> pipeline = (__bridge id<MTLComputePipelineState>)ctx.pipelineState;
    id<MTLBuffer> resultsBuf = (__bridge id<MTLBuffer>)ctx.resultsBuffer;
    id<MTLBuffer> patternsBuf = (__bridge id<MTLBuffer>)ctx.patternsBuffer;
    
    if (!resultsBuf || !patternsBuf || !queue || !pipeline) return;
    
    // Zero out found flag in results buffer
    MetalResult *res = [resultsBuf contents];
    for(int i=0; i<256; i++) res[i].found = 0;
    
    // Copy patterns
    memcpy([patternsBuf contents], patterns, sizeof(MetalPattern) * num_patterns);
    [patternsBuf didModifyRange:NSMakeRange(0, sizeof(MetalPattern) * num_patterns)];
    
    id<MTLCommandBuffer> commandBuffer = [queue commandBuffer];
    id<MTLComputeCommandEncoder> encoder = [commandBuffer computeCommandEncoder];
    
    [encoder setComputePipelineState:pipeline];
    [encoder setBuffer:resultsBuf offset:0 atIndex:0];
    [encoder setBuffer:patternsBuf offset:0 atIndex:1];
    [encoder setBytes:&num_patterns length:sizeof(uint32_t) atIndex:2];
    [encoder setBytes:&base_seed length:sizeof(uint64_t) atIndex:3];
    
    MTLSize gridSize = MTLSizeMake(workgroup_size * 256, 1, 1);
    MTLSize threadGroupSize = MTLSizeMake(256, 1, 1);
    
    [encoder dispatchThreads:gridSize threadsPerThreadgroup:threadGroupSize];
    [encoder endEncoding];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
}

MetalResult check_results_metal(MetalContext ctx) {
    id<MTLBuffer> resultsBuf = (__bridge id<MTLBuffer>)ctx.resultsBuffer;
    MetalResult *res = (MetalResult *)[resultsBuf contents];
    for(int i=0; i<256; i++) {
        if (res[i].found) return res[i];
    }
    MetalResult empty = {0};
    return empty;
}

void deinit_metal(MetalContext ctx) {
    if (ctx.device) CFRelease(ctx.device);
    if (ctx.commandQueue) CFRelease(ctx.commandQueue);
    if (ctx.pipelineState) CFRelease(ctx.pipelineState);
    if (ctx.resultsBuffer) CFRelease(ctx.resultsBuffer);
    if (ctx.patternsBuffer) CFRelease(ctx.patternsBuffer);
}
