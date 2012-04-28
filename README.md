Install libusb:
brew install libusb --universal

Install OpenNI:
git clone https://github.com/OpenNI/OpenNI.git
git checkout unstable
cd Platform/Linux/CreateRedist
./RedistMaker

cd Platform/Linux/Redist/OpenNI-Bin-Dev-MacOSX-v1.5.2.23
sudo ./install.sh

sudo ln -s /usr/lib/libOpenNI.dylib /Applications/Xcode.app/Contents//Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.7.sdk/usr/lib/

To enable Kinect:

Set #define IsOpenNIEnabled (YES) in TFGLView.m.
