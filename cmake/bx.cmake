# bgfx.cmake - bgfx building in cmake
# Written in 2017 by Joshua Brookover <joshua.al.brookover@gmail.com>

# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty.

# You should have received a copy of the CC0 Public Domain Dedication along with
# this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

# Ensure the directory exists
if( NOT IS_DIRECTORY ${BX_DIR} )
	message( SEND_ERROR "Could not load bx, directory does not exist. ${BX_DIR}" )
	return()
endif()

# Grab the bx source files
file( GLOB BX_SOURCES ${BX_DIR}/src/*.cpp )

if(BX_AMALGAMATED)
	set(BX_NOBUILD ${BX_SOURCES})
	list(REMOVE_ITEM BX_NOBUILD ${BX_DIR}/src/amalgamated.cpp)
	foreach(BX_SRC ${BX_NOBUILD})
		set_source_files_properties( ${BX_SRC} PROPERTIES HEADER_FILE_ONLY ON )
	endforeach()
else()
	set_source_files_properties( ${BX_DIR}/src/amalgamated.cpp PROPERTIES HEADER_FILE_ONLY ON )
endif()

# Create the bx target
if(BGFX_LIBRARY_TYPE STREQUAL STATIC)
    add_library( bx STATIC ${BX_SOURCES} )
else()
    add_library( bx SHARED ${BX_SOURCES} )
endif()

target_compile_features( bx PUBLIC cxx_std_14 )
# (note: see bx\scripts\toolchain.lua for equivalent compiler flag)
target_compile_options( bx PUBLIC $<$<CXX_COMPILER_ID:MSVC>:/Zc:__cplusplus> )

# Link against psapi on Windows
if( WIN32 )
	target_link_libraries( bx PUBLIC psapi )
endif()

include(GNUInstallDirs)

# Add include directory of bx
target_include_directories( bx
	PUBLIC
		$<BUILD_INTERFACE:${BX_DIR}/include>
		$<BUILD_INTERFACE:${BX_DIR}/3rdparty>
		$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}> )

# Build system specific configurations
if( MINGW )
	target_include_directories( bx
		PUBLIC
		    $<BUILD_INTERFACE:${BX_DIR}/include/compat/mingw>
		    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/compat/mingw> )
elseif( WIN32 )
	target_include_directories( bx
		PUBLIC
			$<BUILD_INTERFACE:${BX_DIR}/include/compat/msvc>
			$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/compat/msvc> )
elseif( APPLE )
	target_include_directories( bx
		PUBLIC
		    $<BUILD_INTERFACE:${BX_DIR}/include/compat/osx>
		    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/compat/osx> )
endif()

# All configurations
target_compile_definitions( bx PUBLIC "__STDC_LIMIT_MACROS" )
target_compile_definitions( bx PUBLIC "__STDC_FORMAT_MACROS" )
target_compile_definitions( bx PUBLIC "__STDC_CONSTANT_MACROS" )

target_compile_definitions(bx PUBLIC "BX_CONFIG_DEBUG=$<IF:$<CONFIG:Debug>,1,$<BOOL:${BX_CONFIG_DEBUG}>>")

# Additional dependencies on Unix
if (ANDROID)
    # For __android_log_write
    find_library( LOG_LIBRARY log )
    mark_as_advanced( LOG_LIBRARY )
	target_link_libraries( bx PUBLIC ${LOG_LIBRARY} )
elseif( APPLE )
	find_library( FOUNDATION_LIBRARY Foundation)
	mark_as_advanced( FOUNDATION_LIBRARY )
	target_link_libraries( bx PUBLIC ${FOUNDATION_LIBRARY} )
elseif( UNIX )
	# Threads
	find_package( Threads )
	target_link_libraries( bx ${CMAKE_THREAD_LIBS_INIT} dl )

	# Real time (for clock_gettime)
	target_link_libraries( bx rt )
endif()

# Put in a "bgfx" folder in Visual Studio
set_target_properties( bx PROPERTIES FOLDER "bgfx" )
