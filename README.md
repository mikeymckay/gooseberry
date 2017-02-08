# Gooseberry

A system for creating interactive SMS sessions. It stores SMS sessions in CouchDB. It uses Sinatra on ruby to manage incoming/outgoing messages. It can send and receive messages via SMS Gateways like https://africastalking.com/, http://www.bongolive.co.tz/ or phone based gateways like http://smssync.ushahidi.com/. It produces a single app webpage, deployed as a couchapp written in coffeescript (& backbone.js) to look at results (updated in realtime!) and edit the interactive SMS question sets. Results may be downloaded as a CSV.

## How to deploy
* Clone it
* Install the required Ruby gems
* Install couchdb
* Install couchappp
* Push code in couchapp directory to your couchdb
* Connect your web server to the Sinatra app (a unicorn example is in the code)
* Connect your SMS Gateway

That's the high level version. Please get in touch if you want to use it and we will make it easier to deploy.

## Why does the world need Gooseberry?

There are also plenty of tools that manage SMS interactions. https://textit.in/ is good and very visual. https://telerivet.com/ is also good. My experience is that for an interactive SMS system to capture good data you need to design good questions (exhaustive and mutually exclusive), with skip logic to minimize the # of questions, and lots of data validation - the more specific the better (for example if you ask for a city, validate that the city exists). I figured out how to do this sort of thing with Textit and Telerivet for various projects, but it was complex, cumbersome and expensive (you pay an extra amount per message with those services). 

This led me to build Gooseberry (https://github.com/mikeymckay/gooseberry), which is not particularly visual or beautiful but allows me and other non-programmers to quickly build what I consider are good interactive SMS sessions. With Gooseberry deployed on http://digitalocean.com and connected to AfricasTalking we have sent and received millions of SMS with it here in Kenya. On our biggest single day, we sent and received more than 500,000 SMS for 70,000 unique phone numbers. More information about that system can be found here: http://ictedge.org/gooseberry

### Question Set Structure

Good questions need to be designed carefully. Understand what exhaustive and mutually exclusive mean https://rmsbunkerblog.wordpress.com/2010/04/27/mutually-exclusive-collectively-exhaustive-survey-tips-market-research-syracuse-survey/. With Gooseberry, I wanted to easily add skip logic and data validation. Done right, this ensures the minimum number of questions are asked and the data received is high quality. Question sets in gooseberry are just json documents with a little section for each question and some properties that can be defined for each question:

```
  "questions": [
    {
      "text": "1/5 What is your name, as it appears on MPESA?",
      "post_process": "answer.gsub(/,/,' ').gsub(/  /,' ')",
      "validation": "'At least two names required' unless answer.match(/ /)"
    },
    {
      "text": "2/5 What is the ID number of the ECD center you are visiting?",
      "validation": "'An ID number only has numbers in it.' unless answer.match(/^\\d+$/)"
    },
    {
      "text": "3/5 How many hand washing facilities are available?",
      "validation": "'Answer should consist of a numbers only.' unless answer.match(/^\\d+$/)",
      "name": "number_hand_washing_facilities"
    },
    {
      "text": "4/5 Are the hand washing facilities functioning?",
      "post_process": "answer.upcase.gsub(/YES/,'Y').gsub(/NO/,'N')",
      "validation": "'Answer must be y or n' unless answer.match(/^(Y|N)$/)",
      "name": "facilities_functioning",
      "skip_if": "answers['number_hand_washing_facilities'] == '0'"
    },
    {
      "text": "5/5 Since there were no functioning hand washing facilities, what did you do??",
      "skip_if": "answers['facilities_functioning'] == 'Y' or answers['number_hand_washing_facilities'] == '0'"
    },
    ...
```
Currently the available properties include:

* **text** - what is the text for the question being sent
* **post_process** - ruby code to massage your data before validation & skip logic. Useful for getting things in the same case.
* **validation** - ruby code that will run against the reply to the question. If nil is returned then validation passes, otherwise the returned string will be used as the error message sent back to the user.
* **name** - variable name for the result. used for referring to the result of a previously answered question (within the same session) from skip_if statements, and also in the spreadsheet of results
* **skip_if** - ruby code. if result of eval'ing the code is true it will skip the question. Results from previously answered questions can be found by using the 'answers' hash which is populated using the name variable of the corresponding question.


### Question Set Options

In addition to the options described above which are question oriented, there are other options used to manage other behavior of the question set:

* **image_meta_data** - used to define what data to associate a response with an image (for example a scan of an attendance sheet) (see TUSOMETEACHER for example with cascading selects)
* **use_previous_results** - if a phone number already has a completed question set, then the previous results can be used to avoid retyping in the same infomration (for example the name can be pre-populated) (see TUSOMECSO for example)
* **exclude_from_previous_results** - which data elements from previous results should be ignored and re-asked even if the answer from last time is available.
* **complete_message** - the message to send when a question set is completed. Can use #{result['question_name']} to insert data into the message
* **pre-run-requirement** - code that will be executed as soon as a question set has been triggered. There is currently code in ValidationHelper called add_data that can be used by pre-run-requirement to run a query and load the results as answers to the current question set session. Any subsequent questions that match the pre-loaded results will be skipped.
