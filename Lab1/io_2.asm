# QtSpim, part 1

# Data section
.data

# Messages
enter_char_message:
.asciiz "\nPlease enter a character (newline to quit): "
print_char_message:
.asciiz "\nThe character you entered is: "
enter_int_message:
.asciiz "\nPlease enter an integer (0 to quit): "
print_int_message:
.asciiz "\nThe integer you entered is: "
bye_message:
.asciiz "\nBye!"

# Code section
.text

#***************************************************************************************************
# Read character. Return read character in $v0.
#***************************************************************************************************
getc:
  wait_for_char:
    # Initialize CPU registers with addresses of keyboard interface registers
    la  $t0,  0xffff0000  # $t0 <- 0xffff_0000 (address of keyboard control register)
    la  $t1,  0xffff0004  # $t1 <- 0xffff_0004 (address of keyboard data register)
    lw  $t2,  0($t0)    # $t2 <- value of keyboard control register
    andi  $t2,  $t2,  1  # Mask all bits except LSB
    beq  $t2,  $zero,  wait_for_char  # Loop if LSB unset (no character from keyboard)
  lw  $v0,  0($t1)      # Store received character in $v0
  jr  $ra        # Return

#***************************************************************************************************
# Print character in $a0.
#***************************************************************************************************
putc:
  wait_for_console_1:
    # Initialize CPU registers with addresses of console interface registers
    la  $t0,  0xffff0008      # $t0 <- 0xffff_0008 (address of console control register)
    la  $t1,  0xffff000c      # $t1 <- 0xffff_000c (address of console data register)
    lw  $t2,  0($t0)        # $t2 <- value of console control register
    andi  $t2,  $t2,  1      # Mask all bits except LSB
    beq  $zero,  $t2,  wait_for_console_1  # Loop if LSB unset (console busy)
  sw  $a0,  0($t1)        # Send character received from keyboard to console

  wait_for_console_2:
    # Initialize CPU registers with addresses of console interface registers
    lw  $t2,  0($t0)        # $t2 <- value of console control register
    andi  $t2,  $t2,  1      # Mask all bits except LSB
    beq  $zero,  $t2,  wait_for_console_2  # Loop if LSB unset (console busy)
  li  $t3,  10        # ASCII code of newline
  sw  $t3,  0($t1)        # Send newline character to console
  jr $ra
#***************************************************************************************************
# Convertion ASCII code of a character in register $a0 to a decimal integer between 0
# and 9 and returns it in register $v0. Return also an error code in register $v1:
# 0: no error
# 1: not-a-digit error
#***************************************************************************************************
d2i:
	# Check if the ASCII code is greater than 57 ('9')
	li  $t0, 57	# Store 57 in t0
	bgt $a0, $t0, __not_a_number # Branch if $a0 > 57
	
	# Check if the ASCII code is less than 48 ('0')
	li  $t0, 48	# Store 48 in t0
	blt $a0, $t0, __not_a_number # Branch if $a0 < 48

	# $a0 is a number 
	subu $v0, $a0, $t0
	li $v1, 0
	jr $ra

	__not_a_number:
		li	$v1, 1 
		jr $ra	

#***************************************************************************************************
# Read integer. 
# Store the value of the read unsigned integer in register $v0. 
# Return an error code in $v1:
# 0: no error
# 1: not-a-digit error
# 2: overflow (the unsigned integer does not fit on 32 bits)
# Rel 1.0  - Works only with unsigned 
#***************************************************************************************************
geti:
  # $s0 used as temporary result
	addi	$sp, $sp, -16	
	sw		$ra, 12($sp)
	sw    $s2, 8($sp)
	sw		$s1, 4($sp)
	sw		$s0, 0($sp)
	
	xor		$s0, $s0, $s0
	# SAVE s0, s1 and s2!!!!!!!
	# Save Return Address


  __new_char:
	  # Get char from keyboard
	  jal		getc 
	  # If it is 'return' exit
	  addi	$s2, $zero, 10  
	  beq		$s0, $v0, __number_finished
	  # Otherwise convert into number
	  add   $a0, $zero, $v0
	  jal   d2i
	  # Check return code
	  addi  $s2, $zero, 1
	  beq		$s2, $v1, __not_a_number_error
    # Update numerical value
	  addi  $s3, $zero, 10
	  mul   $s0, $s0, $s3
	  add   $s0, $s0, $v0
    b			__new_char

__not_a_number_error:


__number_finished:
	
	add  $v0, $zero, $s0
	
	# Restore Return Address
	lw		$ra, 12($sp)
	lw    $s2, 8($sp)
	lw		$s1, 4($sp)
	lw		$s0, 0($sp)
	addi  $sp, $sp, 16
	

	
	jr  $ra        # Return

#***************************************************************************************************
# Print integer in $a0.
#***************************************************************************************************
puti:
  li  $v0,  1      # Syscall code for print_int
  syscall
  jr  $ra        # Return

#***************************************************************************************************
# Main routine
#***************************************************************************************************
main:

# Read a character, goto end if it is a newline, else print it.
# main_char:
#   la  $a0,  enter_char_message  # Print message
#   li  $v0,  4
#   syscall
#   jal  getc        # Read character
#   li  $t0,  10      # Newline ASCII code
#   beq  $v0,  $t0,  main_end  # Goto end if read character is newline
#   move  $s0,  $v0      # Copy read character in $s0
#   la  $a0,  print_char_message  # Print message
#   li  $v0,  4
#   syscall
#   move  $a0,  $s0      # Copy read character in $a0
#   jal  putc        # Print read character

# Read an integer, goto end if it is 0, else print it.
main_int:
  la  $a0,  enter_int_message  # Print message
  li  $v0,  4
  syscall
  jal  geti        # Read integer
  beq  $v0,  $zero,  main_end  # Goto end if read integer is 0
  move  $s0,  $v0      # Copy read integer in $s0
  la  $a0,  print_int_message  # Print message
  li  $v0,  4
  syscall
  move  $a0,  $s0      # Copy read integer in $a0
  jal  puti        # Print read integer

  b  main      # Loop

main_end:
  la  $a0,  bye_message    # Print message
  li  $v0,  4
  syscall
  li  $v0,  10      # Exit
  syscall
