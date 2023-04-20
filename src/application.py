#scraper.py
#Derek Bandouveres
#re-edited for frontend stuff by Alex Vasquez 

from flask import Flask, render_template, request, jsonify
import tweepy
import json
import os

application = Flask(__name__)

auth = tweepy.OAuth2BearerHandler(
    "AAAAAAAAAAAAAAAAAAAAAPcQKQEAAAAA7pw20O9E5a6AXQFajxRsK6xj5zA%3DDsUWXed2WMoEzyPB1fvTiBSqxTeDEjOw3JgsrFzr8GI4HI8SLe"
)

api = tweepy.API(auth)

#Create list to hold tweets until they're dumped into JSON
def tweet_search(keyword, count):
    tweet_list = list()
    search_words = keyword.strip()
    search = tweepy.Cursor(api.search_tweets, q=search_words, lang="en", tweet_mode='extended').items(count)

    for tweet in search:
        if ((str(tweet.full_text.lower().encode('ascii', errors='ignore')).startswith("rt @")) == False):
            tweet_list.append(tweet._json)

    return json.dumps(tweet_list)


@application.route('/')
def home():
    return render_template('home.html')


@application.route('/search')
def search():
    search_keyword = request.args.get('keyword')
    
    if search_keyword is None:
        chat_bubbles = [{
            'username': 'System',
            'timestamp': '',
            'text': 'Please enter a keyword to search.',
            'user_input': False
        }]
        return render_template('home.html', chat_bubbles=chat_bubbles)
    
    search_results = json.loads(tweet_search(search_keyword, 50))
    chat_bubbles = [{
        'username': 'You',
        'timestamp': '',
        'text': f'Search results for "{search_keyword}"',
        'user_input': True
    }]
    for tweet in search_results:
        username = tweet['user']['screen_name']
        timestamp = tweet['created_at']
        text = tweet['full_text']
        chat_bubbles.append({
            'username': username,
            'timestamp': timestamp,
            'text': text,
            'user_input': False
        })
    return render_template('home.html', chat_bubbles=chat_bubbles, search_keyword=search_keyword)





@application.route('/tweets')
def tweets():
    search_keyword = request.args.get('keyword')
    search_results = json.loads(tweet_search(search_keyword, 500))
    return jsonify(search_results)


if __name__ == '__main__':
    application.run(host='0.0.0.0', port=5000)