"""Widget-family generators.

Each module renders one ``templates/components/*.jinja2`` template into the
committed Dart files under ``lib/components/``. The template is the source of
truth: regenerate and ``git diff lib/`` to detect drift. Never hand-edit a
generated file. ``cpp_store`` renders a consuming project's
``<templates-dir>/<surface>/cpp`` set into that project's ``--output-dir``
tree (both paths passed as explicit required arguments; output gitignored
by the consumer, never committed).

    python3 -m scaffold_codegen.generators.animated_display
    python3 -m scaffold_codegen.generators.composites
    python3 -m scaffold_codegen.generators.cpp_store --templates-dir <dir> --output-dir <dir>
    python3 -m scaffold_codegen.generators.formatted_value
    python3 -m scaffold_codegen.generators.image_placeholder
    python3 -m scaffold_codegen.generators.selection_indicator
    python3 -m scaffold_codegen.generators.theme_defaults [--check]

``theme_defaults`` splices the generated regions of ``lib/theme`` from
``design_tokens.json``. ``python3 -m scaffold_codegen.generators`` runs every
committed generator.
"""

#: Output is committed under lib/ and drift-checked. The order is the run order.
COMMITTED_GENERATORS = (
    "animated_display",
    "composites",
    "formatted_value",
    "image_placeholder",
    "selection_indicator",
    "theme_defaults",
)

#: Renders into a consuming project's tree, needs explicit paths, never run by the drift check.
CONSUMER_GENERATORS = ("cpp_store",)
