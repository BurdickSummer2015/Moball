################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/Moball.c \
../src/vn100.c \
../src/vn200.c \
../src/vndevice.c 

OBJS += \
./src/Moball.o \
./src/vn100.o \
./src/vn200.o \
./src/vndevice.o 

C_DEPS += \
./src/Moball.d \
./src/vn100.d \
./src/vn200.d \
./src/vndevice.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C Compiler'
	arm-cortexa9-linux-gnueabi-gcc -I"/home/me/workspace/Moball/include" -O0 -g3 -Wall -c -fmessage-length=0 -pthread -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


