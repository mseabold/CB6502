/*
 * Copyright (c) 2020 Matt Seabold
 *
 * Interface for 6502 CPU simulator interface.
 *
 */
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

/* 
 * Callback function prototypes for 6502 memory space access.
 */

/**
 * Callback for memory reads
 *
 * @param address  The memory address to read
 *
 * @return The value of the specified memory address
 */
typedef uint8_t (*read_callback_t)(uint16_t address);

/**
 * Callback for memory writes
 *
 * @param address   The memory address to write
 * @param value     The value to write to the specified memory address
 */
typedef void (*write_callback_t)(uint16_t address, uint8_t value);

/**
 * Initialize the 6502 emulator. This sets the memory access functions as well as performs
 * an initial reset6502().
 *
 * @param read_callback - Function pointer for handling memory reads from the 6502
 * @oaram write_callback - Function pointer for handling memory writes from the 6502
 */
void init6502(read_callback_t read_callback, write_callback_t write_callback);

/**
 * Resets the 6502 emulator and forces it to process the reset vector.
 */
void reset6502(void);

/**
 * Executes 6502 code up to the next specified count of clock cycles.
 */
void exec6502(uint32_t tickcount);

/**
 * Executes a single instruction
 */
void step6502(void);


/** TODO interrupts
 * I want to eventually change this to a voting mechanism so that different modules
 * can "pull down" the IRQ line and the IRQ handler will continue to be processed
 * since it is level triggered.
 */
void disassemble(size_t bufLen, char *buf);
bool isBreakpoint(uint16_t pc);
