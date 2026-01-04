cmake_minimum_required(VERSION 3.10)

# Run binary builds:
# cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
# cmake --build build -j

#project(SuperPalmTree C CXX)

#set(CMAKE_C_STANDARD 23)
#set(CMAKE_CXX_STANDARD 26)

#add_executable(yee test/yee.c)
#add_executable(yawp test/yawp.cpp)
#add_executable(spinner c/spinner.c)
#add_executable(kmod freebsd/kmod.c)

#cmake_minimum_required(VERSION 3.10)

cmake_minimum_required(VERSION 3.20)

# ---- Project ----
project(SuperPalmTree LANGUAGES C CXX)

# ---- C/C++ standards (portable) ----
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# ---- Unified output layout: ./out ----
set(OUT_ROOT "${CMAKE_SOURCE_DIR}/out")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${OUT_ROOT}/bin")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${OUT_ROOT}/lib")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${OUT_ROOT}/lib")

if(CMAKE_CONFIGURATION_TYPES) # MSVC/Xcode
  foreach(cfg IN LISTS CMAKE_CONFIGURATION_TYPES)
    string(TOUPPER "${cfg}" CFGU)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${CFGU} "${OUT_ROOT}/${cfg}/bin")
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${CFGU} "${OUT_ROOT}/${cfg}/lib")
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${CFGU} "${OUT_ROOT}/${cfg}/lib")
  endforeach()
endif()

# ---- ABI library (C ABI, C++ impl) ----
set(ABI_PUBLIC_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/cpp/include")
set(ABI_SRC "${CMAKE_SOURCE_DIR}/cpp/src/abi.cpp")

add_library(abi SHARED "${ABI_SRC}")
target_include_directories(abi PUBLIC "${ABI_PUBLIC_INCLUDE_DIR}")
set_target_properties(abi PROPERTIES
  OUTPUT_NAME "abi"
  POSITION_INDEPENDENT_CODE ON
)

# Runtime search paths (so tests find the lib when run from build tree)
if(UNIX AND NOT APPLE) # Linux/FreeBSD
  set_target_properties(abi PROPERTIES
    BUILD_RPATH "\$ORIGIN/../lib"
    INSTALL_RPATH "\$ORIGIN/../lib"
  )
elseif(APPLE)
  set_target_properties(abi PROPERTIES
    BUILD_RPATH "@loader_path/../lib"
    INSTALL_RPATH "@loader_path/../lib"
  )
endif()

# Optional local install under ./out/install
include(GNUInstallDirs)
set(CMAKE_INSTALL_PREFIX "${OUT_ROOT}/install")
install(TARGETS abi
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

# Binaries
add_executable(yee     test/yee.c)
add_executable(yawp    test/yawp.cpp)
add_executable(spinner c/spinner.c)

# Headers from cpp/include if needed later, uncomment:
# target_include_directories(yee PRIVATE "${ABI_PUBLIC_INCLUDE_DIR}")
# target_include_directories(yawp PRIVATE "${ABI_PUBLIC_INCLUDE_DIR}")
# target_include_directories(spinner PRIVATE "${ABI_PUBLIC_INCLUDE_DIR}")

# ---- Helper targets (fixed arg spacing) ----
find_program(PYTHON_EXECUTABLE NAMES python3 python)
if(PYTHON_EXECUTABLE)
  # Build a platform-appropriate loader env var entry
  if(UNIX AND NOT APPLE)
    set(LOADER_ENV "LD_LIBRARY_PATH=$<TARGET_FILE_DIR:abi>:$ENV{LD_LIBRARY_PATH}")
  elseif(APPLE)
    set(LOADER_ENV "DYLD_LIBRARY_PATH=$<TARGET_FILE_DIR:abi>:$ENV{DYLD_LIBRARY_PATH}")
  elseif(WIN32)
    set(LOADER_ENV "PATH=$<TARGET_FILE_DIR:abi>;$ENV{PATH}")
  endif()

  add_custom_target(smoke_py
    COMMAND ${CMAKE_COMMAND} -E env
            "${LOADER_ENV}"
            ${PYTHON_EXECUTABLE} - <<'PY'
import sys, pathlib
sys.path.insert(0, str(pathlib.Path("test/bindings").resolve()))
import pyabi as a
print("add_i32:", a.add_i32(40,2))
print("dot2f:", a.dot2f(1,2,3,4))
p = a.make_point(5,-7)
print("manhattan:", a.manhattan(p))
print(a.hello("SuperPalmTree"))
PY
    DEPENDS abi
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    COMMENT "Running Python ABI smoke test"
  )
endif()

find_program(MOJO_EXECUTABLE NAMES mojo)
if(MOJO_EXECUTABLE)
  if(UNIX AND NOT APPLE)
    set(LOADER_ENV "LD_LIBRARY_PATH=$<TARGET_FILE_DIR:abi>:$ENV{LD_LIBRARY_PATH}")
  elseif(APPLE)
    set(LOADER_ENV "DYLD_LIBRARY_PATH=$<TARGET_FILE_DIR:abi>:$ENV{DYLD_LIBRARY_PATH}")
  elseif(WIN32)
    set(LOADER_ENV "PATH=$<TARGET_FILE_DIR:abi>;$ENV{PATH}")
  endif()

  add_custom_target(run_mojo
    COMMAND ${CMAKE_COMMAND} -E env
            "${LOADER_ENV}"
            ${MOJO_EXECUTABLE} run "${CMAKE_SOURCE_DIR}/mojo/abi_test.mojo"
    DEPENDS abi
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    COMMENT "Running Mojo ABI test"
  )
endif()
