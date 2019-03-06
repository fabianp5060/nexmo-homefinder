# Homefinder Demo
A POC to show how buyers and agents can interact via programmable communications to enhance the home finding experience.  This demo will initiate an SMS message to a buyer (in the POC, this would be done automatically via geo-fencing technology).  The buyer will then interact with a chatbot and be provided with 3 options
* SHOW : This will provide a link to the MLS listing of the house the buyer is "close" to
* SCHEDULE : This will automatically schedule a showing with the agent and place a meeting invite on the agents calendar
* SEE : This will initiate an interactive webRTC session between buyer and agent that support voice/video/chat/screenshare
* MAP : This will provide a google map link to the house

## Getting Started
These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

#### Nexmo Account Info
Nexmo Developer Account: https://dashboard.nexmo.com/sign-up

#### Configure Environmental Variables
* ```export NEXMO_API_KEY='<NEXMO API Key>'```
* ```export NEXMO_API_SECRET='<NEXMO API Secret>'```
* ```export NEXMO_APPLICATION_PRIVATE_KEY_PATH='file_name'``` (assumes app_key is in root of app directory)
* ```export HOMEFINDER_DID='<SenderID for SMS>'```
* ```export HOMEFINDER_APP_ID='<Nexmo Application ID>'```
* ```export HOMEFINDER_APP_NAME='<Nexmo Application Name>'```
* ```export LB_WEB_SERVER2='<Web Server Root Domain>'```
** Note LB_WEB_SERVER2 is optional and will automatically attempt to locate the URLs for ngrok if running locally

#### Ruby Requirements
* Ruby RVM: https://rvm.io/
* Ruby Gem bundler: http://bundler.io/
* Ruby 2.5.1
* Nexmo Ruby GEM "nexmo-5.6"


### Installing

1. Clone github repo `https://github.com/fabianp5060/nexmo.git`
2. Install Bundler `gem install bundler`
3. Install Dependencies `bundler install`

### Starting the application
```rackup config.ru -o 0.0.0.0```

### Endpoints
* /login
** Fake a login page for an agent to associate their name and mobile number

* /homefinder
** Enables "agent" to fake geo-fencing and send an SMS to a buyer near a potential home

