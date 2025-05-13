using SMLMSim
using SMLMData

# Create output directory
mkpath("output")

# Get the API overview and save to a file
println("Getting SMLMSim API overview...")
open("output/smlmsim_api_overview.txt", "w") do io
    redirect_stdout(io) do
        SMLMSim.api_overview()
    end
end
println("SMLMSim API overview saved to output/smlmsim_api_overview.txt")

# Get the SMLMData API overview and save to a file
println("Getting SMLMData API overview...")
open("output/smlmdata_api_overview.txt", "w") do io
    redirect_stdout(io) do
        SMLMData.api_overview()
    end
end
println("SMLMData API overview saved to output/smlmdata_api_overview.txt")

println("Done!")