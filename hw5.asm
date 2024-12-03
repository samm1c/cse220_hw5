.data
space: .asciiz " "    # Space character for printing between numbers
newline: .asciiz "\n" # Newline character
extra_newline: .asciiz "\n\n" # Extra newline at end

.text
.globl zeroOut 
.globl place_tile 
.globl printBoard 
.globl placePieceOnBoard 
.globl test_fit 

# Function: zeroOut
# Arguments: None
# Returns: void
zeroOut:
    # Function prologue
    # load board first
    la $t0, board_width		# t0 -> width addr
    lw $t1, 0($t0)		# t1 = width
    la $t0, board_height	# t0 -> height addr
    lw $t2, 0($t0)		# t2 = height
    la $t3, board		# t3 -> board addr
    
    # start loop
    li $t4, 0			# t4 = i = 0 = row index
zero_outer_loop:
    bge $t4, $t2, zero_done	# i >= height -> end of loop
    li $t5, 0			# t5 = j = 0 = column index
zero_inner_loop:
    bge $t5, $t1, zero_inner_done
    # calculate board[i][j]
    mul $t6, $t4, $t1 		# t6 = i * width -> skip rows
    add $t6, $t6, $t5		# t6 = (i * width) + j -> add column index
    add $t6, $t3, $t6		# t6 = board address + offset = address of board[i][j]
    sb $zero, 0($t6)		# set board[i][j] to 0
    # loop management
    addi $t5, $t5, 1		# j++
    j zero_inner_loop
zero_inner_done:
    addi $t4, $t4, 1		# i++
    j zero_outer_loop
zero_done:
    # Function epilogue
    jr $ra

# Function: placePieceOnBoard
# Arguments: 
#   $a0 - address of piece struct
#   $a1 - ship_num
placePieceOnBoard:
    # Function prologue
    
    # preserve space for ra because this is a non-leaf function (calls other functions)
    addi $sp, $sp, -4		# space
    sw $ra, 0($sp)
    
    # load piece struct
    lw $s3, 0($a0)		# s3 = type (when loading piece fields)
    lw $s4, 4($a0)		# s4 = orientation
    lw $s5, 8($a0)		# s5 = row
    lw $s6, 12($a0)		# s6 = col
    
    move $s1, $a1			# s1 = ship_num
    li $s2, 0

    # Load piece fields
    # First switch on type
    li $t0, 1
    beq $s3, $t0, piece_square
    li $t0, 2
    beq $s3, $t0, piece_line
    li $t0, 3
    beq $s3, $t0, piece_reverse_z
    li $t0, 4
    beq $s3, $t0, piece_L
    li $t0, 5
    beq $s3, $t0, piece_z
    li $t0, 6
    beq $s3, $t0, piece_reverse_L
    li $t0, 7
    beq $s3, $t0, piece_T
    j piece_done       # Invalid type

piece_done: # error checking and return values!

    beq $s2, $zero, piece_success	# total accumulated error = 0 -> success!
    
    jal zeroOut				# non-zero -> error -> clear board
    
    li $t0, 1
    beq $s2, $t0, piece_occupied	# s2 == 1 -> return 1
    
    li $t0, 2
    beq $s2, $t0, piece_outofbounds	# s2 == 2 -> return 2
    
    li $v0, 3				# s2 == 3 -> return 3 guaranteed
    j restore_ra

piece_success:
    li $v0, 0
    j restore_ra
    
piece_occupied:
    li $v0, 1
    j restore_ra

piece_outofbounds:
    li $v0, 2
    j restore_ra

restore_ra: # ends function
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

    
# Function: printBoard
# Arguments: None (uses global variables)
# Returns: void
# Uses global variables: board (char[]), board_width (int), board_height (int)
printBoard:
    # Function prologue
    # load board first b/c we need to perform operations on their addresses
    la $t0, board_width 	# t0 -> holds width address
    lw $t1, 0($t0)		# t1 = board_width
    la $t0, board_height	# t0 -> holds height address
    lw $t2, 0($t0)		# t2 = board_height
    la $t3, board		# t3 -> holds board address
    
    # loop start
    li $t4, 0			# t4 = i = 0 = row index
print_outer_loop:
    bge $t4, $t2, print_end	# i >= height -> end of loop
    li $t5, 0			# t5 = j = 0 = column index
print_inner_loop:
    bge $t5, $t1, print_new_row	# j >= width -> end of loop
    # calulate board[i][j]
    mul $t6, $t4, $t1 		# t6 = i * width -> skip previous rows
    add $t6, $t6, $t5		# t6 = (i * width) + j -> add j column index
    add $t6, $t3, $t6		# t6 = board address + offset = address of board[i][j]
    # print the number
    lb $a0, 0($t6)		# a0 = address of board[i][j] -> function argument for syscall to print
    li $v0, 1			# 11 -> print integer in syscall
    syscall
    # print a space after
    li $a0, 32			# a0 = 32 = ASCII for space
    li $v0, 11			# 11 -> print char
    syscall
    # loop management
    addi $t5, $t5, 1		# j++
    j print_inner_loop		# repeat loop
print_new_row:
    # print new line
    li $a0, 10			# a0 = 10 = ASCII for \n -> function argument for syscall to print
    li $v0, 11			# 11 -> print char
    syscall
    # loop management
    addi $t4, $t4, 1		# i++
    j print_outer_loop		# repeat loop
print_end:
    # Function epilogue
    jr $ra                # Return

# Function: place_tile
# Arguments: 
#   $a0 - row
#   $a1 - col
#   $a2 - value
# Returns:
#   $v0 - 0 if successful, 1 if occupied, 2 if out of bounds
# Uses global variables: board (char[]), board_width (int), board_height (int)
place_tile:
    # load board first
    la $t0, board_width		# t0 -> holds width address
    lw $t1, 0($t0)		# t1 = width
    la $t0, board_height	# t0 -> holds height address
    lw $t2, 0($t0)		# t2 = height
    la $t3, board		# t3 -> holds board address
    
    # calculate board[row][col]
    mul $t4, $a0, $t1		# t4 = row * width -> skip rows
    add $t4, $t4, $a1		# t4 = (row * width) + col -> add col index
    add $t4, $t3, $t4		# t4 = board address + offset -> address of board[row][col]
    lb $t5, 0($t4)		# t5 = board[row][col] -> actual value
    
    # check for out of bounds -> return 2
    bltz $a0, out_of_bounds	# row < 0
    bge $a0, $t2, out_of_bounds	# row >= height
    bltz $a1, out_of_bounds	# col < 0
    bge $a1, $t1, out_of_bounds	# col >= width
    
    # check if occupied -> return 1
    bnez $t5, occupied		# board[row][col] != 0

    # we're in the clear -> modify board!
    sb $a2, 0($t4)		# set board[row][col] to val
    li $v0, 0			# success!
    jr $ra
out_of_bounds:
    li $v0, 2
    jr $ra
occupied:
    li $v0, 1
    jr $ra
    
# Function: test_fit
# Arguments: 
#   $a0 - address of piece array (5 pieces)
test_fit:
    # Function prologue
    jr $ra


T_orientation4:
    # Study the other T orientations in skeleton.asm to understand how to write this label/subroutine
    
    # (0,0)
    # load arguments (a0, a1, a2) for place_tile
    move $a0, $s5		# a0 = row
    move $a1, $s6		# a1 = col
    move $a2, $s1		# a2 = ship_num
    # call place_tile
    jal place_tile
    or $s2, $s2, $v0		# accumulate error by or'ing return value from place_tile
    
    # (1,0)
    move $a0, $s5		
    addi $a0, $a0, 1		# a0 = row + 1
    move $a1, $s6		# a1 = col
    move $a2, $s1		
    jal place_tile
    or $s2, $s2, $v0
    
    # (2,0)
    move $a0, $s5		
    addi $a0, $a0, 2		# a0 = row + 2
    move $a1, $s6		# a1 = col
    move $a2, $s1		
    jal place_tile
    or $s2, $s2, $v0
    
    # (1,1)
    move $a0, $s5		
    addi $a0, $a0, 1		# a0 = row + 1
    move $a1, $s6		
    addi $a1, $a1, 1		# a1 = col + 1
    move $a2, $s1		
    jal place_tile
    or $s2, $s2, $v0
    
    j piece_done

.include "skeleton.asm"
