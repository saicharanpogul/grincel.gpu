#import <Metal/Metal.h>
#import <Foundation/Foundation.h>

typedef struct {
    void *device;
    void *commandQueue;
    void *pipelineState;
    void *resultsBuffer;
    void *patternsBuffer;
} MetalContext;

typedef struct {
    uint32_t mode; // 0: starts, 1: ends, 2: both
    char prefix[48];
    char suffix[48];
    uint32_t prefix_len;
    uint32_t suffix_len;
    uint32_t ignore_case;
} MetalPattern;

typedef struct {
    uint8_t seed[32];           // The 32-byte seed used to generate the keypair
    char address[48];           // Base58 encoded address (for display)
    uint32_t address_len;       // Length of address string
    uint32_t found;
    uint32_t pattern_index;
} MetalResult;

MetalContext init_metal(const char *shader_source);
void dispatch_metal(MetalContext ctx, MetalPattern *patterns, uint32_t num_patterns, uint64_t base_seed, uint32_t workgroup_size);
MetalResult check_results_metal(MetalContext ctx);
void deinit_metal(MetalContext ctx);
