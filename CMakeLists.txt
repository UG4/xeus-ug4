cmake_minimum_required(VERSION 3.4.3)
project(ug4_jupyter_kernel)

set(EXECUTABLE_NAME ug4_jupyter_kernel)

# Configuration
# =============

include(GNUInstallDirs)

# We generate the kernel.json file, given the installation prefix and the executable name
configure_file (
    "${CMAKE_CURRENT_SOURCE_DIR}/share/jupyter/kernels/ug4_kernel/kernel.json.in"
    "${CMAKE_CURRENT_SOURCE_DIR}/share/jupyter/kernels/ug4_kernel/kernel.json"
)

# Dependencies
# ============

# Be sure to use recent versions
# set(xeus_REQUIRED_VERSION 0.25)
# set(cppzmq_REQUIRED_VERSION 4.3.0)

find_package(xeus ${xeus_REQUIRED_VERSION} REQUIRED)
# find_package(cppzmq ${cppzmq_REQUIRED_VERSION} REQUIRED)

#set(xeus-zmq_REQUIRED_VERSION 1.0.0)
#find_package(xeus-zmq ${xeus-zmq_REQUIRED_VERSION} REQUIRED)

#set(xeus-lite_REQUIRED_VERSION 1.0.1)
#find_package(xeus-lite ${xeus-lite_REQUIRED_VERSION} REQUIRED)

# Flags
# =====

include(CheckCXXCompilerFlag)

if (CMAKE_CXX_COMPILER_ID MATCHES "Clang" OR CMAKE_CXX_COMPILER_ID MATCHES "GNU" OR CMAKE_CXX_COMPILER_ID MATCHES "Intel")
    CHECK_CXX_COMPILER_FLAG("-std=c++14" HAS_CPP14_FLAG)

    if (HAS_CPP14_FLAG)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")
    else()
        message(FATAL_ERROR "Unsupported compiler -- xeus requires C++14 support!")
    endif()
endif()


# Identify UG4 installation
message(STATUS "UG4_ROOT: $ENV{UG4_ROOT}")
set (MY_UG4_ROOT $ENV{UG4_ROOT})

if(NOT DEFINED ENV{UG4_ROOT})
	set(MY_UG4_ROOT "${CMAKE_CURRENT_SOURCE_DIR}../../../")
	message(WARNING "Environment variable 'UG4_ROOT' has not been used. " )
else (NOT DEFINED ENV{UG4_ROOT})
	message(WARNING "Environment variable 'UG4_ROOT' has been used. " )
endif(NOT DEFINED ENV{UG4_ROOT})

# Target and link
# ===============

# Kernel source files
set(MY_KERNEL_SRC
    src/custom_interpreter.cpp
    src/custom_interpreter.hpp
    ${MY_UG4_ROOT}/ugcore/ugbase/ug_shell/ugshell_main.cpp
    ${MY_UG4_ROOT}/ugcore/ugbase/ug_shell/shell.cpp
)



# Kernel executable
add_executable(${EXECUTABLE_NAME} src/main.cpp ${MY_KERNEL_SRC} )


find_library(ug4_LIBRARY NAMES ug4 HINTS ${MY_UG4_ROOT}/lib REQUIRED)	
message(STATUS "ug4-xeus: Using ${ug4_LIBRARY}")



# Find xeus libraries
# find_package(xeus REQUIRED)
set(xeus-zmq_REQUIRED_VERSION 1.0.2)
find_package(xeus-zmq ${xeus-zmq_REQUIRED_VERSION} REQUIRED)
message(STATUS "ug4-xeus: Using ${xeus-zmq_LIBRARY}")


find_package(xtl REQUIRED)
message(STATUS "ug4-xeus: Using ${xtl_INCLUDE_DIRS} ${xtl_LIBRARY}")


find_library(zmq_LIBRARY NAMES zmq REQUIRED PATHS "${xtl_INCLUDE_DIRS}/../lib")
message(STATUS "ug4-xeus: Using ${zmq_INCLUDE_DIRS} ${zmq_LIBRARY}")

if(NOT DEFINED ${xeus_LIBRARY})
		find_library(xeus_LIBRARY NAMES xeus REQUIRED PATHS "${xtl_INCLUDE_DIRS}/../lib")
		message(STATUS "ug4-xeus: Using ${xeus_LIBRARY}")
endif() 


# Expand include path
target_include_directories(${EXECUTABLE_NAME} 
	PUBLIC 
	${MY_UG4_ROOT}/ugcore/ugbase 
	${MY_UG4_ROOT}/externals/BoostForUG4
	${xtl_INCLUDE_DIRS}
	)


target_link_libraries(${EXECUTABLE_NAME} 
	PRIVATE ${ug4_LIBRARY} 
	${xeus-zmq_LIBRARY} xeus ${zmq_LIBRARY}  )

if (APPLE)
    set_target_properties(${EXECUTABLE_NAME} PROPERTIES
        MACOSX_RPATH ON
    )
else()
    set_target_properties(${EXECUTABLE_NAME} PROPERTIES
        BUILD_WITH_INSTALL_RPATH 1
        SKIP_BUILD_RPATH FALSE
    )
endif()

set_target_properties(${EXECUTABLE_NAME} PROPERTIES
    INSTALL_RPATH_USE_LINK_PATH TRUE
)



# Installation
# ============

# Install kernel
install(TARGETS ${EXECUTABLE_NAME}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

# Configuration and data directories for jupyter and my_kernel
set(XJUPYTER_DATA_DIR "share/jupyter" CACHE STRING "Jupyter data directory")

# Install Jupyter kernelspecs
set(UG4_KERNELSPEC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/share/jupyter/kernels)
install(DIRECTORY ${UG4_KERNELSPEC_DIR}
        DESTINATION ${XJUPYTER_DATA_DIR}
        PATTERN "*.in" EXCLUDE)
