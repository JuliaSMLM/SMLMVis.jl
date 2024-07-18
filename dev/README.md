## Bugs

i just had a similar problem on an M2. i instantiated an environment which depended on VideoIO along with a bunch of other packages. VideoIO depends on FFMPEG, and for some reason, Pkg chose to try to install FFMPEG v0.2.4 with BinaryProvider v0.5.10, which failed with Platform arm64-apple-darwin22.4.0 is not an officially supported platform. if i then directly added FFMPEG myself to this environment, v0.4.1 was installed, BinaryProvider was removed, no other dependencies were changed, and everything worked.
