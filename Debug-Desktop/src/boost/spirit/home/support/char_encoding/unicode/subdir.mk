################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
CPP_SRCS += \
../src/boost/spirit/home/support/char_encoding/unicode/create_tables.cpp 

OBJS += \
./src/boost/spirit/home/support/char_encoding/unicode/create_tables.o 

CPP_DEPS += \
./src/boost/spirit/home/support/char_encoding/unicode/create_tables.d 


# Each subdirectory must supply rules for building sources it contributes
src/boost/spirit/home/support/char_encoding/unicode/%.o: ../src/boost/spirit/home/support/char_encoding/unicode/%.cpp
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C++ Compiler'
	g++ -I"/home/labrat/workspace/Moball/include" -O0 -g3 -Wall -c -fmessage-length=0 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


