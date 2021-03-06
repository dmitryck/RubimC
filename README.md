### RubimC
This is a Ruby compiler and framework for microcontrollers. Full name RubimCode in Russian transcription heard as "cut down the code". Current version is working but realizes far not all the features of Ruby. All realized features you can find in folder "examples"

### Description:
RubimC designed to simplify the process of programming microcontrollers, but can also be used as an clear С-code generator. The framework is a syntax-flavored Ruby combines the unique features of the Ruby, adding and expanding the functions required for a specific area. At the input  generator takes the program to Ruby, and the output provides a pure C code, based on the user program and libraries that are connected to a select model of the microcontroller. All you need to use RubimC gem is Ruby interpretator and gcc/avr-gcc compiler.

### Benefits of writing programs in RubymC 
+ increase development speed
+ code readability and elegance inherent in the Ruby language
+ an object-oriented approach
+ the use of an interpreted language does not reduce the performance of the final program because there is **no virtual machine**
+ ability of hardware control IC and delivery of messages
+ ability to get a list of the hardware for a particular version of the device, as well as a list of all methods and help them directly from the generator console, on the basis of libraries.

### Why?
First of all for fan...I want to see at Ruby from other point, not only from famous framework Ruby On Rails. Of course, we have great project [mruby] (http://mruby.org/), that compile Ruby code, realized all common functions of Ruby and standart libraries, and supported by **Matz**. But...mruby generate a big-size code, and, as we know, microcontroller have very small memory. For example, for initialize only one array mruby generate binary file with size 1MB! At the other side RubimC generate code with minimal size, in most cases are not different from the similar size of code written on C. In addition, RubimC generator is clearness. You always can to see on generated C-code and to evaluate its performance and size.

### How it`s work
Code generated in three stage:
1. Preprocessing user program, that replaced some Ruby keywords, operators and identificators
2. Shell Ruby-code and generate C-code (use metaprogramming of Ruby)
3. Compile C-code (with gcc or avr-gcc).

### Install
All you need to use **RubimC** gem is Ruby interpretator and gcc/avr-gcc compiler. 

How to [install Ruby] (https://www.ruby-lang.org/en/documentation/installation/). For Ubuntu I recomended to use first chapter of this [manual] (https://gorails.com/setup/ubuntu).

Then you can install RubimC gem:
```sh
gem install rubimc
```

Compiler *gcc* provided by Linux. For others platforms use this [manual] (https://gcc.gnu.org/install/binaries.html).

To install *avr-gcc* use this [manual] (http://avr-eclipse.sourceforge.net/wiki/index.php/The_AVR_GCC_Toolchain).


### ToDo list (main of them):
1. Code generator:
    + support all C types of variables (unsigned int, short, u_int8, e.t.)
    + check match types (in assign and operations) and try to cast values
    + support array, hash, string, range and constants (as full as possible)
    + support user methods and classes
    + support threads
2. Debug mode (it`s very big task, but I sure it possible using gems like byebug and gdb/avr-gdb servers)
3. Write libraries for microcontrollers (AVR, PIC, STM, e.t.)
4. Fix a lot of possible bugs & features

### What is done now
1. Initialize variables (supported types: bool,int,float,double)
2. Support most of ruby operators: arithmetic, unary, comparison, binary, logical (operator 'not' is sometimes bug, use brackets)
3. Support conditions if/unless (with return values) and it modify version
4. Support loops while/until and it modify version (except redo/retry instruction)
5. Support external libraries
6. Realize example library for AVR AtTiny13 MCU with DigitalIO and ADC support

### Example for AVR microcontroller:
Ruby program (*"FirstController.rb"*):
```ruby
require 'rubimc'

class FirstController < AVR_attiny13
    def initialize
        ANALOG_TO_DIGITAL.init(ref: "vcc", channel: ADC0)

        ANALOG_TO_DIGITAL.interrupt(enabled: true) do |volts|
            output :led, port: :B, pin: 3
            led.off if volts < 30
            led.on if volts >= 220
        end
    end

    def main_loop # infinit loop, it stop only when MCU is reset
    end
end
```

To compile this code run in console:
```sh
rubimc compile FirstController.rb
```
or just
```sh
rubimc compile --all
```

It generate C-code placed in *"release/FirstController.c"* and hex-file for upload in MCU placed in *"release/FirstController.hex*
```c
//=============================
#include <stdbool.h>

#define F_CPU 1000000UL
#include <avr/io.h>
#include <avr/iotn13.h>
#include <avr/interrupt.h>

int main() 
{
    // Init ADC
    ADMUX = (0<<REFS0) | (0<<ADLAR) | MUX0;
    ADCSRA = (1<<ADEN) | (0<<ADATE) | (1<<ADPS0) | (0<<ADIE);

    ADMUX |= 1<<ADIE;
    return 1;
}

// ADC Interrupt
ISR(ADC_vect)
{
    int __rubim__volt = ADCL + ((ADCH&0b11) << 8);
    DDRB |= 1<<(3);
    if ((__rubim__volt<=(0))) {
        PORTB &= 255 ^ (1<<(3));
    }
    if (!((__rubim__volt<(15)))) {
        PORTB |= 1<<(3);
    }
}
```
*note: this is a valid C-code, but in real AVR-controllers it may not work, because avr-libraries are still in development*

### Rake generators
For create new project RubimC gem support command "generate" (of just "g"). For example:
```sh
rubimc generate mcu BrainControll type:attiny13 # create template "BrainControll.rb" for AVR microcontroller 'attiny13'
rubimc g mcu FirstProg # create template "FirstProg.rb" for unknown microcontroller
rubimc g clearC Example # create template "Example.rb" for generate clear C code
```

### Some interesting idea
There is interesting idea for connect few microconrollers (IC) via some firmware interfaces, for example I2C or USB **(at this moment is not realized)**. This example will generate two binary files for each microcontroller. 

```ruby
class BrainController < AVR_atmega16
    def initialize()
        input :@button, port: :A, pin: 6 
    end

    def main_loop() # infinit loop, it stop only when IC is reset
        if want_to_say_hello?
            LeftHandController.move_hand = "up" # transfer data to other controller
        end
    end

    private # define user methods and classes
        def want_to_say_hello?
            @button.press?
        end
end

class LeftHandController < AVR_attiny13
    attr_accessor :move_hand, via: "I2C" # I2C - fireware data-transfer bus

    def move_hand=(message) # execute when command is received
        @led.toggle
        if message=="up" 
            # ...run motor...
        end
    end

    def initialize()
        output :@led, port: :B, pin: 3
    end

    def main_loop() # infinit loop, it stop only when IC is reset
    end
end
```

### Help
If you interested the project and find some bugs, you may to write the tests and we try to fix it. Examples of tests is placed in folder *test*. To run tests use command *"rspec test/test_all.rb"*. Of course if you try to modify core and libraries it will be wonder.

Thank you!
