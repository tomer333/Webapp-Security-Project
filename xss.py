#!/usr/bin/python3

#Project Webapp security - a tool that can create phishing pages and find XSS vulnerabilities
#xss.py - obtains variables from xss_request.txt, variables such as: url, cookies and data for sending a request
#Then configures to dictionaries and sends a request get to the url using the payload list

#import module requests to make a request to a web page, and print the response text
import requests

#xss_request.txt genrated from webapp.sh, has all information required to create get request
#information pass into lists but needed as strings or dictionaries
with open('xss_request.txt') as f:
	for line in f:
		if "url" in line:
			l_url = line.split(": ")
		if "cookies" in line:
			l_cookies = line.split(": ")
		if "data" in line:
			l_data = line.split(": ")

#sets values to strings instead of lists.
v_url=l_url[1][:-1]
v_cookies=l_cookies[1][:-1]
v_data=l_data[1][:-1]

#sets value cookies to dictionary.
x = v_cookies.split("; ")
cookies_dict={}
for i in range(0, len(x)):
	y = x[i].split("=")
	cookies_dict.update({y[0]:y[-1]})

#sets value data to dictionary.
x = v_data.split("&")
data_dict={}
for i in range(0, len(x)):
	y = x[i].split("=")
	data_dict.update({y[0]:y[-1]})

#count of successful payloads
count = 0

#read payloads list
xss_payloads = open("xss_payloads.txt", "r")
#append to results list
xss_results = open("xss_results.txt", "a")
xss_results.write(f"\033[1;35;40m[!] XSS Scan on:\033[0m {v_url}\n\n")

#The XSS attack
#loop running on paloads list to preform an attack with all payloads
for payload in xss_payloads:
	#positions payload into data dictionary
	x = {list(data_dict.keys())[0]: payload}
	data_dict.update(x)
	
	#makes a requests using the given url, data and cookies from xss_request.txt
	r = requests.get(v_url, data_dict, cookies = cookies_dict)
	
	#checking in response if payload managed to stay in page.	
	content=str(r.text)
	if payload in content:
		count += 1
		xss_results.write(f"\033[1;31;40m[*]\033[0m \033[1;36;40mPayload Found:\033[0m {payload}")

xss_results.write(f"\033[1;32;40m[+] Payloads success count is:\033[0m \033[1;33;40m{count}\033[0m out of 30\n")

#close opened files
xss_results.close()
xss_payloads.close()


