from flask import Flask, request, render_template
from flask_autoindex import AutoIndex
from pytube import YouTube
import os
import threading

app = Flask(__name__)
# idx = AutoIndex(app, browse_root=f'{os.path.curdir}/yt', add_url_rules=False)
idx = AutoIndex(app, browse_root='yt', add_url_rules=False)


@app.route('/yt')
@app.route('/yt/<path:path>')
def autoindex(path='.'):
    return idx.render_autoindex(path)


@app.route('/', methods=['GET', 'POST']) 
def index():
    if request.method == 'POST':
        url = request.form.get('url')
        title = request.form.get('title').replace(' ','_') + '.mp4'
        yt_thread = threading.Thread(target=yt_function, args=[url, title])
        yt_thread.start()
        return(f'''<h3>Your download and all past downloads are available at 
                <a href="yt">here.</a> <BR>All downloads are deleted every night at midnight!</h3>''')

    return '''<form method="POST">
                  <h3>This page downloads videos from VideoTube.</h3>
                  Enter URL to download from: <input type="text" name="url"><br>
                  Enter the video title here: <input type="text" name="title"><br>
                  <input type="submit" value="Submit"><br>
                  All downloads are deleted every night at midnight.
              </form>'''


def yt_function(url, title):
    try: os.remove("yt/YouTube.mp4")
    except: pass
    yt = YouTube(url)
    yt.streams.filter(progressive=True, file_extension='mp4').get_highest_resolution().download('yt')
    # print("Download complete")
    if {yt.title} == 'YouTube':
        os.rename(f"yt/YouTube.mp4",f'yt/{title}')


if __name__ == '__main__':
    if not os.path.exists('yt'):
        os.makedirs('yt')
    app.run(host='0.0.0.0', port='8000')
