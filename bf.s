# Compile and run with
#
#    gcc -o bf stdio.s bf.s
#    ./bf
#

		.text
		.globl _main
		.globl main

# Registers :
#		%rax, %rdx, %rdi : temporary data
#		%rbx : current cell (relative to %rsp)
#		%rcx : current instruction index (relative to %rsp)
#		%rsi : code length (used to free the stack at the end)
#		%r8 : number of cells available

_main:
main:
		lea	message(%rip), %rax
		push %rax
		call print_string

		# Use %rcx to count the number of instructions in the bf code
		mov $0, %rcx

input_code:
		# Read char
		call getchar

    input_char1:
		mov $'+', %rdx
		cmp %rax, %rdx
		je store_char

		mov $'-', %rdx
		cmp %rax, %rdx
		je store_char

		mov $'+', %rdx
		cmp %rax, %rdx
		je store_char

		mov $'>', %rdx
		cmp %rax, %rdx
		je store_char

		mov $'<', %rdx
		cmp %rax, %rdx
		je store_char

		mov $'[', %rdx
		cmp %rax, %rdx
		je store_char

		mov $']', %rdx
		cmp %rax, %rdx
		je store_char

		mov $'.', %rdx
		cmp %rax, %rdx
		je store_char

		mov $',', %rdx
		cmp %rax, %rdx
		je store_char
		
		mov $';', %rdx
		cmp %rax, %rdx
		je prepare_code

		# Ignore everything except the 8 bf operators & ";"
		jmp input_code
		
    store_char:
		pushq %rax
		addq $1, %rcx

		jmp input_code

prepare_code:

		pushq $';' # end-of-code indicator
		inc %rcx
		
		# %rsi contains the code length
		mov %rcx, %rsi

		# Number of cells
		mov $10, %r8

		# Allocate space for cells on the stack
		mov %r8, %rax
		mov $0, %rdx

    push_zero:
		push $0
		dec %rax
		cmp %rdx, %rax
		jne push_zero
		
		# %rcx : next instruction index (relative to rsp)
		add %r8, %rcx

		# %rbx : current cell index (relative to rsp)
		mov %r8, %rbx
		dec %rbx

eval:
		# Put the next statement in rax
		dec %rcx
		mov (%rsp, %rcx, 8), %rax

plus:
		mov $'+', %rdx
		cmp %rax, %rdx
		jne minus

		incq (%rsp, %rbx, 8)

		jmp eval

minus:	mov $'-', %rdx
		cmp %rax, %rdx
		jne pointer_up

		decq (%rsp, %rbx, 8)

		jmp eval

pointer_up:
		mov $'>', %rdx
		cmp %rax, %rdx
		jne pointer_down

		dec %rbx

		jmp eval

pointer_down:
		mov $'<', %rdx
		cmp %rax, %rdx
		jne loop_open

		inc %rbx

		jmp eval

loop_open:
		mov $'[', %rdx
		cmp %rax, %rdx
		jne loop_close

		mov (%rsp, %rbx, 8), %rax
		cmp $0, %rax
		jne loop_open_nonzero

  loop_open_zero:
		# if current pointer is zero
		# ignore all characters until the corresponding ] is matched

		# count nested loops to ignore them
		mov $0, %rdi
    ignore_code:

		dec %rcx
		mov (%rsp, %rcx, 8), %rax

		sub $']', %rax
		mov $0, %rdx
		
		# if next instruction is ]
		cmp %rax, %rdx
		je test_closing_loop
		jmp test_inc_nested_loop

	  test_closing_loop:
		# if rdi == 0, continue with the code, else, dec number of nested loops
		cmp %rdx, %rdi
		je eval
		jmp dec_nested_loop

      dec_nested_loop:
		dec %rdi
		jmp ignore_code

      test_inc_nested_loop:
		# else if next instruction is [
		
		# %rax contains `instruction` - $']'
		# Note that $'[' - $']' = -2
		mov $-2, %rdx
		cmp %rdx, %rax
		je inc_nested_loop
		
		# else : ignore the char
		jmp ignore_code

      inc_nested_loop:
		inc %rdi
		jmp ignore_code

  loop_open_nonzero:
		# if current pointer is non-zero, stack the
		# current instruction address (%rcx) and adjust %rbx and %rcx

		push %rcx
		inc %rbx
		inc %rcx
		
		jmp eval

loop_close:
		mov $']', %rdx
		cmp %rax, %rdx
		jne print
		
		mov (%rsp, %rbx, 8), %rax
		cmp $0, %rax
		jne loop_close_nonzero

  loop_close_zero:
		# pop the matching [ address and continue
		pop %rax
		dec %rbx
		dec %rcx

		jmp eval

  loop_close_nonzero:

		# if current pointer is non-zero, go to the matching [
		pop %rcx
		push %rcx
		inc %rcx
		
		jmp eval

print:	mov $'.', %rdx
		cmp %rax, %rdx
		jne read

		mov (%rsp, %rbx, 8), %rax
		push %rax
		call putchar
		
		jmp eval

read:	mov $',', %rdx
		cmp %rax, %rdx
		jne quit

		call getchar
		mov %rax, (%rsp, %rbx, 8)

quit:	mov $';', %rdx
		cmp %rax, %rdx
		je	exit

		jmp eval

exit:
		mov (%rsp, %rbx, 8), %rax

		# resize the stack
		add %r8, %rsi
		imul $8, %rsi
		add %rsi, %rsp

		ret

		.data
message:	.asciz "Enter your brainfuck code followed by a \";\" :\n"
