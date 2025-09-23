
using Revise
using HDF5
using SMLMData
using CairoMakie
CM = CairoMakie
using Statistics
using ColorSchemes
using Images

datapath = raw"T:\projects\smart-microscope\data\DNA paint ruler\2025-07-15\python\result_1ch/"
dataname = "20R-ruler-0.1exp-TIRF-onlyZFocusLockDT5-noPol--2025-07-15_01-32-51_loc_1ch_dme"
filename = datapath * dataname * ".h5"
f = h5open(filename, "r")
x = read(f["res/x"])
y = read(f["res/y"])
σ_x = read(f["res/crlb"])[1, :]
σ_y = read(f["res/crlb"])[2, :] 


#smld = SMLMData.SMLD2D(0)
x .-= minimum(x)
y .-= minimum(y)
datasize = ceil(maximum([maximum(x),maximum(y)]))
datasize = [Int(datasize), Int(datasize)]
srimg = Float32.(SMLMData.makegaussim([x y], [σ_x σ_y], datasize; mag = 20.0));


srimg1 = deepcopy(srimg);
Imax = quantile([srimg1...],0.999)
Imax = Float32(Imax)
srimg1[srimg1.>Imax].=Imax;
srimg1 = float.(srimg1./ Imax);
colored_img = map(x -> get(ColorSchemes.inferno, x), srimg1)
save(datapath*dataname*"_SRimg.png",colored_img)

# closing h5 file; maybe useful (not sure)
close(f)