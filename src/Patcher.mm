//@import MachO;
#import "Patcher.h"
#import "Utils.h"
#import "components/LogUtils.h"
#import "src/LCUtils/Shared.h"
#include <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>

#include <dlfcn.h>
// change to 0x1692, and max is 0x7fff
#define TEXT_OFFSET 0x3000
#define TEXT_MAX 0x7fff
#define INTERVENER_COUNT 4

#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach-o/nlist.h>

static uint32_t findImageIndex(const char* dylibName) {
	uint32_t count = _dyld_image_count();
	for (uint32_t i = 0; i < count; ++i) {
		const char* name = _dyld_get_image_name(i);
		if (strstr(name, dylibName))
			return i;
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
		if (strx == 0)
			continue;
		const char* name = strTable + strx;
		if ((symTable[i].n_type & N_STAB) == 0 && (symTable[i].n_type & N_TYPE) == N_SECT) {
			if (strcmp(name, targetMangledName) == 0) {
				uintptr_t addr = symTable[i].n_value + slide;
				// AppLog(@"found symbol %s @ %p", name, (void*)addr);
				AppLog(@"Loaded TulipHook (ID: %lu, func: %p)", (unsigned long)idx, (void*)addr);
				return (void*)addr;
			}
		}
	}
	AppLog(@"Failed to load TulipHook: Symbol not found");
	return nullptr;
}

// please ignore this, this will be moved to another file
#include <string>
#include <vector>
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

	template <class Type> static AbstractType from();
};
class AbstractFunction {
	template <class FunctionType> struct Generator {
		static AbstractFunction generate() { return AbstractFunction(); }
	};

	template <class Return, class... Parameters> struct Generator<Return(Parameters...)> {
		static AbstractFunction generate();
	};

	public:
	AbstractType m_return;
	std::vector<AbstractType> m_parameters;

	template <class FunctionType> static AbstractFunction from() { return Generator<FunctionType>::generate(); }

	template <class Return, class... Parameters> static AbstractFunction from(Return (*)(Parameters...));
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

struct GenerateHandlerReturn {
	// the handler bytes that are generated
	std::vector<uint8_t> handlerBytes;
	// the code size of the handler, "usually" equal to the size of the bytes vector
	size_t codeSize;
};

typedef GenerateHandlerReturn (*generateHandlerTemp)(void* handler, size_t commonHandlerSpaceOffset);
generateHandlerTemp generateHandler;

static size_t codeCaveOffset = TEXT_OFFSET;

@implementation Patcher

static NSMutableDictionary* _originalBytes = nil;
static NSMutableArray* _patchedFuncs = nil;

+ (NSMutableDictionary<NSString*, NSData*>*)originalBytes {
	if (!_originalBytes) {
		_originalBytes = [NSMutableDictionary dictionary];
	}
	return _originalBytes;
}

+ (NSMutableArray<NSNumber*>*)patchedFuncs {
	if (!_patchedFuncs) {
		_patchedFuncs = [NSMutableArray new];
	}
	return _patchedFuncs;
}

+ (void)setPatchedFuncs:(NSMutableArray<NSNumber*>*)patchedFuncs {
	_patchedFuncs = patchedFuncs;
}
+ (void)setOriginalBytes:(NSMutableDictionary<NSString*, NSData*>*)originalBytes {
	_originalBytes = originalBytes;
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
	AppLog(@"Loaded TulipHook (Handle: %#llx)", handle); /*
	 generateTrampoline = (generateTrampolineTemp)dlsym(handle, "__ZN5tulip4hook18generateTrampolineEPvS1_PKvmRKNS0_15HandlerMetadataE");*/
	auto addr = findSymbolAddr("__ZN5tulip4hook18generateTrampolineEPvS1_PKvmRKNS0_15HandlerMetadataE");
	if (!addr)
		return NO;
	auto addr2 = findSymbolAddr("__ZN5tulip4hook15generateHandlerEPvm");
	if (!addr2)
		return NO;
	generateTrampoline = reinterpret_cast<generateTrampolineTemp>(addr);
	generateHandler = reinterpret_cast<generateHandlerTemp>(addr2);
	return YES;
}

/*
codeCave = 0x3000
patch(codeCave, commonHandlerBytes)
codeCave += commonHandlerBytes.size
for func in list:
  res = trampolineGen(codeCave, func)
  patch(codeCave, res.bytes, res.size)
  codeCave += res.size
for func in list:
  patch(func.addr, intervenerBytes)
*/

+ (BOOL)patchFunc:(NSMutableData*)data strAddr:(NSString*)strAddr textSect:(struct section_64*)textSect {
	uint64_t addr = strtoull([strAddr UTF8String], NULL, 0);
	if (self.originalBytes[strAddr] != nil) {
		AppLog(@"Function at %#llx already patched!", addr);
		return NO;
	}
	// safe guard so we dont override some needed bytes
	if (codeCaveOffset >= TEXT_MAX) {
		AppLog(@"Cannot patch more than %#llx! (Current code cave offset: %#llx)", TEXT_MAX, codeCaveOffset);
		return NO;
	}
	int funcIndex = [self.originalBytes count] + 1;

	uint64_t target = textSect->addr + codeCaveOffset;
	uint64_t branch_pc = textSect->addr + addr + 12;
	int64_t byte_offset = (int64_t)target - (int64_t)branch_pc;
	if (byte_offset % 4 != 0) {
		AppLog(@"Unaligned branch offset %#llx", byte_offset);
		return NO;
	}

	uint32_t codeCaveDelta = codeCaveOffset - TEXT_OFFSET;

	uint32_t trampoline[4] = {
		0x10000010, // adr x16, . (or adr x16, #0 because my assembler was being stupid so i have to manually)
		// 0x50000010,												  // adr x16, pc + 8 (or adr x16, #8 because my assembler was being stupid so i have to manually)
		0xD2800000 | ((codeCaveDelta & 0xFFFF) << 5) | 15,		   // mov x15, #trampOffset
		0xD2800000 | ((funcIndex & 0xFFFF) << 5) | 17,			   // mov x17, #index
		0x14000000 | (((uint32_t)(byte_offset >> 2)) & 0x03FFFFFF) // b (delta)
																   // 0x94000000 | (((uint64_t)(byte_offset >> 2)) & 0x03FFFFFF) // bl (delta)
	};

	NSData* original = [data subdataWithRange:NSMakeRange((NSUInteger)addr, sizeof(trampoline))];
	self.originalBytes[strAddr] = original;

	if (generateTrampoline) {
		GenerateTrampolineReturn gen = generateTrampoline((void*)(textSect->addr + addr), (void*)(textSect->addr + codeCaveOffset), original.bytes, original.length, {});
		if (!gen.errorMessage.empty()) {
			AppLog(@"Trampoline gen from TulipHook failed: %s", gen.errorMessage.c_str());
			return NO;
		}
		[data replaceBytesInRange:NSMakeRange(codeCaveOffset, gen.trampolineBytes.size()) withBytes:gen.trampolineBytes.data()];
		[data replaceBytesInRange:NSMakeRange(addr, sizeof(trampoline)) withBytes:trampoline];
		//[self.patchedFuncs addObject:@(addr)];
		codeCaveOffset += gen.trampolineBytes.size();
		return YES;
	}
	return YES;
}

+ (NSArray<NSString*>*)getOffsetsFromData:(NSString*)data {
	// \[GEODE_MODIFY_ADDRESS\] base::get\(\) \+ (0x[0-9a-fA-F]+) \[GEODE_MODIFY_END\]
	NSMutableArray<NSString*>* offsets = [NSMutableArray array];
	NSError* error;
	NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"\\[GEODE_MODIFY_ADDRESS\\]\\s*base::get\\(\\) \\+ (0x[0-9a-fA-F]+) \\[GEODE_MODIFY_END\\]"
																		   options:0
																			 error:&error];
	if (regex && !error) {
		NSArray<NSTextCheckingResult*>* matches = [regex matchesInString:data options:0 range:NSMakeRange(0, data.length)];
		for (NSTextCheckingResult* match in matches) {
			NSRange range = [match rangeAtIndex:1];
			NSString* string = [data substringWithRange:range];
			[offsets addObject:string];
		}
	}
	return [offsets copy];
}

// handler addr being that textHandlerStorage
+ (BOOL)patchGDBinary:(NSURL*)from to:(NSURL*)to withHandlerAddress:(uint64_t)handlerAddress {
	AppLog(@"Patching Binary...");
	if (![Patcher loadTulipHook])
		return NO;
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
	AppLog(@"Patching handler at %#llx...", TEXT_OFFSET);
	if (generateHandler) {
		GenerateHandlerReturn gen = generateHandler((void*)(textSect->addr + TEXT_OFFSET), handlerAddress);
		if (gen.handlerBytes.empty()) {
			AppLog(@"Handler generation from TulipHook failed. (Empty bytes)");
			return NO;
		}
		[data replaceBytesInRange:NSMakeRange(codeCaveOffset, gen.codeSize) withBytes:gen.handlerBytes.data()];
		codeCaveOffset += gen.codeSize;
	} else {
		AppLog(@"Couldn't patch! generateHandler function is null!");
		return NO;
	}

	// === PATCH STEP 2 ====
	AppLog(@"Patching functions...");
	for (NSString* geodeOffset in [Patcher getOffsetsFromData:[[NSString alloc] initWithData:[Utils getTweakData] encoding:NSASCIIStringEncoding]]) {
		AppLog(@"Patching %@", geodeOffset);
		[Patcher patchFunc:data strAddr:geodeOffset textSect:textSect];
	}

	/*AppLog(@"Patching last segment at %#llx...", (unsigned long long)codeCaveOffset);
	NSMutableData* textArea = [NSMutableData data];
	// yes for some reason pushing is str/stp on armv8, unsure what was wrong with it originally but ok!
	const uint8_t pushInst[][4] = {
		{ 0xe0, 0x07, 0xbf, 0xa9 }, // stp x0, x1, [sp, #-16]!
		{ 0xe2, 0x0f, 0xbf, 0xa9 }, // stp x2, x3, [sp, #-16]!
		{ 0xe4, 0x17, 0xbf, 0xa9 }, // stp x4, x5, [sp, #-16]!
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
	if (pad)
		[textArea increaseLengthBy:pad];
	//[textArea increaseLengthBy:8];

	NSUInteger literalPos = textArea.length;
	[textArea appendBytes:&handlerAddress length:8];

	uint64_t ldelta = literalPos - ldrPos;
	int64_t bit = ldelta >> 2;
	if (bit < -(1 << 17) || bit >= (1 << 17)) {
		AppLog(@"Literal too far! %lld", bit);
		return NO;
	}
	uint32_t ldrInsn = 0x58000000 | (((uint32_t)bit & 0x7FFFF) << 5) | 2; // 2 is x2
	[textArea replaceBytesInRange:NSMakeRange(ldrPos, 4) withBytes:&ldrInsn length:4];

	//[textArea appendBytes:&handlerAddress length:8];
	[data replaceBytesInRange:NSMakeRange(codeCaveOffset, textArea.length) withBytes:textArea.bytes];
	AppLog(@"Patched text Area with %lu bytes!", (unsigned long)textArea.length);*/

	[data writeToURL:to options:NSDataWritingAtomic error:&error];
	if (error) {
		AppLog(@"Couldn't patch binary: %@", error);
		return NO;
	}
	AppLog(@"Patched Geometry Dash");

	NSMutableDictionary* jsonDict = [NSMutableDictionary dictionary];
	for (NSString* key in self.originalBytes) {
		NSData* data = self.originalBytes[key];
		const uint8_t* bytes = (const uint8_t*)data.bytes;
		NSMutableArray* arr = [NSMutableArray arrayWithCapacity:data.length];
		for (int i = 0; i < data.length; i++) {
			[arr addObject:@(bytes[i])];
		}
		jsonDict[key] = arr;
	}
	NSData* jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:&error];
	if (!jsonData || error) {
		AppLog(@"Couldn't serialize JSON: %@", error);
		return NO;
	}
	[jsonData writeToFile:[[[LCPath bundlePath] URLByAppendingPathComponent:[Utils gdBundleName]] URLByAppendingPathComponent:@"original_bytes.json"].path atomically:YES];
	AppLog(@"Wrote original bytes");
	return YES;
}
@end
