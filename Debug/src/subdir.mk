################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
CPP_SRCS += \
../src/Moball.cpp \
../src/WaspmoteController.cpp \
../src/simple_serial.cpp 

C_SRCS += \
../src/vn100.c \
../src/vn200.c \
../src/vndevice.c 

OBJS += \
./src/Moball.o \
./src/WaspmoteController.o \
./src/simple_serial.o \
./src/vn100.o \
./src/vn200.o \
./src/vndevice.o 

C_DEPS += \
./src/vn100.d \
./src/vn200.d \
./src/vndevice.d 

CPP_DEPS += \
./src/Moball.d \
./src/WaspmoteController.d \
./src/simple_serial.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.cpp
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C++ Compiler'
	arm-cortexa9-linux-gnueabi-g++ -I"/home/labrat/workspace/Moball/include" -O0 -g3 -Wall -c -fmessage-length=0 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C Compiler'
	arm-cortexa9-linux-gnueabi-gcc -I"/home/labrat/workspace/Moball/include" -O0 -g3 -Wall -c -fmessage-length=0 -pthread -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


