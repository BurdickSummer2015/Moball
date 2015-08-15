################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
CPP_SRCS += \
../src/boost/test/utils/runtime/file/config_file.cpp \
../src/boost/test/utils/runtime/file/config_file_iterator.cpp 

OBJS += \
./src/boost/test/utils/runtime/file/config_file.o \
./src/boost/test/utils/runtime/file/config_file_iterator.o 

CPP_DEPS += \
./src/boost/test/utils/runtime/file/config_file.d \
./src/boost/test/utils/runtime/file/config_file_iterator.d 


# Each subdirectory must supply rules for building sources it contributes
src/boost/test/utils/runtime/file/%.o: ../src/boost/test/utils/runtime/file/%.cpp
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C++ Compiler'
	g++ -I"/home/labrat/workspace/Moball/include" -O0 -g3 -Wall -c -fmessage-length=0 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


