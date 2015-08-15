################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
CPP_SRCS += \
../src/boost/test/utils/runtime/cla/argv_traverser.cpp \
../src/boost/test/utils/runtime/cla/char_parameter.cpp \
../src/boost/test/utils/runtime/cla/dual_name_parameter.cpp \
../src/boost/test/utils/runtime/cla/id_policy.cpp \
../src/boost/test/utils/runtime/cla/named_parameter.cpp \
../src/boost/test/utils/runtime/cla/parser.cpp \
../src/boost/test/utils/runtime/cla/validation.cpp 

OBJS += \
./src/boost/test/utils/runtime/cla/argv_traverser.o \
./src/boost/test/utils/runtime/cla/char_parameter.o \
./src/boost/test/utils/runtime/cla/dual_name_parameter.o \
./src/boost/test/utils/runtime/cla/id_policy.o \
./src/boost/test/utils/runtime/cla/named_parameter.o \
./src/boost/test/utils/runtime/cla/parser.o \
./src/boost/test/utils/runtime/cla/validation.o 

CPP_DEPS += \
./src/boost/test/utils/runtime/cla/argv_traverser.d \
./src/boost/test/utils/runtime/cla/char_parameter.d \
./src/boost/test/utils/runtime/cla/dual_name_parameter.d \
./src/boost/test/utils/runtime/cla/id_policy.d \
./src/boost/test/utils/runtime/cla/named_parameter.d \
./src/boost/test/utils/runtime/cla/parser.d \
./src/boost/test/utils/runtime/cla/validation.d 


# Each subdirectory must supply rules for building sources it contributes
src/boost/test/utils/runtime/cla/%.o: ../src/boost/test/utils/runtime/cla/%.cpp
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C++ Compiler'
	g++ -I"/home/labrat/workspace/Moball/include" -O0 -g3 -Wall -c -fmessage-length=0 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


