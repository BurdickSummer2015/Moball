################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
CPP_SRCS += \
../src/boost/fusion/include/adapt_adt_named.cpp 

OBJS += \
./src/boost/fusion/include/adapt_adt_named.o 

CPP_DEPS += \
./src/boost/fusion/include/adapt_adt_named.d 


# Each subdirectory must supply rules for building sources it contributes
src/boost/fusion/include/%.o: ../src/boost/fusion/include/%.cpp
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C++ Compiler'
	g++ -I"/home/labrat/workspace/Moball/include" -O0 -g3 -Wall -c -fmessage-length=0 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


