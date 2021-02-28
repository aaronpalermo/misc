# All my misc tools, scripts, etc.
## VideoDownloader.py
There was a little too much exploration of video content in my house, especially during COVID-19 mandated tele-school time, so I fix the problem by:
1. Restricted DNS using [PiHole](https://pi-hole.net/) so the video site in question is not longer accessible by default.
1. Made this very simple web interface where I could submit URLs and have videos downloaded to watch locally.  

Think of this as a manual proxy when you want to control the content available in your house.  As an unintended benefit, videos can be streamed in the browser from the Raspberry Pi where this runs (the same Pi also runs pi-hole).  This means no downloading to space-limited Chromebooks, and a consistent experience across phones, tablets, PCs, and Chromebooks in the house.  And since the videos play in Chrome, they are also castable to the Chromecast plugged into the TV.

### TODO
I have a cronjob run nightly to remove everything in the yt directory.  I need to put a checkbox on the page to enable persistent videos.  I'll probably do this with a filename prefix or suffix, like MyCoolVid-temp.mp4 for files that will get deleted nighty via 'rm -f *-temp.mp4'

<a href="https://www.google.com">text link to google</a>
<hr>
Local Image link to google<br>
<a href="https://www.google.com"><img src="smile.png"></a>
<hr>
Remote image link to google<br>
<a href="https://www.google.com"><img src="https://sites.psu.edu/siowfa16/files/2016/10/YeDYzSR-10apkm4-300x295.png"></a>




























<a href ="https://www.google.com">text link to google</a>























Local Image link to google<br>
<a href="http://www.google.com"> <img src="smile.png"> </a>



























Remote image link to google<br>
<a href="http://google.com"> <img src="https://sites.psu.edu/siowfa16/files/2016/10/YeDYzSR-10apkm4-300x295.png"> </a>
