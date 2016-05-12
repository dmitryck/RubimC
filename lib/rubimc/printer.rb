#####################################################################
# RubimCode::Printer 
# 
# It content methods for print generated C-code
#     in output files (.c & .h) and in console
# Main method "generate_cc" call method for print layouts of code,
#     execute user programm, and then print interrupts for MCUs
#####################################################################

class << RubimCode

	# C-code shift (RubimC generate beauty and readable C-code)
	attr_accessor :level
	RubimCode.level = 0

	# Alias for RubimCode::Printer.pout
	def pout(str = "")
		RubimCode::Printer.pout(str)
	end

	# Alias for RubimCode::Printer.perror
	def perror(error_message)
		RubimCode::Printer.perror(error_message)
	end
end

class RubimCode::Printer

	class << self
		# List of varibles that must be defined in header file
		attr_accessor :instance_vars_cc
		RubimCode::Printer.instance_vars_cc = []

		# Destination for 'pout' method
		attr_accessor :pout_destination
		def pout_destination=(dest)
			if dest.nil?
				RubimCode.perror "Wrong parameter for method #{__method__}. Set destination string"
			elsif not (dest.is_a?(String) or dest.in? [:default, :h_file])
				RubimCode.perror "Wrong parameter for method #{__method__}. Only string variable or symbols :default & :h_file values are permit as a parameters"
			end
			@pout_destination = dest
		end
		@pout_destination = :default
	end


	# Add line in generated file and print it in console,
	# or in string object (if it set in pout_destination)
	# Public method
	def self.pout(str = "")
		if str.nil? or str.to_s.nil?
			raise ArgumentError, "str is nil"
		else
			res_str = " "*4*RubimCode.level + str.to_s 
			if RubimCode::Printer.pout_destination.in? [:default, nil]
				puts res_str
				unless defined? TEST_MODE
					File.open("#{ARGV[0]}.c", 'a+') {|file| file.puts(res_str) }
				end
			elsif RubimCode::Printer.pout_destination == :h_file
				unless defined? TEST_MODE
					File.open("#{ARGV[0]}.h", 'a+') {|file| file.puts(res_str) }
				end
			else
				RubimCode::Printer.pout_destination.concat(res_str).concat("\n")
			end
		end
	end

	# Show error message in console end exit
	# Public method
	def self.perror(error_message)
		if error_message.nil? or error_message.to_s.nil? 
			raise ArgumentError, "error message is not string" 
		end

		error_message += "\n"
		code_ptr = caller_locations(2)
		code_ptr.each do |place| 
			place = place.to_s
			place.gsub!(/\/release\//, '/')
			error_message += "\tfrom #{place}\n"
		end
		puts "#ERROR: #{error_message}"
		exit 1
	end

	# Detect type of code to compile
	# Public method (also used in bin/rubim)
	def self.code_type
		if Controllers.all.any?
			"avr-gcc" 
		elsif Controllers.all.empty? and eval("self.private_methods.include? :main")
			"gcc"
		else
			RubimCode.perror "Can not define type of code"
		end
	end

	# Detect name of MCU (used as parameter for avr-gcc compiler)
	# Public method (also used in bin/rubim)
	def self.mcu_type
		code_type == "avr-gcc" ? Controllers.all.first::MCU_NAME : "undefined"
	end

	# Print layout for .c and .h files
	# Private method
	def self.print_layout(position, &layout)
		basename = File.basename(ARGV[0]) # base name of compiled file
		if position == :before_main
			RubimCode::Printer.pout_destination = :h_file
			RubimCode.pout "/**************************************************************"
			RubimCode.pout " * This code was generated by RubimC micro-framework"
			RubimCode.pout " * Include file for \"#{basename}.c\""
			RubimCode.pout " **************************************************************/"

			RubimCode::Printer.pout_destination = :default
			RubimCode.pout "/**************************************************************"
			RubimCode.pout " * This code was generated by RubimC micro-framework"
			RubimCode.pout " * RubimC version: #{RubimCode::VERSION}"
			RubimCode.pout " * RubimC author: Evgeny Danilov"
			RubimCode.pout " * File created at #{Time.now}"
			RubimCode.pout " **************************************************************/"
			RubimCode.pout
			RubimCode.pout "#include <stdbool.h>"
			RubimCode.pout "#include <stdio.h>"
			RubimCode.pout
			yield if block_given? # print includes for current MCU (see mcu libraries)
			RubimCode.pout
			RubimCode.pout "#include \"#{basename}.h\""
			RubimCode.pout
			RubimCode.pout "int main(int argc, char *argv[]) {"
			RubimCode.level += 1
		else
			RubimCode.pout
			RubimCode.pout "return 1;"
			RubimCode.level -= 1
			RubimCode.pout "}"
		end
	end
	self.private_class_method :print_layout

	# Print infinite loop for MCUs
	# Private method
	def self.print_main_loop
		RubimCode.pout
		RubimCode.pout "// === Main Infinite Loop === //"
		RubimCode.pout "while (true) {"
			RubimCode.level += 1
			yield # print body of main loop
			RubimCode.level -= 1
		RubimCode.pout"} // end main loop"
	end
	self.private_class_method :print_main_loop

	# Print varibles defined as inctanse vars
	# Print into header file
	# Private method
	def self.print_instance_vars
		RubimCode::Printer.pout_destination = :h_file
		RubimCode::Printer.instance_vars_cc.each do |var|
			if var.is_a? RubimCode::UserVariable
				RubimCode.pout "#{var.type} #{var.name};"
			end
		end
		RubimCode::Printer.pout_destination = :default
	end
	self.private_class_method :print_instance_vars

	# Main method for generate all C-code
	# Public method
	def self.generate_cc
		exit 0 if defined? TEST_MODE

		if Controllers.all.count > 1
			RubimCode.perror "In current version in one file you can define only one Controller Class"
		end

		if self.code_type == "avr-gcc" # if compile program for MCU
			Controllers.all.each do |mcu_class|
				print_layout(:before_main) do
					mcu_class.layout if mcu_class.respond_to? :layout
				end
				mcu = mcu_class.new # print initialize section
				print_main_loop {mcu.main_loop} # print body of main loop
				print_layout(:after_main) 
				RubimCode::Interrupts.print()
				print_instance_vars()
			end # each Controllers.all

		elsif self.code_type == "gcc" # if compile clear-C program
			if Controllers.all.empty? and eval("self.private_methods.include? :main")
				print_layout(:before_main)
				eval("main(RubimCode::Printer::CC_ARGS.new)") # execute user method :main (CC_ARGS - helper for C agruments argc/argv)
				print_layout(:after_main)
			end
		end
	end

	# Class for arguments when work with clear C-code
	class CC_ARGS 
		def count
			RubimCode::UserVariable.new("argc", "int")
		end

		def [](index)
			RubimCode::UserVariable.new("argv[#{index}]", "char *")
		end
	end # end CC_ARGS class

end # end RubimCode::Printer class

