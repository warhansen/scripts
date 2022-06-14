# importing Flask and other modules
from flask import Flask, request, render_template

# Flask constructor
app = Flask(__name__)

# A decorator used to tell the application
# which URL is associated function
@app.route('/', methods =["GET", "POST"])
def gfg():
    if request.method == "POST":
       # getting input with name = date in HTML form
       date = request.form.get("date")
       # getting input with name = time in HTML form
       time = request.form.get("time")
       return "The time your servers should shut down is "+date +time
    return render_template("form.html")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
