Turing Fluid
============

OSX version of @Flexi23's Turing Fluid demo: http://cake23.de/turing-fluid.html with Kinect support

A demo video: http://youtu.be/jVktMGVhPoE

Install libusb
==============

    brew install libusb --universal
    brew install doxygen

Install OpenNI
==============

    git clone https://github.com/OpenNI/OpenNI.git
    git checkout unstable
    cd Platform/Linux/CreateRedist
    ./RedistMaker

    cd Platform/Linux/Redist/OpenNI-Bin-Dev-MacOSX-v1.5.4.0    # dir name may change
    sudo ./install.sh

    sudo ln -s /usr/lib/libOpenNI.dylib /Applications/Xcode.app/Contents//Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.7.sdk/usr/lib/

Enable Kinect
==============

Set #define IsOpenNIEnabled (YES) in TFGLView.m.
