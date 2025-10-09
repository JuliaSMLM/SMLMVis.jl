#!/usr/bin/env julia
# Setup development environment for SMLMVis
# Run this once to set up dev environment for headless testing

println("="^80)
println("SMLMVis Dev Environment Setup (Headless/Remote)")
println("="^80)

using Pkg

# Get the SMLMVis root directory (parent of dev/)
smlmvis_root = dirname(@__DIR__)

println("\n1. Activating dev environment...")
Pkg.activate(joinpath(smlmvis_root, "dev"))

println("\n2. Adding local SMLMVis package...")
Pkg.develop(path=smlmvis_root)

println("\n3. Installing/updating dev dependencies...")
println("   This will install WGLMakie (browser-based backend)")
println("   GLMakie will NOT be installed (headless system)")
Pkg.add("WGLMakie")
Pkg.instantiate()

println("\n4. Checking package status...")
Pkg.status()

println("\n" * "="^80)
println("Dev Environment Setup Complete!")
println("="^80)

println("\nNext steps:")
println("  1. Test the viewer:")
println("     julia --project=dev dev/test_wgl_quick.jl")
println()
println("  2. On remote server, set up SSH tunnel:")
println("     ssh -L 9284:localhost:9284 user@server")
println()
println("  3. Open browser to:")
println("     http://localhost:9284")
println()
println("="^80)
