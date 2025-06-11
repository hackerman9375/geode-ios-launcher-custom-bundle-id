//@import MachO;
#import "Patcher.h"
#include <Foundation/Foundation.h>
#import "Utils.h"
#import "components/LogUtils.h"
#import <mach-o/loader.h>
#import <mach-o/dyld.h>

#include <dlfcn.h>

#define TEXT_OFFSET 0x3000

#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach-o/nlist.h>

static uint32_t findImageIndex(const char* dylibName) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; ++i) {
        const char* name = _dyld_get_image_name(i);
        if (strstr(name, dylibName)) return i;
    }
    return UINT32_MAX;
}

// sorry but dlsym is NOT working and its giving me a headache, so lets just go through all symbols
void* findSymbolAddr(const char* targetMangledName) {
    uint32_t idx = findImageIndex("libTulipHook.dylib");
    if (idx == UINT32_MAX) {
        AppLog(@"Failed to load TulipHook: couldn't find image index");
        return nullptr;
    }

    const struct mach_header_64* hdr = (struct mach_header_64*)_dyld_get_image_header(idx);
    intptr_t slide = _dyld_get_image_vmaddr_slide(idx);

    struct symtab_command* symtabCmd = nullptr;
    struct load_command* cmd = (struct load_command*)(hdr + 1);
    for (uint32_t i = 0; i < hdr->ncmds; ++i) {
        if (cmd->cmd == LC_SYMTAB) {
            symtabCmd = (struct symtab_command*)cmd;
            break;
        }
        cmd = (struct load_command*)((uint8_t*)cmd + cmd->cmdsize);
    }
    if (!symtabCmd) {
        AppLog(@"Failed to load TulipHook: no symbol table");
        return nullptr;
    }

    auto base = (uint8_t*)hdr;
    auto symTable = (struct nlist_64*)(base + symtabCmd->symoff);
    auto strTable = (char*)(base + symtabCmd->stroff);

    for (uint32_t i = 0; i < symtabCmd->nsyms; ++i) {
        uint32_t strx = symTable[i].n_un.n_strx;
        if (strx == 0) continue;
        const char* name = strTable + strx;
        if ((symTable[i].n_type & N_STAB) == 0 &&
            (symTable[i].n_type & N_TYPE) == N_SECT) {
            if (strcmp(name, targetMangledName) == 0) {
                uintptr_t addr = symTable[i].n_value + slide;
                //AppLog(@"found symbol %s @ %p", name, (void*)addr);
                AppLog(@"Loaded TulipHook (ID: %lu, generateTrampoline: %p)", (unsigned long)idx, (void*)addr);
                return (void*)addr;
            }
        }
    }
	AppLog(@"Failed to load TulipHook: Symbol not found");
    return nullptr;
}



// please ignore this, this will be moved to another file
#include <vector>
#include <string>
using HandlerHandle = size_t;
class CallingConvention;
enum class AbstractTypeKind : uint8_t {
	Primitive,
	FloatingPoint,
	Other,
};

class AbstractType {
public:
	size_t m_size;
	AbstractTypeKind m_kind;

	template <class Type>
	static AbstractType from();
};
class AbstractFunction {
	template <class FunctionType>
	struct Generator {
		static AbstractFunction generate() {
			return AbstractFunction();
		}
	};

	template <class Return, class... Parameters>
	struct Generator<Return(Parameters...)> {
		static AbstractFunction generate();
	};

public:
	AbstractType m_return;
	std::vector<AbstractType> m_parameters;

	template <class FunctionType>
	static AbstractFunction from() {
		return Generator<FunctionType>::generate();
	}

	template <class Return, class... Parameters>
	static AbstractFunction from(Return (*)(Parameters...));
};
class HandlerMetadata {
public:
    std::shared_ptr<CallingConvention> m_convention;

    AbstractFunction m_abstract;
};
struct GenerateTrampolineReturn {
    // the trampoline bytes that are generated after reloc
    std::vector<uint8_t> trampolineBytes;
    // the code size of the trampoline, "usually" equal to the size of the bytes vector
    size_t codeSize;
    // the offset of the original bytes in the trampoline, the offset from the beginning the trampoline jumps to
    size_t originalOffset;
    // an error message if the generation failed
    std::string errorMessage;
};

typedef GenerateTrampolineReturn (*generateTrampolineTemp)(void* address, void* trampoline, void const* originalBuffer, size_t targetSize, const HandlerMetadata& metadata);
generateTrampolineTemp generateTrampoline;

static size_t bumpOffset = 0;

@implementation Patcher

static NSMutableArray *_patchedFuncs = nil;

+ (NSMutableArray<NSNumber*>*)patchedFuncs {
    if (!_patchedFuncs) {
        _patchedFuncs = [NSMutableArray new];
    }
    return _patchedFuncs;
}

+ (void)setPatchedFuncs:(NSMutableArray<NSNumber *> *)patchedFuncs {
    _patchedFuncs = patchedFuncs;
}

+ (BOOL)loadTulipHook {
	// it definitely makes sense
	void* handle = dlopen("@loader_path/Frameworks/libTulipHook.dylib", RTLD_LAZY | RTLD_GLOBAL);
	const char* dlerr = dlerror();
	if (!handle || (uint64_t)handle > 0xf00000000000) {
		if (dlerr) {
			AppLog(@"Failed to load TulipHook: %s", dlerr);
		} else {
			AppLog(@"Failed to load TulipHook: An unknown error occured.");
		}
        return NO;
	}
    AppLog(@"Loaded TulipHook (Handle: %#llx)", handle);/*
    generateTrampoline = (generateTrampolineTemp)dlsym(handle, "__ZN5tulip4hook18generateTrampolineEPvS1_PKvmRKNS0_15HandlerMetadataE");*/
    auto addr = findSymbolAddr("__ZN5tulip4hook18generateTrampolineEPvS1_PKvmRKNS0_15HandlerMetadataE");
    if (!addr) return NO;
    generateTrampoline = reinterpret_cast<generateTrampolineTemp>(addr);
    return YES;
}

+ (BOOL)patchFunc:(NSMutableData *)data addr:(uint64_t)addr textSect:(struct section_64*)textSect withHandlerAddress:(uint64_t)handlerAddress {
	NSNumber *addrNum = @(addr);
	if ([self.patchedFuncs containsObject:addrNum]) {
		AppLog(@"Function at %#llx already patched", (unsigned long long)addrNum);
        return NO;
	}
	GenerateTrampolineReturn ret;
	if (generateTrampoline) {
		// TODO finished yet
	}
	int funcIndex = [self.patchedFuncs count] + 1;

    // because arm LOVES relative offsets!
    uint64_t target = textSect->addr + TEXT_OFFSET;
    uint64_t branch_pc = textSect->addr + addr + 8; 
    int64_t byte_offset = (int64_t)target - (int64_t)branch_pc;
    if (byte_offset % 4 != 0) {
        AppLog(@"Unaligned branch offset %#llx", byte_offset);
        return NO;
    }

	uint32_t trampoline[3] = {
        0x10000010,		     // adr x16, . (or adr x16, #0 because my assembler was being stupid so i have to manually)
        //0x50000010,		 // adr x16, pc + 8 (or adr x16, #8 because my assembler was being stupid so i have to manually)
		0xD2800000 | ((funcIndex & 0xFFFF) << 5) | 0x11, // mov x17, #index
		0x14000000 | (((uint32_t)(byte_offset >> 2)) & 0x03FFFFFF) // b (delta)
		//0x94000000 | (((uint64_t)(byte_offset >> 2)) & 0x03FFFFFF) // bl (delta)
	};
	[data replaceBytesInRange:NSMakeRange(addr, sizeof(trampoline)) withBytes:trampoline];

	[self.patchedFuncs addObject:addrNum];
	return YES;
}

+ (NSArray<NSString *> *)getOffsetsFromData:(NSString*)data {
	// \[GEODE_MODIFY_ADDRESS\] base::get\(\) \+ (0x[0-9a-fA-F]+) \[GEODE_MODIFY_END\]
	NSMutableArray<NSString *> *offsets = [NSMutableArray array];
	NSError* error;
	NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"\\[GEODE_MODIFY_ADDRESS\\]\\s*base::get\\(\\) \\+ (0x[0-9a-fA-F]+) \\[GEODE_MODIFY_END\\]" options:0 error:&error];
	if (regex && !error) {
		NSArray<NSTextCheckingResult *>* matches = [regex matchesInString:data options:0 range:NSMakeRange(0, data.length)];
		for (NSTextCheckingResult *match in matches) {
			NSRange range = [match rangeAtIndex:1];
			NSString *string = [data substringWithRange:range];
			[offsets addObject:string];
		}
	}
	return [offsets copy];
}

// handler addr being that textHandlerStorage
+ (BOOL)patchGDBinary:(NSURL*)from to:(NSURL*)to withHandlerAddress:(uint64_t)handlerAddress {
    AppLog(@"Patching Binary...");
    [Patcher loadTulipHook];
    return YES;
	NSError* error;
	NSMutableData* data = [NSMutableData dataWithContentsOfURL:from options:0 error:&error];
	if (!data || error) {
		AppLog(@"Couldn't read binary: %@", error);
		return NO;
	}
	uint8_t* base = (uint8_t*)data.mutableBytes;
	struct mach_header_64* header = (struct mach_header_64*)base;
	uint8_t* imageHeaderPtr = (uint8_t*)header + sizeof(struct mach_header_64);
	// uint32_t magic;
	//[data getBytes:&magic length:sizeof(uint32_t)];
	if (data.length < sizeof(struct mach_header_64) || (header->magic != MH_MAGIC && header->magic != MH_MAGIC_64)) {
		AppLog(@"Couldn't patch! Binary is not Mach-O.");
		return NO;
	}

	// === PATCH STEP 1 ====
	
	AppLog(@"Patching TEXT segment at %#llx...", (unsigned long long)TEXT_OFFSET);
	NSMutableData* textArea = [NSMutableData data];
	// yes for some reason pushing is str/stp on armv8, unsure what was wrong with it originally but ok!
	const uint8_t pushInst[][4] = {
		{ 0xe0, 0x07, 0xbf, 0xa9 }, // stp x0, x1, [sp, #-16]!
		{ 0xe2, 0x0f, 0xbf, 0xa9 }, // stp x2, x3, [sp, #-16]!
		{ 0xe4, 0x17, 0xbf, 0xa9 }, // stp x4, x5, [sp, #-16]!
		{ 0xe6, 0x1f, 0xbf, 0xa9 }, // stp x6, x7, [sp, #-16]!
		{ 0xe6, 0x1f, 0xbf, 0xa9 }, // stp x6, x7, [sp, #-16]!
		{ 0xe0, 0x07, 0xbf, 0x6d }, // stp d0, d1, [sp, #-16]!
		{ 0xe2, 0x0f, 0xbf, 0x6d }, // stp d2, d3, [sp, #-16]!
		{ 0xe4, 0x17, 0xbf, 0x6d }, // stp d4, d5, [sp, #-16]!
	};

	const uint8_t popInst[][4] = {
		{ 0xe6, 0x1f, 0xc1, 0x6c }, // ldp d6, d7, [sp], #16
		{ 0xe4, 0x17, 0xc1, 0x6c }, // ldp d4, d5, [sp], #16
		{ 0xe2, 0x0f, 0xc1, 0x6c }, // ldp d2, d3, [sp], #16
		{ 0xe0, 0x07, 0xc1, 0x6c }, // ldp d0, d1, [sp], #16
		{ 0xe6, 0x1f, 0xc1, 0xa8 }, // ldp x6, x7, [sp], #16
		{ 0xe4, 0x17, 0xc1, 0xa8 }, // ldp x4, x5, [sp], #16
		{ 0xe2, 0x0f, 0xc1, 0xa8 }, // ldp x2, x3, [sp], #16
		{ 0xe0, 0x07, 0xc1, 0xa8 }, // ldp x0, x1, [sp], #16
	};

	for (int i = 0; i < (sizeof(pushInst) / 4); i++) {
		[textArea appendBytes:pushInst[i] length:4];
	}
	[textArea appendBytes:"\xE0\x03\x10\xAA" length:4]; // mov x0, x16
	[textArea appendBytes:"\xE1\x03\x11\xAA" length:4]; // mov x1, x17
	// tmp reserve for ldr x2, <literal>
	NSUInteger ldrPos = textArea.length;
	const uint32_t insn = 0;
    [textArea appendBytes:&insn length:4];

	[textArea appendBytes:"\x40\x00\x3F\xD6" length:4]; // blr x2
	[textArea appendBytes:"\xF0\x03\x00\xAA" length:4]; // mov x16, x0
	for (int i = 0; i < (sizeof(popInst) / sizeof(popInst[0])); i++) {
		[textArea appendBytes:popInst[i] length:sizeof(popInst[0])];
	}
	[textArea appendBytes:"\00\x02\x1F\xD6" length:4]; // br x16
	
	// alignment just to be safe
	NSUInteger pad = (8 - (textArea.length % 8)) % 8;
    if (pad) [textArea increaseLengthBy:pad];
	//[textArea increaseLengthBy:8];

	NSUInteger literalPos = textArea.length;
    [textArea appendBytes:&handlerAddress length:8];

	uint64_t ldelta = literalPos - ldrPos;
	int64_t bit = ldelta >> 2;
	if (bit < -(1<<18) || bit >= (1<<18)) {
		AppLog(@"Literal too far! %lld", bit);
		//return NO;
	}
	uint32_t ldrInsn = 0x58000000 | (((uint32_t)bit & 0x7FFFF) << 5) | 2; // 2 is x2
	[textArea replaceBytesInRange:NSMakeRange(ldrPos, 4) withBytes:&ldrInsn length:4];

	[textArea appendBytes:&handlerAddress length:8];
	[data replaceBytesInRange:NSMakeRange(TEXT_OFFSET, textArea.length) withBytes:textArea.bytes];
	AppLog(@"Patched text Area with %lu bytes!", (unsigned long)textArea.length);

	// === PATCH STEP 2 ====
	// credits: https://github.com/lark-opensource/iOS-client/blob/develop/external/TSPrivacyKit/TSPrivacyKit/Classes/Custom/RuleEngine/CallStackFilter/TSPKMachInfo.m

	AppLog(@"Patching functions...");

	struct section_64* textSect = NULL; // we really only need __text, since gd doesnt really use __TEXT
	struct linkedit_data_command const* func_start = NULL;
	struct load_command* command = (struct load_command*)imageHeaderPtr;
	for (int i = 0; i < header->ncmds; i++) {
		if (command->cmd == LC_SEGMENT_64) {
			struct segment_command_64* seg = (struct segment_command_64*)command;
			if (strcmp(seg->segname, "__TEXT") == 0) {
				struct section_64* sect = (struct section_64*)(seg + 1);
				for (int x = 0; x < seg->nsects; x++) {
					if (strcmp(sect[x].sectname, "__text") == 0) {
						textSect = &sect[x];
						break;
					}
				}
			}
		} else if (command->cmd == LC_FUNCTION_STARTS) {
			func_start = (struct linkedit_data_command const*)command; // load command of function start
		}
        // void* -> char*
		command = (struct load_command*)((char*)command + command->cmdsize);
	}
	if (!textSect) {
		AppLog(@"Couldn't find __text section.");
		return NO;
	}
	if (func_start == NULL || func_start->datasize == 0) {
		AppLog(@"Couldn't find LC_FUNCTION_STARTS cmd.");
		return NO;
	}

	for (NSString* geodeOffset in [Patcher getOffsetsFromData:[[NSString alloc] initWithData:[Utils getTweakData] encoding:NSASCIIStringEncoding]]) {
		uint64_t value = strtoull([geodeOffset UTF8String], NULL, 0);
		AppLog(@"Patching %#llx", value);
		[Patcher patchFunc:data addr:value textSect:textSect withHandlerAddress:handlerAddress];
	}
	//[Patcher patchFunc:data addr:0x265660 textSect:textSect withHandlerAddress:handlerAddress];
	[data writeToURL:to options:NSDataWritingAtomic error:&error];
	if (error) {
		AppLog(@"Couldn't patch binary: %@", error);
		return NO;
	}
	return YES;
}
@end
