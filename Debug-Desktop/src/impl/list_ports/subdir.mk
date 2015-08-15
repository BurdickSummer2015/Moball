################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
CC_SRCS += \
../src/impl/list_ports/list_ports_linux.cc \
../src/impl/list_ports/list_ports_osx.cc \
../src/impl/list_ports/list_ports_win.cc 

OBJS += \
./src/impl/list_ports/list_ports_linux.o \
./src/impl/list_ports/list_ports_osx.o \
./src/impl/list_ports/list_ports_win.o 

CC_DEPS += \
./src/impl/list_ports/list_ports_linux.d \
./src/impl/list_ports/list_ports_osx.d \
./src/impl/list_ports/list_ports_win.d 


# Each subdirectory must supply rules for building sources it contributes
src/impl/list_ports/%.o: ../src/impl/list_ports/%.cc
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C++ Compiler'
	g++ -I"/home/labrat/workspace/Moball/include" -O0 -g3 -Wall -c -fmessage-length=0 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


