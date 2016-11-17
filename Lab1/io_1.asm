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

# Read character. Return read character in $v0.
getc:
	li	$v0,	12			# Syscall code for read_char
	syscall
	jr	$ra				# Return

# Print character in $a0.
putc:
	li	$v0,	1			# Syscall code for print_int
	syscall
	jr	$ra				# Return

# Read integer. Return read integer in $v0.
geti:
	li	$v0,	5			# Syscall code for read_int
	syscall
	jr	$ra				# Return

# Print integer in $a0.
puti:
	li	$v0,	1			# Syscall code for print_int
	syscall
	jr	$ra				# Return

# Main routine
main:

# Read a character, goto end if it is a newline, else print it.
main_char:
	la	$a0,	enter_char_message	# Print message
	li	$v0,	4
	syscall
	jal	getc				# Read character
	li	$t0,	10			# Newline ASCII code
	beq	$v0,	$t0,	main_end	# Goto end if read character is newline
	move	$s0,	$v0			# Copy read character in $s0
	la	$a0,	print_char_message	# Print message
	li	$v0,	4
	syscall
	move	$a0,	$s0			# Copy read character in $a0
	jal	putc				# Print read character

# Read an integer, goto end if it is 0, else print it.
main_int:
	la	$a0,	enter_int_message	# Print message
	li	$v0,	4
	syscall
	jal	geti				# Read integer
	beq	$v0,	$zero,	main_end	# Goto end if read integer is 0
	move	$s0,	$v0			# Copy read integer in $s0
	la	$a0,	print_int_message	# Print message
	li	$v0,	4
	syscall
	move	$a0,	$s0			# Copy read integer in $a0
	jal	puti				# Print read integer

	b	main_char			# Loop

main_end:
	la	$a0,	bye_message		# Print message
	li	$v0,	4
	syscall
	li	$v0,	10			# Exit
	syscall
