using Revise 
using HDF5
using SMLMVis


groupname = "Channel01/Zposition001/Data0001"
h5open("example.h5", "w") do fid
    g = create_group(fid, groupname)
    dset = create_dataset(g, "Data0001", UInt16, (100,100,10,))
    write(dset,rand(UInt16,100,100,10))
end

file = h5open("example.h5", "r")
HDF5.show_tree(file)
close(file)


SMLMVis.MIC.mic2mp4("example.h5")
