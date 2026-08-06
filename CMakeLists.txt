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

# --------------------------------------------------------
# 5. Template rendering -- dual-directory (scaffold own + parent M3)
#    Scans both internal templates/ and parent-passed TEMPLATES_DIR for
#    .jinja2 files. Renders scaffold's own templates to generated/scaffold/
#    and parent M3 templates to generated/shared/.
if(DEFINED TEMPLATES_DIR AND PYTHON3_EXECUTABLE)
    set(_scaffold_templates_dir "${CMAKE_CURRENT_SOURCE_DIR}/templates")
    set(_scaffold_template_stamps "")

    # --- Source A: Scaffold's own templates -------------------------------
    # This blanket target renders ONLY standalone templates — those that take
    # design tokens alone and no per-template context. In practice that is the
    # base layout (base/). Parameterized templates (components/**, module/**)
    # require driver-injected vars and are owned by their driver targets:
    #   * module/**            — generate_domain_modules.py (per-domain vars)
    #   * components/*.dart    — generate_all_components (per-component vars)
    #   * components/*.html/.css — generate_all_components_html (per-component vars)
    file(GLOB_RECURSE _own_templates "${_scaffold_templates_dir}/base/*.jinja2")
    foreach(_template ${_own_templates})
        file(RELATIVE_PATH _rel "${_scaffold_templates_dir}" "${_template}")
        string(REGEX REPLACE "\\.jinja2$" "" _out "${_rel}")
        set(_stamp "${CMAKE_CURRENT_BINARY_DIR}/template_gen/scaffold/${_out}.stamp")
        set(_output "${GENERATED_DIR}/scaffold/${_out}")
        add_custom_command(
            OUTPUT ${_stamp}
            COMMAND ${PYTHON3_EXECUTABLE} ${ENGINE_SCRIPT}
                --template ${_rel}
                --tokens ${DESIGN_TOKENS}
                --output ${_output}
                --template-dir ${_scaffold_templates_dir}
                --template-dir ${TEMPLATES_DIR}
            COMMAND ${CMAKE_COMMAND} -E touch ${_stamp}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT "Rendering scaffold template: ${_rel}"
            DEPENDS ${_template} ${DESIGN_TOKENS} ${ENGINE_SCRIPT}
        )
        list(APPEND _scaffold_template_stamps ${_stamp})
    endforeach()

    # --- Source B: Parent M3 templates from TEMPLATES_DIR -----------------
    # This blanket target renders ONLY standalone templates — those that take
    # design tokens alone and no per-template context. In practice that is the
    # base layout (base/). Every other template under TEMPLATES_DIR is
    # parameterized and rendered by a driver that injects context:
    #   * module/**            — generate_domain_modules.py (per-domain vars)
    #   * components/*.dart    — generate_all_components (per-component vars)
    #   * components/*.html/.css — generate_all_components_html (per-component vars)
    # Rendering parameterized templates context-free fails with
    # undefined-variable errors, so Source B is restricted to base/.
    # Skip when TEMPLATES_DIR points back at our own templates/ — that
    # would produce duplicate add_custom_command OUTPUT stamps.
    if(NOT TEMPLATES_DIR STREQUAL _scaffold_templates_dir)
    file(GLOB_RECURSE _parent_templates "${TEMPLATES_DIR}/base/*.jinja2")
    foreach(_template ${_parent_templates})
        file(RELATIVE_PATH _rel "${TEMPLATES_DIR}" "${_template}")
        string(REGEX REPLACE "\\.jinja2$" "" _out "${_rel}")
        set(_stamp "${CMAKE_CURRENT_BINARY_DIR}/template_gen/shared/${_out}.stamp")
        set(_output "${GENERATED_DIR}/shared/${_out}")
        add_custom_command(
            OUTPUT ${_stamp}
            COMMAND ${PYTHON3_EXECUTABLE} ${ENGINE_SCRIPT}
                --template ${_rel}
                --tokens ${DESIGN_TOKENS}
                --output ${_output}
                --template-dir ${TEMPLATES_DIR}
                --template-dir ${_scaffold_templates_dir}
            COMMAND ${CMAKE_COMMAND} -E touch ${_stamp}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT "Rendering M3 template: ${_rel}"
            DEPENDS ${_template} ${DESIGN_TOKENS} ${ENGINE_SCRIPT}
        )
        list(APPEND _scaffold_template_stamps ${_stamp})
    endforeach()
    endif()

    add_custom_target(scaffold_generate_templates
        COMMENT "Rendering scaffold identity templates with M3 design tokens"
        DEPENDS ${_scaffold_template_stamps}
    )

    if(TARGET frontend_all)
        add_dependencies(frontend_all scaffold_generate_templates)
    endif()
endif()
