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

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    project(frontend_scaffold_codegen NONE)
endif()

# --------------------------------------------------------
# Find required tools
find_program(PYTHON3_EXECUTABLE python3)
if(NOT PYTHON3_EXECUTABLE)
    message(WARNING "python3 not found — frontend_generate_api will not be available.")
endif()

# --------------------------------------------------------
# Python build tooling lives in tools/ as the `scaffold_codegen` package
# (see pyproject.toml). PYTHONPATH is set per-invocation rather than relying on
# an installed package, so CMake builds need no pip install.
set(_scaffold_pythonpath "${CMAKE_CURRENT_SOURCE_DIR}/tools")
set(_scaffold_python_env ${CMAKE_COMMAND} -E env "PYTHONPATH=${_scaffold_pythonpath}")

# --------------------------------------------------------
# 1. Generate typed API clients from OpenAPI specs
#    Reads ../api-specs/*_openapi.json (parent project)
if(PYTHON3_EXECUTABLE)
    add_custom_target(frontend_generate_api
        COMMAND ${_scaffold_python_env} ${PYTHON3_EXECUTABLE} -m scaffold_codegen.api_clients
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
# 5. Template rendering -- dual-directory (scaffold own + consumer templates)
#    Source A (scaffold's own base/ templates) always runs when Python is
#    available. Source B (consumer-provided templates via TEMPLATES_DIR) is
#    opt-in: set TEMPLATES_DIR before add_subdirectory to activate.
#    All template-render configuration defaults to scaffold-local files and
#    can be overridden via CACHE or -D before add_subdirectory.
# --------------------------------------------------------
set(ENGINE_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/tools/scaffold_codegen/engine.py" CACHE STRING
    "Path to shared Jinja2 template engine")
set(DESIGN_TOKENS "${CMAKE_CURRENT_SOURCE_DIR}/design_tokens.json" CACHE STRING
    "Path to M3 design tokens JSON single source of truth")
set(GENERATED_DIR "${CMAKE_BINARY_DIR}/generated" CACHE STRING
    "Output directory for generated template output")
set(FRONTEND_TARGET "flutter" CACHE STRING
    "Frontend codegen target (flutter, html)")

if(PYTHON3_EXECUTABLE)
    set(_scaffold_templates_dir "${CMAKE_CURRENT_SOURCE_DIR}/templates")
    set(_scaffold_template_stamps "")

    # Optional consumer templates dir — only pass the flag when set, otherwise
    # a bare `--template-dir` (no value) breaks engine.py argument parsing.
    # List form so the flag expands to TWO argv tokens (a single space-embedded
    # string reaches argparse as one token and fails). Skip when TEMPLATES_DIR
    # points back at our own templates/ — that duplicates the Source A
    # `--template-dir ${_scaffold_templates_dir}` (same guard as Source B).
    if(TEMPLATES_DIR AND NOT TEMPLATES_DIR STREQUAL _scaffold_templates_dir)
        set(_parent_template_dir_flag --template-dir "${TEMPLATES_DIR}")
    else()
        set(_parent_template_dir_flag "")
    endif()

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
            COMMAND ${CMAKE_COMMAND} -E make_directory
                "${CMAKE_CURRENT_BINARY_DIR}/template_gen/scaffold/base"
            COMMAND ${PYTHON3_EXECUTABLE} ${ENGINE_SCRIPT}
                --template ${_rel}
                --tokens ${DESIGN_TOKENS}
                --output ${_output}
                --template-dir ${_scaffold_templates_dir}
                ${_parent_template_dir_flag}
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
            COMMAND ${CMAKE_COMMAND} -E make_directory
                "${CMAKE_CURRENT_BINARY_DIR}/template_gen/shared/base"
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

# --------------------------------------------------------
# 6. Component template rendering -- per-component stamp targets.
#    Each M3 component renders THREE files via parallel stamp blocks in the
#    loop below: the Flutter widget plus its HydratedMixin Cubit and plain
#    Dart state class (06-03, BLOC-01/BLOC-02).  The state component's state
#    template is the Q2 special case: state_view_state.dart (NOT
#    state_state.dart).  The FRONTEND_TARGET option gates Flutter output
#    (Phase 4 will add "html" alternative).
#    Per-component named targets enable selective rebuild:
#      cmake --build . --target generate_component_data_table
#    Aggregate target builds all 6 (18 files):
#      cmake --build . --target generate_all_components
# --------------------------------------------------------
set(_comp_templates_dir "${_scaffold_templates_dir}/components")
set(_widgets_output_dir "${GENERATED_DIR}/widgets")

if(PYTHON3_EXECUTABLE AND FRONTEND_TARGET STREQUAL "flutter")
    set(_component_names
        data_table
        form_dialog
        navigation
        search_bar
        card
        state
    )
    set(_component_stamps "")
    set(_component_outputs "")

    foreach(_comp ${_component_names})
        set(_template "${_comp_templates_dir}/${_comp}.dart.jinja2")
        set(_stamp "${CMAKE_CURRENT_BINARY_DIR}/template_gen/component_${_comp}.stamp")
        set(_vars "${_comp_templates_dir}/${_comp}_vars.json")

        # Read file_stem from vars.json — card/search_bar/state use it to
        # derive generated import filenames; fall back to the component name.
        file(READ ${_vars} _vars_json)
        if(_vars_json MATCHES "\"file_stem\"[ \t]*:[ \t]*\"([^\"]+)\"")
            set(_file_stem "${CMAKE_MATCH_1}")
        else()
            set(_file_stem "${_comp}")
        endif()
        set(_output "${_widgets_output_dir}/${_file_stem}.dart")

        add_custom_command(
            OUTPUT ${_stamp} ${_output}
            COMMAND ${CMAKE_COMMAND} -E make_directory
                "${CMAKE_CURRENT_BINARY_DIR}/template_gen"
            COMMAND ${PYTHON3_EXECUTABLE} ${ENGINE_SCRIPT}
                --template "components/${_comp}.dart.jinja2"
                --tokens ${DESIGN_TOKENS}
                --output ${_output}
                --template-dir ${_scaffold_templates_dir}
                --vars ${_vars}
            COMMAND ${CMAKE_COMMAND} -E touch ${_stamp}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT "Rendering component template: ${_comp}"
            DEPENDS ${_template} ${DESIGN_TOKENS} ${ENGINE_SCRIPT} ${_vars}
        )
        list(APPEND _component_stamps ${_stamp})

        # --- Cubit stamp (06-03) -------------------------------------------
        # Same engine invocation shape as the widget; only the template,
        # output, and kind-specific DEPENDS differ.  Shares ${_vars},
        # ${DESIGN_TOKENS}, and ${ENGINE_SCRIPT} so touching only the cubit
        # template re-renders only this stamp (v1.0 incremental invariant).
        set(_template_cubit "${_comp_templates_dir}/${_comp}_cubit.dart.jinja2")
        set(_stamp_cubit "${CMAKE_CURRENT_BINARY_DIR}/template_gen/component_${_comp}_cubit.stamp")
        set(_output_cubit "${_widgets_output_dir}/${_file_stem}_cubit.dart")

        add_custom_command(
            OUTPUT ${_stamp_cubit} ${_output_cubit}
            COMMAND ${CMAKE_COMMAND} -E make_directory
                "${CMAKE_CURRENT_BINARY_DIR}/template_gen"
            COMMAND ${PYTHON3_EXECUTABLE} ${ENGINE_SCRIPT}
                --template "components/${_comp}_cubit.dart.jinja2"
                --tokens ${DESIGN_TOKENS}
                --output ${_output_cubit}
                --template-dir ${_scaffold_templates_dir}
                --vars ${_vars}
            COMMAND ${CMAKE_COMMAND} -E touch ${_stamp_cubit}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT "Rendering component cubit template: ${_comp}_cubit"
            DEPENDS ${_template_cubit} ${DESIGN_TOKENS} ${ENGINE_SCRIPT} ${_vars}
        )
        list(APPEND _component_stamps ${_stamp_cubit})

        # --- State stamp (06-03) -------------------------------------------
        # Q2 special case: the state component's state template is named
        # state_view_state.dart.jinja2 (renders state_view_state.dart) to
        # avoid the awkward state_state.dart filename.
        if(_comp STREQUAL "state")
            set(_state_basename "state_view_state")
        else()
            set(_state_basename "${_comp}_state")
        endif()
        set(_template_state "${_comp_templates_dir}/${_state_basename}.dart.jinja2")
        set(_stamp_state "${CMAKE_CURRENT_BINARY_DIR}/template_gen/component_${_comp}_state.stamp")
        set(_output_state "${_widgets_output_dir}/${_file_stem}_state.dart")

        add_custom_command(
            OUTPUT ${_stamp_state} ${_output_state}
            COMMAND ${CMAKE_COMMAND} -E make_directory
                "${CMAKE_CURRENT_BINARY_DIR}/template_gen"
            COMMAND ${PYTHON3_EXECUTABLE} ${ENGINE_SCRIPT}
                --template "components/${_state_basename}.dart.jinja2"
                --tokens ${DESIGN_TOKENS}
                --output ${_output_state}
                --template-dir ${_scaffold_templates_dir}
                --vars ${_vars}
            COMMAND ${CMAKE_COMMAND} -E touch ${_stamp_state}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT "Rendering component state template: ${_state_basename}"
            DEPENDS ${_template_state} ${DESIGN_TOKENS} ${ENGINE_SCRIPT} ${_vars}
        )
        list(APPEND _component_stamps ${_stamp_state})

        add_custom_target(generate_component_${_comp}
            COMMENT "Generate Flutter widget + cubit + state: ${_comp}"
            DEPENDS ${_stamp} ${_stamp_cubit} ${_stamp_state}
                    ${_output} ${_output_cubit} ${_output_state}
        )
        list(APPEND _component_outputs ${_output} ${_output_cubit} ${_output_state})
    endforeach()

    add_custom_target(generate_all_components
        COMMENT "Generate all 6 M3 component Flutter widget/cubit/state triples (18 files)"
        DEPENDS ${_component_stamps} ${_component_outputs}
    )
endif()

# --------------------------------------------------------
# 7. HTML target -- per-component stamp targets for HTML + CSS output.
#    Each M3 component .jinja2 template renders to a semantic HTML5
#    fragment and companion CSS file when FRONTEND_TARGET=html.
#    Per-component named targets enable selective rebuild:
#      cmake --build . --target generate_component_data_table_html
#      cmake --build . --target generate_component_state_html
#    Aggregate target builds all 6 + m3_tokens.css:
#      cmake --build . --target generate_all_components_html
# --------------------------------------------------------
if(PYTHON3_EXECUTABLE AND FRONTEND_TARGET STREQUAL "html")
    set(_styles_output_dir "${GENERATED_DIR}/styles")
    set(_html_output_dir "${GENERATED_DIR}/html")

    # -- 7a. M3 design tokens CSS generation (shared stylesheet, runs once)
    set(_tokens_stamp "${CMAKE_CURRENT_BINARY_DIR}/template_gen/m3_tokens_css.stamp")
    set(_tokens_output "${_styles_output_dir}/m3_tokens.css")

    add_custom_command(
        OUTPUT ${_tokens_stamp}
        COMMAND ${PYTHON3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/tools/scaffold_codegen/m3_tokens_css.py
            --tokens ${DESIGN_TOKENS}
            --output ${_tokens_output}
        COMMAND ${CMAKE_COMMAND} -E touch ${_tokens_stamp}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Generating M3 design tokens CSS (custom properties)"
        DEPENDS ${DESIGN_TOKENS} ${CMAKE_CURRENT_SOURCE_DIR}/tools/scaffold_codegen/m3_tokens_css.py
    )

    # -- 7b. Per-component HTML + CSS rendering loop
    set(_component_names
        data_table
        form_dialog
        navigation
        search_bar
        card
        state
    )
    set(_html_component_stamps "")
    set(_html_component_outputs "")

    foreach(_comp ${_component_names})
        set(_template_html "${_comp_templates_dir}/${_comp}.html.jinja2")
        set(_template_css "${_comp_templates_dir}/${_comp}.css.jinja2")
        set(_stamp_html "${CMAKE_CURRENT_BINARY_DIR}/template_gen/component_${_comp}_html.stamp")
        set(_stamp_css "${CMAKE_CURRENT_BINARY_DIR}/template_gen/component_${_comp}_css.stamp")
        set(_output_html "${_html_output_dir}/${_comp}.html")
        set(_output_css "${_html_output_dir}/${_comp}.css")
        set(_vars "${_comp_templates_dir}/${_comp}_vars.json")

        # HTML fragment
        add_custom_command(
            OUTPUT ${_stamp_html} ${_output_html}
            COMMAND ${PYTHON3_EXECUTABLE} ${ENGINE_SCRIPT}
                --template "components/${_comp}.html.jinja2"
                --tokens ${DESIGN_TOKENS}
                --output ${_output_html}
                --template-dir ${_scaffold_templates_dir}
                --vars ${_vars}
            COMMAND ${CMAKE_COMMAND} -E touch ${_stamp_html}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT "Rendering HTML component template: ${_comp}"
            DEPENDS ${_template_html} ${DESIGN_TOKENS} ${ENGINE_SCRIPT} ${_vars}
        )

        # CSS stylesheet
        add_custom_command(
            OUTPUT ${_stamp_css} ${_output_css}
            COMMAND ${PYTHON3_EXECUTABLE} ${ENGINE_SCRIPT}
                --template "components/${_comp}.css.jinja2"
                --tokens ${DESIGN_TOKENS}
                --output ${_output_css}
                --template-dir ${_scaffold_templates_dir}
                --vars ${_vars}
            COMMAND ${CMAKE_COMMAND} -E touch ${_stamp_css}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT "Rendering CSS component template: ${_comp}"
            DEPENDS ${_template_css} ${DESIGN_TOKENS} ${ENGINE_SCRIPT} ${_vars}
        )

        list(APPEND _html_component_stamps ${_stamp_html} ${_stamp_css})
        list(APPEND _html_component_outputs ${_output_html} ${_output_css})

        add_custom_target(generate_component_${_comp}_html
            COMMENT "Generate HTML + CSS for component: ${_comp}"
            DEPENDS ${_stamp_html} ${_stamp_css} ${_output_html} ${_output_css}
        )
    endforeach()

    list(APPEND _html_component_stamps ${_tokens_stamp})

    add_custom_target(generate_all_components_html
        COMMENT "Generate all 6 M3 component HTML fragments + CSS + m3_tokens.css"
        DEPENDS ${_html_component_stamps} ${_html_component_outputs}
    )
endif()
