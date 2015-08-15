################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
CC_SRCS += \
../src/impl/unix.cc \
../src/impl/win.cc 

OBJS += \
./src/impl/unix.o \
./src/impl/win.o 

CC_DEPS += \
./src/impl/unix.d \
./src/impl/win.d 


# Each subdirectory must supply rules for building sources it contributes
src/impl/%.o: ../src/impl/%.cc
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C++ Compiler'
	g++ -I"/home/labrat/workspace/Moball/include" -O0 -g3 -Wall -c -fmessage-length=0 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


