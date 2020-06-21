# All my misc tools, scripts, etc.
## VideoDownloader.py
There was a little too much exploration of video content in my house, especially during COVID-19 mandated tele-school, so I 1) restricted DNS using PiHole, and 2) made this very simple web interface where I could submit URLs and have videos downloaded to watch locally.  Think of this as a manual proxy when you want to control the content in your house.
### TODO
I have a cronjob run nightly to remove everything in the yt directory.  I need to put a checkbox on the page to enable persistent videos.  I'll probably do this with a filename prefix or suffix, like MyCoolVid-temp.mp4 for files that will get deleted nighty via 'rm -f *-temp.mp4'

