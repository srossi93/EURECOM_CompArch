# Polling-based IO (simple) example

.text
main:

wait_for_char:
	# Initialize CPU registers with addresses of keyboard interface registers
	la	$t0,	0xffff0000			# $t0 <- 0xffff_0000 (address of keyboard control register)
	la	$t1,	0xffff0004			# $t1 <- 0xffff_0004 (address of keyboard data register)
	lw	$t2,	0($t0)				# $t2 <- value of keyboard control register
	andi	$t2,	$t2,	1			# Mask all bits except LSB
	beq	$t2,	$zero,	wait_for_char		# Loop if LSB unset (no character from keyboard)
	lw	$v0,	0($t1)				# Store received character in $v0

wait_for_console_1:
	# Initialize CPU registers with addresses of console interface registers
	la	$t0,	0xffff0008			# $t0 <- 0xffff_0008 (address of console control register)
	la	$t1,	0xffff000c			# $t1 <- 0xffff_000c (address of console data register)
	lw	$t2,	0($t0)				# $t2 <- value of console control register
	andi	$t2,	$t2,	1			# Mask all bits except LSB
	beq	$zero,	$t2,	wait_for_console_1	# Loop if LSB unset (console busy)
	sw	$v0,	0($t1)				# Send character received from keyboard to console

wait_for_console_2:
	# Initialize CPU registers with addresses of console interface registers
	lw	$t2,	0($t0)				# $t2 <- value of console control register
	andi	$t2,	$t2,	1			# Mask all bits except LSB
	beq	$zero,	$t2,	wait_for_console_2	# Loop if LSB unset (console busy)
	li	$t3,	10				# ASCII code of newline
	sw	$t3,	0($t1)				# Send newline character to console

	b	wait_for_char				# Go to wait_for_char (infinite loop)
