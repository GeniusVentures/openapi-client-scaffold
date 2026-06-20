# Frontend API Client Build Targets
#
# Provides CMake custom targets for generating and building API clients
# from OpenAPI specs. Compatible with the openapi-client-scaffold submodule.
#
# Targets:
#   frontend_generate_api     - Generate typed API clients from OpenAPI specs
#   frontend_build_typescript - Build TypeScript client (tsc)
#   frontend_build_javascript - Bundle JavaScript client (esbuild)
#   frontend_all              - Run all frontend targets

# --------------------------------------------------------
# Find required tools
find_program(PYTHON3_EXECUTABLE python3)
if(NOT PYTHON3_EXECUTABLE)
    message(WARNING "python3 not found — frontend_generate_api will not be available.")
endif()

# --------------------------------------------------------
# 1. Generate typed API clients from OpenAPI specs
#    Reads ../api-specs/*_openapi.json (parent project)
if(PYTHON3_EXECUTABLE)
    add_custom_target(frontend_generate_api
        COMMAND ${PYTHON3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/scripts/generate_api_clients.py
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Generating typed API clients from OpenAPI specs"
    )
endif()

# --------------------------------------------------------
# 2. Build TypeScript client (when generated)
add_custom_target(frontend_build_typescript
    COMMAND npx tsc --project ${CMAKE_CURRENT_SOURCE_DIR}/generated/typescript/gsm/tsconfig.json
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Building TypeScript API client"
    DEPENDS frontend_generate_api
)

# --------------------------------------------------------
# 3. Bundle JavaScript client (when generated)
add_custom_target(frontend_build_javascript
    COMMAND npx esbuild ${CMAKE_CURRENT_SOURCE_DIR}/generated/javascript/gsm/index.js --bundle --outfile=${CMAKE_CURRENT_SOURCE_DIR}/build/gsm-api-client.js
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Bundling JavaScript API client"
    DEPENDS frontend_generate_api
)

# --------------------------------------------------------
# 4. Aggregate target
add_custom_target(frontend_all
    COMMENT "All frontend targets"
    DEPENDS frontend_generate_api frontend_build_typescript
)
