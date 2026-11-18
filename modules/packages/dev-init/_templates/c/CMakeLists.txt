cmake_minimum_required(VERSION 3.25)
project(@PACKAGE@ LANGUAGES C)

set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_executable(@PACKAGE@ src/main.c)
target_compile_options(@PACKAGE@ PRIVATE -Wall -Wextra -Wpedantic)
