#define VGA_MEMORY 0xB8000
#define VGA_WIDTH 80

#define COLOR_WHITE_ON_BLACK 0x0F

static unsigned short* vga_buffer = (unsigned short*)VGA_MEMORY;
static int cursor_x = 0;
static int cursor_y = 0;

void clear_screen(void) {
    for (int i = 0; i < VGA_WIDTH * 25; i++) {
        vga_buffer[i] = (COLOR_WHITE_ON_BLACK << 8) | ' ';
    }
    cursor_x = 0;
    cursor_y = 0;
}

void print_char(char c) {
    if (c == '\n') {
        cursor_x = 0;
        cursor_y++;
        if (cursor_y >= 25) {
            cursor_y = 24;
            for (int i = 0; i < VGA_WIDTH * 24; i++) {
                vga_buffer[i] = vga_buffer[i + VGA_WIDTH];
            }
            for (int i = VGA_WIDTH * 24; i < VGA_WIDTH * 25; i++) {
                vga_buffer[i] = (COLOR_WHITE_ON_BLACK << 8) | ' ';
            }
        }
        return;
    }

    int offset = cursor_y * VGA_WIDTH + cursor_x;
    vga_buffer[offset] = (COLOR_WHITE_ON_BLACK << 8) | c;

    cursor_x++;
    if (cursor_x >= VGA_WIDTH) {
        cursor_x = 0;
        cursor_y++;
        if (cursor_y >= 25) {
            cursor_y = 0;
        }
    }
}

void print_string(const char* str) {
    while (*str) {
        print_char(*str);
        str++;
    }
}

void print_hex(unsigned long value) {
    char hex_chars[] = "0123456789ABCDEF";
    print_string("0x");
    
    for (int i = 60; i >= 0; i -= 4) {
        print_char(hex_chars[(value >> i) & 0xF]);
    }
}

static inline void halt(void) {
    __asm__ __volatile__("hlt");
}

static inline void cli(void) {
    __asm__ __volatile__("cli");
}

static inline void sti(void) {
    __asm__ __volatile__("sti");
}

void main(void) {
    unsigned short* vga = (unsigned short*)0xB8000;
    
    
    for (int i = 4; i < 80 * 25; i++) {
        vga[i] = 0x0F20;
    }
    
    const char* msg = "Hello from kernel!";
    int pos = 0;
    while (msg[pos]) {
        vga[pos] = 0x0F00 | msg[pos];
        pos++;
    }

    while (1) {
        __asm__ __volatile__("hlt");
    }
}