using Revise
using SMLMSim
using SMLMData
using Images
using SMLMVis

smld_true, smld_model, smld_noisy = SMLMSim.sim(;
    ρ=10,
    σ_PSF=0.13,  
    minphotons=50,
    ndatasets=10,
    nframes=1000,
    framerate=50.0, 
    pattern=SMLMSim.Nmer2D(),
    molecule=SMLMSim.GenericFluor(; q=[0 50; 1e-2 0]), #1/s 
    camera=SMLMSim.IdealCamera(; xpixels=256, ypixels=256, pixelsize=0.1)
    ) 

smld_noisy.x *= 10.0
smld_noisy.y *= 10.0
smld_noisy.σ_x *= 10.0
smld_noisy.σ_y *= 10.0
smld_noisy.datasize *= 10
out = render_blobs(smld_noisy; zoom = 20)
save("nmer2d.png", out)

# 3D
# Simulation sequence
n = length(smld_noisy.x)
smld3d = SMLMData.SMLD3D(n)
smld3d.x = smld_noisy.x
smld3d.y = smld_noisy.y
smld3d.z = rand(-1:.1:1, n)
smld3d.σ_x = smld_noisy.σ_x
smld3d.σ_y = smld_noisy.σ_y
smld3d.datasize = smld_noisy.datasize

length(smld3d.x)
out = render_blobs(smld3d; zoom = 20)
save("nmer3d.png", out)



