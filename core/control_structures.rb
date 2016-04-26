class RubimCode
class << self

	@@rubim_defined_values = []

	def rubim_cond(cond, type="if", &block)
		# ToDo: auto-define type of ret_value
		# use::  __rubim__rval__int, __rubim__rval__float, e.t.

		if @@rubim_defined_values.include? @level
			pout "__rubim__rval#{@level} = 0;"
		else
			pout "int __rubim__rval#{@level} = 0;"
		end
		@@rubim_defined_values << @level

		if type=="if"
			pout "if (#{cond}) {"
		elsif type=="unless"
			pout "if (!(#{cond})) {"
		end
		@level += 1 
		ret_val = yield
		pout "__rubim__rval#{@level-1} = #{ret_val};" if ret_val!="__rubim__noreturn"
		pout "}"
		@level -= 1
		return "__rubim__rval#{@level}"
	end

	def rubim_cycle(type="while", cond="true", &block)
		pout "#{type} (#{cond}) {"
		@level+=1
			yield
			pout "}"
		@level-=1
	end

	def rubim_if(cond, &block); rubim_cond(cond, "if", &block); end
	def rubim_unless(cond, &block); rubim_cond(cond, "unless", &block); end
	def rubim_while(cond, &block); rubim_cycle("while", cond, &block); end
	def rubim_until(cond); rubim_cycle("until", cond, &block); end
	def rubim_loop(&block); rubim_cycle("while", "true", &block); end

	def rubim_whilemod(cond); pout "} while (#{cond});"; @level-=1; end
	def rubim_untilmod(cond); pout "} until (#{cond});"; @level-=1; end

	def rubim_ifmod(cond); pout "if (#{cond}) {"; @level+=1; true; end
	def rubim_unlessmod(cond); pout "if (!(#{cond})) {"; @level+=1; true; end
	def rubim_begin(); pout "{"; @level+=1; true; end
	def rubim_end(); pout "}"; @level-=1; "__rubim__noreturn"; end
	def rubim_tmpif(tmp); end

	def rubim_else(); @level-=1; pout "} else {"; @level+=1; end
	def rubim_elsif(cond); @level-=1; pout "} else if (#{cond}) {"; @level+=1; end
	# ToDo: set return_val, like in rubim_if (need to change preprocessor)

end # class << self
end # RubimCode class