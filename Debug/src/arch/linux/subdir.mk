################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/arch/linux/vncp_services.c 

OBJS += \
./src/arch/linux/vncp_services.o 

C_DEPS += \
./src/arch/linux/vncp_services.d 


# Each subdirectory must supply rules for building sources it contributes
src/arch/linux/%.o: ../src/arch/linux/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C Compiler'
	arm-cortexa9-linux-gnueabi-gcc -I"/home/labrat/workspace/Moball/include" -O0 -g3 -Wall -c -fmessage-length=0 -pthread -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


