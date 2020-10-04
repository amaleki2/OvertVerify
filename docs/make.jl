using OvertVerify
using Documenter

makedocs(;
    modules=[OvertVerify],
    authors="Amir Maleki, Chelsea Sidrane",
    repo="https://github.com/amaleki2/OvertVerify.jl/blob/{commit}{path}#L{line}",
    sitename="OvertVerify.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://amaleki2.github.io/OvertVerify.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/amaleki2/OvertVerify.jl",
)
