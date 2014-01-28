SCPD Video Downloader
===============

**Download Videos from Stanford SCPD's new HTML5 website**

Stanford recently updated their SCPD website with a new HTML5 video player. Unfortunately, Stanford broke all existing tools to download these videos with this new update. However, the SCPD site provides links to download courses that you are enrolled in (perhaps defeats the purpose of this script) but there is no way to do this if you are only auditing the class. I found that one might like to enjoy downloading all of the files (at once) via a script for watching these videos offline. 

Previously Stanford limited the speed of the downloads to around 80kbps, now it seems they have removed that limit. I haven't made the code multithreaded for simplicity but will do so if feedback deems it necessary.

**Distributing SCPD lectures is against the terms of service. This script is for private use only!**

# System requirements

- Ruby >= 1.9.3 
- JSON gem (`gem install json`)
- [Mechanize gem](http://mechanize.rubyforge.org/) (`gem install mechanize`)
- ROTP gem(`gem install rotp`)
- [WATIR gem](http://watir.com/) (`gem install watir`)
- watir-webdriver gem (`gem install watir-webdriver`) for chrome/firefox downloads
- headless gem (`gem install headless`)
- yaml gem (`gem install yaml`)
- Firefox web browser

# Usage

Download all lectures to date:
```shell
ruby download.rb 'Department Name' 'Course Name' 
```

Download single lecture:
```shell
ruby download.rb 'Department Name' 'Course Name' lecture_num
```

Download range of lectures:
```shell
ruby download.rb 'Department Name' 'Course Name' start_lecture_num end_lec_num
```

The previous three commands will open up the firefox web browser and begin the download process. Unfortunately, due to Stanford's use of javascript it makes it impossible (or at least difficult) to load navigate the webpage without a browser. 

Get help: 
```shell
ruby download.rb -h
```

#Config Files

The script will require the user's username and password as well as a few two factor auth codes.
Stanford has also added a User Agreement that needs to be accepted when accessing a class that hasn't been viewed before. The script require several inputs from the user in order to proceed

It is possible to circumvent these inputs with a config file. Example can be found (`config/config_example.yml`)
editing the config file (`config/config.yml`) allows to set default values. 

##Config File Params##
- username: this is your SUNetID (the prefix to your email _____@stanford.edu)
- password: your SUNetID password (used to log into all stanford pages.)
- access_code is the two factor auth secret that is entered into the Google Authenticator (or other similar app) that generates 2 factor auth codes.Setting up a new authentication device (via https://accounts.stanford.edu/)
by specifying this value, this script shouldn't need to ask you for your codes.
- always_agree: the first time you access an scpd video from a certain class it will require you to agree to the Stanford terms and conditions for watching/downloading the films. By specifying always_agree: true you will automatically agree to these conditions. This tool is not to be used to violate these tools. by using this tool you already must agree to these terms, however setting this value will automatically agree for you.
- quality: specify either 720 or 540 to specify what quality videos are downloaded. for videos lasting ~1:15 a 540p video corresponds to around a 300MB file while 720 produces a 1.2GB file for each video downloaded.

# Disclaimer* 
The code is provided "as is" without any express or implied warranty of any kind including warranties of merchantability, non-infringement of intellectual property, or fitness for any particular purpose. In no event shall I be liable for any damages whatsoever (including, without limitation, damages for loss of profits, business interruption, loss of information, injury or death) arising out of the use of or inability to use the code, even if I have been advised of the possibility of such loss or damages. 

Piracy is bad. Very bad. And, I do not support or encourage piracy. Do not download a video that you're not allowed or entitled to. You are urged to use this script with good judgment, common sense, discretion, and assume full responsibility for misuse. I accept NO responsibility for your use of this tool.

By using this tool to download videos you agree to Stanford's SCPD User Agreement copied below:

Copyright
            The materials provided to you by the Stanford Center for Professional Development are copyrighted
            to Stanford University. Stanford grants you a limited license to use the materials solely in connection
            with the course for your own personal educational purposes. Any use of the materials outside of the
            course may be in violation of copyright law. You agree that you will not post, share or copy the materials.
            You agree that you will only save the materials for the duration of the course.

Penalties for Misuse
		Penalties for copyright infringement can be harsh. Fines of up to $150,000 in civil statutory damages may apply
           for each separate willful infringement, regardless of the actual damages involved. Stanford may also take
           administrative action against copyright infringement, including loss of networking privileges and SUNet ID,
           or disciplinary action up to and including termination for faculty and staff, and expulsion for students.

*disclaimer copied from [source](https://github.com/abhinavsood/download-scpd-videos)



