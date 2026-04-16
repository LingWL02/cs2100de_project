.eqv MMIO_BASE 0x00002400
.eqv LED_OFF 0x00000000
.eqv DIP_OFF 0x00000004
.eqv PB_OFF 0x00000008
.eqv SEVENSEG_CFG_OFF 0x00000018
.eqv SEVENSEG_DW0_OFF 0x0000001C
.eqv SEVENSEG_DW1_OFF 0x00000020

# This sample program for RISC-V simulation using RARS

# ------- <code memory (ROM mapped to Instruction Memory) begins>
.text	## IROM segment 0x00000000-0x000001FC
# Total number of instructions should not exceed 128 (127 excluding the last line 'halt B halt').

# Note : see the wiki regarding the pseudoinstructions li and la.
# Pseudoinstructions may be implemented using more than one actual instruction. See the assembled code in the Execute tab of RARS
# You can also use the actual register numbers directly. For example, instead of s1, you can write x9

main:
    # MMIO base pointers
    lui s0, 0x2              # s0 = 0x00002000
    addi s0, s0, 1024        # s0 = 0x00002400
    add sp, s0, zero         # initialize stack pointer near top of DRAM/MMIO boundary
    addi s1, s0, LED_OFF     # LEDS
    addi s2, s0, DIP_OFF     # DIPS
    addi s3, s0, PB_OFF      # PBS
    addi s4, s0, SEVENSEG_CFG_OFF
    addi s5, s0, SEVENSEG_DW0_OFF
    addi s6, s0, SEVENSEG_DW1_OFF

    # s7: software cycle counter
    addi s7, zero, 0

    # s11: per-frame delay for ASCII animations
    la t0, DELAY_MSG_FRAME
    lw s11, 0(t0)

    # s8: base address of the 5 target values
    la s8, TARGET_VALUES

    # clear outputs
    sw zero, 0(s1)
    sw zero, 0(s4)
    sw zero, 0(s5)
    sw zero, 0(s6)

    # idle splash: "WELC"
    la a0, MSG_WELC
    add a1, s11, zero
    la t0, DELAY_WELC
    lw a2, 0(t0)
    jal ra, display_ascii_ltr

idle_wait_btnc:
    # idle prompt: "PSH BTNC" (animate once, then hold static while waiting)
    la a0, MSG_PSHC
    add a1, s11, zero
    addi a2, zero, 0
    jal ra, display_ascii_ltr
    la a0, MSG_PSHC
    jal ra, display_ascii_static_z

wait_btnc_press:
    lw t1, 0(s2)             # mirror switches to LEDs in idle
    sw t1, 0(s1)
    lw t2, 0(s3)
    addi s7, s7, 1
    andi t3, t2, 16          # BTN C is bit 4
    beq t3, zero, wait_btnc_press

wait_btnc_release:
    lw t2, 0(s3)
    addi s7, s7, 1
    andi t3, t2, 16
    bne t3, zero, wait_btnc_release

    # show "START"
    la a0, MSG_START
    add a1, s11, zero
    la t0, DELAY_START
    lw a2, 0(t0)
    jal ra, display_ascii_ltr

    # game index = 0
    addi s9, zero, 0

game_next_value:
    addi t0, zero, 5
    beq s9, t0, game_done

    slli t1, s9, 2
    add t2, s8, t1
    lw s10, 0(t2)            # current target (16-bit value in lower half)

    # show target in HEX mode as 0000XXXX
    add a0, s10, zero
    jal ra, display_hex

wait_btnr_submit:
    lw t3, 0(s2)             # show switch position on LEDs
    sw t3, 0(s1)
    lw t4, 0(s3)
    addi s7, s7, 1
    andi t5, t4, 2           # BTN R is bit 1
    beq t5, zero, wait_btnr_submit

    # sample switches when BTN R is pressed
    lw t3, 0(s2)
    slli t3, t3, 16
    srli t3, t3, 16          # t3 = switches[15:0]

    add t6, s10, zero
    slli t6, t6, 16
    srli t6, t6, 16          # t6 = target[15:0]

    bne t3, t6, wrong_answer

wait_btnr_release_ok:
    lw t4, 0(s3)
    addi s7, s7, 1
    andi t5, t4, 2
    bne t5, zero, wait_btnr_release_ok

    addi s9, s9, 1
    jal zero, game_next_value

wrong_answer:
    # show "INV"
    la a0, MSG_INV
    add a1, s11, zero
    la t0, DELAY_INV
    lw a2, 0(t0)
    jal ra, display_ascii_ltr

wait_btnr_release_bad:
    lw t4, 0(s3)
    addi s7, s7, 1
    andi t5, t4, 2
    bne t5, zero, wait_btnr_release_bad

    # redisplay same target and keep waiting
    add a0, s10, zero
    jal ra, display_hex
    jal zero, wait_btnr_submit

game_done:
    # show "CONGRATZ"
    la a0, MSG_CONGRATZ
    add a1, s11, zero
    la t0, DELAY_DONE
    lw a2, 0(t0)
    jal ra, display_ascii_ltr

    # then show elapsed software cycles in HEX mode
    add a0, s7, zero
    jal ra, display_hex

halt:
    jal zero, halt


# a0 = pointer to asciiz message
display_ascii_static_z:
    addi sp, sp, -20
    sw ra, 16(sp)
    sw s0, 12(sp)
    sw s1, 8(sp)
    sw s2, 4(sp)
    sw s3, 0(sp)

    add s0, a0, zero
    add a0, s0, zero
    jal ra, strlen8
    add s1, a0, zero

    add a0, s0, zero
    add a1, s1, zero
    addi a2, zero, 0
    addi a3, zero, 8
    jal ra, render_ascii_frame

    lw s3, 0(sp)
    lw s2, 4(sp)
    lw s1, 8(sp)
    lw s0, 12(sp)
    lw ra, 16(sp)
    addi sp, sp, 20
    jalr zero, 0(ra)


# a0 = pointer to asciiz message
# a1 = per-frame delay ticks
# a2 = hold delay ticks (after message is fully visible)
display_ascii_ltr:
    addi sp, sp, -24
    sw ra, 20(sp)
    sw s0, 16(sp)
    sw s1, 12(sp)
    sw s2, 8(sp)
    sw s3, 4(sp)
    sw s10, 0(sp)

    add s0, a0, zero         # msg ptr
    add s2, a1, zero         # frame delay
    add s3, a2, zero         # hold delay

    add a0, s0, zero
    jal ra, strlen8
    add s1, a0, zero         # len (0..8)

    beq s1, zero, display_ascii_ltr_done

    # Enter phase: reveal from left to right
    addi s10, zero, 1
display_ascii_ltr_enter_check:
    slt t0, s1, s10          # if len < k, done entering
    bne t0, zero, display_ascii_ltr_hold

    add a0, s0, zero
    add a1, s1, zero
    addi a2, zero, 0
    add a3, s10, zero
    jal ra, render_ascii_frame

    add a0, s2, zero
    jal ra, delay_ticks

    addi s10, s10, 1
    jal zero, display_ascii_ltr_enter_check

display_ascii_ltr_hold:
    add a0, s0, zero
    add a1, s1, zero
    addi a2, zero, 0
    add a3, s1, zero
    jal ra, render_ascii_frame

    add a0, s3, zero
    jal ra, delay_ticks

    # Exit phase: blank from left to right
    addi s10, zero, 1
display_ascii_ltr_exit_check:
    slt t0, s1, s10          # if len < lb, done exiting
    bne t0, zero, display_ascii_ltr_done

    sub t1, s1, s10          # visible_count = len - left_blank
    add a0, s0, zero
    add a1, s1, zero
    add a2, s10, zero
    add a3, t1, zero
    jal ra, render_ascii_frame

    add a0, s2, zero
    jal ra, delay_ticks

    addi s10, s10, 1
    jal zero, display_ascii_ltr_exit_check

display_ascii_ltr_done:
    lw s10, 0(sp)
    lw s3, 4(sp)
    lw s2, 8(sp)
    lw s1, 12(sp)
    lw s0, 16(sp)
    lw ra, 20(sp)
    addi sp, sp, 24
    jalr zero, 0(ra)


# a0 = pointer to asciiz string
# returns a0 = length, capped at 8
strlen8:
    addi t0, zero, 0
strlen8_loop:
    add t1, a0, t0
    lbu t2, 0(t1)
    beq t2, zero, strlen8_done
    addi t0, t0, 1
    addi t3, zero, 8
    beq t0, t3, strlen8_done
    jal zero, strlen8_loop
strlen8_done:
    add a0, t0, zero
    jalr zero, 0(ra)


# a0 = msg ptr, a1 = len, a2 = start index in message, a3 = visible_count (from left)
render_ascii_frame:
    addi t0, zero, 0         # i
    addi t1, zero, 0         # dw0
    addi t2, zero, 0         # dw1

render_ascii_frame_loop:
    addi t3, zero, 8
    beq t0, t3, render_ascii_frame_done

    addi t4, zero, 32        # default char = ' '

    # if i < visible_count, try to load message[start+i]
    slt t5, t0, a3
    beq t5, zero, render_ascii_pack

    # j = start + i
    add t6, t0, a2

    # j < len ?
    slt t5, t6, a1
    beq t5, zero, render_ascii_pack

    # load message char
    add a4, a0, t6
    lbu t4, 0(a4)

render_ascii_pack:
    slti t5, t0, 4
    beq t5, zero, render_ascii_pack_dw1

    slli t1, t1, 8
    or t1, t1, t4
    jal zero, render_ascii_next

render_ascii_pack_dw1:
    slli t2, t2, 8
    or t2, t2, t4

render_ascii_next:
    addi t0, t0, 1
    jal zero, render_ascii_frame_loop

render_ascii_frame_done:
    addi t3, zero, 1         # cfg bit0 = ascii mode
    sw t3, 0(s4)
    sw t1, 0(s5)
    sw t2, 0(s6)
    jalr zero, 0(ra)


# a0 = value to display in hex mode (word0)
display_hex:
    sw zero, 0(s4)           # cfg bit0 = 0 -> hex mode
    sw a0, 0(s5)
    sw zero, 0(s6)
    jalr zero, 0(ra)


# a0 = loop count, increments s7 each iteration
delay_ticks:
    beq a0, zero, delay_done_ret
delay_loop:
    addi s7, s7, 1
    addi a0, a0, -1
    bne a0, zero, delay_loop
delay_done_ret:
    jalr zero, 0(ra)


#------- <constant memory (ROM mapped to Data Memory) begins>
.data	## DROM segment 0x00002000-0x000021FC
# All constants should be declared in this section. This section is read only (Only lw, no sw).
# Total number of constants should not exceed 128
# If a variable is accessed multiple times, it is better to store the address in a register and use it rather than load it repeatedly.
DROM:
DELAY_VAL: .word 4
string1:
.asciz "\r\nWelcome to CS2100DE..\r\n"

# Delay constants (tune as needed on hardware)
DELAY_MSG_FRAME: .word 70000
DELAY_WELC:  .word 300000
DELAY_START: .word 180000
DELAY_INV:   .word 180000
DELAY_DONE:  .word 300000

# 5 game values (16-bit each in low halfword)
TARGET_VALUES:
.word 0x00001A2B
.word 0x00000F0F
.word 0x0000BEEF
.word 0x00001357
.word 0x0000C0DE

# ASCII messages for SevenSegDecoderDual
MSG_WELC:     .asciz "WELC"
MSG_PSHC:     .asciz "PSH BTNC"
MSG_START:    .asciz "START"
MSG_INV:      .asciz "INV"
MSG_CONGRATZ: .asciz "CONGRATZ"

#------- <constant memory (ROM mapped to Data Memory) ends>




# ------- <variable memory (RAM mapped to Data Memory) begins>
.align 9 ## DRAM segment. 0x00002200-0x000023FC #assuming rodata size of <= 512 bytes (128 words)
# All variables should be declared in this section, adjusting the space directive as necessary. This section is read-write.
# Total number of variables should not exceed 128.
# No initialization possible in this region. In other words, you should write to a location before you can read from it (i.e., write to a location using sw before reading using lw).
DRAM:
.space 512

# ------- <variable memory (RAM mapped to Data Memory) ends>




# ------- <memory-mapped input-output (peripherals) begins>
.align 9 ## MMIO segment. 0x00002400-0x00002420
MMIO:
LEDS: .word 0x0			# 0x00002400	# Address of LEDs. //volatile unsigned int * LEDS = (unsigned int*)0x00000C00#
DIPS: .word 0x0			# 0x00002404	# Address of DIP switches. //volatile unsigned int * DIPS = (unsigned int*)0x00000C04#
PBS: .word 0x0			# 0x00002408	# Address of Push Buttons. Used only in Lab 2
CONSOLE: .word 0x0		# 0x0000240C	# Address of UART. Used only in Lab 2 and later
CONSOLE_IN_valid: .word 0x0	# 0x00002410	# Address of UART. Used only in Lab 2 and later
CONSOLE_OUT_ready: .word 0x0	# 0x00002414	# Address of UART. Used only in Lab 2 and later
SEVENSEG_CFG: .word	0x0		# 0x00002418	# Address of 7-Segment LEDs. Used only in Lab 2 and later
SEVENSEG_DW0: .word	0x0
SEVENSEG_DW1: .word	0x0