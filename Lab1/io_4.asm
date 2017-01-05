# QtSpim, part 1

# Data section
.data

# The time-out flag
time_out_flag:
.word 0x00000000

time:
.word 0x00000200   # About 5.12 seconds

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
not_char_message:
.asciiz "\nSorry, the character you inserted is not a number. Try again, please!"
overflow_message:
.asciiz "\nSorry, the number you inserted is too big. Try again, please!"

# Code section
.text

#***************************************************************************************************
# Read character. Return read character in $v0.
#***************************************************************************************************
getc:
	# Timer handling
	xor			$t0,  $t0,  $t0
  sw 			$t0,  time_out_flag($zero)						# Reset the time out flag 	
  mtc0		$t0,  $9 													    # Reset the count register of the timer 
	mfc0		$t0,	$12			                        # Read Status register of the coprocessor
	ori			$t0,	$t0,	0x1												# Enable Interrupts 
	addi    $t1,  $zero,  -2
	sll     $t1,  $t0,  16
	ori     $t1,  $t1, 0xFFFF
	and			$t0,	$t0,	$t1			    							# Unmask the Level 5 Interrupts (for Timer) 
	mtc0		$t0,	$12															# Write Status register on the coprocessor


  wait_for_char:
		# Control the timeout flag
		# If the timeout flag is 0 continue, otherwise error
		la  	$t1, 		time_out_flag
		lw		$t7, 		0($t1)
		beq		$t7, 		$zero,		getc_continue
    addi	$v1,		$zero,		3
		b 		getc_exit

	getc_continue:
    # Initialize CPU registers with addresses of keyboard interface registers
    la  	$t0,  	0xffff0000  							# $t0 <- 0xffff_0000 (address of keyboard control register)
    la  	$t1,  	0xffff0004  							# $t1 <- 0xffff_0004 (address of keyboard data register)
    lw  	$t2,  	0($t0)    								# $t2 <- value of keyboard control register
    andi  $t2,  	$t2,	 		1  							# Mask all bits except LSB
    beq  	$t2,  	$zero, 		wait_for_char  	# Loop if LSB unset (no character from keyboard)
  	lw  	$v0,  	0($t1)      							# Store received character in $v0
	
	getc_exit:
 		jr  	$ra  											      # Return

#***************************************************************************************************
# Print character in $a0.
#***************************************************************************************************
putc:
	xor			$t0,  $t0,  $t0
  sw 			$t0,  time_out_flag($zero)						# Reset the time out flag 	
  mtc0		$t0,  $9 													    # Reset the count register of the timer 
	mfc0		$t0,	$12			                        # Read Status register of the coprocessor
	ori			$t0,	$t0,	0x1												# Enable Interrupts 
	addi    $t1,  $zero,  -2
	sll     $t1,  $t0,  16
	ori     $t1,  $t1, 0xFFFF
	and			$t0,	$t0,	$t1			    							# Unmask the Level 5 Interrupts (for Timer) 
	mtc0		$t0,	$12															# Write Status register on the coprocessor
  
	wait_for_console_1:
		# Control the timeout flag
		# If the timeout flag is 0 continue, otherwise error
		la  	$t1, 		time_out_flag
		lw		$t7, 		0($t1)
		beq		$t7, 		$zero, 		putc_continue1
    addi	$v1, 		$zero, 		3
		b 		putc_exit
	
	putc_continue1:
    # Initialize CPU registers with addresses of console interface registers
    la    $t0,  	0xffff0008	                    # $t0 <- 0xffff_0008 (address of console control register)
    la  	$t1,  	0xffff000c  		                # $t1 <- 0xffff_000c (address of console data register)
    lw  	$t2,  	0($t0)          	              # $t2 <- value of console control register
    andi  $t2,  	$t2,			1       							# Mask all bits except LSB
    beq  	$zero,  $t2,  		wait_for_console_1	  # Loop if LSB unset (console busy)
    sw  	$a0,  	0($t1)        									# Send character received from keyboard to console

  wait_for_console_2:
		# Control the timeout flag
		# If the timeout flag is 0 continue, otherwise error
		la  	$t2, 		time_out_flag
		lw		$t7, 		0($t2)
		beq		$t7, 		$zero,		putc_continue2
    addi	$v1, 		$zero, 		3
		b     putc_exit
	
	putc_continue2:
    # Initialize CPU registers with addresses of console interface registers
    lw  		$t2,  	0($t0)        								# $t2 <- value of console control register
    andi  	$t2,		$t2,		1 							    	# Mask all bits except LSB
    beq  		$zero,  $t2,  	wait_for_console_2	  # Loop if LSB unset (console busy)
    li  		$t3,  	10   													# ASCII code of newline
    sw  		$t3,  	0($t1)      									# Send newline character to console

putc_exit:
  	jr 			$ra

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
    # Check for timeout error
		addi	$t0, $zero, 3
		beq   $v1, $t0, __geti_exit

	  # If it is 'return' exit
	  addi	$s2, $zero, '\n'  
	  beq		$s2, $v0, __number_finished
	  # Otherwise convert into number
	  add   $a0, $zero, $v0
	  jal   d2i
	  # Check return code
	  addi  $s2, $zero, 1
	  beq		$s2, $v1, __not_a_number_error
    # Update numerical value
	  addi  $s3,		$zero, 		10
		add   $s4,    $zero, 		$s0  					# Save in s4 the snapshot of the previous number
	  mul   $s0,    $s0, 			$s3
	  add   $s0,    $s0, 			$v0
		# If the new number is less than the number in s4 => overflow
    sgtu  $t1, 		$s0, 			$s4
    b			__new_char

    # Overflow error
		addi 	$v1, 		$zero, 		2
		b 	 	__geti_exit    

  __not_a_number_error:
    addi  $v1, $zero, 1
 	  b     __geti_exit

  __number_finished:
	  add   $v0, $zero, $s0
    addi  $v1, $zero, 0
	
__geti_exit:	
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
  addi    $t0, 	$zero, 500
	mtc0    $t0, 	$11														# Set the Compare register of the timer to 500 (5 sec)


# Read a character, goto end if it is a newline, else print it.
 main_char:
   la			$a0,		enter_char_message  				# Print message
   li  		$v0,  	4
   syscall
   jal  	getc        												# Read character
	 addi 	$t0,	 	$zero,		3									# Check timeout error
	 beq 		$v1, 		$t0, 			main_end					# If timer expires exit
   li  		$t0,  	10      										# Newline ASCII code
   beq  	$v0,  	$t0, 			main_end  				# Goto end if read character is newline
   move  	$s0,  	$v0      										# Copy read character in $s0
   la  		$a0,  	print_char_message  				# Print message
   li  		$v0,  	4
   syscall
   move  	$a0,  	$s0      										# Copy read character in $a0
   jal  	putc        												# Print read character
	 addi 	$t0,	 	$zero,		3									# Check timeout error
	 beq 		$v1, 		$t0, 			main_end					# If timer expires exit

# Read an integer, goto end if it is 0, else print it.
main_int:
  la 	 		$a0,  	enter_int_message  					# Print message
  li  		$v0,  	4
  syscall
  jal  		geti        												# Read integer
	addi 		$t0,	 	$zero,		3									# Check timeout error
	beq 		$v1, 		$t0, 			main_end					# If timer expires exit
  # Check error code
  beq  		$v1, 		$zero, 		no_error # Print if error code is 0
  # We are here if an error has been detected
	addi 		$t0, 		$zero, 		1
  beq  		$v1, 		$t0, 			no_char_error 		# Not char error if error code is 1
  # The error code is 2 (overflow), print something and return
  la  		$a0,  	overflow_message  					# Print message
  li  		$v0,	  4
  syscall
	b		 		main_int

no_char_error:
  # Print something
  la  		$a0,  	not_char_message  					# Print message
  li  		$v0,  	4
  syscall
	b main_int

no_error:
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
