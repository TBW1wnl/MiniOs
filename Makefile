# Makefile to build a simple 64-bit OS kernel with bootloader using NASM and GCC
ASM = nasm
CC = x86_64-elf-gcc
LD = x86_64-elf-ld

# Repository structure
BOOT_DIR = boot/amd64
KERNEL_DIR = kernel
BUILD_DIR = build

# Flags for 64-bit kernel
CFLAGS = -m64 -ffreestanding -nostdlib -fno-pie -fno-stack-protector -mno-red-zone -std=c99
LDFLAGS = -m elf_x86_64 -T $(KERNEL_DIR)/linker.ld

# Source files
BOOTLOADER_SRC = $(BOOT_DIR)/bootloader.asm
STAGE2_SRC = $(BOOT_DIR)/stage2.asm
KERNEL_ENTRY_SRC = $(BOOT_DIR)/kernel_entry.asm
KERNEL_SRC = $(KERNEL_DIR)/kernel.c
LINKER_SCRIPT = $(KERNEL_DIR)/linker.ld

# Output files
BOOTLOADER = $(BUILD_DIR)/bootloader.bin
STAGE2 = $(BUILD_DIR)/stage2.bin
KERNEL_ENTRY = $(BUILD_DIR)/kernel_entry.o
KERNEL_OBJ = $(BUILD_DIR)/kernel.o
KERNEL = $(BUILD_DIR)/kernel.bin
OS_IMAGE = $(BUILD_DIR)/os.img

.PHONY: all run debug clean

all: $(OS_IMAGE)

# Create build directory if it doesn't exist
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)
	@echo "Created build directory"

# Assemble bootloader (sector 1)
$(BOOTLOADER): $(BOOTLOADER_SRC) | $(BUILD_DIR)
	@echo "Building bootloader..."
	$(ASM) -f bin $< -o $@
	@echo "Bootloader built: $@"

# Assemble stage2 (sectors 2-9)
$(STAGE2): $(STAGE2_SRC) | $(BUILD_DIR)
	@echo "Building stage2..."
	$(ASM) -f bin $< -o $@
	@echo "Stage2 built: $@"

# Assemble kernel entry (64-bit)
$(KERNEL_ENTRY): $(KERNEL_ENTRY_SRC) | $(BUILD_DIR)
	@echo "Building kernel entry..."
	$(ASM) -f elf64 $< -o $@
	@echo "Kernel entry built: $@"

# Compile kernel C
$(KERNEL_OBJ): $(KERNEL_SRC) | $(BUILD_DIR)
	@echo "Compiling kernel..."
	$(CC) $(CFLAGS) -c $< -o $@
	@echo "Kernel compiled: $@"

# Link kernel
$(KERNEL): $(KERNEL_ENTRY) $(KERNEL_OBJ) $(LINKER_SCRIPT)
	@echo "Linking kernel..."
	$(LD) $(LDFLAGS) -o $@ $(KERNEL_ENTRY) $(KERNEL_OBJ)
	@echo "Kernel linked: $@"

# Create OS image
$(OS_IMAGE): $(BOOTLOADER) $(STAGE2) $(KERNEL)
	@echo "Creating OS image..."
	cat $(BOOTLOADER) $(STAGE2) $(KERNEL) > $@
	@echo "OS image created: $@"
	@ls -lh $@

run: $(OS_IMAGE)
	qemu-system-x86_64 -drive format=raw,file=$(OS_IMAGE)

debug: $(OS_IMAGE)
	qemu-system-x86_64 -drive format=raw,file=$(OS_IMAGE) -s -S

clean:
	@echo "Cleaning build directory..."
	rm -rf $(BUILD_DIR)
	@echo "Clean complete!"