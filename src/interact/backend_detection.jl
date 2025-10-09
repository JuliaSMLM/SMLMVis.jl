# Backend detection and environment analysis for interactive viewers

"""
    detect_best_backend()::Symbol

Automatically detect the best available backend based on environment and available packages.

Returns one of: `:GLMakie`, `:WGLMakie`, or `:none`

Priority order:
1. Check ENV["SMLMVIS_BACKEND"] for explicit override
2. Check which backends are loaded (registered)
3. Auto-detect based on environment (headless, SSH, notebook, display)
"""
function detect_best_backend()::Symbol
    # Allow explicit ENV override
    if haskey(ENV, "SMLMVIS_BACKEND")
        backend = Symbol(ENV["SMLMVIS_BACKEND"])
        if backend in (:GLMakie, :WGLMakie)
            return backend
        end
    end

    # Check what backends are already loaded/registered
    available = list_available_backends()

    # If both loaded, prefer based on environment
    if :WGLMakie in available && :GLMakie in available
        # Both available - smart selection based on environment
        if is_headless() || is_remote_session()
            return :WGLMakie
        else
            return :GLMakie
        end
    end

    # Return first available backend
    if !isempty(available)
        return first(available)
    end

    # Nothing loaded - recommend based on environment
    if is_headless() || is_remote_session() || is_notebook()
        return :WGLMakie  # Better for remote/browser scenarios
    elseif has_display()
        return :GLMakie   # Better for local desktop
    else
        return :WGLMakie  # Safest default
    end
end

"""
    is_headless()::Bool

Detect if running in a headless environment (no display server).

Checks:
- DISPLAY environment variable (Unix/Linux)
- WAYLAND_DISPLAY environment variable
- Platform-specific defaults
"""
function is_headless()::Bool
    if Sys.isunix()
        # Check for X11 or Wayland display
        display = get(ENV, "DISPLAY", "")
        wayland = get(ENV, "WAYLAND_DISPLAY", "")
        return isempty(display) && isempty(wayland)
    end

    # Windows and macOS typically have displays
    return false
end

"""
    is_remote_session()::Bool

Detect if running in a remote SSH session.

Checks for SSH-related environment variables:
- SSH_CONNECTION
- SSH_CLIENT
- SSH_TTY
"""
function is_remote_session()::Bool
    return haskey(ENV, "SSH_CONNECTION") ||
           haskey(ENV, "SSH_CLIENT") ||
           haskey(ENV, "SSH_TTY")
end

"""
    is_notebook()::Bool

Detect if running in a notebook environment (Jupyter, Pluto, etc.).

Checks for:
- IJulia initialization
- PlutoRunner presence
- JULIA_NOTEBOOK environment variable
"""
function is_notebook()::Bool
    # Check for IJulia
    if isdefined(Main, :IJulia)
        try
            return Main.IJulia.inited
        catch
            return false
        end
    end

    # Check for Pluto
    if isdefined(Main, :PlutoRunner)
        return true
    end

    # Check environment variable
    return get(ENV, "JULIA_NOTEBOOK", "") == "true"
end

"""
    has_display()::Bool

Check if a display is available for GUI windows.

Platform-specific checks:
- Unix: DISPLAY or WAYLAND_DISPLAY environment variables
- Windows/macOS: Assume display available (desktop OS)
"""
function has_display()::Bool
    if Sys.isunix()
        # Check for X11 or Wayland
        return !isempty(get(ENV, "DISPLAY", "")) ||
               !isempty(get(ENV, "WAYLAND_DISPLAY", ""))
    elseif Sys.iswindows() || Sys.isapple()
        # Desktop operating systems - assume display available
        return true
    end
    return false
end

"""
    recommend_backend_installation()::String

Generate helpful installation recommendation based on environment.
"""
function recommend_backend_installation()::String
    if is_headless() || is_remote_session()
        return """
        Recommended for your environment: WGLMakie (web-based)

        Install with:
            using Pkg
            Pkg.add("WGLMakie")
            using WGLMakie
            using SMLMVis.Interact
            stack_viewer(data)

        For remote viewing, use SSH port forwarding:
            ssh -L 9284:localhost:9284 user@server
            # Then open http://localhost:9284 in browser
        """
    elseif is_notebook()
        return """
        Recommended for notebooks: WGLMakie (displays inline)

        Install with:
            using Pkg
            Pkg.add("WGLMakie")
            using WGLMakie
            using SMLMVis.Interact
            stack_viewer(data)
        """
    else
        return """
        Recommended for your environment: GLMakie (desktop)

        Install with:
            using Pkg
            Pkg.add("GLMakie")
            using GLMakie
            using SMLMVis.Interact
            stack_viewer(data)
        """
    end
end
