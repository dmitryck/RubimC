#####################################################################
# Example: "Clear-C code"                                         	#
# Author: Evgeny Danilov                                        	#
# Created at 2016-04-26                                         	#
#####################################################################

require 'rubimc'

def main(argv)

	# some console print example
	print_comment "This is clear C code, it can be compiled with 'gcc' utility"
	printf "========Run Program========\n"
	printf "Hello! I`m code generated by RubimC and compiled by gcc\n"
	printf "I have %d arguments: ", argv.count
	argv.count.times do |i|
		printf "%s ", argv[i]
	end
	printf "\n"

	# some arithmetic operation example
	integer :b
	boolean :c
	double :u1
	b = 1; 
	c = false
	u1 = b*b + (2*b) + (b + 3)

	# some conditions example
	if b > 0
		if u1 == c
			b = 27 & c
			u1 = 33 if b!= c
		end 
	end

	# some loop example
	u1.times do |i|
		next if i==2
		printf("now 'i' value is %d\n", i)
	end

	# connect external library
	ExternLibs.add("test_lib.h")
	printf "External function return: %d\n", ExternLibs.eval("test_lib()")
end