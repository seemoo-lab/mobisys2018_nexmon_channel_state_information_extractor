![NexMon logo](https://github.com/seemoo-lab/nexmon/raw/master/gfx/nexmon.png)

# Nexmon Channel State Information Extractor

This projects allows you to extract channel state information (CSI) of OFDM-modulated
Wi-Fi frames (802.11a/(g)/n/ac) on a per frame basis with up to 80 MHz bandwidth 
using BCM4339 Wi-Fi chips installed, for example, in Nexus 5 smartphones. 

After following the getting stated guide below, you can do the following to capture
raw CSI data on a per frame basis. As the extraction of CSI information takes some
time, we install a filter that compares the first 16 bytes of a Wi-Fi frame. In our
example, we consider beacon frames from an access point with MAC address 
`00:11:22:33:44:55`, running on Wi-Fi channel 100 with a bandwidth of 20 MHz: `64d0`.
By using a channel in the 5 GHz band, we make sure that it uses OFDM-modulated frames.

The following command can be used to prepare a base64-encoded payload for ioctl 500 to
set the channel, activate CSI extraction and set the frame filter (the 2 bytes channel 
specification needs to be flipped):

```
echo "d064010080000000ffffffffffff001122334455" | xxd -r -p | base64
```
We can then send the resulting string to our patched Wi-Fi firmware:
```
nexutil -s500 -l20 -b -vZNABAIAAAAD///////8AESIzRFU=
```
After activating monitor mode, we can capture the filtered frames, followed by a 
broadcasted UDP frame that includes the CSI information:
```
nexutil -m1
tcpdump -i wlan0 -xxx
```
To analyze the dumped CSI information, we provide some MATLAB functions in the 
`matlab` directory. They rely on reading dumped CSI information from pcap files
created using tcpdump. As an example, we provide the captures created for our
MobiSys 2018 paper. The result looks as follows:

![SEEMOO logo](https://raw.githubusercontent.com/seemoo-lab/mobisys2018_nexmon_channel_state_information_extractor/master/matlab/result.png)

# Extract from our License

Any use of the Software which results in an academic publication or
other publication which includes a bibliography must include
citations to the nexmon project a) and the paper cited under b) or 
the thesis cited under c):

   a) "Matthias Schulz, Daniel Wegemer and Matthias Hollick. Nexmon:
       The C-based Firmware Patching Framework. https://nexmon.org"

   b) "Matthias Schulz, Jakob Link, Francesco Gringoli, and Matthias 
       Hollick. Shadow Wi-Fi: Teaching Smartphones to Transmit Raw 
       Signals and to Extract Channel State Information to Implement 
       Practical Covert Channels over Wi-Fi. Accepted to appear in 
       Proceedings of the 16th ACM International Conference on Mobile 
       Systems, Applications, and Services (MobiSys 2018), June 2018."

   c) "Matthias Schulz. Teaching Your Wireless Card New Tricks: 
       Smartphone Performance and Security Enhancements through Wi-Fi
       Firmware Modifications. Dr.-Ing. thesis, Technische Universität
       Darmstadt, Germany, February 2018."

# Getting Started

To compile the source code, you are required to first clone the original nexmon repository 
that contains our C-based patching framework for Wi-Fi firmwares. Than you clone this 
repository as one of the sub-projects in the corresponding patches sub-directory. This 
allows you to build and compile all the firmware patches required to repeat our experiments.
The following steps will get you started on Xubuntu 16.04 LTS:

1. Install some dependencies: `sudo apt-get install git gawk qpdf adb`
2. **Only necessary for x86_64 systems**, install i386 libs: 

  ```
  sudo dpkg --add-architecture i386
  sudo apt-get update
  sudo apt-get install libc6:i386 libncurses5:i386 libstdc++6:i386
  ```
3. Clone the nexmon base repository: `git clone https://github.com/seemoo-lab/nexmon.git`.
4. Download and extract Android NDK r11c (use exactly this version!).
5. Export the NDK_ROOT environment variable pointing to the location where you extracted the 
   ndk so that it can be found by our build environment.
6. Navigate to the previously cloned nexmon directory and execute `source setup_env.sh` to set 
   a couple of environment variables.
7. Run `make` to extract ucode, templateram and flashpatches from the original firmwares.
8. Navigate to utilities and run `make` to build all utilities such as nexmon.
9. Attach your rooted Nexus 5 smartphone running stock firmware version 6.0.1 (M4B30Z, Dec 2016).
10. Run `make install` to install all the built utilities on your phone.
11. Navigate to patches/bcm4339/6_37_34_43/ and clone this repository: 
    `git clone https://github.com/seemoo-lab/mobisys2018_nexmon_channel_state_information_extractor.git`
12. Enter the created subdirectory mobisys2018_nexmon_channel_state_information_extractor and run 
    `make install-firmware` to compile our firmware patch and install it on the attached Nexus 5 
    smartphone.

# References

* Matthias Schulz, Daniel Wegemer and Matthias Hollick. **Nexmon: The C-based Firmware Patching 
  Framework**. https://nexmon.org
* Matthias Schulz, Jakob Link, Francesco Gringoli, and Matthias Hollick. **Shadow Wi-Fi: Teaching 
  Smartphones to Transmit Raw Signals and to Extract Channel State Information to Implement 
  Practical Covert Channels over Wi-Fi. Accepted to appear in *Proceedings of the 16th ACM 
  International Conference on Mobile Systems, Applications, and Services*, MobiSys 2018, June 2018.
* Matthias Schulz. **Teaching Your Wireless Card New Tricks: Smartphone Performance and Security 
  Enhancements through Wi-Fi Firmware Modifications**. Dr.-Ing. thesis, Technische Universität
  Darmstadt, Germany, February 2018.

[Get references as bibtex file](https://nexmon.org/bib)

# Contact

* [Matthias Schulz](https://seemoo.tu-darmstadt.de/mschulz) <mschulz@seemoo.tu-darmstadt.de>

# Powered By

## Secure Mobile Networking Lab (SEEMOO)
<a href="https://www.seemoo.tu-darmstadt.de">![SEEMOO logo](https://github.com/seemoo-lab/nexmon/raw/master/gfx/seemoo.png)</a>
## Networked Infrastructureless Cooperation for Emergency Response (NICER)
<a href="https://www.nicer.tu-darmstadt.de">![NICER logo](https://github.com/seemoo-lab/nexmon/raw/master/gfx/nicer.png)</a>
## Multi-Mechanisms Adaptation for the Future Internet (MAKI)
<a href="http://www.maki.tu-darmstadt.de/">![MAKI logo](https://github.com/seemoo-lab/nexmon/raw/master/gfx/maki.png)</a>
## Technische Universität Darmstadt
<a href="https://www.tu-darmstadt.de/index.en.jsp">![TU Darmstadt logo](https://github.com/seemoo-lab/nexmon/raw/master/gfx/tudarmstadt.png)</a>
## University of Brescia
<a href="http://netweb.ing.unibs.it/">![University of Brescia logo](https://github.com/seemoo-lab/nexmon/raw/master/gfx/brescia.png)</a>
