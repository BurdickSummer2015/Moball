################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/arch/win32/vncp_services.c 

OBJS += \
./src/arch/win32/vncp_services.o 

C_DEPS += \
./src/arch/win32/vncp_services.d 


# Each subdirectory must supply rules for building sources it contributes
src/arch/win32/%.o: ../src/arch/win32/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C Compiler'
	arm-cortexa9-linux-gnueabi-gcc -I/home/labrat/workspace/Moball/include -I/home/labrat/workspace/Moball/src/arch/linux -O0 -g3 -Wall -c -fmessage-length=0 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


