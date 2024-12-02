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

zero_done:
    # Function epilogue
    jr $ra

# Function: placePieceOnBoard
# Arguments: 
#   $a0 - address of piece struct
#   $a1 - ship_num
placePieceOnBoard:
    # Function prologue

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

piece_done:
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
    
    # iterate through the board (rows first)
    li $t4, 0			# t4 = i = 0 = row index
outer_loop:
    bge $t4, $t2, end_print	# i >= height -> end of loop
    # iterate through the columns
    li $t5, 0			# t5 = j = 0 = column index
inner_loop:
    bge $t5, $t1, new_row	# j >= width -> end of loop
    
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
    
    addi $t5, $t5, 1		# j++
    j inner_loop		# repeat loop
new_row:
    # print new line
    li $a0, 10			# a0 = 10 = ASCII for \n -> function argument for syscall to print
    li $v0, 11			# 11 -> print char
    syscall
    
    addi $t4, $t4, 1		# i++
    j outer_loop		# repeat loop
end_print:

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
    jr $ra

# Function: test_fit
# Arguments: 
#   $a0 - address of piece array (5 pieces)
test_fit:
    # Function prologue
    jr $ra


T_orientation4:
    # Study the other T orientations in skeleton.asm to understand how to write this label/subroutine
    j piece_done

.include "skeleton.asm"
