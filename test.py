from server import *
app = Chocolate()
@app.path("/")
def home(request, response):
    response.text = "Hello World!"
@app.path("/whrose/{name}.py")
def rose(request, response,name=""):
    response.text = "Hello %s!" % name
from werkzeug.serving import run_simple
#run_simple('localhost', 8080, app, debug=True)
#run_simple('localhost', 8080, app, use_reloader=True)
import werkzeug as w
print("Running on Werkzeug " + w.__version__)
run_simple('localhost', 8080, app, use_reloader=True)
