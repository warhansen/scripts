## Basic networking for support technician

from bottle import route, run, request, template
import socket
import subprocess
import html2text

@route('/')
def index():
    return """
<center><h1>NOC's Network Tools<h1></center>
<h2>Telnet Check</h2>
<form action='/portCheck'>
  <table  border='1' style='border-spacing: 0'>
    <tr>
      <td>Host:</td>
      <td><input type='text' id='host' name='host'/></td>
    </tr>
    <tr>
      <td>Port:</td>
      <td><input type='text' id='port' name='port'/></td>
    </tr>
    <tr>
      <td colspan='2'><input type='submit'/></td>
    </tr>
  </table>
</form>
<hr/>
<h2>Ping Check</h2>
<form action='/ping'>
  <table  border='1' style='border-spacing: 0'>
    <tr>
      <td>Host:</td>
      <td><input type='text' id='host' name='host'/></td>
    </tr>
    <tr>
      <td colspan='2'><input type='submit'/></td>
    </tr>
  </table>
</form>
<hr/>
<h2>Traceroute Check</h2>
<form action='/traceroute'>
  <table  border='1' style='border-spacing: 0'>
    <tr>
      <td>Host:</td>
      <td><input type='text' id='host' name='host'/></td>
    </tr>
    <tr>
      <td colspan='2'><input type='submit'/></td>
    </tr>
  </table>
</form>
<hr/>
<h2>Curl Check</h2>
<form action='/curl'>
  <table  border='1' style='border-spacing: 0'>
    <tr>
      <td>Host:</td>
      <td><input type='text' id='host' name='host'/></td>
    </tr>
    <tr>
      <td colspan='2'><input type='submit'/></td>
    </tr>
  </table>
</form>
<hr/>
"""

@route('/portCheck')
def doPortCheck():
    host = request.query.host
    port = request.query.port
    cmd = ''.join(['/usr/bin/nmap ', '-p ', port, ' ', host, ' | grep open'])
    try:
        result = subprocess.check_output(cmd, shell=True)
    except subprocess.CalledProcessError as e:
        result = "closed"
    if "open" in result:
        return template('<h2>Telnet Result</h2><b>Trying {{host}}...<br/> Connected to {{host}}. <br/> Escape character is \'^]\'. </b><br/><br/><a href="/">&lt;&lt;-Back</a>', host=host, port=port)
    return template('<h2>Telnet Result</h2><b>Trying {{host}}... </b><br/><br/>(It appears the port is ** not ** available)<br/><br/><a href="/">&lt;&lt;-Back</a>', host=host, port=port)

@route('/ping')
def ping():
    host = request.query.host
    command = ''.join(['/bin/ping ', '-c ', '10 ', host])
    try:
        output = subprocess.check_output(command, shell=True) + '<br/>'
    except subprocess.CalledProcessError as e:
        output = template('<b>PING {{host}} 56(84) bytes of data. <br/> ---  {{host}} ping statistics --- <br/> 10 packets transmitted, 0 received, 100% packet loss, time 9245ms</b></br></br>', host=host)
    if '\n' in output:
        output = output.replace ( '\n', '<br/>' )
        if '\r' in output:
            output = output.replace ( '\r', '' )
    if '\r' in output:
        output = output.replace ( '\r', '<br/>' )
    result = '<h2>Ping Result</h2>' + output + '<a href="/">&lt;&lt;-Back</a>'
    return result

@route('/traceroute')
def traceroute():
    host = request.query.host
    command = ''.join(['/usr/bin/traceroute ',host])
    try:
        output = subprocess.check_output(command, shell=True) + '<br/>'
    except subprocess.CalledProcessError as e:
        output = '<b>%s is ** unreachable </b></br></br>' % host
    if '\n' in output:
        output = output.replace ( '\n', '<br/>' )
        if '\r' in output:
            output = output.replace ( '\r', '' )
    if '\r' in output:
        output = output.replace ( '\r', '<br/>' )
    result = '<h2>Traceroute Result</h2>' + output + '<a href="/">&lt;&lt;-Back</a>'
    return result

@route('/curl')
def curl():
    host = request.query.host
    command = ''.join(['/usr/bin/curl ','-k ','-m 5 ', host])
    try:
        output = subprocess.check_output(command, shell=True) + '<br/>'
    except subprocess.CalledProcessError as e:
        output = '<b>%s is ** unreachable  </b></br></br>' % host
    try:
       html2text.html2text(output)
    except:
       output = '<b>%s is ** reachable ** however there was a problem displaying the curl output  </b></br></br>' % host
    result = '<h2>Curl Result</h2>' + html2text.html2text(output)  + '<br/><br/> <a href="/">&lt;&lt;-Back</a>'   
    return result

run(host='0.0.0.0', port=8080)

