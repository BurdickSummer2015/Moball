################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
CPP_SRCS += \
../src/boost/asio/impl/src.cpp 

OBJS += \
./src/boost/asio/impl/src.o 

CPP_DEPS += \
./src/boost/asio/impl/src.d 


# Each subdirectory must supply rules for building sources it contributes
src/boost/asio/impl/%.o: ../src/boost/asio/impl/%.cpp
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C++ Compiler'
	g++ -I"/home/labrat/workspace/Moball/include" -O0 -g3 -Wall -c -fmessage-length=0 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


