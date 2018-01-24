# Author: vtotient 
# Credit: Dr. Jesus C. Fraga: stripchart_sinewave.py code inside get_temp()
#         Google Speech APIs
#         https://pythonspot.com/speech-recognition-using-google-speech-api/ 
#         : for code inside voice_rec
# Requires PyAudio, PySpeech, matplotlib and numpy as well as the aditional serial
# libraries

# This is the User Interface for the embedded system. The user can use vocie 
# controls to either see a real time strip plot of the temperature or ask the
# computer for the current temperature. 
# Using Google's text to speech and speech to text to communicate with the user.

# Numpy libraries
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import sys, time, math

# Google's Speech API
import speech_recognition as sr
import pyttsx3 # this is an updated version of pyttsx for python 3

# Provided by class
import serial
import serial.tools.list_ports

# constansts
PORT = 'COM3' # For communicating which usb port the SPI is using
xsize = 100   # For plotting data 

# List of currently accepted voice commands:
string1 = str("what is the temperature")
string2 = str("temperature")
string3 = str("do I deserve a good grade")
string4 = str("plot")   

# List of possible responses:
init_response1 = "Welcome!"
init_response2 = "To use voice controls enter voice"
error_response = "Error. Please enter a valid input"
current_response = "The current temperature is"
degrees_response = "degrees Celsius"
hot_response = "Its kind of hot right now"
getting_hot_response = "Its getting pretty hot"
too_hot_response = "Should I alert the fire department?"
yes_response = "Yes, installing all the packages required was a huge pain in the ass"
plot_response = "Sure thing! I will now begin to plot the temperature as a strip plot"

def get_temp():
    try:
        ser.close();
    except:
        print();
    try:
        ser = serial.Serial(PORT, 115200, timeout=100)
    except:
        print ('Serial port %s is not available' % PORT);
        portlist=list(serial.tools.list_ports.comports())
        print('Trying with port %s' % portlist[0][0]);
        ser = serial.Serial(portlist[0][0], 115200, timeout=100)
        ser.isOpen()

    strin = ser.readline();
    return int(strin.decode('ascii'));


def voice_rec():
    # Record Audio
    r = sr.Recognizer()
    with sr.Microphone() as source:
        print("Hello there! You can ask me 'what is the temperature' ")
        audio = r.listen(source)

    # Speech recognition using Google Speech Recognition
    try:
        # for testing purposes, we're just using the default API key
        # to use another API key, use `r.recognize_google(audio, key="GOOGLE_SPEECH_RECOGNITION_API_KEY")`
        # instead of `r.recognize_google(audio)`
        print("You said: " + r.recognize_google(audio))
    except sr.UnknownValueError:
        print("Google Speech Recognition could not understand audio")
    except sr.RequestError as e:
        print("Could not request results from Google Speech Recognition service; {0}".format(e))
    return r.recognize_google(audio)

# This function uses Google's Speech API and checks to for the strings:
# "What is the temperature"
# "temperature"
# "go I deserve a good mark?"
def decode_voice_command(stringin):

    if stringin ==  string1:
        say_temp()

    elif stringin == string2:
        say_temp()

    elif stringin == string3:
        print("Yes!!\n\n")
        engine.say(yes_response)
        engine.runAndWait()

    elif stringin == string4:
        engine.say(plot_response)
        engine.runAndWait()
        import stripchart_sinewave
        execfile(stripchart_sinewave.py) # Display's strip plot of ambient temperature

    else:
        engine.say(error_response)
        engine.runAndWait()
        print("Error, not a valid command")
    return

# This function uses the voice engine to say the current temperature:
def say_temp():
    temp=get_temp()
    print(temp)         # print to the counsel the current temperature so user can compare with voice
    
    if temp <= 24:   
        str_temp=str(temp)  # cast the temperature into a string so that it is compatable with engine
        engine.say(current_response)
        engine.say(str_temp)
        engine.say(degrees_response)
        engine.runAndWait()

    elif temp >24 and temp <= 30:
        str_temp=str(temp)  # cast the temperature into a string so that it is compatable with engine
        engine.say(current_response)
        engine.say(str_temp)
        engine.say(degrees_response)
        engine.say(getting_hot_response) # just for fun (:
        engine.runAndWait()

    elif temp > 30:
        str_temp=str(temp)  # cast the temperature into a string so that it is compatable with engine
        engine.say(current_response)
        engine.say(str_temp)
        engine.say(degrees_response)
        engine.say(too_hot_response)    #just for fun (:
        engine.runAndWait()
    return

#initializing speech engine 
engine = pyttsx3.init()
rate = engine.getProperty('rate')
engine.setProperty('rate', rate-60)
# Main User Interface:

print("\n\nWelcome!\n\n\nTo use voice contorls enter: voice\n\n")
engine.say(init_response1)
engine.say(init_response2)
engine.runAndWait()

while True:
    x = str(input())
    if(x == "voice"):
        string = voice_rec()
        decode_voice_command(string) #compare the voice command and identify next action

    else:
        print("Error, please enter valid input\n")
