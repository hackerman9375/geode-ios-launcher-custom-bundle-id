#pragma once

#include "AbstractFunction.hpp"
#include "AbstractType.hpp"
#include "HandlerData.hpp"

#include <system_error>

namespace tulip {
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

	struct GenerateHandlerReturn {
		// the handler bytes that are generated
		std::vector<uint8_t> handlerBytes;
		// the code size of the handler, "usually" equal to the size of the bytes vector
		size_t codeSize;
	};

	typedef GenerateHandlerReturn (*generateHandlerTemp)(void* handler, size_t commonHandlerSpaceOffset);
}
